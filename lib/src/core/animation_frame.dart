import 'package:flutter/foundation.dart';

/// {@template animation_frame}
/// Represents a single frame in a WebP animation with timing information.
///
/// Contains the frame index, delay from WebP metadata, and calculated timestamp
/// for efficient animation playback.
/// {@endtemplate}
@immutable
class AnimationFrame {
  /// {@macro animation_frame}
  const AnimationFrame({
    required this.index,
    required this.delay,
    required this.timestamp,
  });

  /// The zero-based frame index in the animation sequence.
  final int index;

  /// The delay duration for this frame as specified in the WebP metadata.
  final Duration delay;

  /// The cumulative timestamp when this frame should be displayed,
  /// calculated as the sum of all previous frame delays.
  final double timestamp;

  @override
  int get hashCode => Object.hash(index, delay, timestamp);

  @override
  bool operator ==(covariant final AnimationFrame other) {
    if (identical(this, other)) return true;
    return other.index == index &&
        other.delay == delay &&
        other.timestamp == timestamp;
  }

  /// Creates a copy of this frame with modified properties.
  AnimationFrame copyWith({
    final int? index,
    final Duration? delay,
    final double? timestamp,
  }) => AnimationFrame(
    index: index ?? this.index,
    delay: delay ?? this.delay,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  String toString() =>
      'AnimationFrame(index: $index, delay: $delay, timestamp: $timestamp)';
}
