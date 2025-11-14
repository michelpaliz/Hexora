import 'dart:io';

import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:share_plus/share_plus.dart';

class UploadGroupPhotoUseCase {
  final GroupDomain groupDomain;
  final AuthProvider auth;
  final UserDomain userDomain;
  UploadGroupPhotoUseCase(this.groupDomain, this.auth, this.userDomain);

  /// Upload a group photo and commit it to the server.
  ///
  /// Throws a [StateError] if not authenticated.
  ///
  /// Refreshes the groups for the current user after a successful upload.
  ///
  /// [groupId] is the id of the group that the photo belongs to.
  /// [file] is the file to be uploaded.

  Future<void> call({required String groupId, required XFile file}) async {
    final token = auth.lastToken;
    if (token == null) throw StateError('Not authenticated');
    await groupDomain.groupRepository.uploadAndCommitGroupPhoto(
      groupId: groupId,
      file: File(file.path),
    );
    await groupDomain.refreshGroupsForCurrentUser(userDomain);
  }
}
