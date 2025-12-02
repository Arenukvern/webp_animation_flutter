import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/sprite_sheet.dart';
import '../core/webp_decoder.dart';
import '../models/static_image_sheet.dart';
import '../models/webp_source.dart';
import '../painters/animation_painter.dart';

/// {@template webp_static_image}
/// A widget that displays a static WebP image with efficient GPU rendering.
/// Optimized for single-frame images without animation overhead.
/// {@endtemplate}
class WebpStaticImage extends StatefulWidget {
  /// {@macro webp_static_image}
  const WebpStaticImage({
    required this.uri,
    required this.width,
    required this.height,
    super.key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.builder,
  }) : assert(width > 0, 'width must be positive'),
       assert(height > 0, 'height must be positive');

  /// URI of the WebP image file.
  ///
  /// - Use `Uri.parse('https://...')` for network sources
  /// - Use `Uri(path: 'assets/...')` or `Uri.parse('asset://assets/...')` for assets
  final Uri uri;

  /// Width of the image display area.
  final double width;

  /// Height of the image display area.
  final double height;

  /// How the image should be fitted within the display area.
  final BoxFit fit;

  /// How the image should be aligned within the display area.
  final Alignment alignment;

  /// Quality of filtering when scaling the image.
  final FilterQuality filterQuality;

  /// Optional builder for custom loading/error states.
  ///
  /// If provided, returns a widget instead of the default image rendering.
  /// Useful for custom loading indicators or error handling.
  final Widget Function(
    BuildContext context,
    StaticImageSheet? imageSheet,
    Object? error,
  )?
  builder;

  @override
  State<WebpStaticImage> createState() => _WebpStaticImageState();
}

class _WebpStaticImageState extends State<WebpStaticImage> {
  Future<StaticImageSheet>? _imageSheetFuture;
  StaticImageSheet? _imageSheet;
  ui.Image? _image;
  Object? _error;

  @override
  Widget build(final BuildContext context) {
    // Use custom builder if provided
    if (widget.builder != null) {
      return widget.builder!(context, _imageSheet, _error);
    }

    // Default rendering
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildImageWidget(),
    );
  }

  @override
  void didUpdateWidget(final WebpStaticImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload if uri changed
    if (oldWidget.uri != widget.uri) {
      unawaited(_loadImage());
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadImage());
  }

  Widget _buildImageWidget() {
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
                'Failed to load image',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading state
    if (_imageSheet == null || _image == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Render static image
    return CustomPaint(
      painter: AnimationPainter(
        spriteSheets: [null], // Not used for static rendering
        images: [_image],
        animationStates: [null], // Not used for static rendering
        staticImageSheets: [_imageSheet],
        fit: widget.fit,
        alignment: widget.alignment,
        filterQuality: widget.filterQuality,
      ),
    );
  }

  Future<void> _loadImage() async {
    final source = WebpSource.fromUri(widget.uri);
    _imageSheetFuture = WebpDecoder.decodeStatic(source);
    try {
      final imageSheet = await _imageSheetFuture!;
      if (!mounted) return;

      setState(() {
        _imageSheet = imageSheet;
        _error = null;
      });

      try {
        final image = await WebpDecoder.createImageFromSpriteSheet(
          // Convert StaticImageSheet to SpriteSheet structure for GPU upload
          // Reuses the same GPU texture upload path as animated sprites
          SpriteSheet(
            pixels: imageSheet.pixels,
            width: imageSheet.width,
            height: imageSheet.height,
            frameWidth: imageSheet.width,
            frameHeight: imageSheet.height,
            frameCount: 1,
            frames: const [],
          ),
        );
        if (!mounted) return;

        setState(() {
          _image = image;
        });
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
}
