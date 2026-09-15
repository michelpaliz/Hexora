import 'dart:convert';

import 'package:hexora/presentation/features/shared/widgets/insights_chat_json_utils.dart';
import 'package:test/test.dart';

void main() {
  test('deep-clones nested JSON maps and lists', () {
    final original = <String, dynamic>{
      'preview': {
        'status': 'ready',
        'items': [
          {'id': 1},
        ],
      },
    };

    final cloned = cloneInsightsJsonMap(original);
    final clonedPreview = cloned['preview'] as Map<String, dynamic>;
    clonedPreview['status'] = 'changed';
    (clonedPreview['items'] as List).add({'id': 2});

    expect(cloned, isNot(same(original)));
    expect(original['preview'], {
      'status': 'ready',
      'items': [
        {'id': 1},
      ],
    });
  });

  test('preserves supported JSON scalar values and empty maps', () {
    expect(
      cloneInsightsJsonMap({
        'text': 'value',
        'count': 2,
        'enabled': true,
        'optional': null,
      }),
      {
        'text': 'value',
        'count': 2,
        'enabled': true,
        'optional': null,
      },
    );
    expect(cloneInsightsJsonMap(const {}), isEmpty);
  });

  test('preserves the existing unsupported-value failure', () {
    expect(
      () => cloneInsightsJsonMap({'date': DateTime.utc(2026, 9, 15)}),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
  });
}
