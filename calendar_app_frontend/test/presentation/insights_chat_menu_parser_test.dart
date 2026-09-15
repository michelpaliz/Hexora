import 'package:hexora/presentation/features/shared/widgets/insights_chat_menu_parser.dart';
import 'package:test/test.dart';

void main() {
  test('extracts direct, inline, and nested structured menus', () {
    final direct = extractInsightsMenu({
      'menu': {
        'id': 'direct',
        'options': [
          {'index': 1, 'label': 'First'},
        ],
      },
    });
    final inline = extractInsightsMenu({
      'id': 'inline',
      'options': [
        {'index': 2, 'label': 'Second'},
      ],
    });
    final nested = extractInsightsMenu({
      'data': {
        'data': {
          'menu': {
            'id': 'nested',
            'options': [
              {'index': 3, 'label': 'Third'},
            ],
          },
        },
      },
    });

    expect(direct?.id, 'direct');
    expect(direct?.options.single.label, 'First');
    expect(inline?.id, 'inline');
    expect(inline?.options.single.index, 2);
    expect(nested?.id, 'nested');
    expect(extractInsightsMenu('not a map'), isNull);
  });

  test('parses numbered text with the original accepted separators', () {
    final menu = fallbackInsightsMenuFromText('''
Choose an option
1) First
2. Second
3- Third
4: Fourth
''');

    expect(menu?.title, 'Choose an option');
    expect(menu?.options.map((option) => option.index), [1, 2, 3, 4]);
    expect(
      menu?.options.map((option) => option.label),
      ['First', 'Second', 'Third', 'Fourth'],
    );
    expect(fallbackInsightsMenuFromText('1) Only one line'), isNull);
    expect(fallbackInsightsMenuFromText('No numbered options\nStill none'),
        isNull);
  });

  test('prefers structured menus and suppresses table text fallback', () {
    final structured = resolveInsightsMenuForResponse(
      raw: {
        'menu': {
          'id': 'structured',
          'options': [
            {'index': 1, 'label': 'Structured'},
          ],
        },
      },
      text: '1) Text fallback',
      table: const {
        'rows': [],
      },
    );
    final suppressed = resolveInsightsMenuForResponse(
      raw: const {},
      text: 'Menu\n1) Text fallback',
      table: const {
        'rows': [],
      },
    );
    final fallback = resolveInsightsMenuForResponse(
      raw: const {},
      text: 'Menu\n1) Text fallback',
    );

    expect(structured?.id, 'structured');
    expect(suppressed, isNull);
    expect(fallback?.options.single.label, 'Text fallback');
  });
}
