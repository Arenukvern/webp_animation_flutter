/// {@template webp_error}
/// Base class for WebP-related errors.
/// Provides consistent error handling across all WebP operations.
/// {@endtemplate}
sealed class WebpError implements Exception {
  /// {@macro webp_error}
  const WebpError(this.message);

  /// Error message describing what went wrong.
  final String message;

  @override
  String toString() => 'WebpError: $message';
}

/// {@template network_error}
/// Error that occurs during network operations.
/// {@endtemplate}
class NetworkError extends WebpError {
  /// {@macro network_error}
  const NetworkError(super.message, this.statusCode);

  /// HTTP status code from the failed request.
  final int statusCode;

  @override
  String toString() => 'NetworkError (status: $statusCode): $message';
}

/// {@template decode_error}
/// Error that occurs during WebP decoding operations.
/// {@endtemplate}
class DecodeError extends WebpError {
  /// {@macro decode_error}
  const DecodeError(super.message);

  @override
  String toString() => 'DecodeError: $message';
}

/// {@template asset_error}
/// Error that occurs when loading assets.
/// {@endtemplate}
class AssetError extends WebpError {
  /// {@macro asset_error}
  const AssetError(super.message, this.assetPath);

  /// Path to the asset that failed to load.
  final String assetPath;

  @override
  String toString() => 'AssetError ($assetPath): $message';
}

/// {@template validation_error}
/// Error that occurs when validating WebP data.
/// {@endtemplate}
class ValidationError extends WebpError {
  /// {@macro validation_error}
  const ValidationError(super.message);

  @override
  String toString() => 'ValidationError: $message';
}
