import 'package:flutter/material.dart';

/// {@template webp_animation_item}
/// Represents a single WebP animation to be rendered in a [WebpAnimationLayer].
///
/// Defines the asset path, screen position, and render size for one animation
/// within a batch of multiple animations.
/// {@endtemplate}
@immutable
class WebpAnimationItem {
  /// {@macro webp_animation_item}
  const WebpAnimationItem({
    required this.asset,
    required this.position,
    required this.size,
  });

  /// Asset path to the WebP animation file.
  ///
  /// Should be a valid asset path that can be loaded via `rootBundle.load()`.
  final String asset;

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
  int get hashCode => Object.hash(asset, position, size);

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    return other is WebpAnimationItem &&
        other.asset == asset &&
        other.position == position &&
        other.size == size;
  }

  /// Creates a copy of this item with modified properties.
  WebpAnimationItem copyWith({
    final String? asset,
    final Offset? position,
    final Size? size,
  }) => WebpAnimationItem(
    asset: asset ?? this.asset,
    position: position ?? this.position,
    size: size ?? this.size,
  );

  @override
  String toString() =>
      'WebpAnimationItem(asset: $asset, position: $position, size: $size)';
}
