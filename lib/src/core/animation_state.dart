import '../core/sprite_sheet.dart';
import '../utils/frame_timing.dart';

/// {@template animation_state}
/// Manages animation timing and state without Flutter's AnimationController.
///
/// Provides pure time-based animation progression with support for different
/// timing modes (WebP frame delays vs custom FPS). Eliminates the overhead
/// of animation curves and provides direct control over animation timing.
/// {@endtemplate}
class AnimationState {
  /// {@macro animation_state}
  AnimationState({
    required this.spriteSheet,
    this.speed = 1.0,
    this.respectFrameDelays = true,
    this.fps = 24.0,
    this.loop = true,
  }) : assert(speed > 0, 'speed must be positive'),
       assert(fps > 0, 'fps must be positive');

  /// The sprite sheet containing animation data.
  final SpriteSheet spriteSheet;

  /// Playback speed multiplier (1.0 = normal speed).
  double speed;

  /// Whether to use WebP frame delays (true) or custom FPS (false).
  bool respectFrameDelays;

  /// Frames per second when respectFrameDelays is false.
  double fps;

  /// Whether to loop the animation continuously.
  bool loop;

  /// Current animation time in seconds.
  double _currentTime = 0;

  /// Whether the animation is currently playing.
  bool _isPlaying = false;

  /// Current frame index being displayed.
  int _currentFrameIndex = 0;

  /// Gets the current frame index.
  int get currentFrameIndex => _currentFrameIndex;

  /// Gets the current animation time in seconds.
  double get currentTime => _currentTime;

  /// Whether the animation has completed (only meaningful for non-looping).
  bool get isCompleted => !loop && _currentTime >= _totalDuration;

  /// Whether the animation is currently playing.
  bool get isPlaying => _isPlaying;

  /// Gets the animation progress (0.0 to 1.0).
  double get progress {
    if (spriteSheet.frameCount <= 1) return 0;

    final duration = _totalDuration;
    if (duration == 0.0) return 0;

    final loopedTime = loop
        ? _currentTime % duration
        : _currentTime.clamp(0.0, duration);
    return loopedTime / duration;
  }

  /// Gets the total duration of the animation in seconds.
  double get _totalDuration =>
      FrameTiming.getTotalDuration(
        spriteSheet: spriteSheet,
        respectFrameDelays: respectFrameDelays,
        fps: fps,
      ).inMilliseconds /
      1000.0;

  /// Pauses animation playback.
  ///
  /// @ai Call this to pause animation playback.
  void pause() {
    _isPlaying = false;
  }

  /// Starts or resumes animation playback.
  ///
  /// @ai Call this to begin animation playback.
  void play() {
    _isPlaying = true;
  }

  /// Stops animation and resets to beginning.
  ///
  /// @ai Call this to stop and reset animation.
  void reset() {
    _isPlaying = false;
    _currentTime = 0.0;
    _currentFrameIndex = 0;
  }

  /// Seeks to a specific frame index.
  ///
  /// @ai Use this for frame-based navigation.
  void seekToFrame(final int frameIndex) {
    final clampedFrame = frameIndex.clamp(0, spriteSheet.frameCount - 1);

    if (respectFrameDelays) {
      // Use WebP timing
      if (clampedFrame < spriteSheet.frames.length) {
        final frame = spriteSheet.frames[clampedFrame];
        _currentTime = frame.timestamp;
      }
    } else {
      // Custom FPS: uniform spacing
      final duration = FrameTiming.getTotalDuration(
        spriteSheet: spriteSheet,
        respectFrameDelays: false,
        fps: fps,
      ).inSeconds;

      _currentTime = (clampedFrame / (spriteSheet.frameCount - 1)) * duration;
    }

    _currentFrameIndex = clampedFrame;
  }

  /// Seeks to a specific time in seconds.
  ///
  /// @ai Use this for precise time-based seeking.
  void seekToTime(final double time) {
    _currentTime = time.clamp(0.0, double.infinity);
    _updateCurrentFrame();
  }

  @override
  String toString() =>
      'AnimationState('
      'currentTime: ${_currentTime.toStringAsFixed(2)}s, '
      'frame: $_currentFrameIndex/${spriteSheet.frameCount - 1}, '
      'isPlaying: $_isPlaying, '
      'progress: ${progress.toStringAsFixed(2)})';

  /// Updates the animation state with delta time.
  ///
  /// @ai Call this from your game loop with delta time.
  void update(final double deltaTime) {
    if (!_isPlaying) return;

    final adjustedDelta = deltaTime * speed;
    _currentTime += adjustedDelta;

    // Update current frame index
    _updateCurrentFrame();
  }

  /// Updates the timing configuration.
  ///
  /// @ai Call this when timing parameters change.
  void updateTiming({
    final double? speed,
    final bool? respectFrameDelays,
    final double? fps,
    final bool? loop,
  }) {
    this.speed = speed ?? this.speed;
    this.respectFrameDelays = respectFrameDelays ?? this.respectFrameDelays;
    this.fps = fps ?? this.fps;
    this.loop = loop ?? this.loop;

    // Re-calculate current frame with new timing
    _updateCurrentFrame();
  }

  /// Internal method to update the current frame index based on current time.
  void _updateCurrentFrame() {
    if (spriteSheet.frameCount <= 1) {
      _currentFrameIndex = 0;
      return;
    }

    final duration = _totalDuration;

    final loopedTime = loop
        ? _currentTime % duration
        : _currentTime.clamp(0.0, duration);
    final progress = duration > 0 ? loopedTime / duration : 0.0;

    _currentFrameIndex = FrameTiming.getFrameIndex(
      spriteSheet: spriteSheet,
      progress: progress,
      respectFrameDelays: respectFrameDelays,
      fps: fps,
    );
  }
}
