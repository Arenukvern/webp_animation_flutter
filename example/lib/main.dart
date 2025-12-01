import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:webp_animation_flutter/webp_animation_flutter.dart';

void main() {
  runApp(const WebpAnimationExampleApp());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class WebpAnimationExampleApp extends StatelessWidget {
  const WebpAnimationExampleApp({super.key});

  @override
  Widget build(final BuildContext context) => MaterialApp(
    title: 'WebP Animation Example',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class _HomePageState extends State<HomePage> {
  static const animationAsset = 'assets/animated-webp-supported.webp';
  static const animationCount = 120;
  static const singleAnimationSize = Size(200, 200);
  static const batchAnimationSize = Size(50, 50);

  int _currentIndex = 0;

  // Cached grid calculations to avoid recalculation on every build
  late final int _gridSize = math.sqrt(animationCount).ceil();
  late final double _totalWidth = _gridSize * batchAnimationSize.width;
  late final double _totalHeight = _gridSize * batchAnimationSize.height;
  late final List<WebpAnimationItem> _animationItems = _createAnimationItems();

  @override
  Widget build(final BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('WebP Animation Example'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    ),
    body: SingleChildScrollView(
      child: IndexedStack(
        index: _currentIndex,
        children: [
          // Single animation view
          _buildSingleAnimationView(),
          // Batch animation view
          _buildBatchAnimationView(),
          _buildStaticImageView(),
        ],
      ),
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (final index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.looks_one),
          label: 'Single Animation',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          label: 'Batch ($animationCount Animations)',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.image), label: 'Static Image'),
      ],
    ),
  );

  Widget _buildBatchAnimationView() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Batch Animation Layer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            '$animationCount animations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: _totalWidth,
            height: _totalHeight,
            child: WebpAnimationLayer(animations: _animationItems),
          ),
          const SizedBox(height: 20),
          Text(
            'Single WebpAnimationLayer widget\n'
            'One draw call for all animations\n'
            'Perfect synchronization',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ],
  );

  Widget _buildSingleAnimationView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Single Animation (AssetSource)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        WebpAnimation(
          source: const AssetSource(animationAsset),
          width: singleAnimationSize.width,
          height: singleAnimationSize.height,
        ),
        const SizedBox(height: 20),
        Text(
          'Individual WebpAnimation widget\nSeparate draw call per animation',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          'Single Animation (NetworkSource)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        WebpAnimation(
          source: const NetworkSource(
            'https://mathiasbynens.be/demo/animated-webp-supported.webp',
          ),
          width: singleAnimationSize.width,
          height: singleAnimationSize.height,
        ),
      ],
    ),
  );

  Widget _buildStaticImageView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Static Image (AssetSource)',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        WebpStaticImage(
          source: const AssetSource(animationAsset),
          width: singleAnimationSize.width,
          height: singleAnimationSize.height,
        ),
      ],
    ),
  );

  List<WebpAnimationItem> _createAnimationItems() {
    final animationItems = <WebpAnimationItem>[];
    for (int i = 0; i < animationCount; i++) {
      final row = i ~/ _gridSize;
      final col = i % _gridSize;
      animationItems.add(
        WebpAnimationItem(
          asset: animationAsset,
          position: Offset(
            col * batchAnimationSize.width,
            row * batchAnimationSize.height,
          ),
          size: batchAnimationSize,
        ),
      );
    }
    return animationItems;
  }
}
