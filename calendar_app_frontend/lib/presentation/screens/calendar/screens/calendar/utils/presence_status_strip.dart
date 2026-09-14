import 'package:provider/provider.dart';
import 'package:hexora/services/user/presence_domain.dart';
// lib/.../calendar/widgets/presence_status_strip.dart
import 'package:flutter/material.dart';
import 'package:hexora/models/group_model/group/group.dart';
import 'package:hexora/presentation/screens/calendar/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/presentation/utils/image/user_image/widgets/user_status_row.dart';

class PresenceStatusStrip extends StatelessWidget {
  final Group group;
  final CalendarScreenCoordinator controller;
  final String? selectedUserId;
  final ValueChanged<String?>? onUserSelected;
  final bool showAllOption;
  const PresenceStatusStrip(
      {super.key,
      required this.group,
      required this.controller,
      this.selectedUserId,
      this.onUserSelected,
      this.showAllOption = true});

  @override
  Widget build(BuildContext context) {
    final connectedUsers = context
        .watch<PresenceDomain>()
        .getPresenceForGroup(group.userIds, group.userRoles);
    return UserStatusRow(
      userList: connectedUsers,
      selectedUserId: selectedUserId,
      onUserSelected: onUserSelected,
      showAllOption: showAllOption,
    );
  }
}
