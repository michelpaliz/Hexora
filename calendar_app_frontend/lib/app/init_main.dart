import 'package:hexora/presentation/screens/notifications/show-notifications/notify_phone/local_notification_helper.dart';

Future<void> initializeAppServices() async {
  await setupLocalNotifications();
  await requestIOSNotificationPermissionsManually(); // ✅ ADD THIS
}
