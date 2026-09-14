// lib/services/groups/view_model/presentation/use_cases/update_group_usecase.dart
import 'package:hexora/models/group_model/group/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/user/domain/user_domain.dart';

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

    final saved = await groupDomain.updateGroup(updated, userDomain);
    if (!saved) throw StateError('Group update failed');
  }
}
