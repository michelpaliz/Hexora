import 'package:flutter/foundation.dart';
import 'package:hexora/models/downloads/download_job.dart';
import 'package:hexora/models/notification/notification_user.dart';
import 'package:hexora/data/config/api_constants.dart';
import 'package:hexora/data/notification/domain/notification_domain.dart';
import 'package:hexora/presentation/features/notifications/event_notification_id_allocator.dart';
import 'package:hexora/presentation/features/notifications/show_notifications/notify_phone/local_notification_helper.dart';
import 'package:hexora/presentation/features/shared/downloads/download_jobs_store.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef NotificationSocketHandler = dynamic Function(dynamic data);

abstract interface class NotificationSocketClient {
  bool get connected;

  void connect();
  void dispose();
  void on(String event, NotificationSocketHandler handler);
  void onConnect(NotificationSocketHandler handler);
  void onDisconnect(NotificationSocketHandler handler);
}

class _SocketIoNotificationSocket implements NotificationSocketClient {
  _SocketIoNotificationSocket(String url, Map<String, dynamic> options)
      : _socket = io.io(url, options);

  final io.Socket _socket;

  @override
  bool get connected => _socket.connected;

  @override
  void connect() {
    _socket.connect();
  }

  @override
  void dispose() {
    _socket.dispose();
  }

  @override
  void on(String event, NotificationSocketHandler handler) {
    _socket.on(event, handler);
  }

  @override
  void onConnect(NotificationSocketHandler handler) {
    _socket.onConnect(handler);
  }

  @override
  void onDisconnect(NotificationSocketHandler handler) {
    _socket.onDisconnect(handler);
  }
}

typedef NotificationSocketFactory = NotificationSocketClient Function(
  String url,
  Map<String, dynamic> options,
);

NotificationSocketClient? _notificationSocket;
NotificationSocketFactory _socketFactory = _SocketIoNotificationSocket.new;
String? _activeNotificationSocketUserId;
NotificationDomain? _activeNotificationDomain;

/// Closes the active notification socket and prevents any late events from
/// being applied to the previous user's state.
void resetNotificationSocket() {
  final socket = _notificationSocket;
  _notificationSocket = null;
  _activeNotificationSocketUserId = null;
  _activeNotificationDomain = null;
  try {
    socket?.dispose();
  } catch (_) {}
}

@visibleForTesting
void setNotificationSocketFactoryForTesting(
    NotificationSocketFactory? factory) {
  resetNotificationSocket();
  _socketFactory = factory ?? _SocketIoNotificationSocket.new;
}

void initializeNotificationSocket(
  String userId, {
  NotificationDomain? notificationDomain,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) return;

  final activeNotificationDomain =
      notificationDomain ?? _activeNotificationDomain;

  if (_activeNotificationSocketUserId == normalizedUserId) {
    try {
      if (_notificationSocket?.connected == true) {
        _activeNotificationDomain = activeNotificationDomain;
        return;
      }
    } catch (_) {}
  }
  resetNotificationSocket();

  final socketUrl = ApiConstants.socketBaseUrl;
  _activeNotificationSocketUserId = normalizedUserId;
  _activeNotificationDomain = activeNotificationDomain;

  final socket = _socketFactory(socketUrl, <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
    'query': {'userId': normalizedUserId},
  });
  _notificationSocket = socket;

  socket.connect();

  socket.onConnect((_) {
    print('Connected to notification socket');
  });

  socket.on('notification:created', (data) async {
    if (!_isActiveSocket(socket, normalizedUserId)) return;
    print('Notification received: $data');
    final payload = _asMap(data);
    if (payload == null) return;
    final notification = _extractNotification(payload);
    if (notification == null) return;
    if (!_isForActiveUser(notification)) return;
    await _activeNotificationDomain?.addInboundNotification(notification);
    if (notification.args['action'] == 'assigned') {
      final eventId = notification.args['eventId']?.toString() ?? '';
      if (eventId.isNotEmpty) {
        final notificationId = await eventNotificationIdAllocator.idFor(
          eventId: eventId,
          kind: EventNotificationKind.assignment,
        );
        await showLocalEventNotification(
          id: notificationId,
          title: notification.fallbackTitle,
          body: notification.fallbackMessage,
          eventId: eventId,
        );
      }
    }
  });

  socket.on('event:reminder', (data) async {
    if (!_isActiveSocket(socket, normalizedUserId)) return;
    print('Reminder received: $data');

    final payload = _asMap(data);
    if (payload == null) return;
    final parsedDate = DateTime.tryParse(
      payload['startDate']?.toString() ?? '',
    )?.toLocal();
    if (parsedDate == null) return;

    final eventId = payload['eventId']?.toString() ?? '';
    if (eventId.isEmpty) return;
    final notificationId = await eventNotificationIdAllocator.idFor(
      eventId: eventId,
      kind: EventNotificationKind.reminder,
    );
    final title = payload['title']?.toString() ?? '';
    final body = 'Reminder: $title is starting soon.';

    scheduleLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      dateTime: parsedDate,
      payload: eventId,
    );
  });

  socket.on('event:started', (data) async {
    if (!_isActiveSocket(socket, normalizedUserId)) return;
    print('Event started: $data');

    final payload = _asMap(data);
    if (payload == null) return;
    final now = DateTime.now();
    final eventId = payload['eventId']?.toString() ?? '';
    if (eventId.isEmpty) return;
    final notificationId = await eventNotificationIdAllocator.idFor(
      eventId: eventId,
      kind: EventNotificationKind.start,
    );
    final title = payload['title']?.toString() ?? '';
    final body = '$title has just started.';

    scheduleLocalNotification(
      id: notificationId,
      title: title,
      body: body,
      dateTime: now,
      payload: eventId,
    );
  });

  socket.on('download:ready', (data) {
    if (_isActiveSocket(socket, normalizedUserId)) _handleDownloadEvent(data);
  });
  socket.on('download:failed', (data) {
    if (_isActiveSocket(socket, normalizedUserId)) _handleDownloadEvent(data);
  });

  socket.onDisconnect((_) {
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
  final raw =
      payload['notification'] is Map ? payload['notification'] : payload;
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

bool _isActiveSocket(NotificationSocketClient socket, String userId) {
  return identical(_notificationSocket, socket) &&
      _activeNotificationSocketUserId == userId;
}
