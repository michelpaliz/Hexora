import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/c-frontend/ui-app/h-profile-section/edit/controller/profile_update_contract.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class ProfileEditController {
  Future<void> changePhoto(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final auth = context.read<AuthProvider>();
      final token = await auth.getToken();
      final userDomain = context.read<UserDomain>();
      final user = userDomain.user;

      if (token == null || user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.notAuthenticatedOrUserMissing)),
        );
        return;
      }

      final bytes = kIsWeb ? await picked.readAsBytes() : null;
      final result = await uploadImageToAzure(
        scope: 'users',
        file: kIsWeb ? null : File(picked.path),
        bytes: bytes,
        accessToken: token,
      );

      final commitResp = await AuthenticatedHttpClient.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'blobName': result.blobName}),
      );

      if (commitResp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.failedToSavePhoto}: ${commitResp.statusCode}'),
          ),
        );
        return;
      }

      final updatedUserJson = jsonDecode(commitResp.body) as Map<String, dynamic>;
      final updated = user.copyWith(
        photoUrl: updatedUserJson['photoUrl'] ?? result.photoUrl,
        photoBlobName: updatedUserJson['photoBlobName'] ?? result.blobName,
      );

      userDomain.updateCurrentUser(updated);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.photoUpdated)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.failedToUploadImage}: $e')),
      );
    }
  }

  Future<ProfileSaveResult> saveProfile({
    required BuildContext context,
    required String displayName,
    required String username,
    required String phoneNumber,
    required String location,
    required String bio,
  }) async {
    final l = AppLocalizations.of(context)!;
    final userDomain = context.read<UserDomain>();
    final user = userDomain.user;
    if (user == null) {
      return const ProfileSaveResult(
        success: false,
        message: 'No user loaded.',
      );
    }

    final input = ProfileUpdateInput(
      displayName: displayName,
      userName: username,
      phoneNumber: phoneNumber,
      location: location,
      bio: bio,
    );

    final validation = ProfileUpdateContract.validate(input);
    if (!validation.isValid) {
      return const ProfileSaveResult(
        success: false,
        message: 'Please fix the highlighted fields.',
      ).copyWith(validation: validation);
    }

    final payload = ProfileUpdateContract.buildPayload(input);

    try {
      http.Response resp = await AuthenticatedHttpClient.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Some environments don't expose /users/me for updates.
      if (resp.statusCode == 404) {
        resp = await AuthenticatedHttpClient.put(
          Uri.parse('${ApiConstants.baseUrl}/users/${user.id}'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final raw = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;
        final saved = raw is Map<String, dynamic>
            ? (raw.containsKey('user') && raw['user'] is Map
                ? raw['user'] as Map<String, dynamic>
                : raw)
            : const <String, dynamic>{};

        final updatedUser = user.copyWith(
          displayName: (saved['displayName'] as String?) ??
              (payload['displayName'] as String?),
          userName: (saved['userName'] as String?) ??
              (payload['userName'] as String? ?? user.userName),
          phoneNumber: (saved['phoneNumber'] as String?) ??
              (saved['phone'] as String?) ??
              (payload['phoneNumber'] as String?),
          location:
              (saved['location'] as String?) ?? (payload['location'] as String?),
          bio: (saved['bio'] as String?) ?? (payload['bio'] as String?),
        );

        userDomain.updateCurrentUser(updatedUser);
        return ProfileSaveResult(
          success: true,
          user: updatedUser,
          message: l.profileSaved,
        );
      }

      String? backendMessage;
      if (resp.body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) {
            backendMessage =
                decoded['message']?.toString() ?? decoded['error']?.toString();
          }
        } catch (_) {}
      }

      final message = ProfileUpdateContract.mapErrorMessage(
        statusCode: resp.statusCode,
        backendMessage: backendMessage,
      );

      return ProfileSaveResult(
        success: false,
        message: message,
        validation: ProfileUpdateValidationResult(
          userNameError: resp.statusCode == 409 ||
                  (backendMessage ?? '').toLowerCase().contains('username')
              ? message
              : null,
        ),
      );
    } catch (_) {
      return const ProfileSaveResult(
        success: false,
        message: 'Failed to save profile. Please try again.',
      );
    }
  }
}

class ProfileSaveResult {
  final bool success;
  final String? message;
  final ProfileUpdateValidationResult? validation;
  final User? user;

  const ProfileSaveResult({
    required this.success,
    this.message,
    this.validation,
    this.user,
  });

  ProfileSaveResult copyWith({
    bool? success,
    String? message,
    ProfileUpdateValidationResult? validation,
    User? user,
  }) {
    return ProfileSaveResult(
      success: success ?? this.success,
      message: message ?? this.message,
      validation: validation ?? this.validation,
      user: user ?? this.user,
    );
  }
}
