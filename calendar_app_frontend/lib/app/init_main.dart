import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';

Future<void> initializeAppServices() async {
  await setupLocalNotifications();
  await requestIOSNotificationPermissionsManually(); // ✅ ADD THIS
}
