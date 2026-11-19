import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_card.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

void main() {
  testWidgets('recurrence pencil opens the editor callback', (tester) async {
    final series = <String, dynamic>{
      '_id': 'series-1',
      'clientId': 'client-1',
      'clientName': 'Alqueria',
      'status': 'active',
      'frequency': 'monthly',
      'total': 1573,
    };
    Map<String, dynamic>? edited;
    var opened = false;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(extensions: const [_typography]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecurringSeriesCard(
          series: series,
          clientNamesById: const {'client-1': 'Alqueria'},
          onOpen: (_) => opened = true,
          onEdit: (value) => edited = value,
          onPreview: (_) {},
          onPause: null,
          onResume: null,
          onCancel: null,
          canManage: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(const ValueKey('edit-recurring-series-1')));
    await tester.pump();

    expect(edited, same(series));
    expect(opened, isFalse);
  });
}
