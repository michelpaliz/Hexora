import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_localization.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/rounded_action_button.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final actionable = (notification.category == Category.groupInvitation ||
        notification.questionsAndAnswers.isNotEmpty);

    return Dismissible(
      key: Key(notification.id),
      background: swipeActionLeft(loc),
      secondaryBackground: swipeActionRight(loc),
      confirmDismiss: (_) => _confirmDismiss(context, loc),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.primary.withOpacity(0.18)),
                    ),
                    child: Text(
                      _localizedCategory(notification.category, loc),
                      style: typo.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatTimeDifference(notification.timestamp, context),
                    style: typo.caption.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.getLocalizedTitle(loc),
                style: typo.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notification.getLocalizedMessage(loc),
                style: typo.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              if (actionable) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RoundedActionButton(
                      text: loc.confirm,
                      onPressed: onConfirm ?? () {},
                      backgroundColor: cs.primary,
                      textColor: cs.onPrimary,
                    ),
                    const SizedBox(width: 8),
                    RoundedActionButton(
                      text: loc.cancel,
                      onPressed: onNegate ?? () {},
                      backgroundColor: cs.error.withOpacity(0.12),
                      textColor: cs.error,
                    ),
                  ],
                ),
              ],
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

String _localizedCategory(Category category, AppLocalizations loc) {
  switch (category) {
    case Category.groupInvitation:
      return loc.groupNotificationsSectionTitle;
    case Category.eventReminder:
      return loc.groupNotificationsSectionTitle;
    case Category.groupCreation:
    case Category.groupUpdate:
    case Category.userRemoval:
    case Category.userInvitation:
    case Category.taskUpdate:
    case Category.message:
    case Category.systemAlert:
    case Category.actionRequired:
    case Category.achievement:
    case Category.billing:
    case Category.systemUpdate:
    case Category.feedbackRequest:
    case Category.errorReport:
    default:
      return loc.notifications;
  }
}
