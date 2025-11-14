import 'package:hexora/a-models/notification_model/notification_localization.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/rounded_action_button.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NotificationCard extends StatelessWidget {
  final NotificationUser notification;
  final VoidCallback onDelete;
  final VoidCallback? onConfirm;
  final VoidCallback? onNegate;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
    this.onConfirm,
    this.onNegate,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final actionable = (notification.category == Category.groupInvitation ||
        notification.questionsAndAnswers.isNotEmpty);

    return Dismissible(
      key: Key(notification.id),
      background: swipeActionLeft(loc),
      secondaryBackground: swipeActionRight(loc),
      confirmDismiss: (_) => _confirmDismiss(context, loc),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: ListTile(
          title: Text(
            notification.getLocalizedTitle(loc),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.getLocalizedMessage(loc)),
              const SizedBox(height: 4),
              Text(
                formatTimeDifference(notification.timestamp, context),
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (actionable)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RoundedActionButton(
                      text: loc.confirm,
                      onPressed: onConfirm ?? () {},
                      backgroundColor: Colors.green.shade600,
                      textColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    RoundedActionButton(
                      text: loc.cancel,
                      onPressed: onNegate ?? () {},
                      backgroundColor: Colors.red.shade600,
                      textColor: Colors.white,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDismiss(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(loc.confirmation),
            content: Text(loc.removeConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.confirm),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget swipeActionLeft(AppLocalizations loc) => Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.info, color: Colors.white),
      );

  Widget swipeActionRight(AppLocalizations loc) => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      );
}
