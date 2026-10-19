import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/telegram/api/telegram_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('sends an issued presupuesto with Telegram thread context', () async {
    late http.Request captured;
    final api = TelegramApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{'message': 'Presupuesto enviado'}),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }),
    );

    final result = await api.sendChatPresupuesto(
      chatId: 'chat 42',
      accountId: 'account-1',
      presupuestoId: 'budget/7',
      caption: 'Presupuesto emitido',
      replyToMessageId: 'message-9',
      forumTopicId: 'topic-3',
    );

    expect(result, isNull);
    expect(captured.method, 'POST');
    expect(
      captured.url.path,
      endsWith('/telegram/chats/chat%2042/presupuestos/budget%2F7'),
    );
    expect(
      jsonDecode(captured.body),
      <String, dynamic>{
        'accountId': 'account-1',
        'caption': 'Presupuesto emitido',
        'replyToMessageId': 'message-9',
        'forumTopicId': 'topic-3',
      },
    );
  });

  test('sends uploaded files and presupuestos in one multipart request',
      () async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test-token'});
    late http.Request captured;
    final api = TelegramApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'message': {'id': 3, 'chatId': '42'},
            'messages': [
              {'id': 1, 'chatId': '42'},
              {'id': 2, 'chatId': '42'},
              {'id': 3, 'chatId': '42'},
            ],
          }),
          201,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }),
    );

    final messages = await api.sendChatDocuments(
      chatId: '42',
      accountId: 'account-1',
      files: const [
        TelegramDocumentUpload(bytes: [1, 2], fileName: 'a.pdf'),
        TelegramDocumentUpload(bytes: [3], fileName: 'b.txt'),
      ],
      presupuestoIds: const ['budget-1', ' '],
      caption: 'Hola',
    );

    expect(messages, hasLength(3));
    expect(captured.url.path, endsWith('/telegram/chats/42/documents'));
    expect(captured.headers['Authorization'], 'Bearer test-token');
    final body = utf8.decode(captured.bodyBytes, allowMalformed: true);
    expect('name="files"'.allMatches(body), hasLength(2));
    expect(body, contains('filename="a.pdf"'));
    expect(body, contains('filename="b.txt"'));
    expect(body, contains('["budget-1"]'));
    expect(body, contains('Hola'));
  });
}
