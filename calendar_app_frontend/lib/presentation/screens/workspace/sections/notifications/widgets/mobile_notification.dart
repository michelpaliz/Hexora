import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hexora/models/notifications/notification_localization.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/event_args_helper.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_formatting.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_payload_helper.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// The detail page returns an intent; the host owns persistence and navigation.
enum NotificationDetailAction { open, markRead, confirm, decline, delete }

class MobileNotificationTile extends StatelessWidget {
  const MobileNotificationTile(
      {super.key, required this.notification, required this.onTap});
  final NotificationUser notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final loc = AppLocalizations.of(context)!;
    final meta = resolveNotifMeta(notification, cs);
    final unread = !notification.isRead;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(meta.icon, color: cs.onPrimaryContainer)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(notification.getLocalizedTitle(loc),
                      style: text.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text(notification.getLocalizedMessage(loc),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    Text(formatTimeDifference(notification.timestamp, context),
                        style: text.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    if (unread)
                      Text(
                          Localizations.localeOf(context).languageCode == 'es'
                              ? 'Sin leer'
                              : 'Unread',
                          style: text.bodySmall?.copyWith(
                              color: cs.primary, fontWeight: FontWeight.w700)),
                  ]),
                ])),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ]),
        ),
      ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage(
      {super.key, required this.notification, this.openLabel});
  final NotificationUser notification;
  final String? openLabel;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final document = documentIssuedNotification(notification);
    final event = EventArgsHelper(notification.args);
    final actionable = notification.category == Category.groupInvitation ||
        notification.questionsAndAnswers.isNotEmpty;
    void finish(NotificationDetailAction action) =>
        Navigator.pop(context, action);
    Widget field(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            SelectableText(value,
                style: text.bodyLarge?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.w600)),
          ]),
        );
    return Scaffold(
      appBar:
          AppBar(title: Text(es ? 'Notificación' : 'Notification'), actions: [
        PopupMenuButton<NotificationDetailAction>(
          tooltip: es ? 'Más opciones' : 'More options',
          onSelected: (action) async {
            if (action == NotificationDetailAction.delete) {
              final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text(loc.confirmation),
                        content: Text(loc.removeConfirmation),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(loc.cancel)),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(loc.confirm))
                        ],
                      ));
              if (confirmed != true || !context.mounted) return;
            }
            if (context.mounted) finish(action);
          },
          itemBuilder: (_) => [
            if (!notification.isRead)
              PopupMenuItem(
                  value: NotificationDetailAction.markRead,
                  child: Text(es ? 'Marcar como leída' : 'Mark as read')),
            PopupMenuItem(
                value: NotificationDetailAction.delete,
                child:
                    Text(es ? 'Eliminar notificación' : 'Delete notification')),
          ],
        ),
      ]),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(notification.getLocalizedTitle(loc),
            style: text.headlineSmall
                ?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
            DateFormat.yMMMd(locale)
                .add_Hm()
                .format(notification.timestamp.toLocal()),
            style: text.bodySmall),
        const SizedBox(height: 20),
        SelectableText(notification.getLocalizedMessage(loc),
            style: text.bodyLarge?.copyWith(color: cs.onSurface, height: 1.5)),
        if (isIssuedDocumentNotification(notification)) ...[
          if (document.documentNumber != null)
            field(es ? 'Documento' : 'Document', document.documentNumber!),
          if (document.clientName != null)
            field(es ? 'Cliente' : 'Client', document.clientName!),
          if (document.amount != null)
            field(
                es ? 'Importe' : 'Amount',
                NumberFormat.simpleCurrency(
                        locale: locale, name: document.currency ?? 'EUR')
                    .format(document.amount)),
          if (document.issuedAt != null)
            field(
                es ? 'Emitido' : 'Issued',
                DateFormat.yMMMd(locale)
                    .add_Hm()
                    .format(document.issuedAt!.toLocal())),
          if (document.senderName != null)
            field(es ? 'Emisor' : 'Sender', document.senderName!),
        ],
        if (isEventNotification(notification) ||
            isConcurrentEventNotification(notification)) ...[
          if (event.eventTitle != null)
            field(es ? 'Evento' : 'Event', event.eventTitle!),
          if (event.formattedStartDate(locale) != null)
            field(es ? 'Inicio' : 'Start', event.formattedStartDate(locale)!),
          if (event.formattedEndDate(locale) != null)
            field(es ? 'Fin' : 'End', event.formattedEndDate(locale)!),
          if (event.location != null)
            field(es ? 'Ubicación' : 'Location', event.location!),
          if (event.createdByName != null)
            field(es ? 'Organizador' : 'Organizer', event.createdByName!),
        ],
        const SizedBox(height: 24),
        if (actionable) ...[
          FilledButton(
              onPressed: () => finish(NotificationDetailAction.confirm),
              child: Text(loc.confirm)),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => finish(NotificationDetailAction.decline),
              child: Text(loc.cancel)),
        ],
      ])),
      bottomNavigationBar: openLabel == null &&
              (notification.isRead || actionable)
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: () => finish(openLabel != null
                    ? NotificationDetailAction.open
                    : NotificationDetailAction.markRead),
                icon: Icon(openLabel != null
                    ? Icons.arrow_forward_rounded
                    : Icons.done_rounded),
                label: Text(
                    openLabel ?? (es ? 'Marcar como leída' : 'Mark as read')),
              ),
            ),
    );
  }
}
