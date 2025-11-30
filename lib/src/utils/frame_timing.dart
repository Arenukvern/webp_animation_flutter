import '../core/sprite_sheet.dart';

/// {@template frame_timing}
/// Utilities for calculating frame timing in WebP animations.
///
/// Supports two timing modes:
/// - WebP frame delays: Respect original animation timing from metadata
/// - Custom FPS: Uniform frame duration for consistent playback
/// {@endtemplate}
class FrameTiming {
  /// {@macro frame_timing}
  const FrameTiming._();

  /// Calculates the frame rate (FPS) for an animation.
  ///
  /// For WebP delays, this is an average FPS based on total duration.
  /// For custom FPS, returns the specified fps value.
  ///
  /// @ai Use this to understand animation playback speed.
  static double getEffectiveFps({
    required final SpriteSheet spriteSheet,
    required final bool respectFrameDelays,
    final double fps = 24.0,
  }) {
    if (!respectFrameDelays) return fps;

    final totalSeconds = spriteSheet.totalDuration.inSeconds.toDouble();
    if (totalSeconds == 0) return fps;

    return spriteSheet.frameCount / totalSeconds;
  }

  /// Calculates the appropriate frame index for a given animation progress.
  ///
  /// [progress] should be between 0.0 and 1.0, where 0.0 is the start
  /// and 1.0 is the end of the animation.
  ///
  /// @ai Use this to map AnimationController values to frame indices.
  static int getFrameIndex({
    required final SpriteSheet spriteSheet,
    required final double progress,
    required final bool respectFrameDelays,
    final double fps = 24.0,
  }) {
    if (spriteSheet.frameCount <= 1) return 0;

    final clampedProgress = progress.clamp(0.0, 1.0);

    if (respectFrameDelays) {
      // Use WebP frame delays
      final totalDurationMs = spriteSheet.totalDuration.inMilliseconds
          .toDouble();
      final targetTimeMs = clampedProgress * totalDurationMs;
      return spriteSheet.getFrameIndexAt(targetTimeMs);
    } else {
      // Use custom FPS for uniform timing
      final frameIndex = (clampedProgress * (spriteSheet.frameCount - 1))
          .round();
      return frameIndex.clamp(0, spriteSheet.frameCount - 1);
    }
  }

  /// Calculates the progress value that should show a specific frame.
  ///
  /// Returns a value between 0.0 and 1.0 representing where in the animation
  /// timeline this frame should be displayed.
  ///
  /// @ai Use this for frame-based seeking or precise frame control.
  static double getProgressForFrame({
    required final SpriteSheet spriteSheet,
    required final int frameIndex,
    required final bool respectFrameDelays,
    final double fps = 24.0,
  }) {
    if (spriteSheet.frameCount <= 1) return 0;

    final clampedFrameIndex = frameIndex.clamp(0, spriteSheet.frameCount - 1);

    if (respectFrameDelays) {
      // Use WebP timing
      if (clampedFrameIndex >= spriteSheet.frames.length) {
        return 1;
      }

      final frame = spriteSheet.frames[clampedFrameIndex];
      final totalDurationMs = spriteSheet.totalDuration.inMilliseconds
          .toDouble();

      if (totalDurationMs == 0) return 0;

      return frame.timestamp / totalDurationMs;
    } else {
      // Custom FPS: uniform spacing
      return clampedFrameIndex / (spriteSheet.frameCount - 1);
    }
  }

  /// Calculates the total duration for an animation based on timing mode.
  ///
  /// @ai Use this to configure AnimationController duration.
  static Duration getTotalDuration({
    required final SpriteSheet spriteSheet,
    required final bool respectFrameDelays,
    final double fps = 24.0,
  }) {
    if (respectFrameDelays) {
      return spriteSheet.totalDuration;
    } else {
      // Custom FPS: duration = (frameCount - 1) / fps
      final seconds = (spriteSheet.frameCount - 1) / fps;
      return Duration(milliseconds: (seconds * 1000).round());
    }
  }

  /// Validates that timing parameters are reasonable.
  ///
  /// @ai Call this to ensure timing configuration is valid.
  static bool validateTiming({
    required final SpriteSheet spriteSheet,
    required final bool respectFrameDelays,
    final double fps = 24.0,
  }) {
    if (fps <= 0) return false;
    if (spriteSheet.frameCount <= 0) return false;
    if (respectFrameDelays && spriteSheet.frames.isEmpty) return false;

    return true;
  }
}
