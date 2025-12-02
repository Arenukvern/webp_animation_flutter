import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/animation_state.dart';
import '../core/game_loop_controller.dart';
import '../core/sprite_sheet.dart';
import '../core/webp_decoder.dart';
import '../models/webp_source.dart';
import '../painters/animation_painter.dart';
import 'webp_animation_controller.dart';

/// {@template webp_animation}
/// A widget that displays a WebP animation
/// with efficient sprite sheet rendering.
///
/// Features isolate-based decoding, flexible timing control,
///  and smooth performance.
/// Supports both automatic playback and custom AnimationController integration.
/// {@endtemplate}
class WebpAnimation extends StatefulWidget {
  /// {@macro webp_animation}
  const WebpAnimation({
    required this.uri,
    required this.width,
    required this.height,
    super.key,
    this.autoPlay = true,
    this.loop = true,
    this.speed = 1.0,
    this.respectFrameDelays = true,
    this.fps = 30.0,
    this.controller,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.builder,
  }) : assert(width > 0, 'width must be positive'),
       assert(height > 0, 'height must be positive'),
       assert(speed > 0, 'speed must be positive'),
       assert(fps > 0, 'fps must be positive');

  /// URI of the WebP animation file.
  ///
  /// - Use `Uri.parse('https://...')` for network sources
  /// - Use `Uri(path: 'assets/...')` or `Uri.parse('asset://assets/...')` for assets
  final Uri uri;

  /// Width of the animation display area.
  final double width;

  /// Height of the animation display area.
  final double height;

  /// Whether to start playing automatically when loaded.
  final bool autoPlay;

  /// Whether to loop the animation continuously.
  final bool loop;

  /// Playback speed multiplier (1.0 = normal speed).
  final double speed;

  /// Whether to use WebP frame delays (true) or custom FPS (false).
  final bool respectFrameDelays;

  /// Frames per second when respectFrameDelays is false.
  final double fps;

  /// Optional custom AnimationController for advanced control.
  final AnimationController? controller;

  /// How the animation should be fitted within the display area.
  final BoxFit fit;

  /// How the animation should be aligned within the display area.
  final Alignment alignment;

  /// Quality of filtering when scaling the animation.
  final FilterQuality filterQuality;

  /// Optional builder for custom loading/error states.
  ///
  /// If provided, returns a widget instead of the default animation rendering.
  /// Useful for custom loading indicators or error handling.
  final Widget Function(
    BuildContext context,
    SpriteSheet? spriteSheet,
    Object? error,
  )?
  builder;

  @override
  State<WebpAnimation> createState() => _WebpAnimationState();
}

class _WebpAnimationState extends State<WebpAnimation>
    with TickerProviderStateMixin {
  late Future<SpriteSheet> _spriteSheetFuture;
  SpriteSheet? _spriteSheet;
  ui.Image? _image;
  Object? _error;

  AnimationState? _animationState;
  WebpAnimationController? _webpController;

  /// Gets the WebpAnimationController for this animation.
  ///
  /// Only available when no custom controller is provided.
  WebpAnimationController? get webpController => _webpController;

  @override
  Widget build(final BuildContext context) {
    // Use custom builder if provided
    if (widget.builder != null) {
      return widget.builder!(context, _spriteSheet, _error);
    }

    // Default rendering
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildAnimationWidget(),
    );
  }

  @override
  void didUpdateWidget(final WebpAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload if uri changed
    if (oldWidget.uri != widget.uri) {
      unawaited(_loadAnimation());
    }

    // Update controller if timing parameters changed
    if (oldWidget.respectFrameDelays != widget.respectFrameDelays ||
        oldWidget.fps != widget.fps ||
        oldWidget.speed != widget.speed) {
      _updateAnimationController();
    }
  }

  @override
  void dispose() {
    _webpController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadAnimation());
  }

  Widget _buildAnimationWidget() {
    // Show error state
    if (_error != null) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Failed to load animation',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading state
    if (_spriteSheet == null || _image == null || _animationState == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Render animation with game loop
    return CustomPaint(
      painter: AnimationPainter(
        spriteSheets: [_spriteSheet],
        images: [_image],
        repaint: _webpController?.gameLoopController,
        animationStates: [_animationState],
        fit: widget.fit,
        alignment: widget.alignment,
        filterQuality: widget.filterQuality,
      ),
    );
  }

  void _initializeAnimationController() {
    if (_spriteSheet == null) return;

    // Create animation state
    _animationState = AnimationState(
      spriteSheet: _spriteSheet!,
      speed: widget.speed,
      respectFrameDelays: widget.respectFrameDelays,
      fps: widget.fps,
      loop: widget.loop,
    );

    // Use provided controller or create our own game loop
    if (widget.controller == null) {
      final gameLoopController = GameLoopController(vsync: this)
        ..onTick = _onGameLoopTick;

      _webpController = WebpAnimationController(
        gameLoopController: gameLoopController,
        animationState: _animationState,
      );
    }
  }

  Future<void> _loadAnimation() async {
    final source = WebpSource.fromUri(widget.uri);
    _spriteSheetFuture = WebpDecoder.decodeAnimation(source);
    try {
      final spriteSheet = await _spriteSheetFuture;
      if (!mounted) return;

      setState(() {
        _spriteSheet = spriteSheet;
        _error = null;
      });

      try {
        final image = await WebpDecoder.createImageFromSpriteSheet(spriteSheet);
        if (!mounted) return;

        setState(() {});
        _image = image;

        // Initialize animation controller
        _initializeAnimationController();

        // Start playback if requested
        if (widget.autoPlay && _animationState != null) {
          unawaited(_webpController?.play());
        }
        // ignore: avoid_catches_without_on_clauses
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e;
        });
      }
      // ignore: avoid_catches_without_on_clauses
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
      });
    }
  }

  void _onGameLoopTick(final double deltaTime) {
    if (_animationState != null) {
      _animationState!.update(deltaTime);
    }
  }

  void _updateAnimationController() {
    if (_animationState == null) return;

    _animationState!.updateTiming(
      speed: widget.speed,
      respectFrameDelays: widget.respectFrameDelays,
      fps: widget.fps,
    );
  }
}
