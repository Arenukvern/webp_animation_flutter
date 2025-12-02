import '../models/webp_source.dart';

/// {@template webp_cache}
/// Unified cache for WebP content with source-agnostic keys.
/// Handles both animations and static images with intelligent cache management.
/// {@endtemplate}
class WebpCache {
  WebpCache._();

  /// Singleton instance
  static final WebpCache instance = WebpCache._();

  /// Maximum cache size (configurable)
  static const int maxCacheSize = 50;

  /// Cache for sprite sheets (animations)
  final Map<String, Future<dynamic>> _cache = {};

  /// Access order for LRU eviction
  final List<String> _accessOrder = [];

  /// Gets cache statistics.
  Map<String, dynamic> get stats => {
    'size': _cache.length,
    'maxSize': maxCacheSize,
    'accessOrderLength': _accessOrder.length,
  };

  /// Clears all cached content.
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Retrieves or creates a cached value with type-specific key.
  Future<T> putIfAbsent<T>(
    final WebpSource source,
    final String typeIdentifier,
    final Future<T> Function() ifAbsent,
  ) {
    // Create type-specific key to prevent animation/static image conflicts
    final key = _createKey(source, typeIdentifier);

    // Move to end of access order (most recently used)
    _accessOrder
      ..remove(key)
      ..add(key);

    final result = _cache.putIfAbsent(key, ifAbsent);

    // Ensure cache size after adding new item
    _ensureCacheSize();

    return result as Future<T>;
  }

  /// Generates a cache key from a WebpSource and type identifier.
  String _createKey(final WebpSource source, final String type) =>
      switch (source) {
        AssetSource(path: final path) => '$type:asset:$path',
        NetworkSource(url: final url) => '$type:network:$url',
      };

  /// Ensures cache stays within size limits using LRU eviction.
  void _ensureCacheSize() {
    while (_cache.length > maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      // Remove entry from cache (returned Future is intentionally ignored)
      final _ = _cache.remove(oldestKey);
    }
  }
}
