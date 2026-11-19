import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_workspace_chrome.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
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

  testWidgets('shared document toolbar keeps search and actions responsive',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var query = '';

    Widget app() => MaterialApp(
          theme: AppTheme.forPlatform(
            Brightness.light,
            platform: TargetPlatform.windows,
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => HexoraDocumentToolbar(
                statusTabs: HexoraDocumentStatusTabs(
                  selectedIndex: 0,
                  onSelected: (_) {},
                  tabs: const [
                    HexoraDocumentStatusTab(
                      label: 'Borradores',
                      count: 2,
                      icon: Icons.drafts_outlined,
                    ),
                    HexoraDocumentStatusTab(
                      label: 'Facturas',
                      count: 10,
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                viewSwitcher: const SizedBox(
                  key: ValueKey('test-view-switcher'),
                  width: 64,
                  height: 36,
                ),
                searchHint: 'Buscar documentos...',
                searchValue: query,
                onSearchChanged: (value) => setState(() => query = value),
                actions: const SizedBox(
                  key: ValueKey('test-options'),
                  width: 96,
                  height: 36,
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), 'Cliente Norte');
    await tester.pump();
    expect(query, 'Cliente Norte');
    expect(
        tester.getSize(find.byType(TextField)).width, lessThanOrEqualTo(320));
    expect(
      tester.getCenter(find.byKey(const ValueKey('test-options'))).dy,
      closeTo(tester.getCenter(find.text('Borradores')).dy, 1),
    );

    tester.view.physicalSize = const Size(520, 300);
    await tester.pumpAndSettle();
    expect(find.text('Cliente Norte'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('compact detail header keeps status inline with long client',
      (tester) async {
    tester.view.physicalSize = const Size(520, 180);
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
          body: HexoraDocumentDetailHeader(
            key: ValueKey('compact-detail-header'),
            title: '400-26',
            clientName:
                'Comunidad de propietarios con un nombre especialmente largo',
            statusLabel: 'Enviada',
            statusColor: Colors.blue,
            statusIcon: Icons.check_circle_outline,
            dateLabel: '29 oct 2026',
            compact: true,
            statusInline: true,
            moreActions: SizedBox(width: 28, height: 28),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('compact-detail-header')))
          .height,
      44,
    );
    expect(
      tester.getCenter(find.text('Enviada')).dy,
      closeTo(tester.getCenter(find.text('400-26')).dy, 2),
    );
    expect(tester.takeException(), isNull);
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
            list: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DocumentLayoutSelector(),
                Text('Document list'),
              ],
            ),
            preview: Text('Document preview'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Compact layout'), findsOneWidget);
    expect(find.byTooltip('Extended layout'), findsOneWidget);
    expect(find.text('Document list'), findsOneWidget);
    expect(find.text('Document preview'), findsNothing);

    await tester.tap(find.byTooltip('Compact layout'));
    await tester.pump();
    expect(find.text('Document list'), findsOneWidget);
    expect(find.text('Document preview'), findsNothing);

    await tester.tap(find.byTooltip('Extended layout'));
    await tester.pump();
    expect(find.text('Document list'), findsOneWidget);
    expect(find.text('Document preview'), findsOneWidget);
  });

  testWidgets('list preview action opens drawer and split mode hides the eye',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mode = ValueNotifier<DocumentViewMode?>(DocumentViewMode.list);
    addTearDown(mode.dispose);
    String? selected;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: DocumentSplitView(
            storageKey: 'preview-drawer-test',
            modeNotifier: mode,
            selectionKey: selected,
            list: _ListWithLayoutSelector(
              child: CompactDocumentRow(
                title: 'F2026-028',
                metadata: 'Arjen',
                amount: '300,00 €',
                previewLabel: 'Vista previa',
                quickActionSlots: 1,
                actions: [CompactDocumentAction('More', () {})],
                quickActions: [
                  CompactDocumentQuickAction(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Vista previa',
                    opensPreviewDrawer: true,
                    onPressed: () => setState(() => selected = 'invoice-28'),
                  ),
                ],
              ),
            ),
            preview: const Text('PDF preview'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Compact layout'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Vista previa'));
    await tester.pumpAndSettle();
    final drawer = find.byKey(const ValueKey('document-preview-drawer'));
    expect(drawer, findsOneWidget);
    expect(tester.getSize(drawer).width, inInclusiveRange(420, 520));
    expect(mode.value, DocumentViewMode.list);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(drawer, findsNothing);

    await tester.tap(find.byTooltip('Extended layout'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Vista previa'), findsNothing);
    expect(find.text('PDF preview'), findsOneWidget);
  });
}

class _ListWithLayoutSelector extends StatelessWidget {
  const _ListWithLayoutSelector({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DocumentLayoutSelector(),
          child,
        ],
      );
}
