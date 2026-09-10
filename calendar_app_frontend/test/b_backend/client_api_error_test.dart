import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ClientsApiException', () {
    test('reads the error field from a 409 response', () {
      final exception = ClientsApiException.fromResponse(
        http.Response(
          '{"error":"Client name already exists in this group"}',
          409,
        ),
      );

      expect(exception.statusCode, 409);
      expect(exception.message, 'Client name already exists in this group');
      expect(
        exception.responseData?['error'],
        'Client name already exists in this group',
      );
    });

    test('falls back to the message field', () {
      final exception = ClientsApiException.fromResponse(
        http.Response('{"message":"Server validation failed"}', 422),
      );

      expect(exception.statusCode, 422);
      expect(exception.message, 'Server validation failed');
    });
  });
}
