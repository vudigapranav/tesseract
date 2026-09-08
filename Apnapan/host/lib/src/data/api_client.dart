import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiFailure implements Exception {
  ApiFailure(this.status, this.code);
  final int status;
  final String code;
  bool get retryable => status >= 500;
  @override
  String toString() => 'API $status: $code';
}

/// Token supplier belongs to host identity, never to games or durable settings.
class ApiClient {
  ApiClient({required this.baseUrl, required this.token, http.Client? client})
      : client = client ?? http.Client();
  final Uri baseUrl;
  final Future<String> Function() token;
  final http.Client client;
  bool demo = false;
  Future<Map<String, dynamic>> request(String method, String path,
      [Map<String, Object?>? body]) async {
    final request = http.Request(method, baseUrl.resolve(path));
    request.headers.addAll({
      'Authorization': 'Bearer ${await token()}',
      'Content-Type': 'application/json'
    });
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 20)));
    demo = response.headers['x-tesseract-demo-mode'] == 'true';
    final value =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final decoded = value is List
        ? <String, dynamic>{'items': value}
        : value as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiFailure(response.statusCode,
          (decoded['error'] as Map?)?['code'] as String? ?? 'request_failed');
    }
    return decoded;
  }
}
