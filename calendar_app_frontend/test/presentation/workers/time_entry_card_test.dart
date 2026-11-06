import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/time_tracking/time_entry.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/time_entry_card.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';

class _Repository implements ITimeTrackingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const entryKey = ValueKey('time-entry-entry');
  final entry = TimeEntry(
    id: 'entry',
    workerId: 'worker',
    start: DateTime(2026, 10, 2, 7, 30),
    end: DateTime(2026, 10, 2, 15),
  );

  Future<void> pumpCard(WidgetTester tester, double width) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width,
                child: TimeEntryCard(
                  entry: entry,
                  groupId: 'group',
                  repo: _Repository(),
                  getToken: () async => 'token',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('uses a compact 52px desktop row', (tester) async {
    await pumpCard(tester, 900);

    expect(tester.getSize(find.byKey(entryKey)).height, 52);
    expect(find.text('Completados'), findsOneWidget);
    expect(find.text('7 h 30 m'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps record information usable at narrow widths',
      (tester) async {
    await pumpCard(tester, 500);

    expect(find.byKey(entryKey), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
