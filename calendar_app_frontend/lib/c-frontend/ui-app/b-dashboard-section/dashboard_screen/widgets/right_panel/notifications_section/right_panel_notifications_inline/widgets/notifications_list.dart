import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_localization.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_grouping.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NotificationsList extends StatelessWidget {
  final List<NotificationUser> notifications;
  final String? selectedId;
  final FutureOr<void> Function(NotificationUser) onSelect;
  final Future<void> Function(NotificationUser) onDelete;

  const NotificationsList({
    super.key,
    required this.notifications,
    required this.selectedId,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final grouped = groupNotificationsByTime(notifications, loc);

    // Build a flat list of header + card items, skipping empty groups
    final items = <_ListItem>[];
    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;
      items.add(_ListItem.header(entry.key));
      for (final n in entry.value) {
        items.add(_ListItem.notification(n));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.isHeader) {
          return _GroupHeader(label: item.header!);
        }
        final n = item.notification!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SettingsLikeNotificationRow(
            notification: n,
            isSelected: selectedId == n.id,
            onTap: () => onSelect(n),
            onDelete: () => onDelete(n),
          ),
        );
      },
    );
  }
}

// Simple discriminated union for list items
class _ListItem {
  final String? header;
  final NotificationUser? notification;

  const _ListItem._({this.header, this.notification});

  factory _ListItem.header(String label) => _ListItem._(header: label);
  factory _ListItem.notification(NotificationUser n) =>
      _ListItem._(notification: n);

  bool get isHeader => header != null;
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: t.caption.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.40),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsLikeNotificationRow extends StatelessWidget {
  const _SettingsLikeNotificationRow({
    required this.notification,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationUser notification;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    final meta = resolveNotifMeta(notification, cs);
    final args = EventArgsHelper(notification.args);
    final isEvent = isEventNotification(notification);
    final priority = _priorityForCategory(notification.category);
    final priorityColor = _priorityColor(priority, meta.color, cs);
    final isHighPriority = priority == _NotificationPriority.high;

    final relTime = args.relativeTime(
      inMin: (m) => isEs ? 'en $m min' : 'in $m min',
      inHours: (h) => isEs ? 'en $h h' : 'in $h h',
      agoMin: (m) => isEs ? 'hace $m min' : '$m min ago',
      agoHours: (h) => isEs ? 'hace $h h' : '$h h ago',
    );

    final chips = <({String label, Color color})>[];
    if (isEvent) {
      if (args.action != null) {
        chips.add((
          label: actionLabel(args.action, isEs: isEs),
          color: resolveActionMeta(args.action, cs).color,
        ));
      }
      if (args.status != null && args.status != 'pending') {
        chips.add((
          label: statusLabel(args.status, isEs: isEs),
          color: resolveStatusMeta(args.status, cs).color,
        ));
      }
      if (args.allDay == true) {
        chips.add((
          label: isEs ? 'Todo el dia' : 'All day',
          color: cs.onSurface.withValues(alpha: 0.4),
        ));
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          decoration: BoxDecoration(
            color: notification.isRead
                ? cs.surfaceContainerHighest.withValues(alpha: 0.12)
                : priorityColor.withValues(alpha: isHighPriority ? 0.10 : 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? priorityColor.withValues(alpha: 0.5)
                  : (notification.isRead
                      ? cs.outlineVariant.withValues(alpha: 0.25)
                      : priorityColor.withValues(
                          alpha: isHighPriority ? 0.28 : 0.18,
                        )),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelected || isHighPriority || !notification.isRead)
                Container(
                  width: isHighPriority ? 4 : 3,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(
                      alpha: notification.isRead ? 0.65 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: priorityColor.withValues(
                    alpha: isHighPriority ? 0.15 : 0.11,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(meta.icon, color: priorityColor, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!notification.isRead)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: meta.color,
                              boxShadow: isHighPriority
                                  ? [
                                      BoxShadow(
                                        color: priorityColor.withValues(
                                            alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            isEvent && args.eventTitle != null
                                ? args.eventTitle!
                                : notification.getLocalizedTitle(l),
                            style: t.bodySmall.copyWith(
                              fontWeight: notification.isRead
                                  ? (isHighPriority
                                      ? FontWeight.w600
                                      : FontWeight.w500)
                                  : FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.getLocalizedMessage(l),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (isEvent && args.formattedStartDate(locale) != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              args.formattedStartDate(locale)!,
                              style: t.caption.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (relTime != null)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: meta.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                relTime,
                                style: t.caption.copyWith(
                                  color: meta.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: chips
                            .map(
                              (c) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: c.color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: c.color.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  c.label,
                                  style: t.caption.copyWith(
                                    color: c.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      formatInlineNotificationTimestamp(notification.timestamp),
                      style: t.caption.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                tooltip: l.delete,
                onPressed: onDelete,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(26, 26),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatInlineNotificationTimestamp(DateTime ts) {
  final now = DateTime.now();
  final diff = now.difference(ts);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${ts.day}/${ts.month}/${ts.year}';
}

enum _NotificationPriority { high, medium, low }

_NotificationPriority _priorityForCategory(Category category) {
  switch (category) {
    case Category.systemAlert:
    case Category.errorReport:
    case Category.billing:
    case Category.actionRequired:
      return _NotificationPriority.high;
    case Category.message:
    case Category.eventReminder:
    case Category.taskUpdate:
      return _NotificationPriority.medium;
    case Category.achievement:
    case Category.feedbackRequest:
    case Category.systemUpdate:
    case Category.userInvitation:
    case Category.groupInvitation:
    case Category.groupCreation:
    case Category.groupUpdate:
    case Category.userRemoval:
      return _NotificationPriority.low;
  }
}

Color _priorityColor(
  _NotificationPriority priority,
  Color fallback,
  ColorScheme cs,
) {
  switch (priority) {
    case _NotificationPriority.high:
      return const Color(0xFFD97706);
    case _NotificationPriority.medium:
      return fallback;
    case _NotificationPriority.low:
      return cs.onSurfaceVariant;
  }
}
