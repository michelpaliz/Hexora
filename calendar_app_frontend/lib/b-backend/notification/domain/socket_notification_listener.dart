import 'package:hexora/a-models/downloads/download_job.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/c-frontend/ui-app/f-notification-section/show-notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/c-frontend/ui-app/shared/downloads/download_jobs_store.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

late io.Socket notificationSocket;
String? _activeNotificationSocketUserId;
NotificationDomain? _activeNotificationDomain;

void initializeNotificationSocket(
  String userId, {
  NotificationDomain? notificationDomain,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return;

  _activeNotificationDomain = notificationDomain ?? _activeNotificationDomain;

  if (_activeNotificationSocketUserId == normalizedUserId) {
    try {
      if (notificationSocket.connected) {
        return;
      }
    } catch (_) {}
  } else {
    try {
      notificationSocket.dispose();
    } catch (_) {}
  }

  final socketUrl = ApiConstants.socketBaseUrl;
  _activeNotificationSocketUserId = normalizedUserId;

  notificationSocket = io.io(socketUrl, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
    'query': {'userId': normalizedUserId},
  });

  notificationSocket.connect();

  notificationSocket.onConnect((_) {
    print('Connected to notification socket');
  });

  notificationSocket.on('notification:created', (data) async {
    print('Notification received: $data');
    final payload = _asMap(data);
    if (payload == null) return;
    final notification = _extractNotification(payload);
    if (notification == null) return;
    if (!_isForActiveUser(notification)) return;
    await _activeNotificationDomain?.addInboundNotification(notification);
  });

  notificationSocket.on('event:reminder', (data) {
    print('Reminder received: $data');

    final payload = _asMap(data);
    if (payload == null) return;
    final parsedDate = DateTime.tryParse(
      payload['startDate']?.toString() ?? '',
    )?.toLocal();
    if (parsedDate == null) return;

    final notificationId = (payload['eventId']?.toString() ?? '').hashCode;
    final title = payload['title']?.toString() ?? '';
    final body = 'Reminder: $title is starting soon.';

    scheduleLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      dateTime: parsedDate,
    );
  });

  notificationSocket.on('event:started', (data) {
    print('Event started: $data');

    final payload = _asMap(data);
    if (payload == null) return;
    final now = DateTime.now();
    final notificationId =
        (payload['eventId']?.toString() ?? '').hashCode + 1000;
    final title = payload['title']?.toString() ?? '';
    final body = '$title has just started.';

    scheduleLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      dateTime: now,
    );
  });

  notificationSocket.on('download:ready', _handleDownloadEvent);
  notificationSocket.on('download:failed', _handleDownloadEvent);

  notificationSocket.onDisconnect((_) {
    print('Notification socket disconnected');
  });
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

NotificationUser? _extractNotification(Map<String, dynamic> payload) {
  final raw = payload['notification'] is Map ? payload['notification'] : payload;
  if (raw is! Map) return null;
  try {
    return NotificationUser.fromJson(Map<String, dynamic>.from(raw));
  } catch (_) {
    return null;
  }
}

void _handleDownloadEvent(dynamic data) {
  final payload = _asMap(data);
  if (payload == null) return;

  final rawJob = payload['downloadJob'];
  if (rawJob is! Map) return;
  try {
    final job = DownloadJob.fromJson(Map<String, dynamic>.from(rawJob));
    DownloadJobsStore.instance.upsert(job);
  } catch (_) {}
}

bool _isForActiveUser(NotificationUser notification) {
  final activeUserId = _activeNotificationSocketUserId?.trim() ?? '';
  if (activeUserId.isEmpty) return false;
  return notification.recipientId.trim() == activeUserId;
}
