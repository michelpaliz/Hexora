import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/group/show-groups/group_card_widget/group_card_widget.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({
    super.key,
    required this.groups,
    required this.axis,
    required this.currentUser,
    required this.userDomain,
    required this.groupDomain,
    required this.updateRole,
  });

  final List<Group> groups;
  final Axis axis;
  final User currentUser;
  final UserDomain userDomain;
  final GroupDomain groupDomain;
  final void Function(String?) updateRole;

  static const double _kHorizontalRowHeight = 220;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = axis == Axis.horizontal;

    final list = ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: !isHorizontal,
      scrollDirection: axis,
      itemCount: groups.length,
      separatorBuilder: (_, __) =>
          isHorizontal ? const SizedBox(width: 10) : const SizedBox(height: 10),
      itemBuilder: (_, index) {
        return buildGroupCard(
          context,
          groups[index],
          currentUser,
          userDomain,
          groupDomain,
          updateRole,
        );
      },
    );

    if (isHorizontal) {
      return SizedBox(height: _kHorizontalRowHeight, child: list);
    }
    return list;
  }
}
