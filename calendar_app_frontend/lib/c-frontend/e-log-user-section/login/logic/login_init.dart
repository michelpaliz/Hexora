import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_service.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/group_mng_flow/event/socket/socket_manager.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/socket_notification_listener.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';

// Import or replace with your actual constants location
class ApiConstants {
  static const bool avatarsArePublic = true; // set from backend config
  static const String cdnBaseUrl =
      'https://mantemichelstore.blob.core.windows.net/profile-images';
}

class LoginInitializer {
  final AuthService authService;
  final UserDomain userDomain;
  final GroupDomain groupDomain;

  User? _user;

  LoginInitializer({
    required this.authService,
    required this.userDomain,
    required this.groupDomain,
  });

  Future<void> initializeUserAndServices(String email, String password) async {
    await authService.logIn(email: email, password: password);
    final rawUser = await authService.getCurrentUserModel();
    debugPrint('🔍 Got user from authService: $rawUser');

    if (rawUser != null) {
      // 🔧 Normalize photoUrl in public avatar mode
      final normalizedUser = ApiConstants.avatarsArePublic
          ? rawUser.copyWith(
              photoUrl: _normalizePublicAvatar(rawUser.photoUrl ?? ''))
          : rawUser;
      authService.currentUser = normalizedUser;

      _user = normalizedUser;

      final token = await TokenService.loadToken();

      // ✅ Pass normalized user to state management
      userDomain.setCurrentUser(
        normalizedUser,
      );
      groupDomain.setCurrentUser(normalizedUser);

      debugPrint('✅ setCurrentUser called with: ${normalizedUser.userName}');

      initializeNotificationSocket(normalizedUser.id);

      if (token != null) {
        SocketManager().connect(token);
      } else {
        debugPrint('❌ No auth token found — cannot connect socket.');
      }
    } else {
      debugPrint('❌ getCurrentUserModel returned null');
    }
  }

  User? get user => _user;

  /// Ensures `photoUrl` is in `${CDN_BASE_URL}/<blobName>` format without query params.
  String _normalizePublicAvatar(String photoUrl) {
    if (photoUrl.isEmpty) return photoUrl;

    final uri = Uri.tryParse(photoUrl);
    if (uri == null) return photoUrl;

    final alreadyCdn =
        photoUrl.startsWith(ApiConstants.cdnBaseUrl) && !uri.hasQuery;
    if (alreadyCdn) return photoUrl;

    final segments = uri.pathSegments;
    if (segments.isEmpty) return photoUrl;

    final blobName = segments.last;
    if (blobName.isEmpty) return photoUrl;

    return '${ApiConstants.cdnBaseUrl}/$blobName';
  }
}
