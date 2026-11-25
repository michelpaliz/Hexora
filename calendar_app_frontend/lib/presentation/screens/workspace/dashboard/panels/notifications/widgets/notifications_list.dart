import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/models/notifications/notification_localization.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_grouping.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_density.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class NotificationsList extends StatelessWidget {
  final List<NotificationUser> notifications;
  final String? selectedId;
  final FutureOr<void> Function(NotificationUser) onSelect;
  final Future<void> Function(NotificationUser) onDelete;
  final FutureOr<void> Function(NotificationUser)? onMarkRead;

  /// Optional controls (e.g. refresh / more-actions) rendered on the right of
  /// the first section header, so they share that row instead of taking a
  /// dedicated toolbar above the list.
  final Widget? headerTrailing;

  const NotificationsList({
    super.key,
    required this.notifications,
    required this.selectedId,
    required this.onSelect,
    required this.onDelete,
    this.onMarkRead,
    this.headerTrailing,
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
    final firstHeaderIndex = items.indexWhere((item) => item.isHeader);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item.isHeader) {
          return _GroupHeader(
            label: item.header!,
            trailing: i == firstHeaderIndex ? headerTrailing : null,
          );
        }
        final n = item.notification!;
        return Padding(
          padding: const EdgeInsets.only(bottom: NotifDensity.rowGap),
          child: _SettingsLikeNotificationRow(
            notification: n,
            isSelected: selectedId == n.id,
            onTap: () => onSelect(n),
            onDelete: () => onDelete(n),
            onMarkRead: onMarkRead == null ? null : () => onMarkRead!(n),
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
  const _GroupHeader({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    // No decorative rule beside the label — spacing and weight carry the break.
    final text = Text(
      label.toUpperCase(),
      style: t.caption.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: NotifDensity.sectionLabelSize,
        color: NotifDensity.sectionLabelColor(cs),
        letterSpacing: NotifDensity.sectionLabelSpacing,
      ),
    );
    if (trailing == null) {
      return Padding(
        padding: NotifDensity.sectionHeaderPadding,
        child: text,
      );
    }
    // Share the row with inline actions (refresh / more) to save vertical
    // space: the section label sits left, the controls align right.
    return Padding(
      padding: NotifDensity.sectionHeaderPadding.add(
        const EdgeInsets.only(right: 2),
      ),
      child: Row(
        children: [
          Expanded(child: text),
          const SizedBox(width: 8),
          trailing!,
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
    this.onMarkRead,
  });

  final NotificationUser notification;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;

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

    // Rows sit directly on the workspace canvas. Background communicates
    // selection only; unread uses a blue dot and a heavier title.
    final radius = BorderRadius.circular(NotifDensity.rowRadius);
    return AnimatedContainer(
      key: ValueKey('notification-row-${notification.id}'),
      duration: HexoraMotion.duration(context, NotifDensity.transition),
      curve: HexoraMotion.enter,
      decoration: BoxDecoration(
        color: isSelected ? NotifDensity.selectedRowFill(cs) : null,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor:
              isSelected ? Colors.transparent : NotifDensity.hoverRowFill(cs),
          highlightColor: Colors.transparent,
          splashColor: cs.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: NotifDensity.rowPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: NotifDensity.iconBox,
                  height: NotifDensity.iconBox,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(
                      alpha: isHighPriority ? 0.15 : 0.11,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(meta.icon,
                      color: priorityColor, size: NotifDensity.iconGlyph),
                ),
                const SizedBox(width: NotifDensity.iconTextGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!notification.isRead)
                            Container(
                              key: const ValueKey('notification-unread-dot'),
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: cs.primary,
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
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatInlineNotificationTimestamp(
                                notification.timestamp),
                            key: const ValueKey('notification-row-time'),
                            style: t.caption.copyWith(
                              color: NotifDensity.timestampColor(cs),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        compactNotificationDescription(notification, l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(color: cs.onSurfaceVariant),
                      ),
                      if (isEvent &&
                          args.formattedStartDate(locale) != null) ...[
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
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  relTime,
                                  style: t.caption.copyWith(
                                    color: NotifDensity.timestampColor(cs),
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
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: isEs ? 'Acciones' : 'Actions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 180),
                  onSelected: (value) {
                    if (value == 'read') onMarkRead?.call();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    if (!notification.isRead && onMarkRead != null)
                      PopupMenuItem<String>(
                        value: 'read',
                        child: Row(children: [
                          const Icon(Icons.mark_email_read_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(isEs ? 'Marcar como leída' : 'Mark as read'),
                        ]),
                      ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: cs.error),
                        const SizedBox(width: 8),
                        Text(l.delete, style: TextStyle(color: cs.error)),
                      ]),
                    ),
                  ],
                  icon: Icon(Icons.more_horiz_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                ),
              ],
            ),
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

String compactNotificationDescription(
  NotificationUser notification,
  AppLocalizations localizations,
) {
  final message = notification.getLocalizedMessage(localizations).trim();
  final title = notification.getLocalizedTitle(localizations).toLowerCase();
  final bankMatch = RegExp(
    r'(\d+)\s+gastos? bancarios.*?(?:total de|total)\s+([^.]*)',
    caseSensitive: false,
  ).firstMatch(message);
  if (title.contains('gastos bancarios') && bankMatch != null) {
    final count = bankMatch.group(1)!;
    return '$count ${count == '1' ? 'movimiento' : 'movimientos'} · ${bankMatch.group(2)!.trim()}';
  }

  final recurring = RegExp(
    r'(?:para\s+)(.+?)(?:\s+a partir de la recurrencia\s+)["“]?(.+?)["”]?(?:\s+por\s+)([^.]+)',
    caseSensitive: false,
  ).firstMatch(message);
  if (recurring != null) {
    return '${recurring.group(1)!.trim()} · ${recurring.group(2)!.trim()} · ${recurring.group(3)!.trim()}';
  }
  return message;
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
    case Category.eventStarted:
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
