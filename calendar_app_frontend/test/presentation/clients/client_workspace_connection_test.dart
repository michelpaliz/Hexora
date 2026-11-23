import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/client_detail_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/clients_list_panel.dart';
import 'package:hexora/presentation/shared/widgets/client_initial_avatar.dart';
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:hexora/theme/themes/app_theme.dart';

final _clients = <GroupClient>[
  GroupClient(id: 'sono', name: 'SONOLAND INMOBILIARIA, SLU'),
  GroupClient(id: 'chalet', name: 'Villa Mar', propertyType: 'chalet'),
  for (var i = 0; i < 40; i++)
    GroupClient(id: 'c$i', name: 'Zeta cliente ${i.toString().padLeft(2, '0')}'),
];

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: AppTheme.forPlatform(brightness, platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// List panel laid out like the split: panel · 12 px handle · workspace.
Widget _split({
  required GroupClient? selected,
  double panelWidth = 480,
  bool connector = true,
  ValueChanged<GroupClient>? onSelect,
}) {
  final search = TextEditingController();
  return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SizedBox(
      width: panelWidth,
      child: ClientsListPanel(
        allClients: _clients,
        filteredClients: _clients,
        selectedClient: selected,
        selectedHiddenByFilters: false,
        hideInactive: true,
        onToggleHideInactive: () {},
        missingCurrentMonthInvoiceOnly: false,
        onToggleMissingCurrentMonthInvoiceOnly: (_) {},
        searchController: search,
        onSearchChanged: () {},
        entityFilter: null,
        propertyFilter: null,
        entityOptions: const [],
        propertyOptions: const [],
        onClearFilters: () {},
        onToggleEntityFilter: (_) {},
        onTogglePropertyFilter: (_) {},
        onClearEntityFilter: () {},
        onClearPropertyFilter: () {},
        onSelectClient: onSelect ?? (_) {},
        showSelectionConnector: connector,
      ),
    ),
    const SizedBox(width: 12),
    const Expanded(child: SizedBox()),
  ]);
}

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Finder _row(String id) => find.byWidgetPredicate(
    (w) => w is HexoraListRow && w.key == ValueKey('client-sidebar-row-$id'));
const _connector = ValueKey('client-selection-connector');

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('selected row: white, 3 px indicator, semibold ($brightness)',
        (tester) async {
      await _size(tester, const Size(1200, 800));
      await tester.pumpWidget(
          _app(_split(selected: _clients.first), brightness: brightness));
      await tester.pump();
      final cs = Theme.of(tester.element(_row('sono'))).colorScheme;

      final material = tester.widget<Material>(find
          .descendant(of: _row('sono'), matching: find.byType(Material))
          .first);
      expect(material.color, cs.surface);
      expect(
        tester
            .widget<Material>(find
                .descendant(of: _row('chalet'), matching: find.byType(Material))
                .first)
            .color,
        Colors.transparent,
      );
      final row = tester.widget<HexoraListRow>(_row('sono'));
      expect(row.selectedIndicatorWidth, 3);
      expect(row.selectedBorderColor, isNull, reason: 'no full outline');
      expect(row.borderRadius, 0);

      Text name(String text) => tester.widget<Text>(find.text(text));
      expect(name('SONOLAND INMOBILIARIA, SLU').style!.fontWeight,
          FontWeight.w600);
      expect(name('Villa Mar').style!.fontWeight, FontWeight.w400);
      expect(
        tester
            .widget<ClientInitialAvatar>(
                find.byKey(const ValueKey('client-sidebar-avatar-sono')))
            .emphasized,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('selection does not change row size', (tester) async {
    await _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_split(selected: null)));
    await tester.pump();
    final before = tester.getRect(_row('chalet'));
    await tester.pumpWidget(_app(_split(selected: _clients[1])));
    await tester.pump();
    expect(tester.getRect(_row('chalet')), before);
  });

  testWidgets('connector joins the selected row to the divider',
      (tester) async {
    await _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_split(selected: _clients.first)));
    await tester.pump();
    await tester.pump();
    final row = tester.getRect(_row('sono'));
    final connector = tester.getRect(find.byKey(_connector));
    expect(connector.left, row.right);
    expect(connector.width, ClientsListPanel.connectorReach);
    // Ends on the divider line (centre of the 12 px handle), not beyond it.
    expect(connector.right, 480 + 6);
    expect(connector.top, row.top);
    expect(connector.height, row.height);
  });

  testWidgets('connector hides when the row scrolls away; selection stays',
      (tester) async {
    await _size(tester, const Size(1200, 500));
    await tester.pumpWidget(_app(_split(selected: _clients.first)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_connector), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_connector), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_connector), findsOneWidget);
    expect(tester.widget<HexoraListRow>(_row('sono')).selected, isTrue);
  });

  testWidgets('connector can be turned off (tablet / tight layouts)',
      (tester) async {
    await _size(tester, const Size(800, 800));
    await tester.pumpWidget(
        _app(_split(selected: _clients.first, connector: false)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(_connector), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('property column does not repeat the type fallback',
      (tester) async {
    await _size(tester, const Size(1200, 800));
    await tester.pumpWidget(_app(_split(selected: null, panelWidth: 640)));
    await tester.pump();
    expect(
      find.descendant(of: _row('chalet'), matching: find.text('Chalet')),
      findsOneWidget,
    );
  });

  group('workspace header', () {
    Widget detail(GroupClient client) => ClientDetailPanel(
          groupId: 'group-1',
          clients: _clients,
          selectedClient: client,
          issuedInvoices: const [],
          draftInvoices: const [],
          entityOptions: const [],
          propertyOptions: const [],
          assignBusy: false,
          onEditSelectedClient: () {},
          onCreateInvoice: () {},
          onCreateReceipt: () {},
          onEditReceipt: (_) {},
          onOpenInvoiceDetail: (_) {},
          invoicePreviewBuilder: (_, __, ___, ____, _____) =>
              const SizedBox.shrink(),
          receiptPreviewBuilder: (_, __, ___, ____, _____) =>
              const SizedBox.shrink(),
          onDeleteInvoice: (_) {},
          onDownloadVisibleInvoices: (_) async {},
          onApplyClassification: ({entityType, propertyKind}) async {},
        );

    testWidgets('matches the list identity and dedupes the type line',
        (tester) async {
      await _size(tester, const Size(1200, 800));
      final client = GroupClient(
        id: 'v',
        name: 'Villa Mar',
        customerType: 'chalet',
        propertyType: 'chalet',
      );
      await tester.pumpWidget(_app(detail(client)));
      await tester.pump();
      final avatar = tester.widget<ClientInitialAvatar>(
          find.byKey(const ValueKey('client-detail-avatar')));
      expect(avatar.emphasized, isTrue);
      expect(ClientInitialAvatar.initialOf(avatar.name), 'V');
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('client-detail-name')))
              .data,
          'Villa Mar');
      expect(find.text('Chalet'), findsOneWidget);
      expect(find.textContaining('Chalet · Chalet'), findsNothing);
    });

    testWidgets('switching clients keeps the active document tab',
        (tester) async {
      await _size(tester, const Size(1200, 800));
      await tester.pumpWidget(_app(detail(_clients.first)));
      await tester.pump();
      await tester.tap(find.text('Gráfico'));
      await tester.pump(const Duration(milliseconds: 400));
      TabController controller() => DefaultTabController.of(
          tester.element(find.byKey(const ValueKey('client-detail-tabs-row'))));
      expect(controller().index, 3);

      await tester.pumpWidget(_app(detail(_clients[1])));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('client-detail-name')))
              .data,
          'Villa Mar',
          reason: 'header shows the new client, not the previous one');
      expect(controller().index, 3);
    });
  });
}
