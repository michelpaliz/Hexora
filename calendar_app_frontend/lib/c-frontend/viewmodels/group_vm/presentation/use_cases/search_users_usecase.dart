import 'dart:convert';

import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:http/http.dart' as http;

class SearchUsersUseCase {
  final http.Client client;
  final AuthProvider auth;
  final String baseUrl; // ← inject here

  SearchUsersUseCase(this.client, this.auth, this.baseUrl);

  /// Searches users on the backend. Accepts either:
  /// - a top-level list: [ {...}, {...} ]
  /// - or an object with items: { "items": [ {...}, ... ] }
  Future<List<User>> call(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final token = auth.lastToken;
    final uri = Uri.parse(
      '$baseUrl/users/search?q=${Uri.encodeQueryComponent(q)}&limit=$limit',
    );

    final resp = await client.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode != 200) return [];

    final decoded = jsonDecode(resp.body);
    final list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List ? decoded['items'] : []);

    return List<User>.from(list.map((e) => User.fromJson(e)));
  }
}
