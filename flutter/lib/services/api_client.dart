import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 20);

  static Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) {
    final uri = apiUri(path, queryParameters: queryParameters);
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    return http.get(uri, headers: headers).timeout(_timeout);
  }

  static Future<http.Response> postJson(
    String path, {
    Object? body,
    String? token,
  }) {
    final uri = apiUri(path);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final encodedBody = body == null ? null : jsonEncode(body);
    return http.post(uri, headers: headers, body: encodedBody).timeout(_timeout);
  }

  static Map<String, dynamic> decodeJsonMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Expected JSON object');
  }
}

