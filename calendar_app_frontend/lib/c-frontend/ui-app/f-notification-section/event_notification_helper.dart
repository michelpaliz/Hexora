import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/event_notification_id_allocator.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<int> notifIdFor(
  Event event, {
  EventNotificationIdAllocator? allocator,
}) {
  return (allocator ?? eventNotificationIdAllocator).idFor(
    eventId: event.id,
    kind: EventNotificationKind.reminder,
  );
}

Future<void> syncReminderFor(
  BuildContext context,
  Event e, {
  bool showSchedulingStatus = false,
  EventNotificationIdAllocator? idAllocator,
}) async {
  final notificationId = await notifIdFor(e, allocator: idAllocator);
  await flutterLocalNotificationsPlugin.cancel(notificationId);

  if (e.reminderTime == null) return;

  final trigger = e.startDate.subtract(Duration(minutes: e.reminderTime!));
  if (trigger.isBefore(DateTime.now())) return;

  final localizations = AppLocalizations.of(context);
  if (localizations == null) {
    debugPrint("❌ AppLocalizations is null — cannot set reminder.");
    return;
  }

  // ðŸ•’ Better formatting using intl
  final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(e.startDate);

  final body = localizations.notificationEventReminderBodyWithTime(
    e.title,
    formattedTime,
  );

  final scheduleMode = await scheduleLocalNotification(
    id: notificationId,
    title: localizations.notificationEventReminderTitle,
    body: body,
    dateTime: trigger,
    payload: e.id,
  );

  if (showSchedulingStatus &&
      scheduleMode == ReminderScheduleMode.inexact &&
      context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.reminderScheduledInexact)),
    );
  }
}


/// Cancels notification for an event
Future<void> cancelReminderFor(
  Event e, {
  EventNotificationIdAllocator? idAllocator,
}) async {
  await flutterLocalNotificationsPlugin.cancel(
    await notifIdFor(e, allocator: idAllocator),
  );
}
