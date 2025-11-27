import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/errors/group_limit_exception.dart';

class CreateGroupUseCase {
  final GroupDomain groupDomain;
  final UserDomain userDomain;
  CreateGroupUseCase(this.groupDomain, this.userDomain);

  Future<Group> call({
    required String name,
    required String description,
    required User owner,
  }) async {
    if (owner.groupIds.length >= 2) {
      throw const GroupLimitException(
        'You can only belong to two groups at a time.',
      );
    }
    final group = Group(
      id: '',
      name: name,
      ownerId: owner.id,
      userRoles: {owner.id: 'owner'},
      userIds: [owner.id],
      createdTime: DateTime.now(),
      description: description,
      photoUrl: '',
      photoBlobName: null,
      defaultCalendarId: null,
      defaultCalendar: null,
    );
    final created = await groupDomain.createGroupReturning(group, userDomain);
    await groupDomain.refreshGroupsForCurrentUser(userDomain);
    return created;
  }
}
