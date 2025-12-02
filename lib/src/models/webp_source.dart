/// {@template asset_source}
/// Specifies a WebP source from Flutter assets.
/// {@endtemplate}
class AssetSource extends WebpSource {
  /// {@macro asset_source}
  const AssetSource(this.path);

  /// Asset path to the WebP file.
  final String path;

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(covariant final AssetSource other) =>
      identical(this, other) || other.path == path;

  @override
  String toString() => 'AssetSource(path: $path)';
}

/// {@template network_source}
/// Specifies a WebP source from a network URL.
/// {@endtemplate}
class NetworkSource extends WebpSource {
  /// {@macro network_source}
  const NetworkSource(this.url);

  /// URL to the WebP file.
  final String url;

  @override
  int get hashCode => url.hashCode;

  @override
  bool operator ==(covariant final NetworkSource other) =>
      identical(this, other) || other.url == url;

  @override
  String toString() => 'NetworkSource(url: $url)';
}

/// {@template webp_source}
/// Base class for WebP image sources.
/// Provides type-safe source specification for assets vs URLs.
/// Internal implementation detail - use Uri in public APIs.
/// {@endtemplate}
sealed class WebpSource {
  /// {@macro webp_source}
  const WebpSource();

  /// Creates a WebpSource from a Uri.
  ///
  /// - `http://` or `https://` schemes → NetworkSource
  /// - `asset://` scheme or no scheme (relative path) → AssetSource
  static WebpSource fromUri(final Uri uri) {
    final scheme = uri.scheme;
    if (scheme == 'http' || scheme == 'https') {
      return NetworkSource(uri.toString());
    }
    // asset:// scheme or no scheme (relative path) → treat as asset
    String path;
    if (scheme == 'asset') {
      // Remove leading slash from path if present
      path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
    } else {
      // No scheme - use the full URI string as path
      path = uri.toString();
    }
    return AssetSource(path);
  }
}
