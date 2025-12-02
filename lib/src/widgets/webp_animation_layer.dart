import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/animation_state.dart';
import '../core/game_loop_controller.dart';
import '../core/sprite_sheet.dart';
import '../core/webp_decoder.dart';
import '../models/webp_animation_item.dart';
import '../models/webp_source.dart';
import '../painters/animation_painter.dart';
import 'webp_animation_layer_controller.dart';

/// {@template webp_animation_layer}
/// A widget that efficiently renders multiple WebP animations
/// in a single draw call.
///
/// Batches all animations together for optimal GPU performance, similar to
/// sprite batching in game engines. All animations share
/// the same timing settings.
/// {@endtemplate}
class WebpAnimationLayer extends StatefulWidget {
  /// {@macro webp_animation_layer}
  const WebpAnimationLayer({
    required this.animations,
    super.key,
    this.autoPlay = true,
    this.loop = true,
    this.speed = 1.0,
    this.respectFrameDelays = true,
    this.fps = 30.0,
    this.filterQuality = FilterQuality.medium,
    this.builder,
  }) : assert(animations.length > 0, 'animations list must be non-empty'),
       assert(speed > 0, 'speed must be positive'),
       assert(fps > 0, 'fps must be positive');

  /// List of animation items to render.
  final List<WebpAnimationItem> animations;

  /// Whether to start all animations automatically when loaded.
  final bool autoPlay;

  /// Whether to loop all animations continuously.
  final bool loop;

  /// Playback speed multiplier for all animations (1.0 = normal speed).
  final double speed;

  /// Whether to use WebP frame delays (true) or custom FPS (false).
  final bool respectFrameDelays;

  /// Frames per second when respectFrameDelays is false.
  final double fps;

  /// Quality of filtering when scaling animations.
  final FilterQuality filterQuality;

  /// Optional builder for custom loading/error states.
  ///
  /// Receives lists of sprite sheets and errors for all animations.
  /// Useful for custom loading indicators or error handling.
  final Widget Function(
    BuildContext context,
    List<SpriteSheet?> spriteSheets,
    List<Object?> errors,
  )?
  builder;

  @override
  State<WebpAnimationLayer> createState() => _WebpAnimationLayerState();
}

class _WebpAnimationLayerState extends State<WebpAnimationLayer>
    with TickerProviderStateMixin {
  late List<Future<SpriteSheet>> _spriteSheetFutures;
  late List<SpriteSheet?> _spriteSheets;
  late List<ui.Image?> _images;
  late List<Object?> _errors;
  late List<AnimationState?> _animationStates;

  WebpAnimationLayerController? _layerController;

  bool _allLoaded = false;

  @override
  Widget build(final BuildContext context) {
    // Use custom builder if provided
    if (widget.builder != null) {
      return widget.builder!(context, _spriteSheets, _errors);
    }

    // Default rendering
    return _buildLayerWidget();
  }

  @override
  void didUpdateWidget(final WebpAnimationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if animations changed
    if (!_areAnimationsEqual(oldWidget.animations, widget.animations)) {
      _layerController?.dispose();
      _layerController = null;
      _initializeState();
    } else {
      // Update timing parameters if they changed
      if (oldWidget.respectFrameDelays != widget.respectFrameDelays ||
          oldWidget.fps != widget.fps ||
          oldWidget.speed != widget.speed) {
        _updateLayerController();
      }
    }
  }

  @override
  void dispose() {
    _layerController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  bool _areAnimationsEqual(
    final List<WebpAnimationItem> a,
    final List<WebpAnimationItem> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Widget _buildLayerWidget() {
    // Check if any animations failed to load
    final hasErrors = _errors.any((final error) => error != null);
    if (hasErrors && !_allLoaded) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(
                'Some animations failed to load',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading state
    if (!_allLoaded) {
      return Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Render all animations in a single CustomPaint with game loop repaint
    return CustomPaint(
      isComplex: true,
      painter: AnimationPainter(
        spriteSheets: _spriteSheets,
        images: _images,
        repaint: _layerController?.gameLoopController,
        animationStates: _animationStates,
        animationItems: widget.animations,
        fit: BoxFit.fill, // Items define their own size
        alignment: Alignment.topLeft,
        filterQuality: widget.filterQuality,
      ),
    );
  }

  void _initializeState() {
    final count = widget.animations.length;

    _spriteSheets = List.filled(count, null);
    _images = List.filled(count, null);
    _errors = List.filled(count, null);
    _animationStates = List.filled(count, null);

    // Load all animations in parallel
    _spriteSheetFutures = widget.animations.map((final item) {
      final source = WebpSource.fromUri(item.uri);
      return WebpDecoder.decodeAnimation(source);
    }).toList();

    // Load animations
    unawaited(_loadAnimations());
  }

  Future<void> _loadAnimations() async {
    final futures = _spriteSheetFutures.asMap().entries.map((
      final entry,
    ) async {
      final index = entry.key;
      final future = entry.value;

      try {
        final spriteSheet = await future;
        if (!mounted) return;

        setState(() {
          _spriteSheets[index] = spriteSheet;
          _errors[index] = null;
        });

        // Create GPU image
        final image = await WebpDecoder.createImageFromSpriteSheet(spriteSheet);
        if (!mounted) return;

        setState(() {
          _images[index] = image;
        });

        // Create animation state for this animation
        if (_spriteSheets[index] != null) {
          _animationStates[index] = AnimationState(
            spriteSheet: _spriteSheets[index]!,
            speed: widget.speed,
            respectFrameDelays: widget.respectFrameDelays,
            fps: widget.fps,
            loop: widget.loop,
          );
        }
        // ignore: avoid_catches_without_on_clauses
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _errors[index] = error;
        });
      }
    });

    // Wait for all animations to load
    await Future.wait(futures);

    if (!mounted) return;

    setState(() {
      _allLoaded = true;
    });

    // Initialize game loop controller
    final gameLoopController = GameLoopController(vsync: this)
      ..onTick = _onGameLoopTick;

    // Create layer controller
    _layerController = WebpAnimationLayerController(
      gameLoopController: gameLoopController,
      animationStates: _animationStates.whereType<AnimationState>().toList(),
    );

    // Start playback if requested
    if (widget.autoPlay && _allLoaded) {
      unawaited(_layerController?.play());
    }
  }

  void _onGameLoopTick(final double deltaTime) {
    for (final state in _animationStates) {
      if (state != null) {
        state.update(deltaTime);
      }
    }
  }

  void _updateLayerController() {
    // Update all animation states with new timing parameters
    for (final state in _animationStates) {
      state?.updateTiming(
        speed: widget.speed,
        respectFrameDelays: widget.respectFrameDelays,
        fps: widget.fps,
      );
    }
  }
}
