import 'package:flutter/foundation.dart';
import 'package:hexora/presentation/features/notifications/show_notifications/notify_phone/local_notification_helper.dart';

typedef AppServiceInitializer = Future<void> Function();

Future<void> initializeAppServices({
  AppServiceInitializer? initializeLocalNotifications,
  AppServiceInitializer? requestNotificationPermissions,
}) async {
  await _initializeOptionalNotificationService(
    'local notification initialization',
    initializeLocalNotifications ?? setupLocalNotifications,
  );
  await _initializeOptionalNotificationService(
    'local notification permissions',
    requestNotificationPermissions ?? requestLocalNotificationPermissions,
  );
}

Future<void> _initializeOptionalNotificationService(
  String service,
  AppServiceInitializer initialize,
) async {
  try {
    await initialize();
  } catch (error, stackTrace) {
    // Notifications are optional; the rest of the app can still start.
    debugPrint('Optional $service failed: $error\n$stackTrace');
  }
}
