import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/data/user/domain/user_domain.dart';
import 'package:hexora/data/group_management/group/domain/group_domain.dart';

class CreateGroupUseCase {
  final GroupDomain groupDomain;
  final UserDomain userDomain;
  CreateGroupUseCase(this.groupDomain, this.userDomain);

  Future<Group> call({
    required String name,
    required String description,
    required User owner,
  }) async {
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
