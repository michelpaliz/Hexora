// lib/.../calendar/widgets/presence_status_strip.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/utils/image/user_image/widgets/user_status_row.dart';

class PresenceStatusStrip extends StatelessWidget {
  final Group group;
  final CalendarScreenCoordinator controller;
  final String? selectedUserId;
  final ValueChanged<String?>? onUserSelected;
  const PresenceStatusStrip(
      {super.key,
      required this.group,
      required this.controller,
      this.selectedUserId,
      this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    final connectedUsers = controller.buildPresenceFor(group);
    return UserStatusRow(
      userList: connectedUsers,
      selectedUserId: selectedUserId,
      onUserSelected: onUserSelected,
    );
  }
}
