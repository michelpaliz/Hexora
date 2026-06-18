// ignore_for_file: dead_code
//
// Story/test states for NotificationCard and _NotificationDetailsPanel.
// Render these inside a WidgetCatalogScreen or golden test to verify each
// payload scenario without a running backend.
//
// Usage (in any dev screen):
//   NotificationCardStories.all.map((s) => NotificationCard(notification: s, onDelete: () {}))

import 'package:hexora/a-models/notification_model/notification_user.dart';

abstract final class NotificationCardStories {
  /// 1. Minimal / legacy notification — only titleKey + fallback, no args.
  static final NotificationUser legacy = NotificationUser(
    id: 'story_legacy',
    senderId: 'sender1',
    recipientId: 'me',
    titleKey: 'notification.event.created.title',
    messageKey: 'notification.event.created.message',
    fallbackTitle: 'Event Created',
    fallbackMessage: 'An event "Garden visit" has been created.',
    args: const {},
    timestamp: DateTime.now().subtract(const Duration(minutes: 27)),
    groupId: 'g1',
    isRead: true,
    category: Category.eventReminder,
    priority: PriorityLevel.medium,
  );

  /// 2. Enriched reminder — full payload, starts in 10 min.
  static final NotificationUser enrichedReminder = NotificationUser(
    id: 'story_reminder',
    senderId: 'sender1',
    recipientId: 'me',
    titleKey: 'notification.event.reminder.title',
    messageKey: 'notification.event.reminder.message',
    fallbackTitle: 'Event Reminder',
    fallbackMessage: 'Reminder: "Pool maintenance" is coming up soon.',
    args: {
      'action': 'reminder',
      'eventId': 'evt_001',
      'eventTitle': 'Pool maintenance – Michel',
      'startDate': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      'endDate': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'allDay': false,
      'reminderTime': 15,
      'status': 'confirmed',
      'eventType': 'work_visit',
      'groupId': 'g1',
      'groupName': 'Mantenimiento Michel SL',
      'ownerName': 'Michel',
      'ownerId': 'user_01',
      'senderName': 'Sistema',
      'clientId': 'client_42',
      'clientName': 'Residencia García',
      'primaryServiceId': 'svc_pool',
      'stopId': 'stop_7',
      'location': 'Calle Mayor 12, 28001 Madrid',
      'note': 'Bring extra chlorine tablets.',
      'categoryId': 'maintenance',
      'subcategoryId': 'pool',
    },
    timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
    groupId: 'g1',
    isRead: false,
    category: Category.eventReminder,
    priority: PriorityLevel.high,
  );

  /// 3. Enriched started — event just began.
  static final NotificationUser enrichedStarted = NotificationUser(
    id: 'story_started',
    senderId: 'sender1',
    recipientId: 'me',
    titleKey: 'notification.event.started.title',
    messageKey: 'notification.event.started.message',
    fallbackTitle: 'Event Started',
    fallbackMessage: 'The event "Team meeting" has just started.',
    args: {
      'action': 'started',
      'eventId': 'evt_002',
      'eventTitle': 'Weekly team meeting',
      'startDate': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      'endDate': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'allDay': false,
      'status': 'confirmed',
      'eventType': 'meeting',
      'groupId': 'g2',
      'groupName': 'Dev Team',
      'ownerName': 'Ana López',
      'isDone': false,
      'recurrenceRuleId': 'rr_weekly_mon',
      'description': 'Sprint review + planning for next week.',
    },
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    groupId: 'g2',
    isRead: false,
    category: Category.eventReminder,
    priority: PriorityLevel.medium,
  );

  /// 4. Missing / invalid dates — startDate is garbage, endDate absent.
  static final NotificationUser invalidDates = NotificationUser(
    id: 'story_bad_date',
    senderId: 'sender1',
    recipientId: 'me',
    titleKey: 'notification.event.reminder.title',
    messageKey: 'notification.event.reminder.message',
    fallbackTitle: 'Event Reminder',
    fallbackMessage: 'Reminder: "Unknown event" is coming up soon.',
    args: {
      'action': 'reminder',
      'eventId': 'evt_003',
      'eventTitle': 'Unknown event',
      'startDate': 'not-a-date',  // intentionally invalid
      'groupName': 'Test Group',
    },
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    groupId: 'g3',
    isRead: true,
    category: Category.eventReminder,
    priority: PriorityLevel.low,
  );

  /// 5. Unknown action + unknown category — graceful fallback rendering.
  static final NotificationUser unknownAction = NotificationUser(
    id: 'story_unknown',
    senderId: 'sender1',
    recipientId: 'me',
    titleKey: '',
    messageKey: '',
    fallbackTitle: 'Custom alert',
    fallbackMessage: 'Something happened with event XYZ.',
    args: {
      'action': 'custom_future_action',  // unknown value
      'eventId': 'evt_004',
      'eventTitle': 'XYZ Event',
      'status': 'pending_approval',      // unknown status
      'eventType': 'workshop',           // unknown type
      'groupName': 'Future Group',
    },
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    groupId: 'g4',
    isRead: false,
    category: Category.eventReminder,
    priority: PriorityLevel.medium,
  );

  /// All stories in display order.
  static List<NotificationUser> get all => [
        legacy,
        enrichedReminder,
        enrichedStarted,
        invalidDates,
        unknownAction,
      ];
}
