import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/telegram/api/telegram_api_client.dart';
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
}
