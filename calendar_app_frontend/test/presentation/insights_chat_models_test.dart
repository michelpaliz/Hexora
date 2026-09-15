import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:test/test.dart';

void main() {
  group('InsightsChatMessage', () {
    test('preserves persisted response metadata through a JSON round trip', () {
      final timestamp = DateTime.utc(2026, 9, 15, 12, 30);
      final message = InsightsChatMessage(
        isUser: false,
        text: 'Results',
        displayText: 'Visible results',
        timestamp: timestamp,
        conversationId: 'conversation-1',
        canExport: true,
        exportAction: const {'endpoint': '/exports/1'},
        view: 'table',
        table: const {
          'columns': ['name'],
          'rows': [
            {'name': 'Example'},
          ],
        },
        followUps: const ['Next'],
        menu: const InsightsMenu(
          id: 'root',
          parentId: null,
          backAction: '__back__:root',
          title: 'Choose',
          options: [
            InsightsMenuOption(index: 1, label: 'First', action: 'first'),
          ],
        ),
        eventAssistant: const {'status': 'preview'},
      );

      final restored = InsightsChatMessage.fromJson(message.toJson());

      expect(restored, isNotNull);
      expect(restored!.isUser, isFalse);
      expect(restored.text, 'Results');
      expect(restored.displayText, 'Visible results');
      expect(restored.timestamp, timestamp);
      expect(restored.conversationId, 'conversation-1');
      expect(restored.canExport, isTrue);
      expect(restored.exportAction, {'endpoint': '/exports/1'});
      expect(restored.view, 'table');
      expect(restored.table?['rows'], [
        {'name': 'Example'},
      ]);
      expect(restored.followUps, ['Next']);
      expect(restored.menu?.options.single.action, 'first');
      expect(restored.eventAssistant, {'status': 'preview'});
    });

    test('keeps permissive persisted-value parsing and rejects invalid rows',
        () {
      final restored = InsightsChatMessage.fromJson({
        'isUser': true,
        'text': 42,
        'timestamp': '2026-09-15T12:30:00.000Z',
        'conversationId': '  conversation-2  ',
        'followUps': ['  one  ', '', null, 2],
        'table': <Object, Object>{'rows': const []},
      });

      expect(restored?.text, '42');
      expect(restored?.conversationId, 'conversation-2');
      expect(restored?.followUps, ['one', '2']);
      expect(restored?.table, {'rows': const []});
      expect(InsightsChatMessage.fromJson(null), isNull);
      expect(
        InsightsChatMessage.fromJson({
          'text': ' ',
          'timestamp': '2026-09-15T12:30:00.000Z',
        }),
        isNull,
      );
      expect(
        InsightsChatMessage.fromJson({'text': 'ok', 'timestamp': 'invalid'}),
        isNull,
      );
    });
  });

  test('InsightsMenu accepts and sorts legacy option maps', () {
    final menu = InsightsMenu.fromDynamic({
      'metadata': {
        'menuId': 'finance',
        'parent_id': 'root',
        'back_action': '__back__:root',
        'label': 'Finance',
      },
      'option_map': {
        '2': {'text': 'Second', 'token': 'second'},
        '1': 'First',
        'ignored': 'No index',
      },
    });

    expect(menu?.id, 'finance');
    expect(menu?.parentId, 'root');
    expect(menu?.backAction, '__back__:root');
    expect(menu?.title, 'Finance');
    expect(menu?.options.map((option) => option.index), [1, 2]);
    expect(menu?.options.map((option) => option.label), ['First', 'Second']);
    expect(menu?.options.last.action, 'second');
  });

  test('shared value coercion keeps the original permissive behavior', () {
    final typed = <String, dynamic>{'value': 1};

    expect(identical(insightsChatSafeMap(typed), typed), isTrue);
    expect(insightsChatSafeMap(<Object, Object>{1: 'one'}), {'1': 'one'});
    expect(insightsChatSafeMap('not a map'), isNull);
    expect(insightsChatReadInt(3.9), 3);
    expect(insightsChatReadInt('4'), 4);
    expect(insightsChatReadInt(null), isNull);
  });
}
