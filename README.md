# webp_animation_flutter

[![pub package](https://img.shields.io/pub/v/webp_animation_flutter.svg?include_prereleases)](https://pub.dev/packages/webp_animation_flutter)
[![All Contributors](https://img.shields.io/github/all-contributors/Arenukvern/webp_animation_flutter?color=ee8449&style=flat-square)](https://github.com/Arenukvern/webp_animation_flutter#contributors-)
[![maintained with Skill Steward](https://raw.githubusercontent.com/Arenukvern/skill_steward/main/docs/brand/assets/svg/badge-light.svg)](https://github.com/Arenukvern/skill_steward)


High-performance Flutter library for animated WebP, using a game loop architecture for perfect sync and ultra-efficient rendering.

Please notice: this package status is a `proof of concept`. Feel free to clone, contribute, and improve it if you will have use for it:)

## Features

- 🎬 **Animated WebP Support**: Smooth playback of animated WebP files
- 🖼️ **Static WebP Support**: Optimized rendering for single-frame WebP images
- 🌐 **Network Loading**: Load animations and images from URLs
- 📦 **Asset Loading**: Load from Flutter assets
- ⚡ **Isolate-based Decoding**: WebP decoding happens in background threads
- 🎮 **Game Loop Architecture**: Perfect synchronization for multiple animations
- 🚀 **Batch Rendering**: Multiple animations in a single GPU draw call
- 💾 **Intelligent Caching**: Automatic caching prevents re-decoding
- 🎯 **Flexible Timing**: Respect WebP frame delays or use custom FPS
- 🎨 **Custom Controls**: Play, pause, seek, and loop control

## Credits

The animated WebP demo asset from Mathias Bynens for example purposes only: [https://mathiasbynens.be/demo/animated-webp](https://mathiasbynens.be/demo/animated-webp)

## Demo

Check out a quick video demo:

[![WebP Animation Flutter Demo](https://img.youtube.com/vi/-6i0OvZ2IJk/hqdefault.jpg)](https://youtube.com/shorts/-6i0OvZ2IJk?si=P795dIv3OfScBolE)

---

## FAQ

### What is this library for?

Animates multiple WebP files in Flutter with high performance: unified timing, isolate decoding, and batch GPU rendering—ideal for games and complex UI, but simple for one-off animations.

### How do I add it to my project?

Add to your `pubspec.yaml`:

```yaml
dependencies:
  webp_animation_flutter: ^0.1.0-dev.1
```

---

## Usage Examples

### Simple: Single Animation from Asset (auto-play)

```dart
import 'package:webp_animation_flutter/webp_animation_flutter.dart';

WebpAnimation(
  uri: Uri(path: 'assets/animations/character.webp'),
  width: 100,
  height: 100,
)
```

### Simple: Single Animation from Network

```dart
WebpAnimation(
  uri: Uri.parse('https://example.com/animations/character.webp'),
  width: 100,
  height: 100,
)
```

### Simple: Custom FPS & Speed

```dart
WebpAnimation(
  uri: Uri(path: 'assets/effects/explosion.webp'),
  width: 200,
  height: 150,
  respectFrameDelays: false, // Use custom FPS
  fps: 30.0,
  speed: 2.0,
)
```

### Simple: Static WebP Image

```dart
WebpStaticImage(
  uri: Uri(path: 'assets/images/logo.webp'),
  width: 200,
  height: 200,
)
```

### Simple: Error & Loading States

```dart
WebpAnimation(
  uri: Uri(path: 'assets/loading.webp'),
  width: 50,
  height: 50,
  builder: (context, sheet, error) {
    if (error != null) return Icon(Icons.error, color: Colors.red);
    if (sheet == null) return CircularProgressIndicator();
    return SizedBox.shrink();
  },
)
```

### Advanced: Batch Rendering (Perfect Sync)

```dart
WebpAnimationLayer(
  animations: [
    WebpAnimationItem(
      uri: Uri(path: 'assets/char_idle.webp'),
      position: Offset(10, 20),
      size: Size(100, 100),
    ),
    WebpAnimationItem(
      uri: Uri(path: 'assets/char_walk.webp'),
      position: Offset(150, 50),
      size: Size(80, 80),
    ),
    WebpAnimationItem(
      uri: Uri(path: 'assets/effects/particles.webp'),
      position: Offset(200, 100),
      size: Size(60, 60),
    ),
  ],
  autoPlay: true,
  loop: true,
  speed: 1.0,
)
```

### Advanced: Unified Layer Controller (Play/Pause/Seek All)

```dart
class GameScreen extends StatefulWidget {
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late final WebpAnimationLayerController _layerController;

  @override
  void initState() {
    super.initState();
    _layerController = WebpAnimationLayerController(
      vsync: this,
      respectFrameDelays: false,
      fps: 24.0,
      speed: 1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated layer controls
        Row(
          children: [
            ElevatedButton(
              onPressed: _layerController.play,
              child: Text('Play'),
            ),
            ElevatedButton(
              onPressed: _layerController.pause,
              child: Text('Pause'),
            ),
            ElevatedButton(
              onPressed: _layerController.reset,
              child: Text('Reset'),
            ),
            Slider(
              value: _layerController.controller.value,
              onChanged: (value) => _layerController.seek(value),
            ),
          ],
        ),
        // Layer with animations
        WebpAnimationLayer(
          animations: [
            WebpAnimationItem(
              uri: Uri(path: 'assets/game/character.webp'),
              position: Offset.zero,
              size: Size(100, 100),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _layerController.dispose();
    super.dispose();
  }
}
```

---

## Common Questions

**Can I control each animation individually in a batch?**  
Use standalone `WebpAnimation` widgets with custom controllers for individual control.  
Use `WebpAnimationLayer` for perfect sync and unified control.

**Can I use my own AnimationController?**  
Yes, pass it to a `WebpAnimation` for advanced timing.

**Can I load animations from the network?**  
Yes! Use `Uri.parse()` for network URLs:

```dart
WebpAnimation(
  uri: Uri.parse('https://example.com/animation.webp'),
  width: 100,
  height: 100,
)
```

**What's the difference between WebpAnimation and WebpStaticImage?**

- `WebpAnimation`: For animated WebP files with multiple frames
- `WebpStaticImage`: For static WebP images (single frame), optimized without animation overhead

**How do I migrate from older versions?**  
The `source: WebpSource` parameter has been replaced with `uri: Uri`. Use standard Dart `Uri` instead:

```dart
// Old
WebpAnimation(source: AssetSource('path.webp'), ...)
WebpAnimation(source: NetworkSource('https://...'), ...)

// New
WebpAnimation(uri: Uri(path: 'path.webp'), ...)
WebpAnimation(uri: Uri.parse('https://...'), ...)
```

**What's performance like?**

- WebP decoding in separate thread (isolate)
- Batches all rendering into a single GPU call
- Zero timing drift, minimal CPU use even with many animations
- Intelligent caching prevents re-decoding the same source

---

## API References (short)

- **WebpAnimation:** Single animation widget (uses `uri: Uri` parameter)
- **WebpStaticImage:** Static WebP image widget (optimized for single-frame images, uses `uri: Uri`)
- **WebpAnimationLayer:** Multi-animation, synched and batch-rendered
- **WebpAnimationLayerController:** Controls a layer (play/pause/seek/reset)
- **WebpAnimationItem:** Position/size/configuration for each animation in a layer (uses `uri: Uri`)

**URI Format:**

- Assets: `Uri(path: 'assets/...')` or `Uri.parse('asset://assets/...')`
- Network: `Uri.parse('https://...')` or `Uri.parse('http://...')`

---

## Requirements

- Flutter >=3.3.0
- Dart >=3.8.1


## ✨ Contributors

Huge thanks to everyone who has helped improve this package.

This roster is maintained with [all-contributors](https://allcontributors.org/).
To add someone, update [`.all-contributorsrc`](.all-contributorsrc) and regenerate the README table, or use the all-contributors bot/CLI from a PR.

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="https://xsoulspace.dev"><img src="https://avatars.githubusercontent.com/u/15068151?v=4?s=100" width="100px;" alt="Anton Malofeev"/><br /><sub><b>Anton Malofeev</b></sub></a><br /><a href="https://github.com/Arenukvern/webp_animation_flutter/commits?author=Arenukvern" title="Code">💻</a> <a href="https://github.com/Arenukvern/webp_animation_flutter/commits?author=Arenukvern" title="Documentation">📖</a> <a href="#maintenance-Arenukvern" title="Maintenance">🚧</a></td>
      <td align="center" valign="top" width="14.28%"><a href="https://github.com/molihuan"><img src="https://avatars.githubusercontent.com/u/78474077?v=4?s=100" width="100px;" alt="molihuan"/><br /><sub><b>molihuan</b></sub></a><br /><a href="https://github.com/Arenukvern/webp_animation_flutter/commits?author=molihuan" title="Code">💻</a> <a href="https://github.com/Arenukvern/webp_animation_flutter/issues?q=author%3Amolihuan" title="Bug reports">🐛</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

## License

MIT License. See LICENSE for details.

---
