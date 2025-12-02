import 'dart:typed_data';

import 'package:flutter/material.dart';

/// {@template static_image_sheet}
/// Represents a single-frame WebP image as a static image sheet.
/// Optimized for static image rendering without animation overhead.
/// {@endtemplate}
@immutable
class StaticImageSheet {
  /// {@macro static_image_sheet}
  const StaticImageSheet({
    required this.pixels,
    required this.width,
    required this.height,
  });

  /// Raw RGBA pixel data as Uint8List, ready for GPU upload.
  final Uint8List pixels;

  /// Width of the image.
  final int width;

  /// Height of the image.
  final int height;

  @override
  int get hashCode => Object.hash(width, height);

  /// Calculates the image rectangle for rendering.
  Rect get imageRect =>
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

  /// Validates that the static image data is consistent.
  bool get isValid =>
      pixels.isNotEmpty &&
      width > 0 &&
      height > 0 &&
      pixels.length == width * height * 4; // RGBA

  @override
  bool operator ==(covariant final StaticImageSheet other) {
    if (identical(this, other)) return true;
    return other.width == width &&
        other.height == height &&
        other.pixels.length == pixels.length;
  }

  @override
  String toString() =>
      'StaticImageSheet(width: $width, height: $height, valid: $isValid)';
}
