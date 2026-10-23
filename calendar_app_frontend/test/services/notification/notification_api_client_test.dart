import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/services/notification/notification_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test-token'});
    TokenService.configureStore(SecureTokenStore());
  });

  test('mark read uses authenticated PATCH with only isRead', () async {
    final requests = <http.Request>[];
    final api = NotificationApiClient(client: MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode({
        'id': '507f1f77bcf86cd799439011',
        'isRead': true,
        'timestamp': '2026-10-23T00:00:00.000Z',
      }), 200);
    }));
    final notification = NotificationUser.fromJson({
      'id': '507f1f77bcf86cd799439011',
      'isRead': true,
      'fallbackTitle': 'Invoice ready',
    });

    final updated = await api.updateNotification(notification);

    expect(updated.isRead, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'PATCH');
    expect(requests.single.url.path,
        '/api/notifications/507f1f77bcf86cd799439011');
    expect(requests.single.headers['authorization'], 'Bearer test-token');
    expect(jsonDecode(requests.single.body), {'isRead': true});
  });

  test('server rejection does not report a successful read', () async {
    final api = NotificationApiClient(client: MockClient((_) async =>
        http.Response('{"message":"Notification not found"}', 404)));
    final notification = NotificationUser.fromJson({
      'id': '507f1f77bcf86cd799439011',
      'isRead': true,
    });

    await expectLater(api.updateNotification(notification),
        throwsA(predicate((error) => error.toString().contains('Notification not found'))));
  });
}
