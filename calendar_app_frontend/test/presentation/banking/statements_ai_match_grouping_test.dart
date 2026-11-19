import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/statements_ai_match_suggest_dialog.dart';

void main() {
  group('month grouping', () {
    test('groups suggestions by document issueDate month', () {
      final suggestions = <Map<String, dynamic>>[
        {
          'suggestionId': 's1',
          'score': 0.9,
          'documents': [
            {'id': 'd1', 'issueDate': '2026-10-15'},
          ],
        },
        {
          'suggestionId': 's2',
          'score': 0.8,
          'documents': [
            {'id': 'd2', 'issueDate': '2026-10-03'},
          ],
        },
        {
          'suggestionId': 's3',
          'score': 0.7,
          'documents': [
            {'id': 'd3', 'issueDate': '2026-09-20'},
          ],
        },
      ];

      final groups =
          StatementsAiMatchSuggestDialog.groupByMonthForTest(suggestions);

      expect(groups.keys, containsAll(['2026-10', '2026-09']));
      expect(groups['2026-10']!.length, 2);
      expect(groups['2026-09']!.length, 1);
    });

    test('suggestions without issueDate land in the unknown group', () {
      final suggestions = <Map<String, dynamic>>[
        {
          'suggestionId': 's1',
          'score': 0.9,
          'documents': [
            {'id': 'd1'},
          ],
        },
        {
          'suggestionId': 's2',
          'score': 0.8,
          'documents': [
            {'id': 'd2', 'issueDate': '2026-10-05'},
          ],
        },
      ];

      final groups =
          StatementsAiMatchSuggestDialog.groupByMonthForTest(suggestions);

      expect(groups.keys, containsAll(['unknown', '2026-10']));
      expect(groups['unknown']!.length, 1);
    });
  });

  group('sorting', () {
    final suggestions = <Map<String, dynamic>>[
      {
        'suggestionId': 's1',
        'score': 0.9,
        'totalAmount': 1200,
        'documents': [
          {'id': 'd1', 'issueDate': '2026-09-15'},
        ],
      },
      {
        'suggestionId': 's2',
        'score': 0.6,
        'totalAmount': 1000,
        'documents': [
          {'id': 'd2', 'issueDate': '2026-10-20'},
        ],
      },
      {
        'suggestionId': 's3',
        'score': 0.8,
        'totalAmount': 1010,
        'documents': [
          {'id': 'd3', 'issueDate': '2026-08-01'},
        ],
      },
    ];

    test('score sort preserves original order', () {
      final sorted = StatementsAiMatchSuggestDialog.sortAlternativesForTest(
        suggestions,
        mode: 'score',
        targetAmount: 1000,
      );
      expect(sorted.map((s) => s['suggestionId']), ['s1', 's2', 's3']);
    });

    test('invoiceDate sort orders newest first', () {
      final sorted = StatementsAiMatchSuggestDialog.sortAlternativesForTest(
        suggestions,
        mode: 'invoiceDate',
        targetAmount: 1000,
      );
      expect(sorted.map((s) => s['suggestionId']), ['s2', 's1', 's3']);
    });

    test('amountDifference sort orders smallest delta first', () {
      final sorted = StatementsAiMatchSuggestDialog.sortAlternativesForTest(
        suggestions,
        mode: 'amountDifference',
        targetAmount: 1000,
      );
      // s2 delta=0, s3 delta=10, s1 delta=200
      expect(sorted.map((s) => s['suggestionId']), ['s2', 's3', 's1']);
    });
  });

  group('daysBetween', () {
    test('returns absolute day count', () {
      final a = DateTime(2026, 10, 20);
      final b = DateTime(2026, 10, 15);
      expect(StatementsAiMatchSuggestDialog.daysBetweenForTest(a, b), 5);
      expect(StatementsAiMatchSuggestDialog.daysBetweenForTest(b, a), 5);
    });

    test('same day returns 0', () {
      final d = DateTime(2026, 10, 20);
      expect(StatementsAiMatchSuggestDialog.daysBetweenForTest(d, d), 0);
    });
  });

  group('monthYearLabel', () {
    test('returns Spanish label', () {
      expect(
        StatementsAiMatchSuggestDialog.monthYearLabelForTest('2026-10'),
        'Octubre 2026',
      );
      expect(
        StatementsAiMatchSuggestDialog.monthYearLabelForTest('2026-01'),
        'Enero 2026',
      );
    });

    test('returns English label', () {
      expect(
        StatementsAiMatchSuggestDialog.monthYearLabelForTest(
          '2026-10',
          isEs: false,
        ),
        'October 2026',
      );
    });

    test('unknown key returns Spanish fallback', () {
      expect(
        StatementsAiMatchSuggestDialog.monthYearLabelForTest('unknown'),
        'Sin fecha de factura',
      );
    });
  });
}
