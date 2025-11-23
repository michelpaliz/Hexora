import 'dart:convert';

import 'package:hexora/b-backend/auth_user/exceptions/exception.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/notification/utils/result.dart';
import 'package:http/http.dart' as http;

import '../../a-models/notification_model/notification_user.dart'; // Update this import based on your file structure

class NotificationApiClient {
  final String baseUrl = '${ApiConstants.baseUrl}/notifications';

  Future<List<NotificationUser>> getAllNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/'));
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
    print('📡 GET: $url');

    final response = await http.get(url);

    print('📬 Status: ${response.statusCode}');
    print('📦 Body: ${response.body}');

    if (response.statusCode == 200) {
      final body = response.body;
      try {
        final List<dynamic> jsonData = jsonDecode(body);
        return jsonData.map((data) => NotificationUser.fromJson(data)).toList();
      } catch (e) {
        print('❌ Failed to parse notifications JSON: $e');
        throw Exception('Invalid response format');
      }
    } else if (response.statusCode == 404) {
      print('ℹ️ No notifications found for user: $username');
      return []; // Don't throw — just return empty
    } else {
      throw Exception(
          'Failed to fetch user notifications: ${response.statusCode}');
    }
  }

  Future<List<NotificationUser>> getNotificationsForGroup(
      String groupId) async {
    final url = Uri.parse('$baseUrl/group/$groupId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((data) => NotificationUser.fromJson(data)).toList();
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
      final response = await http.post(
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
    final res = await http.get(Uri.parse('$baseUrl/$id'));
    print('🐛 status=${res.statusCode}');
    print('📦 body=${res.body}');

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
    final response = await http.put(
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
    final response = await http.delete(url);

    // Backend returns 200 or 204; accept both.
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove all notifications '
          '(status ${response.statusCode})');
    }
  }

  Future<bool> deleteNotification(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }
    return true;
  }
}
