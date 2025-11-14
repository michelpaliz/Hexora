import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';

// This widget plugs into the AppBar and manages:
//     Live unread notification badge
//     Navigation to the notifications screen
//     Marking notifications as read

Widget buildNotificationIcon({
  required BuildContext context,
  required UserDomain userDomain,
  required NotificationDomain notificationDomain,
}) {
  final currentUser = userDomain.user;

  if (currentUser == null) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        // Optional: show login warning or redirect
      },
    );
  }

  return StreamBuilder<List<NotificationUser>>(
    stream: notificationDomain.notificationStream,
    builder: (context, snapshot) {
      final notifications = snapshot.data ?? [];
      final unread = notifications.where((n) => !n.isRead).toList();
      final hasUnread = unread.isNotEmpty;

      return IconButton(
        icon: Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(Icons.notifications),
            if (hasUnread)
              const Positioned(
                right: 0,
                child: Icon(Icons.brightness_1, size: 10, color: Colors.red),
              ),
          ],
        ),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.showNotifications,
            arguments: currentUser,
          );
          notificationDomain.markAllNotificationsAsRead();
        },
      );
    },
  );
}
