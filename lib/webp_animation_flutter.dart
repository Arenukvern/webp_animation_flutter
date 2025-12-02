/// High-performance WebP animation library for Flutter using
/// game dev principles.
///
/// This library provides efficient WebP animation rendering with isolate-based
/// decoding and sprite sheet batching for smooth performance.
///
/// ## Features
///
/// - **Isolate-based decoding**: WebP decoding happens in background isolates
/// - **Sprite sheet rendering**: All frames packed into single GPU texture
/// - **Batch rendering**: Multiple animations in single draw call
/// - **Flexible timing**: Respect WebP delays or use custom FPS
/// - **Simple API**: Two main widgets with intuitive parameters
///
/// ## Usage
///
/// ### Single Animation from Asset
/// ```dart
/// WebpAnimation(
///   uri: Uri(path: 'assets/animations/character.webp'),
///   width: 100,
///   height: 100,
///   autoPlay: true,
///   loop: true,
/// )
/// ```
///
/// ### Single Animation from Network
/// ```dart
/// WebpAnimation(
///   uri: Uri.parse('https://example.com/animation.webp'),
///   width: 100,
///   height: 100,
/// )
/// ```
///
/// ### Static WebP Image
/// ```dart
/// WebpStaticImage(
///   uri: Uri(path: 'assets/images/logo.webp'),
///   width: 200,
///   height: 200,
/// )
/// ```
///
/// ### Multiple Animations (Batch)
/// ```dart
/// WebpAnimationLayer(
///   animations: [
///     WebpAnimationItem(
///       uri: Uri(path: 'assets/char1.webp'),
///       position: Offset(10, 20),
///       size: Size(100, 100),
///     ),
///   ],
/// )
/// ```
library;

export 'src/core/animation_state.dart';
export 'src/core/game_loop_controller.dart';
export 'src/core/sprite_sheet.dart';
export 'src/core/webp_cache.dart';
export 'src/core/webp_decoder.dart';
export 'src/core/webp_error.dart';
export 'src/models/static_image_sheet.dart';
export 'src/models/webp_animation_item.dart';
// WebpSource, AssetSource, and NetworkSource are internal implementation details
// Use Uri in public APIs instead
export 'src/painters/animation_painter.dart';
export 'src/widgets/webp_animation.dart';
export 'src/widgets/webp_animation_controller.dart';
export 'src/widgets/webp_animation_layer.dart';
export 'src/widgets/webp_animation_layer_controller.dart';
export 'src/widgets/webp_static_image.dart';
