import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../models/static_image_sheet.dart';
import '../models/webp_source.dart';
import 'animation_frame.dart';
import 'sprite_sheet.dart';
import 'webp_cache.dart';
import 'webp_error.dart';

/// BACKGROUND ISOLATE FUNCTION
/// This does the heavy CPU lifting: decoding WebP and creating sprite sheet.

DecodedSpriteSheetData _decodeAndCreateSpriteSheet(final Uint8List webpBytes) {
  // Decode the WebP animation using the image package
  final animation = img.decodeWebP(webpBytes);

  if (animation == null) {
    throw const DecodeError('Failed to decode WebP animation');
  }

  if (animation.numFrames == 0) {
    throw const ValidationError('WebP animation contains no frames');
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

/// BACKGROUND ISOLATE FUNCTION
/// This decodes a static WebP image (single frame or first frame of animation).

DecodedStaticImageData _decodeAndCreateStaticImage(final Uint8List webpBytes) {
  // Decode the WebP image using the image package
  final image = img.decodeWebP(webpBytes);

  if (image == null) {
    throw const DecodeError('Failed to decode WebP image');
  }

  // Use first frame for static images (works for both animated and static WebP)
  final frame = image.frames.isNotEmpty ? image.frames[0] : image;

  // Convert to RGBA bytes for Flutter's ui.decodeImageFromPixels
  final rgbaBytes = frame.getBytes(order: img.ChannelOrder.rgba);

  return DecodedStaticImageData(
    pixels: rgbaBytes,
    width: frame.width,
    height: frame.height,
  );
}

/// Internal data structure passed between isolates.
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

/// Internal data structure for static images passed between isolates.
@immutable
class DecodedStaticImageData {
  const DecodedStaticImageData({
    required this.pixels,
    required this.width,
    required this.height,
  });
  final Uint8List pixels;
  final int width;
  final int height;
}

/// {@template webp_decoder}
/// Handles WebP animation decoding using isolate-based processing.
///
/// This class implements the "deconstruct and ship" strategy:
/// - Background isolate decodes WebP and creates sprite sheet
/// - Main isolate uploads pixels to GPU once
/// - Zero runtime decoding overhead during playback
/// {@endtemplate}
class WebpDecoder {
  WebpDecoder._();

  /// Unified cache for all WebP content.
  static final WebpCache _cache = WebpCache.instance;

  /// Clears the decode cache for all assets.
  ///
  /// Useful for memory management or when assets have changed.
  static void clearCache() {
    _cache.clear();
  }

  /// Converts a decoded WebP animation to a GPU-ready ui.Image.
  ///
  /// This should be called on the main isolate after decoding.
  /// The resulting image contains the entire sprite sheet.
  ///
  /// @ai Call this after decoding to get a GPU texture for rendering.
  static Future<ui.Image> createImageFromSpriteSheet(
    final SpriteSheet spriteSheet,
  ) {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      spriteSheet.pixels,
      spriteSheet.width,
      spriteSheet.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );

    return completer.future;
  }

  /// Decodes a WebP animation from any source type.
  ///
  /// Uses isolate-based decoding to prevent UI thread blocking.
  /// Results are cached to avoid re-decoding the same animation.
  ///
  /// @ai Use this method to load WebP animations from any supported source.
  static Future<SpriteSheet> decodeAnimation(final WebpSource source) =>
      switch (source) {
        AssetSource(path: final path) => decodeFromAsset(path),
        NetworkSource(url: final url) => decodeFromUrl(url),
      };

  /// Decodes a WebP animation from an asset path to a sprite sheet.
  ///
  /// Uses isolate-based decoding to prevent UI thread blocking.
  /// Results are cached to avoid re-decoding the same animation.
  ///
  /// @ai Use this method to load WebP animations efficiently.
  static Future<SpriteSheet> decodeFromAsset(final String assetPath) =>
      _cache.putIfAbsent(
        AssetSource(assetPath),
        'animation',
        () => _decodeFromAsset(assetPath),
      );

  /// Decodes a WebP animation from a network URL to a sprite sheet.
  ///
  /// Uses isolate-based decoding to prevent UI thread blocking.
  /// Results are cached to avoid re-decoding the same animation.
  ///
  /// @ai Use this method to load WebP animations from the network efficiently.
  static Future<SpriteSheet> decodeFromUrl(final String url) => _cache
      .putIfAbsent(NetworkSource(url), 'animation', () => _decodeFromUrl(url));

  /// Decodes a static WebP image from any source type.
  ///
  /// Uses isolate-based decoding to prevent UI thread blocking.
  /// Results are cached to avoid re-decoding the same image.
  ///
  /// @ai Use this method to load static WebP images from any supported source.
  static Future<StaticImageSheet> decodeStatic(final WebpSource source) =>
      switch (source) {
        AssetSource(path: final path) => decodeStaticFromAsset(path),
        NetworkSource(url: final url) => decodeStaticFromUrl(url),
      };

  /// Decodes a static WebP image from an asset path to a static
  /// image sheet.
  ///
  /// Uses isolate-based decoding to prevent UI thread blocking.
  /// Results are cached to avoid re-decoding the same image.
  ///
  /// @ai Use this method to load static WebP images
  /// efficiently.
  static Future<StaticImageSheet> decodeStaticFromAsset(
    final String assetPath,
  ) => _cache.putIfAbsent(
    AssetSource(assetPath),
    'static',
    () => _decodeStaticFromAsset(assetPath),
  );

  /// Decodes a static WebP image from a network URL to a static image sheet.
  ///
  /// Uses isolate-based decoding to prevent UI thread blocking.
  /// Results are cached to avoid re-decoding the same image.
  ///
  /// @ai Use this method to load static WebP images from the
  /// network efficiently.
  static Future<StaticImageSheet> decodeStaticFromUrl(final String url) =>
      _cache.putIfAbsent(
        NetworkSource(url),
        'static',
        () => _decodeStaticFromUrl(url),
      );

  /// Internal method to decode a WebP animation from an asset.
  static Future<SpriteSheet> _decodeFromAsset(final String assetPath) async {
    // Load raw bytes from assets on main isolate
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer.asUint8List();

    // Decode in background isolate
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

  /// Internal method to decode a WebP animation from a network URL.
  static Future<SpriteSheet> _decodeFromUrl(final String url) async {
    // Load raw bytes from network on main isolate
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw NetworkError(
        'Failed to load WebP from network',
        response.statusCode,
      );
    }
    final buffer = response.bodyBytes;

    // Decode in background isolate
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

  /// Internal method to decode a static WebP image from an asset.
  static Future<StaticImageSheet> _decodeStaticFromAsset(
    final String assetPath,
  ) async {
    // Load raw bytes from assets on main isolate
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer.asUint8List();

    // Decode in background isolate
    final decodedData = await compute(_decodeAndCreateStaticImage, buffer);

    // Convert to StaticImageSheet model
    return StaticImageSheet(
      pixels: decodedData.pixels,
      width: decodedData.width,
      height: decodedData.height,
    );
  }

  /// Internal method to decode a static WebP image from a network URL.
  static Future<StaticImageSheet> _decodeStaticFromUrl(final String url) async {
    // Load raw bytes from network on main isolate
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw NetworkError(
        'Failed to load WebP from network',
        response.statusCode,
      );
    }
    final buffer = response.bodyBytes;

    // Decode in background isolate
    final decodedData = await compute(_decodeAndCreateStaticImage, buffer);

    // Convert to StaticImageSheet model
    return StaticImageSheet(
      pixels: decodedData.pixels,
      width: decodedData.width,
      height: decodedData.height,
    );
  }
}
