import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/notification/notification_api_client.dart';

void main() {
  group('formatNotificationApiDiagnostic', () {
    test('redacts user request identifiers and query values', () {
      final diagnostic = formatNotificationApiDiagnostic(
        method: 'GET',
        uri: Uri.parse(
          'https://api.example.test/api/notifications/user/alice@example.test'
          '?access_token=secret-query-value',
        ),
      );

      if (!kDebugMode) {
        expect(diagnostic, isNull);
        return;
      }

      expect(diagnostic, '[NotificationApi] GET /notifications/user/[redacted]');
      expect(diagnostic, isNot(contains('alice@example.test')));
      expect(diagnostic, isNot(contains('secret-query-value')));
    });

    test('reports response metadata without response or error details', () {
      const responseBody = '{"token":"private-response-value"}';
      final diagnostic = formatNotificationApiDiagnostic(
        method: 'GET',
        uri: Uri.parse('https://api.example.test/api/notifications/notification-42'),
        statusCode: 200,
        responseBody: responseBody,
        error: const FormatException('private-error-detail'),
      );

      if (!kDebugMode) {
        expect(diagnostic, isNull);
        return;
      }

      expect(
        diagnostic,
        '[NotificationApi] GET /notifications/[redacted] '
        'status=200 responseBytes=${utf8.encode(responseBody).length} '
        'errorType=FormatException',
      );
      expect(diagnostic, isNot(contains('private-response-value')));
      expect(diagnostic, isNot(contains('private-error-detail')));
      expect(diagnostic, isNot(contains('notification-42')));
    });
  });
}
