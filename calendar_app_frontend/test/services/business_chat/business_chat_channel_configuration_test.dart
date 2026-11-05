import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';

void main() {
  group('BusinessChatConversation composer configuration', () {
    test('maps legacy income channel without coupling the composer to title',
        () {
      final conversation = BusinessChatConversation.fromJson({
        'id': 'income',
        'type': 'team',
        'title': 'Factura_Ingresos',
      });

      expect(conversation.channelType, BusinessChatChannelType.income);
      expect(
        conversation.composerActions,
        containsAll({
          BusinessChatComposerAction.attachFile,
          BusinessChatComposerAction.invoice,
          BusinessChatComposerAction.receipt,
        }),
      );
    });

    test('server configuration overrides legacy defaults and keeps files', () {
      final conversation = BusinessChatConversation.fromJson({
        'id': 'custom',
        'type': 'team',
        'title': 'Any title',
        'channelType': 'custom',
        'allowedActions': ['links', 'quote'],
      });

      expect(conversation.channelType, BusinessChatChannelType.custom);
      expect(
        conversation.composerActions,
        {
          BusinessChatComposerAction.attachFile,
          BusinessChatComposerAction.link,
          BusinessChatComposerAction.quote,
        },
      );
    });

    test('keeps business record metadata on old and new message shapes', () {
      final direct = BusinessChatMessage.fromJson({
        'id': 'm1',
        'conversationId': 'c1',
        'senderId': 'u1',
        'senderName': 'User',
        'body': '',
        'createdAt': '2026-11-03T10:00:00Z',
        'businessRecord': {'type': 'invoice', 'id': 'i1'},
      });
      final nested = BusinessChatMessage.fromJson({
        'id': 'm2',
        'conversationId': 'c1',
        'senderId': 'u1',
        'senderName': 'User',
        'body': '',
        'createdAt': '2026-11-03T10:00:00Z',
        'attachment': {
          'fileName': 'invoice.pdf',
          'businessRecord': {'type': 'invoice', 'id': 'i1'},
        },
      });

      expect(direct.businessRecord?['id'], 'i1');
      expect(nested.businessRecord?['id'], 'i1');
    });
  });
}
