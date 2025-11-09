// lib/.../calendar/widgets/presence_status_strip.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/c-group-calendar-section/screens/calendar/presentation/coordinator/calendar_screen_coordinator.dart';
import 'package:hexora/c-frontend/utils/image/user_status_avatar_row.dart';

class PresenceStatusStrip extends StatelessWidget {
  final Group group;
  final CalendarScreenCoordinator controller;
  const PresenceStatusStrip(
      {super.key, required this.group, required this.controller});

  @override
  Widget build(BuildContext context) {
    final connectedUsers = controller.buildPresenceFor(group);
    return UserStatusRow(userList: connectedUsers);
  }
}
