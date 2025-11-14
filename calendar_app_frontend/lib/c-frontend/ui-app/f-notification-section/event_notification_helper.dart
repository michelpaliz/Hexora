import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Generates a unique notification ID based on event ID
int notifIdFor(Event e) => e.id.hashCode;

Future<void> syncReminderFor(BuildContext context, Event e) async {
  await flutterLocalNotificationsPlugin.cancel(notifIdFor(e));

  if (e.reminderTime == null) return;

  final trigger = e.startDate.subtract(Duration(minutes: e.reminderTime!));
  if (trigger.isBefore(DateTime.now())) return;

  final localizations = AppLocalizations.of(context);
  if (localizations == null) {
    debugPrint("❌ AppLocalizations is null — cannot set reminder.");
    return;
  }

  // 🕒 Better formatting using intl
  final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(e.startDate);

  final body = localizations.notificationEventReminderBodyWithTime(
    e.title,
    formattedTime,
  );

  await scheduleLocalNotification(
    id: notifIdFor(e),
    title: localizations.notificationEventReminderTitle,
    body: body,
    dateTime: trigger,
  );
}


/// Cancels notification for an event
Future<void> cancelReminderFor(Event e) async {
  await flutterLocalNotificationsPlugin.cancel(notifIdFor(e));
}
