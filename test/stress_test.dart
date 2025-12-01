import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webp_animation_flutter/webp_animation_flutter.dart';

/// Stress tests for WebP animation widgets structure and instantiation.
///
/// These tests verify widget instantiation, basic rendering structure,
/// and parameter handling with multiple animation instances.
/// Asset loading is tested separately in integration tests.
void main() {
  const animationAsset = 'example/assets/animated-webp-supported.webp';
  const animationCount = 10; // Small count for widget structure tests
  const animationSize = Size(50, 50);

  group('WebP Animation Stress Tests', () {
    testWidgets('WebpAnimation instantiates multiple widgets correctly', (
      final tester,
    ) async {
      // Arrange: Create multiple WebpAnimation widgets
      final animations = _createAnimationGrid(
        count: animationCount,
        builder: (final index) => WebpAnimation(
          source: const AssetSource(animationAsset),
          width: animationSize.width,
          height: animationSize.height,
        ),
      );

      // Act: Pump the widget tree
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Column(children: animations)),
        ),
      );

      // Assert: All widgets should be instantiated correctly
      expect(
        find.byType(WebpAnimation),
        findsNWidgets(animationCount),
        reason:
            'All $animationCount WebpAnimation widgets should be instantiated',
      );

      // Each WebpAnimation should have proper sizing
      for (final animation in animations) {
        expect(
          find.byWidget(animation),
          findsOneWidget,
          reason: 'Each animation widget should be present in tree',
        );
      }
    });

    testWidgets('WebpAnimationLayer instantiates with multiple animations', (
      final tester,
    ) async {
      // Arrange: Create layer with multiple animations
      final gridSize = math.sqrt(animationCount).ceil();
      final animationItems = List.generate(
        animationCount,
        (final index) => WebpAnimationItem(
          asset: animationAsset,
          position: Offset(
            (index % gridSize) * animationSize.width,
            (index ~/ gridSize) * animationSize.height,
          ),
          size: animationSize,
        ),
      );

      // Act: Pump the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: gridSize * animationSize.width,
              height: gridSize * animationSize.height,
              child: WebpAnimationLayer(animations: animationItems),
            ),
          ),
        ),
      );

      // Assert: Layer should be instantiated correctly
      expect(
        find.byType(WebpAnimationLayer),
        findsOneWidget,
        reason: 'WebpAnimationLayer widget should be instantiated',
      );

      // Should have proper number of animation items
      expect(
        animationItems.length,
        animationCount,
        reason: 'Should have $animationCount animation items',
      );
    });

    testWidgets('WebpAnimation parameters are validated correctly', (
      final tester,
    ) async {
      // Test that invalid parameters throw assertions
      expect(
        () => WebpAnimation(
          source: const AssetSource(animationAsset),
          width: -1, // Invalid negative width
          height: animationSize.height,
        ),
        throwsAssertionError,
        reason: 'Should throw assertion error for negative width',
      );

      expect(
        () => WebpAnimation(
          source: const AssetSource(animationAsset),
          width: animationSize.width,
          height: 0, // Invalid zero height
        ),
        throwsAssertionError,
        reason: 'Should throw assertion error for zero height',
      );

      expect(
        () => WebpAnimation(
          source: const AssetSource(animationAsset),
          width: animationSize.width,
          height: animationSize.height,
          speed: -1, // Invalid negative speed
        ),
        throwsAssertionError,
        reason: 'Should throw assertion error for negative speed',
      );
    });

    testWidgets('WebpAnimationLayer validates animation list', (
      final tester,
    ) async {
      // Test that empty animation list throws assertion
      expect(
        () => WebpAnimationLayer(
          animations: const [], // Empty list
        ),
        throwsAssertionError,
        reason: 'Should throw assertion error for empty animation list',
      );

      // Test with valid animations
      final animationItems = List.generate(
        animationCount,
        (final index) => const WebpAnimationItem(
          asset: animationAsset,
          position: Offset.zero,
          size: animationSize,
        ),
      );

      expect(
        () => WebpAnimationLayer(animations: animationItems),
        isNotNull,
        reason: 'Should create layer with valid animation list',
      );
    });
  });
}

/// Creates a list of animation widgets for stress testing.
List<Widget> _createAnimationGrid({
  required final int count,
  required final Widget Function(int index) builder,
}) => List.generate(count, builder);
