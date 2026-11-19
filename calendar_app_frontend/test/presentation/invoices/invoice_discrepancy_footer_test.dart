import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/invoice/invoice_line.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/group_invoices_invoices_view.dart';
import 'package:hexora/services/auth/token/i_token_store.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Tokens implements TokenStore {
  @override
  Future<String?> readAccess() async => 'test';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Invoice _invoice({
  required String id,
  required String number,
  required String clientId,
  required num base,
  required num vat,
  required num total,
}) =>
    Invoice(
      id: id,
      invoiceNumber: number,
      groupId: 'group',
      clientId: clientId,
      clientName: clientId == 'client-a' ? 'Cliente A' : 'Cliente B',
      status: 'issued',
      issueDate: DateTime(2026, 10, 20),
      subtotal: base,
      taxTotal: vat,
      total: total,
      lines: [
        InvoiceLine(
          invoiceId: id,
          position: 0,
          description: 'Servicio',
          unitPrice: base,
        ),
      ],
    );

void main() {
  testWidgets(
      'discrepancy footer filters invoices and restores existing search',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1700, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    TokenService.configureStore(_Tokens());
    addTearDown(() => TokenService.configureStore(SecureTokenStore()));

    final mismatch = _invoice(
      id: 'mismatch',
      number: '400-26',
      clientId: 'client-a',
      base: 100,
      vat: 21,
      total: 120,
    );
    final validA = _invoice(
      id: 'valid-a',
      number: '399-26',
      clientId: 'client-a',
      base: 100,
      vat: 21,
      total: 121,
    );
    final validB = _invoice(
      id: 'valid-b',
      number: '398-26',
      clientId: 'client-b',
      base: 50,
      vat: 10.5,
      total: 60.5,
    );
    String? openedInvoiceId;

    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.forPlatform(
              Brightness.light,
              platform: TargetPlatform.windows,
            ),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GroupInvoicesInvoicesView(
                drafts: const [],
                invoices: [mismatch, validA, validB],
                clients: [
                  GroupClient(id: 'client-a', name: 'Cliente A'),
                  GroupClient(id: 'client-b', name: 'Cliente B'),
                ],
                billingProfile: null,
                group: Group(
                  id: 'group',
                  name: 'Empresa',
                  ownerId: 'owner',
                  userRoles: const {},
                  userIds: const [],
                  createdTime: DateTime(2026),
                  description: '',
                ),
                selectedInvoice: null,
                onSelectInvoice: (invoice) => openedInvoiceId = invoice.id,
                onDeleteInvoice: (_) {},
                onEditDraft: (_) {},
                onIssueDraft: (_) async {},
                onCreateInvoice: () {},
                onRefresh: () {},
                sortState: const InvoiceSortState(
                  by: InvoiceSortBy.date,
                  dir: InvoiceSortDir.desc,
                ),
                onSortBySelected: (_) {},
                initialTabIndex: 1,
                showHeaderTabs: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).first, 'Cliente A');
        await tester.pump(const Duration(milliseconds: 320));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('mismatch')), findsOneWidget);
        expect(find.byKey(const ValueKey('valid-a')), findsOneWidget);
        expect(find.byKey(const ValueKey('valid-b')), findsNothing);

        final warning = find.byKey(const ValueKey('invoice-footer-mismatches'));
        expect(warning, findsOneWidget);
        expect(find.byTooltip('Facturas con desajustes'), findsOneWidget);

        await tester.tap(warning);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('mismatch')), findsOneWidget);
        expect(find.byKey(const ValueKey('valid-a')), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(
          tester.widgetList<Tooltip>(find.byType(Tooltip)).any(
                (tooltip) =>
                    tooltip.message?.contains(
                      'Base + IVA no coincide con el total',
                    ) ??
                    false,
              ),
          isTrue,
        );

        await tester.tap(find.text('400-26'));
        expect(openedInvoiceId, 'mismatch');

        await tester.tap(warning);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('mismatch')), findsOneWidget);
        expect(find.byKey(const ValueKey('valid-a')), findsOneWidget);
        expect(find.byKey(const ValueKey('valid-b')), findsNothing);

        await tester.enterText(find.byType(TextFormField).first, 'Cliente B');
        await tester.pump(const Duration(milliseconds: 320));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('valid-b')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('invoice-footer-mismatches')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
      () => MockClient((request) async {
        if (request.url.path.endsWith('/summary')) {
          return http.Response(
            jsonEncode({
              'count': 3,
              'subtotal': 250,
              'taxTotal': 52.5,
              'total': 301.5,
              'mismatchCount': 1,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
}
