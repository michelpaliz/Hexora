import 'package:hexora/presentation/features/shared/widgets/insights_chat_models.dart';
import 'package:hexora/presentation/features/shared/widgets/insights_chat_table_accessors.dart';
import 'package:test/test.dart';

void main() {
  InsightsChatMessage message({String? view, Map<String, dynamic>? table}) {
    return InsightsChatMessage(
      isUser: false,
      text: 'Table response',
      timestamp: DateTime.utc(2026, 9, 15),
      view: view,
      table: table,
    );
  }

  test('requires the table view and at least one raw row', () {
    expect(
      insightsMessageHasStructuredTable(
        message(view: 'table', table: {
          'rows': const [{}]
        }),
      ),
      isTrue,
    );
    expect(
      insightsMessageHasStructuredTable(
        message(view: 'card', table: {
          'rows': const [{}]
        }),
      ),
      isFalse,
    );
    expect(
      insightsMessageHasStructuredTable(
        message(view: 'table', table: {'rows': const []}),
      ),
      isFalse,
    );
    expect(insightsMessageHasStructuredTable(message(view: 'table')), isFalse);
  });

  test('coerces map keys and filters invalid columns and rows', () {
    final value = message(
      view: 'table',
      table: {
        'columns': [
          <Object, Object>{1: 'number'},
          'invalid',
          {'key': 'amount'},
        ],
        'rows': [
          <Object, Object>{2: 'value'},
          null,
          {'amount': 10},
        ],
      },
    );

    expect(insightsTableColumnsForMessage(value), [
      {'1': 'number'},
      {'key': 'amount'},
    ]);
    expect(insightsTableRowsForMessage(value), [
      {'2': 'value'},
      {'amount': 10},
    ]);
  });

  test('returns empty lists for invalid collections', () {
    final value = message(
      table: {'columns': 'invalid', 'rows': 'invalid'},
    );

    expect(insightsTableColumnsForMessage(value), isEmpty);
    expect(insightsTableRowsForMessage(value), isEmpty);
  });

  test('coerces summary maps and rejects non-map summaries', () {
    expect(
      insightsTableSummaryForMessage(
        message(table: {
          'summary': <Object, Object>{1: 'invoice'},
        }),
      ),
      {'1': 'invoice'},
    );
    expect(
      insightsTableSummaryForMessage(
        message(table: {'summary': 'invalid'}),
      ),
      isNull,
    );
  });
}
