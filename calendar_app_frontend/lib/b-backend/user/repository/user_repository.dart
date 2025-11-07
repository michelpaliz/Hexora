import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/api/i_user_api_client.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';

typedef TokenSupplier = Future<String?> Function();

class UserRepository implements IUserRepository {
  final IUserApiClient _svc;
  final TokenSupplier _tokenSupplier;

  UserRepository({
    required IUserApiClient apiClient,
    required TokenSupplier tokenSupplier,
  })  : _svc = apiClient,
        _tokenSupplier = tokenSupplier;

  Future<String> _token() async {
    final token = await _tokenSupplier();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }
    return token;
  }

  // 🔐 Auth
  @override
  Future<String> getAuthToken({bool forceRefresh = false}) async {
    // If your token supplier can force-refresh, call it here.
    // Otherwise just return the current token.
    return _token();
  }

  // -------- Blobs / Avatars --------
  @override
  Future<String> getFreshAvatarUrl({required String blobName}) async {
    final t = await _token();
    return _svc.getFreshAvatarUrl(blobName: blobName, token: t);
  }

  // -------- Blobs / Avatars --------
  // @override
  // Future<String> getFreshAvatarUrl({required String blobName}) async {
  //   final t = await _token();
  //   return _svc.getFreshAvatarUrl(blobName: blobName, token: t);
  // }

  // -------- Create / Read / Update / Delete --------
  @override
  Future<User> createUser(User user) => _svc.createUser(user);

  @override
  Future<User> getUserById(String id) async =>
      _svc.getUserById(id, token: await _token());

  @override
  Future<User> getUserByEmail(String email) async =>
      _svc.getUserByEmail(email, token: await _token());

  @override
  Future<User> getUserByAuthID(String authID) async =>
      _svc.getUserByAuthID(authID, token: await _token());

  @override
  Future<User> updateUser(User user) async =>
      _svc.updateUser(user, token: await _token());

  @override
  Future<User> updateUserByUsername(String username, User user) async =>
      _svc.updateUserByUsername(username, user, token: await _token());

  @override
  Future<void> deleteUser(String id) async =>
      _svc.deleteUser(id, token: await _token());

  @override
  Future<List<User>> getAllUsers() async =>
      _svc.getAllUsers(token: await _token());

  // -------- Lookups --------
  @override
  Future<User> getUserByUsername(String username) async =>
      _svc.getUserByUsername(username, token: await _token());

  @override
  Future<List<String>> searchUsernames(String query) async =>
      _svc.searchUsernames(query, token: await _token());

  // -------- Helpers --------
  @override
  Future<List<User>> getUsersForGroup(Group group) async {
    final ids = group.userIds.map((e) => e.toString()).toList();
    return getUsersByIds(ids);
  }

  @override
  Future<List<User>> getUsersByIds(List<String> ids) async {
    return Future.wait(ids.map(getUserById), eagerError: false);
  }

  // -------- Notifications --------
  @override
  Future<List<NotificationUser>> getNotificationsByUser(
          String userName) async =>
      _svc.getNotificationsByUser(userName, token: await _token());

  // -------- Generic selector --------
  @override
  Future<User> getUserBySelector(String selector) async =>
      _svc.getUserBySelector(selector, token: await _token());
}
