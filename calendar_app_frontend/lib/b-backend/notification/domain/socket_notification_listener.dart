import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

late IO.Socket notificationSocket;

void initializeNotificationSocket(String userId) {
  final socketUrl = ApiConstants.baseUrl.replaceFirst('/api', '');

  notificationSocket = IO.io(socketUrl, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
    'query': {'userId': userId},
  });

  notificationSocket.connect();

  notificationSocket.onConnect((_) {
    print('✅ Connected to Notification Socket');
  });

  notificationSocket.on('event:reminder', (data) {
    print('📩 Reminder received: $data');

    final parsedDate = DateTime.parse(data['startDate']).toLocal();
    final notificationId = data['eventId'].hashCode;
    final title = data['title'];
    final body = 'Reminder: ${data['title']} is starting soon.';

    print('🔔 Scheduling reminder notification with values:');
    print('   - ID: $notificationId');
    print('   - Title: $title');
    print('   - Body: $body');
    print('   - Scheduled At: $parsedDate');

    scheduleLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      dateTime: parsedDate,
    );
  });

  notificationSocket.on('event:started', (data) {
    print('🚀 Event started: $data');

    final now = DateTime.now();
    final notificationId = data['eventId'].hashCode + 1000;
    final title = data['title'];
    final body = '${data['title']} has just started.';

    print('📢 Scheduling start notification with values:');
    print('   - ID: $notificationId');
    print('   - Title: $title');
    print('   - Body: $body');
    print('   - Time: $now');

    scheduleLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      dateTime: now,
    );
  });

  notificationSocket.onDisconnect((_) {
    print('❌ Notification socket disconnected');
  });
}
