// lib/b-backend/auth_user/user/repository/i_user_repository.dart
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';

abstract class IUserRepository {
  // Blobs / Avatars
  Future<String> getFreshAvatarUrl({required String blobName});

  // 🔐 Auth
  Future<String> getAuthToken({bool forceRefresh = false}); // <-- ADD

  // CRUD
  Future<User> createUser(User user);
  Future<User> getUserById(String id);
  Future<User> getUserByEmail(String email);
  Future<User> getUserByAuthID(String authID);
  Future<User> updateUser(User user);
  Future<User> updateUserByUsername(String username, User user);
  Future<void> deleteUser(String id);
  Future<List<User>> getAllUsers();

  // Lookups
  Future<User> getUserByUsername(String username);
  Future<List<String>> searchUsernames(String query);

  // Helpers
  Future<List<User>> getUsersForGroup(Group group);
  Future<List<User>> getUsersByIds(List<String> ids);

  // Notifications
  Future<List<NotificationUser>> getNotificationsByUser(String userName);

  // Generic selector
  Future<User> getUserBySelector(String selector);
}
