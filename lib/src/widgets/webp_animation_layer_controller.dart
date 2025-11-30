import '../core/animation_state.dart';
import '../core/game_loop_controller.dart';

/// {@template webp_animation_layer_controller}
/// Controller for managing multiple animations in a layer using game loop timing.
///
/// Provides unified control over all animations in a WebpAnimationLayer,
/// maintaining the same API while using the new game loop system internally.
/// {@endtemplate}
class WebpAnimationLayerController {
  /// {@macro webp_animation_layer_controller}
  WebpAnimationLayerController({
    required this.gameLoopController,
    final List<AnimationState>? animationStates,
  }) : _animationStates = animationStates ?? [];

  /// The underlying GameLoopController.
  final GameLoopController gameLoopController;

  /// Animation states for all animations in the layer.
  final List<AnimationState> _animationStates;

  /// Whether any animations have completed (only meaningful for non-looping).
  bool get isCompleted =>
      _animationStates.any((final state) => state.isCompleted);

  /// Whether any animations are currently playing.
  bool get isPlaying => _animationStates.any((final state) => state.isPlaying);

  /// Disposes of the controller and cleans up resources.
  void dispose() {
    gameLoopController.dispose();
  }

  /// Calculates and returns the current frame indices for all animations.
  ///
  /// Returns a list where each index corresponds to the current frame
  /// for that animation in the layer.
  List<int> getCurrentFrameIndices() =>
      _animationStates.map((final state) => state.currentFrameIndex).toList();

  /// Pauses all animations at their current frames.
  void pause() {
    for (final state in _animationStates) {
      state.pause();
    }
    gameLoopController.stop();
  }

  /// Starts playing all animations.
  ///
  /// Animations will loop continuously.
  Future<void> play() async {
    for (final state in _animationStates) {
      state
        ..reset()
        ..play();
    }
    await gameLoopController.start();
  }

  /// Resets all animations to their first frames and stops playback.
  void reset() {
    for (final state in _animationStates) {
      state.reset();
    }
    gameLoopController.stop();
  }

  /// Seeks to a specific progress point (0.0 to 1.0).
  ///
  /// All animations will jump to the corresponding frame.
  void seek(final double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    for (final state in _animationStates) {
      final duration = state.spriteSheet.totalDuration.inSeconds;
      state.seekToTime(clampedProgress * duration);
    }
  }
}
