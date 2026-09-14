import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupLocalNotifications() async {
  tz.initializeTimeZones();

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings(); // used for both iOS & macOS

  const settings = InitializationSettings(
    android: android,
    iOS: darwin,
    macOS: darwin, 
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  await _requestPermissions();
}

Future<void> _requestPermissions() async {
  // Android (Android 13+ runtime notifications permission)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

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

/// Optional: manual iOS permission trigger
Future<void> requestIOSNotificationPermissionsManually() async {
  final iosPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  final granted = await iosPlugin?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );

  print('📱 iOS notification permission granted: $granted');
}

Future<void> scheduleLocalNotification({
  required int id,
  required String title,
  required String body,
  required DateTime dateTime,
}) async {
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
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: null,
  );
}
