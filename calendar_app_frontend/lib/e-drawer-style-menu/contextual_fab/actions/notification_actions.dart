import 'package:flutter/material.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';
import 'package:hexora/b-backend/notification/view_model/notification_view_model.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Future<void> confirmAndClearAllNotifications(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final user = context.read<UserDomain>().user;

  if (user == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.zeroNotifications)));
    }
    return;
  }

  final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(loc.clearAllConfirmTitle),
          content: Text(loc.clearAllConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.clearAll),
            ),
          ],
        ),
      ) ??
      false;

  if (!confirmed) return;

  final controller = NotificationViewModel(
    userDomain: context.read<UserDomain>(),
    groupDomain: context.read<GroupDomain>(),
    notificationDomain: context.read<NotificationDomain>(),
    notificationService: NotificationApiClient(),
  );

  await controller.removeAllNotifications(user);

  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(loc.clearedAllSuccess)));
  }
}
