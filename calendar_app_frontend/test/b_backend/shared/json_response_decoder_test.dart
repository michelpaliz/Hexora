import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/shared/json_response_decoder.dart';
import 'package:http/http.dart' as http;

class _TestApiException implements Exception {
  final JsonApiErrorContext context;

  const _TestApiException(this.context);
}

void main() {
  final uri = Uri.parse('https://example.test/items');

  test('maps decoded JSON for successful responses', () {
    final result = decodeJsonResponse<Map<String, dynamic>>(
      http.Response('{"ok":true}', 200),
      url: uri,
      method: 'GET',
      map: (json) => Map<String, dynamic>.from(json as Map),
      createException: _TestApiException.new,
    );

    expect(result, const {'ok': true});
  });

  test('passes a non-JSON successful body to the mapper as text', () {
    final result = decodeJsonResponse<String>(
      http.Response('plain response', 200),
      url: uri,
      method: 'GET',
      map: (json) => json as String,
      createException: _TestApiException.new,
    );

    expect(result, 'plain response');
  });

  test('uses the JSON message and preserves response metadata on errors', () {
    late JsonApiErrorContext captured;

    expect(
      () => decodeJsonResponse<void>(
        http.Response(
          '{"message":"Invalid item"}',
          422,
          headers: const {'x-request-id': 'request-1'},
        ),
        url: uri,
        method: 'POST',
        map: (_) {},
        createException: (context) {
          captured = context;
          return _TestApiException(context);
        },
        shouldLogError: (_) => false,
      ),
      throwsA(isA<_TestApiException>()),
    );

    expect(captured.statusCode, 422);
    expect(captured.message, 'Invalid item');
    expect(captured.method, 'POST');
    expect(captured.responseBody, '{"message":"Invalid item"}');
    expect(captured.responseHeaders['x-request-id'], 'request-1');
  });

  test('falls back to a trimmed plain-text error message', () {
    expect(
      () => decodeJsonResponse<void>(
        http.Response('  Server unavailable  ', 503),
        url: uri,
        method: 'GET',
        map: (_) {},
        createException: _TestApiException.new,
        shouldLogError: (_) => false,
      ),
      throwsA(
        isA<_TestApiException>().having(
          (error) => error.context.message,
          'message',
          'Server unavailable',
        ),
      ),
    );
  });

  test('limits JSON error extraction to configured message keys', () {
    expect(
      () => decodeJsonResponse<void>(
        http.Response(
          '{"error":"Internal details"}',
          400,
          reasonPhrase: 'Bad Request',
        ),
        url: uri,
        method: 'GET',
        map: (_) {},
        createException: _TestApiException.new,
        errorMessageKeys: const ['message'],
        shouldLogError: (_) => false,
      ),
      throwsA(
        isA<_TestApiException>().having(
          (error) => error.context.message,
          'message',
          'Bad Request',
        ),
      ),
    );
  });
}
