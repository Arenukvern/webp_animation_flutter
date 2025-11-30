# webp_animation_flutter

High-performance Flutter library for animated WebP, using a game loop architecture for perfect sync and ultra-efficient rendering.

Please notice: this package status is a `proof of concept`. Feel free to clone, contribute, and improve it if you will have use for it:)

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

### Simple: Single Animation (auto-play)

```dart
import 'package:webp_animation_flutter/webp_animation_flutter.dart';

WebpAnimation(
  asset: 'assets/animations/character.webp',
  width: 100,
  height: 100,
)
```

### Simple: Custom FPS & Speed

```dart
WebpAnimation(
  asset: 'assets/effects/explosion.webp',
  width: 200,
  height: 150,
  respectFrameDelays: false, // Use custom FPS
  fps: 30.0,
  speed: 2.0,
)
```

### Simple: Error & Loading States

```dart
WebpAnimation(
  asset: 'assets/loading.webp',
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
      asset: 'assets/char_idle.webp',
      position: Offset(10, 20),
      size: Size(100, 100),
    ),
    WebpAnimationItem(
      asset: 'assets/char_walk.webp',
      position: Offset(150, 50),
      size: Size(80, 80),
    ),
    WebpAnimationItem(
      asset: 'assets/effects/particles.webp',
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
              asset: 'assets/game/character.webp',
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

**How do I migrate from older versions?**  
Remove the `controllers:` parameter from `WebpAnimationLayer`—timing is now unified internally.

**What's performance like?**

- WebP decoding in separate thread (isolate)
- Batches all rendering into a single GPU call
- Zero timing drift, minimal CPU use even with many animations

---

## API References (short)

- **WebpAnimation:** Single animation (see above)
- **WebpAnimationLayer:** Multi-animation, synched and batch-rendered
- **WebpAnimationLayerController:** Controls a layer (play/pause/seek/reset)
- **WebpAnimationItem:** Position/size/configuration for each animation in a layer

---

## Requirements

- Flutter >=3.3.0
- Dart >=3.8.1

## License

MIT License. See LICENSE for details.

---

## Credits

Animated WebP demo assets: [https://mathiasbynens.be/demo/animated-webp](https://mathiasbynens.be/demo/animated-webp)
