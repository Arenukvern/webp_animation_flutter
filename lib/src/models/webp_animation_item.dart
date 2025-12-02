import 'package:flutter/material.dart';

/// {@template webp_animation_item}
/// Represents a single WebP animation to be rendered in a [WebpAnimationLayer].
///
/// Defines the URI, screen position, and render size for one animation
/// within a batch of multiple animations.
/// {@endtemplate}
@immutable
class WebpAnimationItem {
  /// {@macro webp_animation_item}
  const WebpAnimationItem({
    required this.uri,
    required this.position,
    required this.size,
  });

  /// URI of the WebP animation file.
  ///
  /// - Use `Uri.parse('https://...')` for network sources
  /// - Use `Uri(path: 'assets/...')` or `Uri.parse('asset://assets/...')` for assets
  final Uri uri;

  /// Screen position where this animation should be rendered.
  ///
  /// The top-left corner of the animation will be positioned at this offset.
  final Offset position;

  /// Render size for the animation.
  ///
  /// The animation will be scaled to fit this size
  /// while maintaining aspect ratio
  /// if the size doesn't match the original frame dimensions.
  final Size size;

  @override
  int get hashCode => Object.hash(uri, position, size);

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is WebpAnimationItem &&
        other.uri == uri &&
        other.position == position &&
        other.size == size;
  }

  /// Creates a copy of this item with modified properties.
  WebpAnimationItem copyWith({
    final Uri? uri,
    final Offset? position,
    final Size? size,
  }) => WebpAnimationItem(
    uri: uri ?? this.uri,
    position: position ?? this.position,
    size: size ?? this.size,
  );

  @override
  String toString() =>
      'WebpAnimationItem(uri: $uri, position: $position, size: $size)';
}
