import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local, account-scoped chat drafts. Never shared with the server.
class BusinessChatDrafts {
  BusinessChatDrafts({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  Future<void> _pending = Future.value();

  String _key(String userId, String groupId, String conversationId) =>
      'business_chat_draft:$userId:$groupId:$conversationId';

  Future<String?> read(
      String userId, String groupId, String conversationId) async {
    await _pending.catchError((_) {});
    return _storage.read(key: _key(userId, groupId, conversationId));
  }

  Future<void> write(
      String userId, String groupId, String conversationId, String text) {
    final key = _key(userId, groupId, conversationId);
    _pending = _pending.catchError((_) {}).then((_) => text.trim().isEmpty
        ? _storage.delete(key: key)
        : _storage.write(key: key, value: text));
    return _pending;
  }

  Future<void> clearGroup(String userId, String groupId) async {
    await _pending.catchError((_) {});
    final prefix = 'business_chat_draft:$userId:$groupId:';
    final entries = await _storage.readAll();
    for (final key in entries.keys.where((key) => key.startsWith(prefix))) {
      await _storage.delete(key: key);
    }
  }
}
