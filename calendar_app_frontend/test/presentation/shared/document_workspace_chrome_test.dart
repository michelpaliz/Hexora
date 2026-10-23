import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_workspace_chrome.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('document status tabs preserve selection callbacks',
      (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: HexoraDocumentStatusTabs(
              selectedIndex: selected,
              onSelected: (value) => setState(() => selected = value),
              tabs: const [
                HexoraDocumentStatusTab(
                  label: 'Borradores',
                  count: 3,
                  icon: Icons.drafts_outlined,
                ),
                HexoraDocumentStatusTab(
                  label: 'Facturas',
                  count: 8,
                  icon: Icons.receipt_long_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Facturas'));
    await tester.pumpAndSettle();

    expect(selected, 1);
  });

  testWidgets('detail header exposes navigation, expand and close actions',
      (tester) async {
    var previous = 0;
    var next = 0;
    var expanded = 0;
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: Scaffold(
          body: HexoraDocumentDetailHeader(
            title: 'F2026-028',
            clientName: 'Arjen',
            statusLabel: 'Emitida',
            statusColor: Colors.green,
            statusIcon: Icons.check_circle_outline,
            dateLabel: '19 oct 2026',
            onPrevious: () => previous++,
            onNext: () => next++,
            onExpand: () => expanded++,
            onClose: () => closed++,
            moreActions: const SizedBox(width: 30, height: 30),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.tap(find.byIcon(Icons.open_in_full_rounded));
    await tester.tap(find.byIcon(Icons.close_rounded));

    expect((previous, next, expanded, closed), (1, 1, 1, 1));
  });

  testWidgets('split layout controls are horizontal and preserve modes',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: const Scaffold(
          body: DocumentSplitView(
            storageKey: 'workspace-control-test',
            selectionKey: 'selected-document',
            list: Text('Document list'),
            preview: Text('Document preview'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('List only'), findsOneWidget);
    expect(find.byTooltip('Split view'), findsOneWidget);

    await tester.tap(find.byTooltip('List only'));
    await tester.pump();
    expect(find.text('Document list'), findsOneWidget);
    expect(find.text('Document preview'), findsNothing);

    await tester.tap(find.byTooltip('Split view'));
    await tester.pump();
    expect(find.text('Document list'), findsOneWidget);
    expect(find.text('Document preview'), findsOneWidget);
  });
}
