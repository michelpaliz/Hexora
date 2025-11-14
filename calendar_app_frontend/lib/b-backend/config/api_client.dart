// lib/b-backend/api/api_client.dart
import 'dart:convert';

import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client _client = http.Client();

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await _client.get(url, headers: headers);
  }

  Future<http.Response> post(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await _client.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }


  Future<http.Response> put(
    String endpoint,
    dynamic body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await _client.put(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return await _client.delete(url, headers: headers);
  }
}
