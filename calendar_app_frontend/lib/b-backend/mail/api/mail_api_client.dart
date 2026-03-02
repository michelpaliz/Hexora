import 'dart:convert';

import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_page.dart';
import 'package:hexora/a-models/mail/mail_thread.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/errorClases/error_classes/error_classes.dart';
import 'package:hexora/b-backend/mail/api/i_mail_api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MailApiClient implements IMailApiClient {
  MailApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  final String _base = ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/mail'
      : '${ApiConstants.baseUrl}/api/mail';

  Map<String, String> _headers({String? token}) {
    final _ = token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Uri _u(String path, [Map<String, String>? params]) {
    final base = Uri.parse('$_base$path');
    if (params == null || params.isEmpty) return base;
    return base.replace(queryParameters: params);
  }

  String _extractErrorMessage(dynamic body, int statusCode, String? reason) {
    String pick(dynamic v) => (v == null) ? '' : v.toString().trim();

    if (body is Map) {
      final message = pick(body['message']);
      if (message.isNotEmpty) return message;

      final error = body['error'];
      if (error is Map) {
        final nestedMessage = pick(error['message']);
        if (nestedMessage.isNotEmpty) return nestedMessage;
        final nestedDetail = pick(error['detail']);
        if (nestedDetail.isNotEmpty) return nestedDetail;
      } else {
        final plainError = pick(error);
        if (plainError.isNotEmpty) return plainError;
      }

      final detail = pick(body['detail']);
      if (detail.isNotEmpty) return detail;

      final title = pick(body['title']);
      if (title.isNotEmpty) return title;
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    final safeReason = (reason ?? '').trim();
    if (safeReason.isNotEmpty) return safeReason;

    if (statusCode >= 500) {
      return 'Server error ($statusCode). Please try again.';
    }
    return 'Request failed ($statusCode).';
  }

  bool _isTrashDuplicateFailure(HttpFailure failure) {
    if (failure.statusCode != 500) return false;
    final m = failure.message.toLowerCase();
    return m.contains('e11000 duplicate key error') &&
        m.contains('folder_1_imapuid_1') &&
        m.contains('inbox.trash');
  }

  dynamic _decode(http.Response r) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }
    if (ok) return body;

    final message = _extractErrorMessage(body, r.statusCode, r.reasonPhrase);
    throw HttpFailure(r.statusCode, message);
  }

  MailPage<T> _decodePage<T>(
    http.Response r,
    T Function(Map<String, dynamic>) map,
  ) {
    final data = _decode(r);
    if (data is List) {
      final items = data
          .whereType<Map>()
          .map((e) => map(e.cast<String, dynamic>()))
          .toList();
      return MailPage<T>(items: items);
    }
    if (data is Map) {
      final cursor = data['nextCursor'] ??
          data['next_cursor'] ??
          data['cursor'] ??
          data['next'] ??
          data['nextPageCursor'];
      final list = data['items'] ??
          data['messages'] ??
          data['threads'] ??
          data['results'] ??
          data['data'];
      final items = list is List
          ? list
              .whereType<Map>()
              .map((e) => map(e.cast<String, dynamic>()))
              .toList()
          : <T>[];
      return MailPage<T>(
        items: items,
        nextCursor: cursor?.toString(),
      );
    }
    return MailPage<T>(items: const []);
  }

  @override
  Future<MailPage<MailMessage>> getMessages({
    required String folder,
    required String token,
    int limit = 25,
    String? cursor,
  }) async {
    final params = <String, String>{
      'folder': folder,
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final r = await AuthenticatedHttpClient.get(
      _u('/messages', params),
      headers: _headers(token: token),
      client: _client,
    );
    return _decodePage<MailMessage>(r, MailMessage.fromJson);
  }

  @override
  Future<MailMessage> getMessage({
    required String id,
    required String token,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/messages/$id'),
      headers: _headers(token: token),
      client: _client,
    );
    final data = _decode(r);
    if (data is Map<String, dynamic>) return MailMessage.fromJson(data);
    if (data is Map) return MailMessage.fromJson(data.cast<String, dynamic>());
    throw HttpFailure(r.statusCode, 'Unexpected message payload');
  }

  @override
  Future<MailPage<MailMessage>> searchMessages({
    required String token,
    String? query,
    String? folder,
    bool? unread,
    DateTime? after,
    DateTime? before,
    int limit = 25,
    String? cursor,
  }) async {
    final params = <String, String>{
      if (query != null) 'q': query,
      if (folder != null) 'folder': folder,
      if (unread != null) 'unread': unread ? 'true' : 'false',
      if (after != null) 'after': after.toIso8601String(),
      if (before != null) 'before': before.toIso8601String(),
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final r = await AuthenticatedHttpClient.get(
      _u('/search', params),
      headers: _headers(token: token),
      client: _client,
    );
    return _decodePage<MailMessage>(r, MailMessage.fromJson);
  }

  @override
  Future<MailPage<MailThread>> getThreads({
    required String folder,
    required String token,
    int limit = 25,
    String? cursor,
  }) async {
    final params = <String, String>{
      'folder': folder,
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final r = await AuthenticatedHttpClient.get(
      _u('/threads', params),
      headers: _headers(token: token),
      client: _client,
    );
    return _decodePage<MailThread>(r, MailThread.fromJson);
  }

  @override
  Future<MailThreadDetail> getThread({
    required String threadKey,
    required String token,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/threads/$threadKey'),
      headers: _headers(token: token),
      client: _client,
    );
    final data = _decode(r);
    if (data is Map<String, dynamic>) return MailThreadDetail.fromJson(data);
    if (data is Map) return MailThreadDetail.fromJson(data.cast<String, dynamic>());
    throw HttpFailure(r.statusCode, 'Unexpected thread payload');
  }

  @override
  Future<void> markRead({required String id, required String token}) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/read'),
      headers: _headers(token: token),
      body: jsonEncode({}),
      client: _client,
    );
    _decode(r);
  }

  @override
  Future<void> markUnread({required String id, required String token}) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/unread'),
      headers: _headers(token: token),
      body: jsonEncode({}),
      client: _client,
    );
    _decode(r);
  }

  @override
  Future<void> archive({required String id, required String token}) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/archive'),
      headers: _headers(token: token),
      body: jsonEncode({}),
      client: _client,
    );
    _decode(r);
  }

  @override
  Future<void> trash({required String id, required String token}) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/trash'),
      headers: _headers(token: token),
      body: jsonEncode({}),
      client: _client,
    );
    try {
      _decode(r);
    } on HttpFailure catch (e) {
      // Backend can return duplicate-key 500 when the message is already
      // present in Trash. Treat this as an idempotent success.
      if (_isTrashDuplicateFailure(e)) {
        if (kDebugMode) {
          debugPrint(
            '[MailApiClient] Ignoring duplicate trash operation for message=$id',
          );
        }
        return;
      }
      rethrow;
    }
  }

  @override
  Future<void> spam({required String id, required String token}) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/spam'),
      headers: _headers(token: token),
      body: jsonEncode({}),
      client: _client,
    );
    _decode(r);
  }

  @override
  Future<http.Response> downloadAttachment({
    required String attachmentId,
    required String token,
  }) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/attachments/$attachmentId'),
      headers: _headers(token: token),
      client: _client,
    );
    if (r.statusCode >= 200 && r.statusCode < 300) return r;
    final message = r.body.isNotEmpty ? r.body : (r.reasonPhrase ?? '');
    throw HttpFailure(r.statusCode, message);
  }

  @override
  Future<void> sendMessage({
    required Map<String, dynamic> payload,
    required String token,
  }) async {
    if (kDebugMode) {
      debugPrint('[MailApiClient] /api/mail/send payload=${jsonEncode(payload)}');
    }
    final r = await AuthenticatedHttpClient.post(
      _u('/send'),
      headers: _headers(token: token),
      body: jsonEncode(payload),
      client: _client,
    );
    if (kDebugMode) {
      final body = r.body;
      final preview = body.length > 800 ? '${body.substring(0, 800)}...' : body;
      debugPrint('[MailApiClient] /api/mail/send status=${r.statusCode}');
      if (preview.isNotEmpty) {
        debugPrint('[MailApiClient] /api/mail/send body=$preview');
      }
    }
    _decode(r);
  }

  @override
  Future<void> reply({
    required String id,
    required Map<String, dynamic> payload,
    required String token,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/reply'),
      headers: _headers(token: token),
      body: jsonEncode(payload),
      client: _client,
    );
    _decode(r);
  }

  @override
  Future<void> forward({
    required String id,
    required Map<String, dynamic> payload,
    required String token,
  }) async {
    final r = await AuthenticatedHttpClient.post(
      _u('/messages/$id/forward'),
      headers: _headers(token: token),
      body: jsonEncode(payload),
      client: _client,
    );
    _decode(r);
  }
}
