// lib/b-services/categories/category_api.dart  (use this single source of truth)
import 'dart:convert';

import 'package:hexora/models/group_model/category/event_category.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CategoryApi {
  final String baseUrl;
  final Future<Map<String, String>> Function() headersProvider;

  CategoryApi({required this.baseUrl, required this.headersProvider});

  Uri _u(String path, {Map<String, String?> query = const {}}) {
    // Handles trailing slashes robustly
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(
      queryParameters: {
        for (final e in query.entries)
          if (e.value != null) e.key: e.value!
      },
    );
  }

  // Future<List<EventCategory>> list({String? parentId}) async {
  //   final headers = await headersProvider();
  //   final uri = _u('/event-categories', query: {'parentId': parentId});
  //   if (kDebugMode) debugPrint('GET $uri');
  //   final r = await http.get(uri, headers: headers);
  //   if (r.statusCode != 200) {
  //     throw Exception('Failed to load categories (${r.statusCode}): ${r.body}');
  //   }
  //   final data = jsonDecode(r.body) as List;
  //   return data
  //       .map((e) => EventCategory.fromMap(e as Map<String, dynamic>))
  //       .toList();
  // }

  // lib/b-services/categories/category_api.dart
  Future<List<EventCategory>> list({String? parentId}) async {
    final headers = await headersProvider();
    final uri = _u('/event-categories', query: {'parentId': parentId});

    final r = await http.get(uri, headers: headers);

    if (r.statusCode == 200) {
      final json = jsonDecode(r.body);
      if (json is List) {
        return json
            .map((e) => EventCategory.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      // defensive: server returned 200 with non-list
      return <EventCategory>[];
    }

    // 👇 treat "no content" or "no categories yet" as empty
    if (r.statusCode == 204 || r.statusCode == 404) {
      return <EventCategory>[];
    }

    throw Exception('Failed to load categories (${r.statusCode}): ${r.body}');
  }

  Future<EventCategory> create(EventCategory input) async {
    final headers = await headersProvider();
    final uri = _u('/event-categories');
    if (kDebugMode) debugPrint('POST $uri body=${input.toBackendCreateJson()}');
    final r = await http.post(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(input.toBackendCreateJson()),
    );
    if (r.statusCode != 201) {
      throw Exception('Failed to create category (${r.statusCode}): ${r.body}');
    }
    return EventCategory.fromMap(jsonDecode(r.body));
  }

  Future<EventCategory> update(String id,
      {String? name, String? color, String? icon}) async {
    final headers = await headersProvider();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (color != null) body['color'] = color;
    if (icon != null) body['icon'] = icon;

    final uri = _u('/event-categories/$id');
    if (kDebugMode) debugPrint('PATCH $uri body=$body');
    final r = await http.patch(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode != 200) {
      throw Exception('Failed to update category (${r.statusCode}): ${r.body}');
    }
    return EventCategory.fromMap(jsonDecode(r.body));
  }

  Future<void> delete(String id) async {
    final headers = await headersProvider();
    final uri = _u('/event-categories/$id');
    if (kDebugMode) debugPrint('DELETE $uri');
    final r = await http.delete(uri, headers: headers);
    if (r.statusCode != 200) {
      throw Exception('Failed to delete category (${r.statusCode}): ${r.body}');
    }
  }
}
