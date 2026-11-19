import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ReceiptsApi PDF endpoints', () {
    test('preview uses the injected client and returns PDF bytes', () async {
      late http.Request captured;
      final api = ReceiptsApi(
        client: MockClient((request) async {
          captured = request;
          return http.Response.bytes(
            const <int>[0x25, 0x50, 0x44, 0x46],
            200,
            headers: const {'content-type': 'application/pdf'},
            request: request,
          );
        }),
      );

      final response = await api.previewPdf('receipt-1');

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/receipts/receipt-1/pdf/preview');
      expect(response.bodyBytes, const <int>[0x25, 0x50, 0x44, 0x46]);
    });

    test('preview exposes the backend message for a gateway failure', () async {
      final api = ReceiptsApi(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(<String, dynamic>{
              'message': 'No se pudo generar el PDF del recibo',
            }),
            502,
            headers: const {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );

      await expectLater(
        api.previewPdf('receipt-1'),
        throwsA(
          isA<ReceiptsApiException>()
              .having((error) => error.statusCode, 'statusCode', 502)
              .having(
                (error) => error.message,
                'message',
                'No se pudo generar el PDF del recibo',
              ),
        ),
      );
    });

    test('preview falls back to the download endpoint after a 5xx', () async {
      final paths = <String>[];
      final api = ReceiptsApi(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/pdf/preview')) {
            return http.Response(
              jsonEncode(<String, dynamic>{'message': 'Bad gateway'}),
              502,
              request: request,
            );
          }
          return http.Response.bytes(
            const <int>[0x25, 0x50, 0x44, 0x46],
            200,
            headers: const {'content-type': 'application/pdf'},
            request: request,
          );
        }),
      );

      final response = await api.previewPdfWithFallback('receipt-1');

      expect(response.bodyBytes, const <int>[0x25, 0x50, 0x44, 0x46]);
      expect(paths, <String>[
        '/api/receipts/receipt-1/pdf/preview',
        '/api/receipts/receipt-1/pdf',
      ]);
    });

    test('preview retries once after a browser transport failure', () async {
      var attempts = 0;
      final api = ReceiptsApi(
        client: MockClient((request) async {
          attempts++;
          if (attempts == 1) {
            throw http.ClientException('network error', request.url);
          }
          return http.Response.bytes(
            const <int>[0x25, 0x50, 0x44, 0x46],
            200,
            request: request,
          );
        }),
      );

      await api.previewPdfWithFallback('receipt-1');

      expect(attempts, 2);
    });
  });
}
