import 'dart:convert';

import 'package:hexora/models/announcements/announcement.dart';
import 'package:hexora/services/auth/authenticated_http_client.dart';
import 'package:hexora/services/config/api_constants.dart';
import 'package:http/http.dart' as http;

class AnnouncementsApi {
  String get _root => ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/announcements'
      : '${ApiConstants.baseUrl}/api/announcements';

  String get _adminRoot => ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/admin/announcements'
      : '${ApiConstants.baseUrl}/api/admin/announcements';

  Future<AnnouncementPage> list({
    required String language,
    String? placement,
    String? category,
    int page = 1,
    int limit = 10,
    bool publicOnly = false,
    bool admin = false,
    String? status,
  }) async {
    final base = admin ? _adminRoot : publicOnly ? '$_root/public' : _root;
    final uri = Uri.parse(base).replace(queryParameters: {
      'language': language == 'en' ? 'en' : 'es',
      'page': '$page',
      'limit': '$limit',
      if (placement != null) 'placement': placement,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
    });
    final response = publicOnly
        ? await http.get(uri, headers: {'Accept-Language': language})
        : await AuthenticatedHttpClient.get(uri);
    if (response.statusCode != 200) {
      throw StateError('Could not load announcements (${response.statusCode})');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : const <String, dynamic>{};
    return AnnouncementPage(
      items: (json['announcements'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Announcement.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      page: (pagination['page'] as num?)?.toInt() ?? page,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<void> markRead(String id) async {
    final response = await AuthenticatedHttpClient.post(Uri.parse('$_root/$id/read'));
    if (response.statusCode != 200) throw StateError('Could not mark announcement as read');
  }

  Future<Announcement> saveDraft({String? id, required Map<String, dynamic> data}) async {
    final body = jsonEncode(data);
    final response = id == null
        ? await AuthenticatedHttpClient.post(Uri.parse(_adminRoot), body: body)
        : await AuthenticatedHttpClient.patch(Uri.parse('$_adminRoot/$id'), body: body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(_message(response));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return Announcement.fromJson(Map<String, dynamic>.from(json['announcement'] as Map));
  }

  Future<void> publish(String id) => _adminAction(id, 'publish');
  Future<void> archive(String id) => _adminAction(id, 'archive');

  Future<void> _adminAction(String id, String action) async {
    final response = await AuthenticatedHttpClient.post(
      Uri.parse('$_adminRoot/$id/$action'),
      body: '{}',
    );
    if (response.statusCode != 200) throw StateError(_message(response));
  }

  String _message(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['message'] ?? 'Request failed').toString();
    } catch (_) {
      return 'Request failed (${response.statusCode})';
    }
  }
}
