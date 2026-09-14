import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/data/auth/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/data/auth/exceptions/exception.dart';
import 'package:hexora/data/config/api_constants.dart';
import 'package:hexora/data/notification/utils/result.dart';
import 'package:hexora/models/jobs/job_notification.dart';

import '../../models/notification/notification_user.dart'; // Update this import based on your file structure

class NotificationApiClient {
  final String baseUrl = '${ApiConstants.baseUrl}/notifications';

  Uri _u([String path = '', Map<String, String>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  dynamic _decodeBody(dynamic response) {
    final body = response.body as String;
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  void _ensureOk(dynamic response, {String fallback = 'Request failed'}) {
    final statusCode = response.statusCode as int;
    if (statusCode >= 200 && statusCode < 300) return;
    final body = _decodeBody(response);
    var message = fallback;
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw Exception(message);
  }

  Future<List<JobNotification>> getJobNotifications({
    bool unread = false,
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await AuthenticatedHttpClient.get(
      _u('', {
        if (unread) 'unread': 'true',
        'limit': '$limit',
        'skip': '$skip',
      }),
    );
    _ensureOk(response, fallback: 'Failed to load notifications');
    final body = _decodeBody(response);
    final raw = body is List
        ? body
        : body is Map
            ? (body['items'] ??
                body['notifications'] ??
                body['data'] ??
                body['results'])
            : null;
    if (raw is! List) return const <JobNotification>[];
    return raw
        .whereType<Map>()
        .map((entry) => JobNotification.fromJson(
              Map<String, dynamic>.from(entry),
            ))
        .toList(growable: false);
  }

  Future<void> markJobNotificationRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    final response = await AuthenticatedHttpClient.patch(_u('/$trimmed/read'));
    _ensureOk(response, fallback: 'Failed to mark notification as read');
  }

  Future<void> markAllJobNotificationsRead() async {
    final response = await AuthenticatedHttpClient.patch(_u('/read-all'));
    _ensureOk(response, fallback: 'Failed to mark notifications as read');
  }

  Future<List<NotificationUser>> getAllNotifications() async {
    final response = await AuthenticatedHttpClient.get(Uri.parse('$baseUrl/'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((data) => NotificationUser.fromJson(data))
          .toList(); // Convert to List<NotificationUser>
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<List<NotificationUser>> getNotificationsForUser(
      String username) async {
    final url = Uri.parse('$baseUrl/user/$username');
    _debugNotificationApi(method: 'GET', uri: url);

    final response = await AuthenticatedHttpClient.get(url);
    _debugNotificationApi(
      method: 'GET',
      uri: url,
      statusCode: response.statusCode,
      responseBody: response.body,
    );

    if (response.statusCode == 200) {
      final body = response.body;
      try {
        final List<dynamic> jsonData = jsonDecode(body);
        return _dedupeNotifications(
          jsonData.map((data) => NotificationUser.fromJson(data)).toList(),
          includeRecipient: true,
        );
      } catch (error) {
        _debugNotificationApi(
          method: 'GET',
          uri: url,
          statusCode: response.statusCode,
          responseBody: body,
          error: error,
        );
        throw Exception('Invalid response format');
      }
    } else if (response.statusCode == 404) {
      return []; // Don't throw — just return empty
    } else {
      throw Exception(
          'Failed to fetch user notifications: ${response.statusCode}');
    }
  }

  Future<List<NotificationUser>> getNotificationsForGroup(
      String groupId) async {
    final url = Uri.parse('$baseUrl/group/$groupId');
    final response = await AuthenticatedHttpClient.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return _dedupeNotifications(
        jsonData.map((data) => NotificationUser.fromJson(data)).toList(),
        includeRecipient: false,
      );
    } else if (response.statusCode == 404) {
      return const <NotificationUser>[];
    }
    throw Exception(
      'Failed to fetch notifications for group $groupId '
      '(${response.statusCode})',
    );
  }

  Future<NotificationUser> createNotification(
    NotificationUser notification,
  ) async {
    try {
      final response = await AuthenticatedHttpClient.post(
        Uri.parse('$baseUrl/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
          notification.toJsonForCreation(),
        ), // Use NotificationUser's toJson method
      );

      if (response.statusCode == 201) {
        return NotificationUser.fromJson(
          jsonDecode(response.body),
        ); // Convert back to NotificationUser
      } else {
        throw CustomException(
          'Failed to create notification',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } catch (error) {
      final errorMessage =
          error is CustomException ? error.message : 'Unknown error';
      final errorDetails = error is CustomException
          ? error.responseBody
          : 'No details available';

      throw CustomException(
        'Failed to create notification: $errorMessage. Details: $errorDetails',
        statusCode: error is CustomException ? error.statusCode : 500,
        responseBody: errorDetails,
      );
    }
  }

  Future<GetNotifResult> getNotificationById(String id) async {
    final url = Uri.parse('$baseUrl/$id');
    _debugNotificationApi(method: 'GET', uri: url);
    final res = await AuthenticatedHttpClient.get(url);
    _debugNotificationApi(
      method: 'GET',
      uri: url,
      statusCode: res.statusCode,
      responseBody: res.body,
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return const NotifError('Invalid response format');
      }
      return NotifOk(NotificationUser.fromJson(decoded));
    }
    if (res.statusCode == 404) return const NotifNotFound();
    return NotifError('Failed: ${res.statusCode}');
  }

  Future<NotificationUser> updateNotification(
    NotificationUser notification,
  ) async {
    final response = await AuthenticatedHttpClient.put(
      Uri.parse('$baseUrl/${notification.id}'), // Use notification's id
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
        notification.toJson(),
      ), // Use NotificationUser's toJson method
    );
    if (response.statusCode == 200) {
      return NotificationUser.fromJson(
        jsonDecode(response.body),
      ); // Convert back to NotificationUser
    } else {
      throw Exception('Failed to update notification');
    }
  }

  /// DELETE /notifications  -> removes all notifications for the authenticated user
  Future<void> deleteAllMine() async {
    final url = Uri.parse(baseUrl); // no trailing slash needed
    final response = await AuthenticatedHttpClient.delete(url);

    // Backend returns 200 or 204; accept both.
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove all notifications '
          '(status ${response.statusCode})');
    }
  }

  Future<bool> deleteNotification(String id) async {
    final response =
        await AuthenticatedHttpClient.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }
    return true;
  }
}

List<NotificationUser> _dedupeNotifications(
  List<NotificationUser> notifications, {
  required bool includeRecipient,
}) {
  final bySemanticKey = <String, NotificationUser>{};
  for (final notification in notifications) {
    final key = _notificationSemanticKey(
      notification,
      includeRecipient: includeRecipient,
    );
    final existing = bySemanticKey[key];
    if (existing == null ||
        notification.timestamp.isAfter(existing.timestamp)) {
      bySemanticKey[key] = notification;
    }
  }
  return bySemanticKey.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}

String _notificationSemanticKey(
  NotificationUser notification, {
  required bool includeRecipient,
}) {
  return <String>[
    notification.groupId,
    if (includeRecipient) notification.recipientId,
    notification.titleKey,
    notification.messageKey,
    notification.fallbackTitle.trim().toLowerCase(),
    notification.fallbackMessage.trim().toLowerCase(),
    notification.category.name,
    notification.type.name,
    _canonicalJson(notification.args),
  ].join('|');
}

@visibleForTesting
String? formatNotificationApiDiagnostic({
  required String method,
  required Uri uri,
  int? statusCode,
  String? responseBody,
  Object? error,
}) {
  if (!kDebugMode) return null;

  final details = <String>[
    '[NotificationApi] $method ${_redactedNotificationPath(uri)}',
    if (statusCode != null) 'status=$statusCode',
    if (responseBody != null) 'responseBytes=${utf8.encode(responseBody).length}',
    if (error != null) 'errorType=${error.runtimeType}',
  ];
  return details.join(' ');
}

void _debugNotificationApi({
  required String method,
  required Uri uri,
  int? statusCode,
  String? responseBody,
  Object? error,
}) {
  final diagnostic = formatNotificationApiDiagnostic(
    method: method,
    uri: uri,
    statusCode: statusCode,
    responseBody: responseBody,
    error: error,
  );
  if (diagnostic != null) debugPrint(diagnostic);
}

String _redactedNotificationPath(Uri uri) {
  final segments = uri.pathSegments;
  final notificationIndex = segments.indexOf('notifications');
  if (notificationIndex == -1 || notificationIndex == segments.length - 1) {
    return '/notifications';
  }

  final action = segments[notificationIndex + 1];
  if (action == 'read-all') return '/notifications/read-all';
  if (action == 'user' || action == 'group') {
    return '/notifications/$action/[redacted]';
  }
  return '/notifications/[redacted]';
}

String _canonicalJson(dynamic value) {
  return jsonEncode(_canonicalValue(value));
}

dynamic _canonicalValue(dynamic value) {
  if (value is Map) {
    final sorted = <String, dynamic>{};
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      sorted[key] = _canonicalValue(value[key]);
    }
    return sorted;
  }
  if (value is List) {
    return value.map(_canonicalValue).toList(growable: false);
  }
  return value;
}
