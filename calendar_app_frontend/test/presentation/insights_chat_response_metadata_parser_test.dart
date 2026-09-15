import 'package:hexora/presentation/features/shared/widgets/insights_chat_response_metadata_parser.dart';
import 'package:test/test.dart';

void main() {
  test('extracts export capability and view through nested data envelopes', () {
    expect(
      extractInsightsCanExport({
        'canExport': false,
        'data': {
          'data': {'canExport': 'TRUE'},
        },
      }),
      isTrue,
    );
    expect(extractInsightsCanExport({'canExport': 'false'}), isFalse);
    expect(extractInsightsCanExport(null), isFalse);

    expect(
      extractInsightsResponseView({
        'view': ' ',
        'data': {
          'view': ' table ',
        },
      }),
      'table',
    );
    expect(extractInsightsResponseView('not a map'), isNull);
  });

  test('extracts inline, named, and nested structured tables', () {
    final inline = {
      'columns': ['name'],
      'rows': [
        {'name': 'Example'},
      ],
    };
    final named = <Object, Object>{'rows': const []};

    expect(identical(extractInsightsStructuredTable(inline), inline), isTrue);
    expect(
        extractInsightsStructuredTable({'table': named}), {'rows': const []});
    expect(
      extractInsightsStructuredTable({
        'data': {'table': const <String, dynamic>{}},
      }),
      isEmpty,
    );
    expect(extractInsightsStructuredTable(const {}), isNull);
  });

  test('normalizes follow-ups while retaining nested fallback behavior', () {
    expect(
      extractInsightsFollowUps({
        'followUps': [null, '', '  '],
        'data': {
          'followUps': ['  First  ', 2, null],
        },
      }),
      ['First', '2'],
    );
    expect(extractInsightsFollowUps({'followUps': 'First'}), isNull);
  });

  test('extracts the first non-empty event assistant map', () {
    expect(
      extractInsightsEventAssistant({
        'eventAssistant': const <String, dynamic>{},
        'data': {
          'eventAssistant': <Object, Object>{'status': 'preview'},
        },
      }),
      {'status': 'preview'},
    );
    expect(
        extractInsightsEventAssistant({'eventAssistant': 'invalid'}), isNull);
  });
}
