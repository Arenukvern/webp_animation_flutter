// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// {@template game_loop_controller}
/// Provides a pure game loop timing system without animation curves.
///
/// This controller delivers consistent delta time updates for smooth animation
/// playback, similar to game engines. It eliminates the overhead of Flutter's
/// AnimationController by providing direct delta time values.
/// {@endtemplate}
class GameLoopController with ChangeNotifier {
  /// {@macro game_loop_controller}
  GameLoopController({
    required this.vsync,
    this.maxFrameTime = 1.0 / 60.0, // Cap at 60 FPS
  }) {
    _ticker = vsync.createTicker(_tick);
  }

  /// The ticker provider for frame synchronization.
  final TickerProvider vsync;

  /// Maximum frame time to prevent spiral of death (default: ~60 FPS).
  final double maxFrameTime;

  late final Ticker _ticker;

  /// Current delta time in seconds since last frame.
  double _deltaTime = 0;

  /// Timestamp of the last frame.
  Duration _lastTime = Duration.zero;

  /// Whether the game loop is currently running.
  bool _isRunning = false;

  /// Callback invoked on each frame with delta time.
  void Function(double deltaTime)? onTick;

  /// Gets the current delta time in seconds.
  double get deltaTime => _deltaTime;

  /// Whether the game loop is currently running.
  bool get isRunning => _isRunning;

  /// Disposes of the controller and cleans up resources.
  ///
  /// @ai Always call this when the controller is no longer needed.
  @override
  void dispose() {
    stop();
    _ticker.dispose();
    super.dispose();
  }

  /// Starts the game loop.
  ///
  /// @ai Call this to begin animation updates.
  Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    _lastTime = Duration.zero; // Will be set on first tick
    await _ticker.start();
  }

  /// Stops the game loop.
  ///
  /// @ai Call this to pause animation updates.
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _ticker.stop();
  }

  @override
  String toString() =>
      'GameLoopController(deltaTime: ${_deltaTime.toStringAsFixed(4)}s, isRunning: $_isRunning)';

  /// Internal tick handler that calculates delta time.
  void _tick(final Duration time) {
    if (!_isRunning) return;

    // Calculate delta time
    if (_lastTime != Duration.zero) {
      final rawDelta = (time - _lastTime).inMicroseconds / 1e6;
      _deltaTime = rawDelta.clamp(0.0, maxFrameTime);
    } else {
      _deltaTime = 1.0 / 60.0; // Assume 60 FPS for first frame
    }

    _lastTime = time;

    // Notify listeners
    onTick?.call(_deltaTime);
    notifyListeners();
  }
}
