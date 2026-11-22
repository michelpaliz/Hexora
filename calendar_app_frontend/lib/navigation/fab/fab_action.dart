import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'actions/group_event_actions.dart';
import 'actions/notification_actions.dart';
import 'actions/profile_actions.dart';

class FabAction {
  final IconData icon;
  final VoidCallback? onPressed;
  const FabAction({required this.icon, required this.onPressed});
}

FabAction resolveFabAction({
  required BuildContext context,
  required String routeName,
  required Color accentColor,
  Group? groupArg,
}) {
  // route with Group argument → add event to that group
  if (groupArg != null) {
    return FabAction(
      icon: LucideIcons.calendarPlus,
      onPressed: () =>
          Navigator.pushNamed(context, AppRoutes.addEvent, arguments: groupArg),
    );
  }

  // home (or empty) → create group
  if (routeName == AppRoutes.homePage || routeName.isEmpty) {
    return FabAction(
      icon: LucideIcons.circlePlus,
      onPressed: () => Navigator.pushNamed(context, AppRoutes.createGroupData),
    );
  }

  // agenda → pick group then add event
  if (routeName == AppRoutes.agenda) {
    return FabAction(
      icon: LucideIcons.calendarPlus,
      onPressed: () => pickGroupAndAddEvent(context),
    );
  }

  // notifications → clear all
  if (routeName == AppRoutes.showNotifications) {
    return FabAction(
      icon: LucideIcons.trash2,
      onPressed: () => confirmAndClearAllNotifications(context),
    );
  }

  // profile details → open action sheet (edit/share/add to contacts)
  if (routeName == AppRoutes.profileDetails) {
    return FabAction(
      icon: LucideIcons.pencil,
      onPressed: () => openProfileActions(context, accentColor),
    );
  }

  // default → create group
  return FabAction(
    icon: LucideIcons.circlePlus,
    onPressed: () => Navigator.pushNamed(context, AppRoutes.createGroupData),
  );
}
