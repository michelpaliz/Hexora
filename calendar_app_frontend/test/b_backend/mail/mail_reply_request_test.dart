import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/errorClases/error_classes/error_classes.dart';
import 'package:hexora/b-backend/mail/api/mail_api_client.dart';
import 'package:hexora/b-backend/mail/models/mail_requests.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  MailReplyRequest replyRequest() => const MailReplyRequest(
        groupId: 'group-123',
        subject: 'Re: Envío de factura',
        textBody: 'Plain-text reply',
        htmlBody: '<p>HTML reply</p>',
        applyDefaultFooter: true,
      );

  test('reply payload contains content and context but no recipient', () {
    final request = replyRequest();

    expect(request.hasContent, isTrue);
    expect(request.toJson(), {
      'subject': 'Re: Envío de factura',
      'text': 'Plain-text reply',
      'html': '<p>HTML reply</p>',
      'groupId': 'group-123',
      'applyDefaultFooter': true,
    });
    expect(request.toJson(), isNot(contains('to')));
  });

  test('reply requires text or html content', () {
    const request = MailReplyRequest(groupId: 'group-123');
    expect(request.hasContent, isFalse);
  });

  Future<void> expectReplyPost(String messageId) async {
    late http.Request captured;
    final api = MailApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      }),
    );

    await api.reply(
      id: messageId,
      payload: replyRequest().toJson(),
      token: 'unused-by-authenticated-client',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/mail/messages/$messageId/reply');
    expect(jsonDecode(captured.body), replyRequest().toJson());
    expect(jsonDecode(captured.body), isNot(contains('to')));
  }

  test('replies to the selected inbox message id', () async {
    await expectReplyPost('inbox-message-id');
  });

  test('replies to the selected Sent invoice message id', () async {
    await expectReplyPost('sent-invoice-314-26-message-id');
  });

  test('reply exposes backend error field', () async {
    final api = MailApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'No se puede responder a este mensaje.'}),
          422,
        ),
      ),
    );

    expect(
      () => api.reply(
        id: 'message-id',
        payload: replyRequest().toJson(),
        token: 'unused-by-authenticated-client',
      ),
      throwsA(
        isA<HttpFailure>().having(
          (failure) => failure.message,
          'message',
          'No se puede responder a este mensaje.',
        ),
      ),
    );
  });

  test('reply exposes backend message field', () async {
    final api = MailApiClient(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'El mensaje original ya no existe.'}),
          404,
        ),
      ),
    );

    expect(
      () => api.reply(
        id: 'missing-message-id',
        payload: replyRequest().toJson(),
        token: 'unused-by-authenticated-client',
      ),
      throwsA(
        isA<HttpFailure>().having(
          (failure) => failure.message,
          'message',
          'El mensaje original ya no existe.',
        ),
      ),
    );
  });

  test('reply leaves an empty error message for the UI fallback', () async {
    final api = MailApiClient(
      client: MockClient((_) async => http.Response('', 500)),
    );

    expect(
      () => api.reply(
        id: 'message-id',
        payload: replyRequest().toJson(),
        token: 'unused-by-authenticated-client',
      ),
      throwsA(
        isA<HttpFailure>().having(
          (failure) => failure.message,
          'message',
          isEmpty,
        ),
      ),
    );
  });
}
