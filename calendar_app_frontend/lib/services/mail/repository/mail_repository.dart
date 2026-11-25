import 'package:hexora/models/mail/mail_folder.dart';
import 'package:hexora/models/mail/mail_message.dart';
import 'package:hexora/models/mail/mail_page.dart';
import 'package:hexora/models/mail/mail_thread.dart';
import 'package:hexora/services/mail/api/i_mail_api_client.dart';
import 'package:hexora/services/mail/models/mail_requests.dart';
import 'package:hexora/services/mail/repository/i_mail_repository.dart';
import 'package:http/http.dart' as http;

class MailRepository implements IMailRepository {
  MailRepository({
    required IMailApiClient apiClient,
    required TokenSupplier tokenSupplier,
  })  : _api = apiClient,
        _token = tokenSupplier;

  final IMailApiClient _api;
  final TokenSupplier _token;
  String? _scopeGroupId;

  void setGroupScope(String? groupId) {
    final trimmed = groupId?.trim();
    _scopeGroupId = trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<String> _requireToken() async {
    final token = await _token();
    if (token.isEmpty) throw Exception('Not authenticated');
    return token;
  }

  @override
  Future<MailPage<MailMessage>> getMessages({
    required MailFolder folder,
    int limit = 25,
    String? cursor,
  }) async {
    final token = await _requireToken();
    return _api.getMessages(
      folder: folder.wireName,
      token: token,
      groupId: _scopeGroupId,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  Future<MailMessage> getMessage(String id) async {
    final token = await _requireToken();
    return _api.getMessage(id: id, token: token, groupId: _scopeGroupId);
  }

  @override
  Future<MailPage<MailMessage>> searchMessages({
    required String query,
    MailFolder? folder,
    bool? unread,
    DateTime? after,
    DateTime? before,
    int limit = 25,
    String? cursor,
  }) async {
    final token = await _requireToken();
    return _api.searchMessages(
      token: token,
      groupId: _scopeGroupId,
      query: query,
      folder: folder?.wireName,
      unread: unread,
      after: after,
      before: before,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  Future<MailPage<MailThread>> getThreads({
    required MailFolder folder,
    int limit = 25,
    String? cursor,
    String? query,
  }) async {
    final token = await _requireToken();
    return _api.getThreads(
      folder: folder.wireName,
      token: token,
      groupId: _scopeGroupId,
      limit: limit,
      cursor: cursor,
      query: query,
    );
  }

  @override
  Future<MailThreadDetail> getThread(String threadKey) async {
    final token = await _requireToken();
    return _api.getThread(
      threadKey: threadKey,
      token: token,
      groupId: _scopeGroupId,
    );
  }

  @override
  Future<void> markRead(String id) async {
    final token = await _requireToken();
    await _api.markRead(id: id, token: token, groupId: _scopeGroupId);
  }

  @override
  Future<void> markUnread(String id) async {
    final token = await _requireToken();
    await _api.markUnread(id: id, token: token, groupId: _scopeGroupId);
  }

  @override
  Future<void> archive(String id) async {
    final token = await _requireToken();
    await _api.archive(id: id, token: token, groupId: _scopeGroupId);
  }

  @override
  Future<void> trash(String id) async {
    final token = await _requireToken();
    await _api.trash(id: id, token: token, groupId: _scopeGroupId);
  }

  @override
  Future<void> spam(String id) async {
    final token = await _requireToken();
    await _api.spam(id: id, token: token, groupId: _scopeGroupId);
  }

  @override
  Future<http.Response> downloadAttachment(String attachmentId) async {
    final token = await _requireToken();
    return _api.downloadAttachment(
      attachmentId: attachmentId,
      token: token,
      groupId: _scopeGroupId,
    );
  }

  @override
  Future<void> sendMessage(MailSendRequest request) async {
    final token = await _requireToken();
    final payload = request.toJson();
    if (_scopeGroupId != null) payload['groupId'] = _scopeGroupId;
    await _api.sendMessage(payload: payload, token: token);
  }

  @override
  Future<void> reply(String id, MailReplyRequest request) async {
    final token = await _requireToken();
    await _api.reply(id: id, payload: request.toJson(), token: token);
  }

  @override
  Future<void> forward(String id, MailForwardRequest request) async {
    final token = await _requireToken();
    final payload = request.toJson();
    if (_scopeGroupId != null) payload['groupId'] = _scopeGroupId;
    await _api.forward(id: id, payload: payload, token: token);
  }
}
