import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/l10n/app_localizations.dart';

Future<AppLocalizations> _localizationsFor(
  WidgetTester tester,
  Locale locale,
) async {
  late AppLocalizations l;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return l;
}

void main() {
  test('dropdown includes bimensual/trimestral with required order', () {
    expect(
      recurringFrequencyDropdownOrder,
      equals(<String>[
        recurringFreqDaily,
        recurringFreqWeekly,
        recurringFreqMonthly,
        recurringFreqBimensual,
        recurringFreqTrimestral,
        recurringFreqYearly,
      ]),
    );
  });

  test('legacy typo is normalized and canonicalized', () {
    expect(normalizeFrequencyFromApi('trimestal'), recurringFreqTrimestral);
    expect(canonicalFrequencyForApi('trimestal'), recurringFreqTrimestral);
  });

  testWidgets('legacy trimestal renders as Trimestral (es)', (tester) async {
    final l = await _localizationsFor(tester, const Locale('es'));
    expect(recurringFrequencyLabel(l, 'trimestal'), 'Trimestral');
    expect(recurringFrequencyLabel(l, 'trimestral'), 'Trimestral');
  });

  testWidgets('bimensual/trimestral summary singular/plural (es)', (
    tester,
  ) async {
    final l = await _localizationsFor(tester, const Locale('es'));
    expect(
      recurringFrequencySummary(
        l,
        rawFrequency: recurringFreqBimensual,
        interval: 1,
      ),
      'Cada 1 bimestre',
    );
    expect(
      recurringFrequencySummary(
        l,
        rawFrequency: recurringFreqBimensual,
        interval: 2,
      ),
      'Cada 2 bimestres',
    );
    expect(
      recurringFrequencySummary(
        l,
        rawFrequency: recurringFreqTrimestral,
        interval: 1,
      ),
      'Cada 1 trimestre',
    );
    expect(
      recurringFrequencySummary(
        l,
        rawFrequency: recurringFreqTrimestral,
        interval: 2,
      ),
      'Cada 2 trimestres',
    );
  });
}

