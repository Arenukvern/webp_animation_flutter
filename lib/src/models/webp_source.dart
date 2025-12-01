/// {@template webp_source}
/// Base class for WebP image sources.
/// Provides type-safe source specification for assets vs URLs.
/// {@endtemplate}
sealed class WebpSource {
  /// {@macro webp_source}
  const WebpSource();
}

/// {@template asset_source}
/// Specifies a WebP source from Flutter assets.
/// {@endtemplate}
class AssetSource extends WebpSource {
  /// {@macro asset_source}
  const AssetSource(this.path);

  /// Asset path to the WebP file.
  final String path;

  @override
  bool operator ==(covariant final AssetSource other) =>
      identical(this, other) || other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'AssetSource(path: $path)';
}

/// {@template network_source}
/// Specifies a WebP source from a network URL.
/// {@endtemplate}
class NetworkSource extends WebpSource {
  /// {@macro network_source}
  const NetworkSource(this.url, {this.headers});

  /// URL to the WebP file.
  final String url;

  /// Optional HTTP headers for the request.
  final Map<String, String>? headers;

  @override
  bool operator ==(covariant final NetworkSource other) =>
      identical(this, other) ||
      (other.url == url && other.headers == headers);

  @override
  int get hashCode => Object.hash(url, headers);

  @override
  String toString() => 'NetworkSource(url: $url, headers: $headers)';
}
