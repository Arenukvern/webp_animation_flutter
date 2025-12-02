import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/animation_state.dart';
import '../core/sprite_sheet.dart';
import '../models/static_image_sheet.dart';
import '../models/webp_animation_item.dart';

/// {@template animation_painter}
/// Unified painter for rendering WebP animations with optimal GPU performance.
///
/// Supports both single animations and batched multi-animation rendering.
/// Uses efficient GPU operations to minimize draw calls
/// and maximize frame rates.
/// {@endtemplate}
class AnimationPainter extends CustomPainter {
  /// {@macro animation_painter}
  AnimationPainter({
    required this.spriteSheets,
    required this.images,
    required this.animationStates,
    this.animationItems,
    this.staticImageSheets,
    this.fit = BoxFit.contain,
    super.repaint,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
  }) : assert(
         spriteSheets.length == images.length,
         'spriteSheets and images must have same length',
       ),
       assert(
         spriteSheets.length == animationStates.length,
         'spriteSheets and animationStates must have same length',
       ),
       assert(
         animationItems == null || animationItems.length == spriteSheets.length,
         'animationItems length must match spriteSheets when provided',
       ),
       assert(
         staticImageSheets == null || staticImageSheets.length == images.length,
         'staticImageSheets length must match images when provided',
       );

  /// Sprite sheets for all animations to render.
  final List<SpriteSheet?> spriteSheets;

  /// GPU images for all sprite sheets.
  final List<ui.Image?> images;

  /// Animation states for all animations.
  final List<AnimationState?> animationStates;

  /// Animation items defining positions and sizes (for batch rendering).
  /// If null, renders as single animation filling the canvas.
  final List<WebpAnimationItem>? animationItems;

  /// Static image sheets for rendering static images.
  /// If provided, takes precedence over animation rendering.
  final List<StaticImageSheet?>? staticImageSheets;

  /// How to fit animations within their bounds.
  final BoxFit fit;

  /// How to align animations within their bounds.
  final Alignment alignment;

  /// Quality of filtering for scaling.
  final FilterQuality filterQuality;

  @override
  void paint(final Canvas canvas, final Size size) {
    if (images.isEmpty) {
      return;
    }

    // Check if we have static images to render
    final hasStaticImages = staticImageSheets != null &&
        staticImageSheets!.isNotEmpty &&
        staticImageSheets![0] != null;

    final paint = Paint()
      ..filterQuality = filterQuality
      ..isAntiAlias = true;

    if (animationItems == null) {
      // Single mode - fill the entire canvas
      if (hasStaticImages) {
        _paintSingleStaticImage(canvas, size, paint);
      } else {
        _paintSingleAnimation(canvas, size, paint);
      }
    } else {
      // Batch mode - render multiple items
      if (hasStaticImages) {
        _paintBatchStaticImages(canvas, size, paint);
      } else {
        _paintBatchAnimations(canvas, size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant final AnimationPainter oldDelegate) => true;

  @override
  String toString() =>
      'AnimationPainter('
      'count: ${spriteSheets.length}, '
      'batchMode: ${animationItems != null}, '
      'staticMode: ${staticImageSheets != null}, '
      'fit: $fit, '
      'alignment: $alignment)';

  /// Applies BoxFit logic to calculate fitted size.
  Size _applyBoxFit(final Size inputSize, final Size outputSize) {
    if (inputSize.isEmpty || outputSize.isEmpty) return Size.zero;

    switch (fit) {
      case BoxFit.fill:
        return outputSize;

      case BoxFit.contain:
        final scale = math.min(
          outputSize.width / inputSize.width,
          outputSize.height / inputSize.height,
        );
        return Size(inputSize.width * scale, inputSize.height * scale);

      case BoxFit.cover:
        final scale = math.max(
          outputSize.width / inputSize.width,
          outputSize.height / inputSize.height,
        );
        return Size(inputSize.width * scale, inputSize.height * scale);

      case BoxFit.fitWidth:
        final scale = outputSize.width / inputSize.width;
        return Size(inputSize.width * scale, inputSize.height * scale);

      case BoxFit.fitHeight:
        final scale = outputSize.height / inputSize.height;
        return Size(inputSize.width * scale, inputSize.height * scale);

      case BoxFit.none:
        return inputSize;

      case BoxFit.scaleDown:
        final scale = math.min(
          1,
          math.min(
            outputSize.width / inputSize.width,
            outputSize.height / inputSize.height,
          ),
        );
        return Size(inputSize.width * scale, inputSize.height * scale);
    }
  }

  /// Calculates destination rectangle based on fit and alignment.
  Rect _calculateDestinationRect(
    final Size canvasSize,
    final Size contentSize,
    final Size bounds,
  ) {
    final fittedSize = _applyBoxFit(contentSize, bounds);

    final offset = alignment.alongSize(
      Size(bounds.width - fittedSize.width, bounds.height - fittedSize.height),
    );

    return Rect.fromLTWH(
      offset.dx,
      offset.dy,
      fittedSize.width,
      fittedSize.height,
    );
  }

  /// Paints multiple animations in batch mode.
  void _paintBatchAnimations(
    final Canvas canvas,
    final Size size,
    final Paint paint,
  ) {
    final items = animationItems;
    if (items == null) return;
    final batchData = <ui.Image>[];
    final transforms = <RSTransform>[];
    final rects = <Rect>[];
    final colors = <Color>[];

    for (int i = 0; i < items.length; i++) {
      final spriteSheet = spriteSheets[i];
      final image = images[i];
      final animationState = animationStates[i];
      final item = items[i];

      if (spriteSheet == null || image == null || animationState == null) {
        continue;
      }

      final frameIndex = animationState.currentFrameIndex;
      final srcRect = spriteSheet.getFrameRect(frameIndex);
      final dstRect = Rect.fromLTWH(
        item.position.dx,
        item.position.dy,
        item.size.width,
        item.size.height,
      );

      // For batch rendering, we need to prepare data for drawAtlas
      batchData.add(image);
      transforms.add(
        RSTransform.fromComponents(
          rotation: 0,
          scale: dstRect.width / srcRect.width,
          anchorX: 0,
          anchorY: 0,
          translateX: dstRect.left,
          translateY: dstRect.top,
        ),
      );
      rects.add(srcRect);
      colors.add(const Color(0xFFFFFFFF));
    }

    if (batchData.isNotEmpty) {
      // Single draw call for all animations
      canvas.drawAtlas(
        batchData.first, // All images should be the same for batching
        transforms,
        rects,
        colors,
        BlendMode.srcOver,
        null,
        paint,
      );
    }
  }

  /// Paints a single animation filling the entire canvas.
  void _paintSingleAnimation(
    final Canvas canvas,
    final Size size,
    final Paint paint,
  ) {
    final spriteSheet = spriteSheets[0];
    final image = images[0];
    final animationState = animationStates[0];

    if (spriteSheet == null || image == null || animationState == null) {
      return;
    }

    final frameIndex = animationState.currentFrameIndex;
    final srcRect = spriteSheet.getFrameRect(frameIndex);
    final dstRect = _calculateDestinationRect(size, srcRect.size, size);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  /// Paints a single static image filling the canvas.
  void _paintSingleStaticImage(
    final Canvas canvas,
    final Size size,
    final Paint paint,
  ) {
    final staticImageSheet = staticImageSheets?[0];
    final image = images[0];

    if (staticImageSheet == null || image == null) {
      return;
    }

    final srcRect = staticImageSheet.imageRect;
    final dstRect = _calculateDestinationRect(size, srcRect.size, size);

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  /// Paints multiple static images in batch mode.
  void _paintBatchStaticImages(
    final Canvas canvas,
    final Size size,
    final Paint paint,
  ) {
    final items = animationItems;
    if (items == null || staticImageSheets == null) return;

    for (int i = 0; i < items.length; i++) {
      final staticImageSheet = staticImageSheets![i];
      final image = images[i];
      final item = items[i];

      if (staticImageSheet == null || image == null) {
        continue;
      }

      final srcRect = staticImageSheet.imageRect;
      final dstRect = Rect.fromLTWH(
        item.position.dx,
        item.position.dy,
        item.size.width,
        item.size.height,
      );

      canvas.drawImageRect(image, srcRect, dstRect, paint);
    }
  }
}
