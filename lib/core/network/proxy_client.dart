import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown for any failure talking to the backend proxy (network, timeout,
/// non-200 status, malformed body). Callers fall back to on-device logic.
class ProxyException implements Exception {
  const ProxyException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ProxyException($statusCode): $message';
}

/// Minimal JSON client for the VisionAssist FastAPI proxy.
///
/// Adds the `X-API-Key` header and a hard timeout, and converts every error
/// into a [ProxyException]. Request/response bodies are never logged.
class ProxyClient {
  ProxyClient({
    required String baseUrl,
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final String apiKey;
  final Duration timeout;
  final http.Client _client;

  /// POSTs [body] to `/v1<path>` and returns the decoded JSON object.
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_baseUrl/v1$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
              'X-API-Key': apiKey,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ProxyException(
          'Proxy returned HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const ProxyException('Unexpected response shape');
      }
      return decoded;
    } on ProxyException {
      rethrow;
    } on TimeoutException {
      throw const ProxyException('Proxy request timed out');
    } on FormatException {
      throw const ProxyException('Proxy returned invalid JSON');
    } on http.ClientException catch (e) {
      throw ProxyException('Network error: ${e.message}');
    } catch (e) {
      // SocketException / HandshakeException etc.
      throw ProxyException('Network error: ${e.runtimeType}');
    }
  }

  void close() => _client.close();
}
