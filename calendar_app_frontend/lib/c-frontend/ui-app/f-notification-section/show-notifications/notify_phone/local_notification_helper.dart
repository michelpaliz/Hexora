import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/event_notification_tap_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

enum ReminderScheduleMode { exact, inexact }

ReminderScheduleMode androidReminderScheduleMode(
  bool? canScheduleExactNotifications,
) {
  return canScheduleExactNotifications == true
      ? ReminderScheduleMode.exact
      : ReminderScheduleMode.inexact;
}

AndroidScheduleMode androidScheduleModeFor(ReminderScheduleMode scheduleMode) {
  return scheduleMode == ReminderScheduleMode.exact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;
}

Future<void> setupLocalNotifications() async {
  tz.initializeTimeZones();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings(); // used for both iOS & macOS

  const settings = InitializationSettings(
    android: android,
    iOS: darwin,
    macOS: darwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (response) {
      unawaited(routeEventNotificationTap(response.payload));
    },
  );
}

Future<void> requestLocalNotificationPermissions() async {
  // Android (Android 13+ runtime notifications permission)
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();

  // Android 12+ requires special access for exact alarms. Scheduling remains
  // available with an inexact alarm when access is not granted.
  try {
    if (await androidPlugin?.canScheduleExactNotifications() == false) {
      await androidPlugin?.requestExactAlarmsPermission();
    }
  } catch (_) {
    // Some Android versions do not expose exact-alarm special access.
  }

  // iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);

  // macOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
}

Future<ReminderScheduleMode> scheduleLocalNotification({
  required int id,
  required String title,
  required String body,
  required DateTime dateTime,
  String? payload,
}) async {
  final scheduleMode = await _resolveReminderScheduleMode();
  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(dateTime, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'event_reminders',
        'Event Reminders',
        channelDescription: 'Reminder notifications for upcoming events',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails( // 👈 Add macOS details
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    androidScheduleMode: androidScheduleModeFor(scheduleMode),
    matchDateTimeComponents: null,
    payload: payload,
  );
  return scheduleMode;
}

Future<ReminderScheduleMode> _resolveReminderScheduleMode() async {
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin == null) return ReminderScheduleMode.exact;

  try {
    return androidReminderScheduleMode(
      await androidPlugin.canScheduleExactNotifications(),
    );
  } catch (_) {
    return ReminderScheduleMode.inexact;
  }
}
