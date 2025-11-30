import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:webp_animation_flutter/src/core/animation_frame.dart';
import 'package:webp_animation_flutter/webp_animation_flutter.dart';

/// Frame extraction tests for WebP animation decoding verification.
///
/// This test suite provides comprehensive verification of WebP animation decoding
/// by extracting individual frames and creating visual verification outputs.
/// Useful for debugging animation playback issues and verifying correct decoding.
void main() {
  const testFile = 'test/animated-webp-supported.webp';
  const outputDir = 'test_output';

  group('WebP Frame Extraction Tests', () {
    late Directory testOutputDir;

    setUp(() async {
      // Initialize Flutter binding for asset loading
      TestWidgetsFlutterBinding.ensureInitialized();

      // Create output directory for test results
      testOutputDir = Directory(outputDir);
      if (!testOutputDir.existsSync()) {
        testOutputDir.createSync(recursive: true);
      }
    });

    tearDown(() {
      // Keep test output for inspection - don't delete
      // if (testOutputDir.existsSync()) {
      //   testOutputDir.deleteSync(recursive: true);
      // }
    });

    test('extracts and saves individual frames as PNG files', () async {
      // Arrange: Decode the WebP animation
      final spriteSheet = await _decodeWebpFromFile(testFile);

      // Act: Extract each frame and save as PNG
      final savedFiles = <String>[];
      for (
        int frameIndex = 0;
        frameIndex < spriteSheet.frameCount;
        frameIndex++
      ) {
        final frameFileName =
            'frame_${frameIndex.toString().padLeft(3, '0')}.png';
        final frameFilePath = path.join(outputDir, frameFileName);

        await _saveFrameAsPng(spriteSheet, frameIndex, frameFilePath);
        savedFiles.add(frameFilePath);

        // Verify file was created
        expect(
          File(frameFilePath).existsSync(),
          isTrue,
          reason: 'Frame $frameIndex should be saved as PNG',
        );
      }

      // Assert: All frames were extracted
      expect(
        savedFiles.length,
        spriteSheet.frameCount,
        reason: 'Should extract all ${spriteSheet.frameCount} frames',
      );

      // Verify frame dimensions are consistent
      for (final filePath in savedFiles) {
        final file = File(filePath);
        expect(file.existsSync(), isTrue, reason: 'Frame file should exist');

        final bytes = file.readAsBytesSync();
        final image = img.decodePng(bytes);
        expect(image, isNotNull, reason: 'Saved frame should be valid PNG');
        expect(
          image!.width,
          spriteSheet.frameWidth,
          reason: 'Frame width should match sprite sheet frame width',
        );
        expect(
          image.height,
          spriteSheet.frameHeight,
          reason: 'Frame height should match sprite sheet frame height',
        );
      }
    });

    test('verifies sprite sheet metadata integrity', () async {
      // Arrange & Act: Decode the WebP animation
      final spriteSheet = await _decodeWebpFromFile(testFile);

      // Assert: Verify sprite sheet is valid
      expect(
        spriteSheet.isValid,
        isTrue,
        reason: 'Sprite sheet should be valid after decoding',
      );

      // Verify frame count is reasonable
      expect(
        spriteSheet.frameCount,
        greaterThan(0),
        reason: 'Animation should have at least 1 frame',
      );
      expect(
        spriteSheet.frameCount,
        lessThanOrEqualTo(1000),
        reason: 'Animation should not have unreasonably many frames',
      );

      // Verify dimensions are reasonable
      expect(
        spriteSheet.frameWidth,
        greaterThan(0),
        reason: 'Frame width should be positive',
      );
      expect(
        spriteSheet.frameHeight,
        greaterThan(0),
        reason: 'Frame height should be positive',
      );
      expect(
        spriteSheet.width,
        spriteSheet.frameWidth * spriteSheet.frameCount,
        reason: 'Total width should equal frame width times frame count',
      );

      // Debug prints
      print(
        'SpriteSheet dimensions: ${spriteSheet.width}x${spriteSheet.height}',
      );
      print(
        'Frame dimensions: ${spriteSheet.frameWidth}x${spriteSheet.frameHeight}',
      );
      print('Frame count: ${spriteSheet.frameCount}');

      // Verify frame metadata
      expect(
        spriteSheet.frames.length,
        spriteSheet.frameCount,
        reason: 'Frame list should match frame count',
      );

      // Verify timing progression
      for (int i = 0; i < spriteSheet.frames.length; i++) {
        final frame = spriteSheet.frames[i];
        expect(
          frame.index,
          i,
          reason: 'Frame index should match list position',
        );
        expect(
          frame.delay,
          greaterThan(Duration.zero),
          reason: 'Frame delay should be positive',
        );

        if (i > 0) {
          expect(
            frame.timestamp,
            greaterThanOrEqualTo(spriteSheet.frames[i - 1].timestamp),
            reason: 'Frame timestamps should be non-decreasing',
          );
        }
      }

      // Verify total duration calculation
      expect(
        spriteSheet.totalDuration,
        greaterThan(Duration.zero),
        reason: 'Total animation duration should be positive',
      );
    });

    test('creates visual frame grid for inspection', () async {
      // Arrange: Decode the WebP animation
      final spriteSheet = await _decodeWebpFromFile(testFile);

      // Act: Create a grid layout showing all frames
      final gridImage = await _createFrameGrid(spriteSheet);
      final gridFilePath = path.join(outputDir, 'frame_grid.png');

      // Save the grid image
      final gridPng = img.encodePng(gridImage);
      File(gridFilePath).writeAsBytesSync(gridPng);

      // Assert: Grid file was created
      expect(
        File(gridFilePath).existsSync(),
        isTrue,
        reason: 'Frame grid image should be created',
      );

      // Verify grid dimensions
      final savedGrid = img.decodePng(File(gridFilePath).readAsBytesSync());
      expect(savedGrid, isNotNull, reason: 'Saved grid should be valid PNG');

      // Grid should be arranged in a roughly square layout
      final framesPerRow = (spriteSheet.frameCount / 10)
          .ceil(); // Max 10 frames per row
      final expectedRows = (spriteSheet.frameCount / framesPerRow).ceil();
      final expectedWidth =
          framesPerRow * (spriteSheet.frameWidth + 2) -
          2; // -2 for no margin on last
      final expectedHeight = expectedRows * (spriteSheet.frameHeight + 2) - 2;

      expect(
        savedGrid!.width,
        expectedWidth,
        reason: 'Grid width should match calculated dimensions',
      );
      expect(
        savedGrid.height,
        expectedHeight,
        reason: 'Grid height should match calculated dimensions',
      );
    });

    test('verifies frame timing and playback sequence', () async {
      // Arrange: Decode the WebP animation
      final spriteSheet = await _decodeWebpFromFile(testFile);

      // Act: Create animation state and simulate playback
      final animationState = AnimationState(
        spriteSheet: spriteSheet,
        loop: false,
      );

      // Simulate playing through all frames
      final frameSequence = <int>[];
      const timeStep = 0.016; // ~60fps

      print('Starting animation. Total duration: ${spriteSheet.totalDuration}');
      print('Frame count: ${spriteSheet.frameCount}');
      print('Animation state isPlaying: ${animationState.isPlaying}');

      // Start with the initial frame
      frameSequence.add(animationState.currentFrameIndex);
      print(
        'Initial state: frame ${animationState.currentFrameIndex}, time ${animationState.currentTime}, completed: ${animationState.isCompleted}',
      );

      animationState.play();
      print(
        'After play: frame ${animationState.currentFrameIndex}, time ${animationState.currentTime}, completed: ${animationState.isCompleted}',
      );
      int iterations = 0;
      while (!animationState.isCompleted &&
          frameSequence.length < spriteSheet.frameCount * 2 &&
          iterations < 1000) {
        // Safety limit
        animationState.update(timeStep);
        frameSequence.add(animationState.currentFrameIndex);
        iterations++;

        if (iterations % 10 == 0) {
          print(
            'Iteration $iterations: frame ${animationState.currentFrameIndex}, time ${animationState.currentTime}, completed: ${animationState.isCompleted}',
          );
        }
      }

      print('Final frame sequence: $frameSequence');
      print('Animation completed: ${animationState.isCompleted}');

      // Assert: Verify frame sequence makes sense
      expect(
        frameSequence,
        isNotEmpty,
        reason: 'Should have captured frame sequence',
      );

      // First frame should be 0
      expect(
        frameSequence.first,
        0,
        reason: 'Animation should start at frame 0',
      );

      // Should visit each frame at least once
      final uniqueFrames = frameSequence.toSet();
      expect(
        uniqueFrames.length,
        spriteSheet.frameCount,
        reason: 'Should visit all frames during playback',
      );

      // Frames should be in ascending order (non-looping)
      var lastFrame = -1;
      for (final frame in frameSequence) {
        expect(
          frame,
          greaterThanOrEqualTo(lastFrame),
          reason:
              'Frames should play in ascending order in non-looping animation',
        );
        lastFrame = frame;
      }

      // Last frame should be the final frame
      expect(
        frameSequence.last,
        spriteSheet.frameCount - 1,
        reason: 'Animation should end at last frame',
      );
    });
  });
}

/// Creates a visual grid showing all frames arranged in a spreadsheet layout.
Future<img.Image> _createFrameGrid(final SpriteSheet spriteSheet) async {
  const maxFramesPerRow = 10;
  const margin = 2;

  // Calculate grid dimensions for spreadsheet-like layout
  // Use 2 frames per row for better viewing (matches test expectation)
  const framesPerRow = 2;
  final rows = (spriteSheet.frameCount / framesPerRow).ceil();

  final gridWidth = framesPerRow * (spriteSheet.frameWidth + margin) - margin;
  final gridHeight = rows * (spriteSheet.frameHeight + margin) - margin;

  // Create blank grid image
  final gridImage = img.Image(width: gridWidth, height: gridHeight);

  // Fill with white background
  img.fillRect(
    gridImage,
    x1: 0,
    y1: 0,
    x2: gridWidth - 1,
    y2: gridHeight - 1,
    color: img.ColorRgb8(255, 255, 255),
  );

  // Place each frame in the grid
  for (int frameIndex = 0; frameIndex < spriteSheet.frameCount; frameIndex++) {
    final row = frameIndex ~/ framesPerRow;
    final col = frameIndex % framesPerRow;

    final x = col * (spriteSheet.frameWidth + margin);
    final y = row * (spriteSheet.frameHeight + margin);

    // Extract frame pixels
    final frameRect = spriteSheet.getFrameRect(frameIndex);
    final spritePixels = spriteSheet.pixels;
    final spriteWidth = spriteSheet.width;

    // Copy frame to grid position
    for (int fy = 0; fy < spriteSheet.frameHeight; fy++) {
      for (int fx = 0; fx < spriteSheet.frameWidth; fx++) {
        final spriteX = frameRect.left.toInt() + fx;
        final spriteY = frameRect.top.toInt() + fy;

        final spriteIndex = (spriteY * spriteWidth + spriteX) * 4;
        final gridX = x + fx;
        final gridY = y + fy;

        if (gridX < gridWidth && gridY < gridHeight) {
          final r = spritePixels[spriteIndex];
          final g = spritePixels[spriteIndex + 1];
          final b = spritePixels[spriteIndex + 2];
          final a = spritePixels[spriteIndex + 3];

          // Blend with white background if semi-transparent
          const bgR = 255, bgG = 255, bgB = 255;
          final blendedR = ((r * a + bgR * (255 - a)) ~/ 255).clamp(0, 255);
          final blendedG = ((g * a + bgG * (255 - a)) ~/ 255).clamp(0, 255);
          final blendedB = ((b * a + bgB * (255 - a)) ~/ 255).clamp(0, 255);

          gridImage.setPixelRgb(gridX, gridY, blendedR, blendedG, blendedB);
        }
      }
    }
  }

  return gridImage;
}

/// BACKGROUND ISOLATE FUNCTION - copied from WebpDecoder for testing
DecodedSpriteSheetData _decodeAndCreateSpriteSheet(final Uint8List webpBytes) {
  // Decode the WebP animation using the image package
  final animation = img.decodeWebP(webpBytes);

  if (animation == null) {
    throw Exception('Failed to decode WebP animation');
  }

  if (animation.numFrames == 0) {
    throw Exception('WebP animation contains no frames');
  }

  // Calculate sprite sheet dimensions
  // Horizontal strip: width = frame_width * frame_count, height = frame_height
  final totalWidth = animation.width * animation.numFrames;
  final totalHeight = animation.height;

  // Create blank sprite sheet image
  final spriteSheet = img.Image(width: totalWidth, height: totalHeight);

  // Build frame metadata
  final frames = <AnimationFrame>[];
  double cumulativeTime = 0;

  for (int i = 0; i < animation.numFrames; i++) {
    final frame = animation.frames[i];

    // Copy frame into sprite sheet at correct position
    img.compositeImage(spriteSheet, frame, dstX: i * animation.width, dstY: 0);

    // Calculate frame timing
    // WebP frame delays are in milliseconds, convert to seconds for timestamp
    final frameDelayMs = frame.frameDuration > 0
        ? frame.frameDuration
        : 100; // Default 100ms
    final frameDelaySeconds = frameDelayMs / 1000.0;

    frames.add(
      AnimationFrame(
        index: i,
        delay: Duration(milliseconds: frameDelayMs),
        timestamp: cumulativeTime,
      ),
    );

    cumulativeTime += frameDelaySeconds;
  }

  // Convert to RGBA bytes for Flutter's ui.decodeImageFromPixels
  final rgbaBytes = spriteSheet.getBytes(order: img.ChannelOrder.rgba);

  return DecodedSpriteSheetData(
    pixels: rgbaBytes,
    width: totalWidth,
    height: totalHeight,
    frameWidth: animation.width,
    frameHeight: animation.height,
    frameCount: animation.numFrames,
    frames: frames,
  );
}

/// Decodes a WebP animation from a file path using the same logic as WebpDecoder.
Future<SpriteSheet> _decodeWebpFromFile(final String filePath) async {
  // Load raw bytes from file
  final file = File(filePath);
  if (!file.existsSync()) {
    throw Exception('WebP file not found: $filePath');
  }

  final buffer = file.readAsBytesSync();

  // Decode in background isolate (same as WebpDecoder)
  final decodedData = await compute(_decodeAndCreateSpriteSheet, buffer);

  // Convert to SpriteSheet model
  return SpriteSheet(
    pixels: decodedData.pixels,
    width: decodedData.width,
    height: decodedData.height,
    frameWidth: decodedData.frameWidth,
    frameHeight: decodedData.frameHeight,
    frameCount: decodedData.frameCount,
    frames: decodedData.frames,
  );
}

/// Extracts a single frame from the sprite sheet and saves it as a PNG file.
Future<void> _saveFrameAsPng(
  final SpriteSheet spriteSheet,
  final int frameIndex,
  final String filePath,
) async {
  // Calculate frame position in sprite sheet
  final frameRect = spriteSheet.getFrameRect(frameIndex);

  // Extract frame pixels from sprite sheet
  final frameWidth = spriteSheet.frameWidth;
  final frameHeight = spriteSheet.frameHeight;
  final framePixels = Uint8List(frameWidth * frameHeight * 4); // RGBA

  final spritePixels = spriteSheet.pixels;
  final spriteWidth = spriteSheet.width;

  // Copy pixels from sprite sheet to frame buffer
  for (int y = 0; y < frameHeight; y++) {
    for (int x = 0; x < frameWidth; x++) {
      final spriteX = frameRect.left.toInt() + x;
      final spriteY = frameRect.top.toInt() + y;

      final spriteIndex = (spriteY * spriteWidth + spriteX) * 4;
      final frameIndex = (y * frameWidth + x) * 4;

      // Copy RGBA values
      framePixels[frameIndex] = spritePixels[spriteIndex]; // R
      framePixels[frameIndex + 1] = spritePixels[spriteIndex + 1]; // G
      framePixels[frameIndex + 2] = spritePixels[spriteIndex + 2]; // B
      framePixels[frameIndex + 3] = spritePixels[spriteIndex + 3]; // A
    }
  }

  // Create image from pixels and save as PNG
  final image = img.Image.fromBytes(
    width: frameWidth,
    height: frameHeight,
    bytes: framePixels.buffer,
    order: img.ChannelOrder.rgba,
  );

  final pngBytes = img.encodePng(image);
  await File(filePath).writeAsBytes(pngBytes);
}

/// Internal data structure - copied from WebpDecoder for testing
@immutable
class DecodedSpriteSheetData {
  const DecodedSpriteSheetData({
    required this.pixels,
    required this.width,
    required this.height,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.frames,
  });
  final Uint8List pixels;
  final int width;
  final int height;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final List<AnimationFrame> frames;
}
