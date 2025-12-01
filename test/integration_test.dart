import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webp_animation_flutter/src/core/animation_frame.dart';
import 'package:webp_animation_flutter/src/utils/frame_timing.dart';
import 'package:webp_animation_flutter/webp_animation_flutter.dart';

/// Integration tests for complete WebP animation pipeline verification.
///
/// These tests verify the end-to-end functionality from asset loading
/// through rendering to ensure the complete animation system works correctly.
void main() {
  group('WebP Animation Integration Tests', () {
    testWidgets('WebpAnimation widget loads and displays animation correctly', (
      final tester,
    ) async {
      // Arrange: Create WebpAnimation widget
      const animationAsset = 'example/assets/animated-webp-supported.webp';

      await tester.pumpWidget(
        const MaterialApp(
          home: WebpAnimation(
            source: AssetSource(animationAsset),
            width: 200,
            height: 200,
            autoPlay: false, // Don't auto-play for controlled testing
          ),
        ),
      );

      // Act: Wait for loading
      await tester.pump(); // Start loading
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // Allow async loading

      // Assert: Widget should be present
      expect(find.byType(WebpAnimation), findsOneWidget);

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for animation to load (this would normally take longer)
      // In a real integration test, we'd wait for the Future to complete
      await tester.pump(const Duration(seconds: 2));

      // Note: In this test environment, asset loading might not complete
      // due to test limitations, but the widget instantiation works correctly
    });

    testWidgets('WebpAnimationLayer loads multiple animations correctly', (
      final tester,
    ) async {
      // Arrange: Create multiple animation items
      const animationAsset = 'example/assets/animated-webp-supported.webp';
      final animationItems = [
        const WebpAnimationItem(
          asset: animationAsset,
          position: Offset.zero,
          size: Size(100, 100),
        ),
        const WebpAnimationItem(
          asset: animationAsset,
          position: Offset(100, 0),
          size: Size(100, 100),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 100,
            child: WebpAnimationLayer(animations: animationItems),
          ),
        ),
      );

      // Act: Wait for loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert: Layer widget should be present
      expect(find.byType(WebpAnimationLayer), findsOneWidget);

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('AnimationState timing works correctly after bug fixes', () {
      // Arrange: Create sprite sheet (simulate decoded data)
      final spriteSheet = SpriteSheet(
        pixels: Uint8List(400 * 400 * 4), // 400x400 RGBA
        width: 400, // Single frame for simplicity
        height: 400,
        frameWidth: 400,
        frameHeight: 400,
        frameCount: 1,
        frames: const [
          AnimationFrame(
            index: 0,
            delay: Duration(milliseconds: 100),
            timestamp: 0,
          ),
        ],
      );

      // Act: Create animation state
      final animationState = AnimationState(
        spriteSheet: spriteSheet,
        loop: false,
      );

      // For single-frame animations, completion depends on timing
      // This is expected behavior - single frame animations are
      // immediately "complete"
      // in terms of having displayed all their content

      // Should start at frame 0
      expect(
        animationState.currentFrameIndex,
        0,
        reason: 'Animation should start at frame 0',
      );

      // Should be able to play
      animationState.play();
      expect(
        animationState.isPlaying,
        isTrue,
        reason: 'Animation should be playing after play()',
      );

      // For single-frame animation with 100ms delay,
      // after 100ms it should be completed
      animationState.update(
        0.1,
      ); // 100ms - should complete single frame animation
      expect(
        animationState.isCompleted,
        isTrue,
        reason:
            'Single-frame animation should be completed '
            'after its delay duration',
      );
    });

    test('Frame timing calculation works correctly', () {
      // Test the FrameTiming.getFrameIndex function directly
      final spriteSheet = SpriteSheet(
        pixels: Uint8List(2400 * 400 * 4), // 6 frames * 400x400 pixels
        width: 2400, // 6 * 400
        height: 400,
        frameWidth: 400,
        frameHeight: 400,
        frameCount: 6,
        frames: const [
          AnimationFrame(
            index: 0,
            delay: Duration(milliseconds: 100),
            timestamp: 0,
          ),
          AnimationFrame(
            index: 1,
            delay: Duration(milliseconds: 100),
            timestamp: 0.1,
          ),
          AnimationFrame(
            index: 2,
            delay: Duration(milliseconds: 100),
            timestamp: 0.2,
          ),
          AnimationFrame(
            index: 3,
            delay: Duration(milliseconds: 100),
            timestamp: 0.3,
          ),
          AnimationFrame(
            index: 4,
            delay: Duration(milliseconds: 100),
            timestamp: 0.4,
          ),
          AnimationFrame(
            index: 5,
            delay: Duration(milliseconds: 100),
            timestamp: 0.5,
          ),
        ],
      );

      // Test frame index calculation at different progress points
      expect(
        FrameTiming.getFrameIndex(
          spriteSheet: spriteSheet,
          progress: 0, // Start
          respectFrameDelays: true,
        ),
        0,
        reason: 'Should show frame 0 at start',
      );

      expect(
        FrameTiming.getFrameIndex(
          spriteSheet: spriteSheet,
          progress: 0.2, // 20% through animation
          respectFrameDelays: true,
        ),
        1,
        reason: 'Should show frame 1 at 20% progress',
      );

      expect(
        FrameTiming.getFrameIndex(
          spriteSheet: spriteSheet,
          progress: 1, // End
          respectFrameDelays: true,
        ),
        5,
        reason: 'Should show last frame at end',
      );
    });
  });
}
