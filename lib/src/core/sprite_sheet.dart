import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'animation_frame.dart';

/// {@template sprite_sheet}
/// Represents a decoded WebP animation as a sprite sheet
/// ready for GPU rendering.
///
/// Contains the raw pixel data, dimensions, and frame metadata for efficient
/// animation playback. All frames are packed horizontally
/// into a single texture.
/// {@endtemplate}
@immutable
class SpriteSheet {
  /// {@macro sprite_sheet}
  const SpriteSheet({
    required this.pixels,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.frames,
  });

  /// Raw RGBA pixel data as Uint8List, ready for GPU upload.
  final Uint8List pixels;

  /// Total width of the sprite sheet (frameWidth * frameCount).
  final int width;

  /// Height of the sprite sheet (same as individual frame height).
  final int height;

  /// Width of a single frame.
  final int frameWidth;

  /// Height of a single frame.
  final int frameHeight;

  /// Total number of frames in the animation.
  final int frameCount;

  /// List of frame metadata with timing information.
  final List<AnimationFrame> frames;

  @override
  int get hashCode =>
      Object.hash(width, height, frameWidth, frameHeight, frameCount);

  /// Validates that the sprite sheet data is consistent.
  bool get isValid {
    if (pixels.isEmpty ||
        width <= 0 ||
        height <= 0 ||
        frameWidth <= 0 ||
        frameHeight <= 0 ||
        frameCount <= 0) {
      return false;
    }

    // Check that the pixel data matches the expected size
    final expectedPixelCount = width * height * 4; // RGBA
    if (pixels.length != expectedPixelCount) {
      return false;
    }

    // Check that frames list matches frameCount
    if (frames.length != frameCount) {
      return false;
    }

    // Validate frame indices
    for (int i = 0; i < frames.length; i++) {
      if (frames[i].index != i) {
        return false;
      }
    }

    return true;
  }

  /// Calculates the total duration of the animation based on frame delays.
  Duration get totalDuration {
    if (frames.isEmpty) return Duration.zero;
    return Duration(milliseconds: (frames.last.timestamp * 1000).round());
  }

  @override
  bool operator ==(covariant final SpriteSheet other) {
    if (identical(this, other)) return true;
    return other.width == width &&
        other.height == height &&
        other.frameWidth == frameWidth &&
        other.frameHeight == frameHeight &&
        other.frameCount == frameCount;
  }

  /// Gets the frame at the specified index, clamping to valid range.
  AnimationFrame getFrame(final int index) {
    if (frames.isEmpty) {
      throw StateError('SpriteSheet has no frames');
    }
    return frames[index.clamp(0, frames.length - 1)];
  }

  /// Finds the appropriate frame index for a given timestamp in the animation.
  ///
  /// @param timestamp Time in milliseconds from animation start.
  int getFrameIndexAt(final double timestampMs) {
    if (frames.isEmpty) return 0;

    // Handle timestamps beyond the total duration
    final totalMs = totalDuration.inMilliseconds.toDouble();
    if (timestampMs >= totalMs && frames.isNotEmpty) {
      return frames.length - 1;
    }

    // Binary search for the appropriate frame
    // Convert frame timestamps from seconds to milliseconds for comparison
    int left = 0;
    int right = frames.length - 1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final frame = frames[mid];
      final frameTimestampMs = frame.timestamp * 1000.0;

      if (timestampMs < frameTimestampMs) {
        right = mid - 1;
      } else if (mid < frames.length - 1) {
        final nextFrameTimestampMs = frames[mid + 1].timestamp * 1000.0;
        if (timestampMs >= nextFrameTimestampMs) {
          left = mid + 1;
        } else {
          return frame.index;
        }
      } else {
        return frame.index;
      }
    }

    return frames.isNotEmpty ? frames.first.index : 0;
  }

  /// Calculates the source rectangle for a given frame
  /// index in the sprite sheet.
  Rect getFrameRect(final int frameIndex) {
    final clampedIndex = frameIndex.clamp(0, frameCount - 1);
    final x = clampedIndex * frameWidth.toDouble();
    return Rect.fromLTWH(x, 0, frameWidth.toDouble(), frameHeight.toDouble());
  }

  @override
  String toString() =>
      'SpriteSheet('
      'width: $width, '
      'height: $height, '
      'frameCount: $frameCount, '
      'totalDuration: $totalDuration)';
}
