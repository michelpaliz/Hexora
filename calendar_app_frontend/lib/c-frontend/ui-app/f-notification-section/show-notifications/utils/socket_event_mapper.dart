import 'package:hexora/a-models/notification_model/notification_user.dart';

/// Maps a raw `event:reminder` or `event:started` socket payload to a
/// [NotificationUser] that can be rendered by [NotificationCard] with full
/// enriched data.
///
/// Usage in [socket_notification_listener.dart]:
/// ```dart
/// notificationSocket.on('event:reminder', (data) {
///   final notif = socketEventToNotification(
///     payload: Map<String, dynamic>.from(data as Map),
///     action: 'reminder',
///     recipientId: currentUserId,
///   );
///   notificationDomain.addInboundNotification(notif); // push into stream
///   scheduleLocalNotification(...);                   // existing behaviour
/// });
/// ```
NotificationUser socketEventToNotification({
  required Map<String, dynamic> payload,
  required String action, // 'reminder' | 'started'
  required String recipientId,
}) {
  final args = _mapPayloadToArgs(payload, action: action);
  final isReminder = action == 'reminder';
  final title = payload['title']?.toString() ?? '';

  return NotificationUser(
    id: '${payload['eventId'] ?? ''}__$action',
    senderId: payload['senderId']?.toString() ?? '',
    recipientId: recipientId,
    titleKey: isReminder
        ? 'notification.event.reminder.title'
        : 'notification.event.started.title',
    messageKey: isReminder
        ? 'notification.event.reminder.message'
        : 'notification.event.started.message',
    fallbackTitle: isReminder ? 'Event Reminder' : 'Event Started',
    fallbackMessage: isReminder
        ? 'Reminder: "$title" is coming up soon.'
        : 'The event "$title" has just started.',
    args: args,
    timestamp: DateTime.now(),
    groupId: payload['groupId']?.toString() ?? '',
    isRead: false,
    type: NotificationType.reminder,
    priority: PriorityLevel.medium,
    category: Category.eventReminder,
  );
}

/// Copies every known field from the socket payload into the standard
/// [NotificationUser.args] map so [EventArgsHelper] can read them.
/// Unknown extra keys are forwarded as-is for forward compatibility.
Map<String, dynamic> _mapPayloadToArgs(
  Map<String, dynamic> payload, {
  required String action,
}) {
  // Start with all keys from payload (forward-compat)
  final args = <String, dynamic>{...payload};

  // Normalise the title → eventTitle (used by EventArgsHelper)
  if (payload['title'] != null) {
    args['eventTitle'] = payload['title'];
  }

  // Stamp the action so resolveNotifMeta / actionLabel can use it
  args['action'] = action;

  // Remove keys that are already top-level fields on NotificationUser
  // to avoid duplication in the details panel
  args.remove('title');
  args.remove('senderId');

  return args;
}
