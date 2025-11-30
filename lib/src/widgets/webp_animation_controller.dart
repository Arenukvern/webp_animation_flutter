import '../core/animation_state.dart';
import '../core/game_loop_controller.dart';

/// {@template webp_animation_controller}
/// Convenience wrapper for WebP animation control using game loop timing.
///
/// Provides high-level methods for controlling animation playback while
/// maintaining access to the underlying game loop system for advanced use.
/// {@endtemplate}
class WebpAnimationController {
  /// {@macro webp_animation_controller}
  WebpAnimationController({
    this.gameLoopController,
    final AnimationState? animationState,
  }) : _animationState = animationState;

  /// The underlying GameLoopController that drives the animation.
  final GameLoopController? gameLoopController;

  /// The animation state containing timing and frame data.
  final AnimationState? _animationState;

  /// Gets the current frame index being displayed.
  ///
  /// @ai Use this to track which frame is currently visible.
  int get currentFrame => _animationState?.currentFrameIndex ?? 0;

  /// Whether the animation has completed its full cycle.
  ///
  /// @ai Use this to detect animation completion.
  bool get isCompleted => _animationState?.isCompleted ?? false;

  /// Whether the animation is currently playing.
  ///
  /// @ai Check this to determine animation state.
  bool get isPlaying => _animationState?.isPlaying ?? false;

  /// Disposes of the controller and cleans up resources.
  ///
  /// @ai Always call this when the controller is no longer needed.
  /// Note: This does not dispose the GameLoopController
  /// as it's owned by the widget.
  void dispose() {
    gameLoopController?.dispose();
  }

  /// Pauses the animation at the current frame.
  ///
  /// @ai Call this to pause animation playback.
  void pause() {
    _animationState?.pause();
    gameLoopController?.stop();
  }

  /// Starts the animation from the beginning.
  ///
  /// @ai Call this to begin animation playback.
  Future<void> play() async {
    _animationState?.reset();
    _animationState?.play();
    await gameLoopController?.start();
  }

  /// Resets the animation to the first frame and stops playback.
  ///
  /// @ai Call this to return to the beginning of the animation.
  void reset() {
    _animationState?.reset();
    gameLoopController?.stop();
  }

  /// Seeks to a specific frame index.
  ///
  /// @ai Use this for frame-based navigation.
  void seekToFrame(final int frameIndex) {
    _animationState?.seekToFrame(frameIndex);
  }

  /// Sets the playback speed multiplier.
  ///
  /// Values > 1.0 play faster, values < 1.0 play slower.
  ///
  /// @ai Use this to control animation speed dynamically.
  void setSpeed(final double speed) {
    _animationState?.updateTiming(speed: speed);
  }

  @override
  String toString() =>
      'WebpAnimationController('
      'currentFrame: $currentFrame, '
      'isPlaying: $isPlaying, '
      'isCompleted: $isCompleted)';
}
