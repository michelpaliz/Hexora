import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/sections/time_summary_section.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('marks a zero-duration time entry as invalid', (tester) async {
    await initializeDateFormatting('en');
    final time = DateTime(2026, 11, 6, 9);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppTypography.light()]),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TimeSummarySection(
            start: time,
            end: time,
            dateFormat: DateFormat.yMMMd('en'),
            timeFormat: DateFormat.Hm('en'),
            selectedCount: 1,
          ),
        ),
      ),
    );

    expect(find.textContaining('Invalid time'), findsOneWidget);
  });
}
