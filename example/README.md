# WebP Animation Example

This example demonstrates the performance difference between single WebP animations and batched rendering with the `webp_animation_flutter` library.

## Features Demonstrated

- **Single Animation**: Uses `WebpAnimation` widget for individual animation control
- **Batch Animation**: Uses `WebpAnimationLayer` widget for efficient rendering of 60+ synchronized animations
- **Performance Comparison**: Toggle between views to see the difference in rendering approaches

## Running the Example

1. Navigate to the example directory:

   ```bash
   cd example
   ```

2. Get dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## What You'll See

### Single Animation View

- One large WebP animation (200x200) in the center
- Uses individual `WebpAnimation` widget
- Separate draw call per animation
- Good for: Individual control, <10 animations

### Batch Animation View

- 60+ small WebP animations (50x50) in a grid layout
- Uses single `WebpAnimationLayer` widget
- Single draw call for all animations
- Perfect synchronization across all animations
- Good for: Games, complex UIs, 10+ synchronized animations

## Performance Notes

- **WebpAnimation**: N draw calls, N controllers, higher overhead
- **WebpAnimationLayer**: 1 draw call, 1 controller, optimal for many animations
- All animations share the same WebP asset to demonstrate efficiency
