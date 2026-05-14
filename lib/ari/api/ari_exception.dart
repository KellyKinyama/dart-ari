import 'dart:convert';
import 'dart:io';

/// Exception raised when an Asterisk REST Interface (ARI) HTTP call returns
/// a status code outside the 2xx range, or when the underlying transport
/// fails (DNS, connect, TLS, socket reset, etc.).
///
/// Callers should treat this as a control-flow signal that the requested
/// Asterisk operation did not succeed and the local view of the resource
/// (channel, bridge, playback, ...) may be stale.
class AriException implements Exception {
  /// HTTP method used for the request (GET, POST, DELETE, PUT).
  final String method;

  /// The request URI (with `api_key` stripped from the query for safe logging).
  final Uri uri;

  /// HTTP status code returned by Asterisk, or `null` for transport failures.
  final int? statusCode;

  /// Raw response body (or transport error message when [statusCode] is null).
  final String body;

  AriException(this.method, Uri uri, this.statusCode, this.body)
      : uri = _scrub(uri);

  bool get isTransportFailure => statusCode == null;

  static Uri _scrub(Uri uri) {
    if (!uri.queryParameters.containsKey('api_key')) return uri;
    final scrubbed = Map<String, String>.from(uri.queryParameters)
      ..['api_key'] = '<redacted>';
    return uri.replace(queryParameters: scrubbed);
  }

  @override
  String toString() {
    if (isTransportFailure) {
      return 'AriException: $method ${uri.path} (transport failure): $body';
    }
    return 'AriException: $method ${uri.path} -> $statusCode: $body';
  }
}

/// Reads the response body for an ARI HTTP call. Throws [AriException] when
/// the status code is not in the 2xx range. Returns the decoded body string
/// on success.
///
/// Use this immediately after `await request.close()` so non-2xx responses
/// surface as exceptions instead of being silently treated as success by
/// callers that ignore `statusCode`.
Future<String> readAriBody(
    HttpClientResponse response, String method, Uri uri) async {
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw AriException(method, uri, response.statusCode, body);
  }
  return body;
}

/// Wraps the typical ARI `request.close()` + body-read flow so every HTTP
/// call site has consistent error handling:
/// - Non-2xx => [AriException] with status + body.
/// - Transport errors => [AriException] with `statusCode == null`.
Future<({int statusCode, String resp})> sendAriRequest(
    HttpClientRequest request) async {
  try {
    final response = await request.close();
    final body = await readAriBody(response, request.method, request.uri);
    return (statusCode: response.statusCode, resp: body);
  } on AriException {
    rethrow;
  } catch (err) {
    throw AriException(request.method, request.uri, null, err.toString());
  }
}
