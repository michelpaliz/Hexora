import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:iconsax/iconsax.dart';

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
      icon: Iconsax.calendar_add,
      onPressed: () =>
          Navigator.pushNamed(context, AppRoutes.addEvent, arguments: groupArg),
    );
  }

  // home (or empty) → create group
  if (routeName == AppRoutes.homePage || routeName.isEmpty) {
    return FabAction(
      icon: Iconsax.add_circle,
      onPressed: () => Navigator.pushNamed(context, AppRoutes.createGroupData),
    );
  }

  // agenda → pick group then add event
  if (routeName == AppRoutes.agenda) {
    return FabAction(
      icon: Iconsax.calendar_add,
      onPressed: () => pickGroupAndAddEvent(context),
    );
  }

  // notifications → clear all
  if (routeName == AppRoutes.showNotifications) {
    return FabAction(
      icon: Iconsax.trash,
      onPressed: () => confirmAndClearAllNotifications(context),
    );
  }

  // profile details → open action sheet (edit/share/add to contacts)
  if (routeName == AppRoutes.profileDetails) {
    return FabAction(
      icon: Iconsax.edit,
      onPressed: () => openProfileActions(context, accentColor),
    );
  }

  // default → create group
  return FabAction(
    icon: Iconsax.add_circle,
    onPressed: () => Navigator.pushNamed(context, AppRoutes.createGroupData),
  );
}
