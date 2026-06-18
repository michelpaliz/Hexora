import 'package:flutter/material.dart';
import 'package:hexora/a-models/notification_model/notification_localization.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/utils/notification_payload_helper.dart';
import 'package:hexora/c-frontend/utils/view-item-styles/button/rounded_action_button.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationUser notification;
  final VoidCallback onDelete;
  final VoidCallback? onConfirm;
  final VoidCallback? onNegate;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;

  /// Called when the user taps "Open event". Receives (eventId, groupId).
  /// May be null if the host cannot handle deep-linking.
  final void Function(String eventId, String groupId)? onOpenEvent;
  final VoidCallback? onOpenDocument;

  final bool isSelected;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
    this.onConfirm,
    this.onNegate,
    this.onTap,
    this.onMarkRead,
    this.onOpenEvent,
    this.onOpenDocument,
    this.isSelected = false,
  });

  // ── helpers ────────────────────────────────────────────────────────────────

  bool get _isConcurrentEvent =>
      isConcurrentEventNotification(notification);
  bool get _isIssuedDocument =>
      isIssuedDocumentNotification(notification);
  bool get _isEvent => isEventNotification(notification);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(notification.id),
      background: _swipeLeft(),
      secondaryBackground: _swipeRight(),
      confirmDismiss: (_) => _confirmDismiss(context, loc),
      onDismissed: (_) => onDelete(),
      child: _isConcurrentEvent
          ? _ConcurrentEventCard(
              notification: notification,
              onMarkRead: onMarkRead,
              onOpenEvent: onOpenEvent,
              onTap: onTap,
              isSelected: isSelected,
            )
          : _isIssuedDocument
              ? _IssuedDocumentCard(
                  notification: notification,
                  onMarkRead: onMarkRead,
                  onOpenDocument: onOpenDocument,
                  onTap: onTap,
                  isSelected: isSelected,
                )
              : _isEvent
          ? _EventCard(
              notification: notification,
              onDelete: onDelete,
              onMarkRead: onMarkRead,
              onOpenEvent: onOpenEvent,
              onTap: onTap,
              isSelected: isSelected,
            )
          : _DefaultCard(
              notification: notification,
              onConfirm: onConfirm,
              onNegate: onNegate,
              onTap: onTap,
              isSelected: isSelected,
            ),
    );
  }

  Future<bool> _confirmDismiss(BuildContext context, AppLocalizations loc) =>
      showDialog<bool>(
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
      ).then((v) => v ?? false);

  Widget _swipeLeft() => Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.info, color: Colors.white),
      );

  Widget _swipeRight() => Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      );
}

// ── Default card (unchanged appearance) ───────────────────────────────────────

class _DefaultCard extends StatelessWidget {
  const _DefaultCard({
    required this.notification,
    required this.isSelected,
    this.onConfirm,
    this.onNegate,
    this.onTap,
  });

  final NotificationUser notification;
  final bool isSelected;
  final VoidCallback? onConfirm;
  final VoidCallback? onNegate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = notification.getLocalizedTitle(loc);
    final isUnread = !notification.isRead;

    final actionable = notification.category == Category.groupInvitation ||
        notification.questionsAndAnswers.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      color: isUnread ? cs.primary.withValues(alpha: 0.04) : null,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: cs.primary.withValues(alpha: 0.45), width: 1.2)
            : isUnread
                ? BorderSide(color: cs.primary.withValues(alpha: 0.20), width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: cs.primary.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      title,
                      style: typo.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isUnread)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    formatTimeDifference(notification.timestamp, context),
                    style: typo.caption.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                notification.getLocalizedMessage(loc),
                style: typo.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (actionable) ...[
                const SizedBox(height: 6),
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
                      backgroundColor: cs.error.withValues(alpha: 0.12),
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
}

// ── Rich event card ────────────────────────────────────────────────────────────

class _ConcurrentEventCard extends StatelessWidget {
  const _ConcurrentEventCard({
    required this.notification,
    required this.isSelected,
    this.onMarkRead,
    this.onOpenEvent,
    this.onTap,
  });

  final NotificationUser notification;
  final VoidCallback? onMarkRead;
  final void Function(String eventId, String groupId)? onOpenEvent;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final meta = resolveNotifMeta(notification, cs);
    final data = concurrentEventNotification(notification);
    final title = notification.getLocalizedTitle(loc);
    final body = notification.getLocalizedMessage(loc);
    final overlapCount = data.overlapCount ?? data.overlappingEventIds.length;
    final eventTitle = data.eventTitle;
    final senderName = data.senderName;
    final isUnread = !notification.isRead;
    final effectiveGroupId = data.groupId ?? notification.groupId;
    final canOpen =
        data.eventId != null && effectiveGroupId.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: meta.color.withValues(alpha: isSelected ? 0.55 : 0.24),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(meta.icon, size: 16, color: meta.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: typo.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: meta.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    formatTimeDifference(notification.timestamp, context),
                    style: typo.caption.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: typo.bodySmall.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (eventTitle != null)
                    _MicroChip(label: eventTitle, color: cs.primary),
                  _MicroChip(
                    label: isEs
                        ? '$overlapCount solapamiento${overlapCount == 1 ? '' : 's'}'
                        : '$overlapCount overlap${overlapCount == 1 ? '' : 's'}',
                    color: meta.color,
                  ),
                  if (senderName != null)
                    _MicroChip(
                      label: senderName,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                ],
              ),
              if (_formatRangeText(
                    locale: loc.localeName,
                    start: data.startDate,
                    end: data.endDate,
                    isEs: isEs,
                  ) !=
                  null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _formatRangeText(
                          locale: loc.localeName,
                          start: data.startDate,
                          end: data.endDate,
                          isEs: isEs,
                        )!,
                        style: typo.caption.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.calendar_month_rounded,
                    label: isEs ? 'Abrir calendario' : 'Open calendar',
                    color: meta.color,
                    enabled: canOpen,
                    onPressed: canOpen && onOpenEvent != null
                        ? () => onOpenEvent!(data.eventId!, effectiveGroupId)
                        : null,
                  ),
                  const Spacer(),
                  if (onMarkRead != null && isUnread)
                    _ActionButton(
                      icon: Icons.done_rounded,
                      label: isEs ? 'Marcar leida' : 'Mark as read',
                      color: cs.onSurface.withValues(alpha: 0.6),
                      enabled: true,
                      onPressed: onMarkRead,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssuedDocumentCard extends StatelessWidget {
  const _IssuedDocumentCard({
    required this.notification,
    required this.isSelected,
    this.onMarkRead,
    this.onOpenDocument,
    this.onTap,
  });

  final NotificationUser notification;
  final VoidCallback? onMarkRead;
  final VoidCallback? onOpenDocument;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final data = documentIssuedNotification(notification);
    final meta = resolveDocumentTypeMeta(data.documentType, cs);
    final title = notification.getLocalizedTitle(loc);
    final body = notification.getLocalizedMessage(loc);
    final isUnread = !notification.isRead;
    final documentTypeLabel = _documentTypeLabel(data.documentType, isEs: isEs);
    final amountLabel = _formatCurrency(
      data.amount,
      currency: data.currency,
      locale: loc.localeName,
    );
    final issuedAtLabel = _formatDate(
      data.issuedAt,
      locale: loc.localeName,
    );
    final effectiveOnTap = onTap ?? onOpenDocument;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: meta.color.withValues(alpha: isSelected ? 0.55 : 0.22),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: effectiveOnTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(meta.icon, size: 16, color: meta.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: typo.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          body,
                          style: typo.bodySmall.copyWith(
                            color: ThemeColors.textSecondary(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: meta.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MicroChip(label: documentTypeLabel, color: meta.color),
                  if (data.documentNumber != null)
                    _MicroChip(
                      label: data.documentNumber!,
                      color: cs.primary,
                    ),
                  if (data.senderName != null)
                    _MicroChip(
                      label: data.senderName!,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (data.clientName != null)
                    _MetaLabelValue(
                      icon: Icons.person_outline_rounded,
                      label: isEs ? 'Cliente' : 'Client',
                      value: data.clientName!,
                    ),
                  if (amountLabel != null)
                    _MetaLabelValue(
                      icon: Icons.payments_outlined,
                      label: isEs ? 'Importe' : 'Amount',
                      value: amountLabel,
                    ),
                  if (issuedAtLabel != null)
                    _MetaLabelValue(
                      icon: Icons.event_outlined,
                      label: isEs ? 'Emitido' : 'Issued',
                      value: issuedAtLabel,
                    ),
                ],
              ),
              if (data.alreadyResolvedStatus != null) ...[
                const SizedBox(height: 5),
                _MicroChip(
                  label: data.alreadyResolvedStatus!,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    formatTimeDifference(notification.timestamp, context),
                    style: typo.caption.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  if (onOpenDocument != null) ...[
                    _ActionButton(
                      icon: Icons.open_in_new_rounded,
                      label: isEs ? 'Abrir' : 'Open',
                      color: meta.color,
                      enabled: true,
                      onPressed: onOpenDocument,
                    ),
                    if (onMarkRead != null && isUnread)
                      const SizedBox(width: 4),
                  ],
                  if (onMarkRead != null && isUnread)
                    _ActionButton(
                      icon: Icons.done_rounded,
                      label: isEs ? 'Marcar leida' : 'Mark as read',
                      color: cs.onSurface.withValues(alpha: 0.6),
                      enabled: true,
                      onPressed: onMarkRead,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.notification,
    required this.onDelete,
    required this.isSelected,
    this.onMarkRead,
    this.onOpenEvent,
    this.onTap,
  });

  final NotificationUser notification;
  final VoidCallback onDelete;
  final VoidCallback? onMarkRead;
  final void Function(String eventId, String groupId)? onOpenEvent;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final isEs = Localizations.localeOf(context).languageCode == 'es';

    final meta = resolveNotifMeta(notification, cs);
    final args = EventArgsHelper(notification.args);

    final eventTitle = args.eventTitle ?? notification.getLocalizedTitle(loc);
    final subtitle = notification.getLocalizedMessage(loc);
    final dateStr = args.formattedStartDate(locale);
    final relTime = args.relativeTime(
      inMin: (minutes) => isEs ? 'en $minutes min' : 'in $minutes min',
      inHours: (hours) => isEs ? 'en $hours h' : 'in $hours h',
      inDays: (days) => isEs ? 'en $days d' : 'in $days d',
      agoMin: (minutes) => loc.timeMinutesAgo(minutes),
      agoHours: (hours) => loc.timeHoursAgo(hours),
      agoDays: (days) => loc.timeDaysAgo(days.toString()),
    );

    final eventId = args.eventId;
    final groupId = notification.groupId;
    final isUnread = !notification.isRead;
    final isHighPriority = notification.priority == PriorityLevel.high;

    // Actor name: use backend-provided fields in priority order.
    // For action-type events (created, updated, deleted, etc.) fall back to
    // "Desconocido" so the UI always surfaces who triggered the notification.
    // For reminder/started events (no actor) the row stays hidden when null.
    final actorName = args.createdByName ??
        (args.action != null &&
                args.action != 'reminder' &&
                args.action != 'started'
            ? (isEs ? 'Desconocido' : 'Unknown')
            : null);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(color: meta.color.withValues(alpha: 0.55), width: 1.5)
            : BorderSide(
                color:
                    meta.color.withValues(alpha: isHighPriority ? 0.35 : 0.15),
                width: isHighPriority ? 1.2 : 0.8,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: meta.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row ─────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: meta.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(meta.icon, size: 15, color: meta.color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              eventTitle,
                              style: typo.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isUnread)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: meta.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // ── Subtitle (localized message) ───────────────────
                      Text(
                        subtitle,
                        style: typo.bodySmall.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // ── Action / status / type chips ───────────────────
                      Builder(builder: (context) {
                        final chips = <Widget>[];
                        final action = args.action;
                        if (action != null) {
                          final am = resolveActionMeta(action, cs);
                          chips.add(_MicroChip(
                            label: actionLabel(action, isEs: isEs),
                            color: am.color,
                          ));
                        }
                        final st = args.status;
                        if (st != null && st != 'pending') {
                          final sm = resolveStatusMeta(st, cs);
                          chips.add(_MicroChip(
                            label: statusLabel(st, isEs: isEs),
                            color: sm.color,
                          ));
                        }
                        final et = args.eventType;
                        if (et != null) {
                          chips.add(_MicroChip(
                            label: eventTypeLabel(et, isEs: isEs),
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ));
                        }
                        if (args.allDay == true) {
                          chips.add(_MicroChip(
                            label: isEs ? 'Todo el día' : 'All day',
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ));
                        }
                        if (chips.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: chips,
                          ),
                        );
                      }),

                      // ── Date + relative time row ───────────────────────
                      if (dateStr != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: typo.caption.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                            ),
                            if (relTime != null)
                              _RelativeTimeBadge(
                                label: relTime,
                                color: meta.color,
                              ),
                          ],
                        ),
                      ],

                      // ── Group / actor row ──────────────────────────────
                      if (args.groupName != null || actorName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (args.groupName != null) ...[
                              Icon(Icons.group_rounded,
                                  size: 13,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  args.groupName!,
                                  style: typo.caption.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (args.groupName != null && actorName != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text('·',
                                    style: typo.caption.copyWith(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.4))),
                              ),
                            if (actorName != null) ...[
                              Icon(Icons.person_rounded,
                                  size: 13,
                                  color: cs.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  actorName,
                                  style: typo.caption.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],

                      const SizedBox(height: 6),

                      // ── Footer: timestamp + priority + actions ─────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formatTimeDifference(
                                notification.timestamp, context),
                            style: typo.caption.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _PriorityBadge(
                              priority: notification.priority,
                              isEs: isEs,
                              typo: typo),
                          const Spacer(),
                          // Quick actions
                          _ActionButton(
                            icon: Icons.open_in_new_rounded,
                            label: isEs ? 'Abrir evento' : 'Open event',
                            color: meta.color,
                            enabled: eventId != null,
                            onPressed: eventId != null && onOpenEvent != null
                                ? () => onOpenEvent!(eventId, groupId)
                                : null,
                          ),
                          if (onMarkRead != null && isUnread) ...[
                            const SizedBox(width: 4),
                            _ActionButton(
                              icon: Icons.done_rounded,
                              label: isEs ? 'Marcar leída' : 'Mark as read',
                              color: cs.onSurface.withValues(alpha: 0.6),
                              enabled: true,
                              onPressed: onMarkRead,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _RelativeTimeBadge extends StatelessWidget {
  const _RelativeTimeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: typo.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MicroChip extends StatelessWidget {
  const _MicroChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: typo.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({
    required this.priority,
    required this.isEs,
    required this.typo,
  });

  final PriorityLevel priority;
  final bool isEs;
  final AppTypography typo;

  @override
  Widget build(BuildContext context) {
    if (priority == PriorityLevel.medium) return const SizedBox.shrink();

    final (label, color) = switch (priority) {
      PriorityLevel.high => (isEs ? 'Alta' : 'High', Colors.red.shade600),
      PriorityLevel.low => (isEs ? 'Baja' : 'Low', Colors.grey.shade500),
      _ => ('', Colors.transparent),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: typo.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _MetaLabelValue extends StatelessWidget {
  const _MetaLabelValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: typo.caption.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        Text(
          value,
          style: typo.caption.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

String _documentTypeLabel(
  IssuedDocumentType type, {
  required bool isEs,
}) {
  switch (type) {
    case IssuedDocumentType.invoice:
      return isEs ? 'Factura' : 'Invoice';
    case IssuedDocumentType.receipt:
      return isEs ? 'Recibo' : 'Receipt';
    case IssuedDocumentType.presupuesto:
      return isEs ? 'Presupuesto' : 'Presupuesto';
    case IssuedDocumentType.unknown:
      return isEs ? 'Documento' : 'Document';
  }
}

String? _formatCurrency(
  double? amount, {
  required String? currency,
  required String locale,
}) {
  if (amount == null) return null;
  final normalizedCurrency = (currency ?? 'EUR').trim().toUpperCase();
  if (normalizedCurrency == 'EUR') {
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    ).format(amount);
  }
  return NumberFormat.simpleCurrency(
    locale: locale,
    name: normalizedCurrency,
    decimalDigits: 2,
  ).format(amount);
}

String? _formatDate(DateTime? date, {required String locale}) {
  if (date == null) return null;
  return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
}

String? _formatRangeText({
  required String locale,
  required DateTime? start,
  required DateTime? end,
  required bool isEs,
}) {
  if (start == null) return null;
  final startLabel = DateFormat.yMMMd(locale).add_Hm().format(start.toLocal());
  if (end == null) return startLabel;
  final endLabel = DateFormat.yMMMd(locale).add_Hm().format(end.toLocal());
  return isEs ? '$startLabel -> $endLabel' : '$startLabel -> $endLabel';
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.35);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: effectiveColor),
            const SizedBox(width: 3),
            Text(
              label,
              style: typo.caption.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
