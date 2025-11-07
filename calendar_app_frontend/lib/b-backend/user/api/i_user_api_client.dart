// lib/b-backend/login_user/user/api/i_user_api_client.dart
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';

abstract class IUserApiClient {
  // Blobs / Avatars
  Future<String> getFreshAvatarUrl({
    required String blobName,
    required String token,
  });

  // CRUD
  Future<User> createUser(User user);
  Future<User> getUserById(String userId, {required String token});
  Future<User> getUserByEmail(String email, {String? token});
  Future<User> getUserByAuthID(String authID, {String? token});
  Future<User> updateUser(User user, {required String token});
  Future<User> updateUserByUsername(String username, User user,
      {required String token});
  Future<void> deleteUser(String id, {required String token});
  Future<List<User>> getAllUsers({String? token});

  // Lookups
  Future<User> getUserByUsername(String username, {String? token});
  Future<List<String>> searchUsernames(String username, {String? token});

  // Notifications
  Future<List<NotificationUser>> getNotificationsByUser(
    String userName, {
    required String token,
  });

  // Generic selector
  Future<User> getUserBySelector(String selector, {String? token});
}
