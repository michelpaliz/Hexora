// lib/b-backend/group_mng_flow/group/view_model/presentation/use_cases/update_group_usecase.dart
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';

class UpdateGroupUseCase {
  final GroupDomain groupDomain;
  final UserDomain userDomain;
  UpdateGroupUseCase(this.groupDomain, this.userDomain);

  /// Update an existing group by taking the original and overriding changed fields.
  Future<void> call({
    required Group original,
    required String name,
    required String description,
    String? photoUrl,
    String? photoBlobName,
  }) async {
    // Prefer copyWith if your Group supports it; otherwise build a new instance.
    final updated = original.copyWith(
      name: name,
      description: description,
      photoUrl: photoUrl ?? original.photoUrl,
      photoBlobName: photoBlobName ?? original.photoBlobName,
      // keep ownerId, userIds, userRoles, createdTime, etc.
    );

    await groupDomain.updateGroup(updated, userDomain);
    await groupDomain.refreshGroupsForCurrentUser(userDomain);
  }
}
