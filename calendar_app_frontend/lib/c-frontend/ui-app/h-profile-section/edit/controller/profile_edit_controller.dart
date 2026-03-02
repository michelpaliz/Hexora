import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/c-frontend/utils/errors/group_membership_error_mapper.dart';
import 'package:hexora/c-frontend/utils/errors/premium_upgrade_dialog.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
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

      // 1) Upload to Azure (helper returns blobName + (maybe) public photoUrl)
      final bytes = kIsWeb ? await picked.readAsBytes() : null;
      final result = await uploadImageToAzure(
        scope: 'users',
        file: kIsWeb ? null : File(picked.path),
        bytes: bytes,
        accessToken: token,
      );

      // 2) Commit on backend
      final commitResp = await AuthenticatedHttpClient.patch(
        Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'blobName': result.blobName}),
      );

      if (commitResp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${l.failedToSavePhoto}: ${commitResp.statusCode}')),
        );
        return;
      }

      // 3) Update local user
      final updatedUserJson =
          jsonDecode(commitResp.body) as Map<String, dynamic>;
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

  Future<bool> saveProfile({
    required BuildContext context,
    required String name,
    required String username,
  }) async {
    final l = AppLocalizations.of(context)!;
    final userDomain = context.read<UserDomain>();
    final user = userDomain.user;
    if (user == null) return false;

    try {
      final updated = user.copyWith(
        name: name.trim(),
        userName: username.trim(),
      );
      final ok = await userDomain.updateUser(updated);
      if (!ok && userDomain.lastUpdateError != null) {
        final err = userDomain.lastUpdateError!;
        if (GroupMembershipErrorMapper.isPremiumMultiGroupError(err)) {
          await showPremiumUpgradeDialog(
            context,
            message: GroupMembershipErrorMapper.messageFor(
              l,
              GroupMembershipErrorContext.profileMembershipUpdate,
            ),
          );
          return false;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? l.profileSaved : l.failedToSaveProfile)),
      );
      return ok;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      return false;
    }
  }
}
