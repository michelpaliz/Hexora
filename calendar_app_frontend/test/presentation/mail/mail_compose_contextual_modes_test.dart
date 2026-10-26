import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/invoice/invoice_line.dart';
import 'package:hexora/models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_compose_screen.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:http/http.dart' as http;

class _ClientsApi extends ClientsApi {
  @override
  Future<List<GroupClient>> list({
    String? groupId,
    String? search,
    bool? active,
    bool includeCurrentMonthInvoiceFlag = false,
    bool? missingCurrentMonthInvoice,
  }) async =>
      [
        GroupClient(
          id: 'client-1',
          name: 'Las Alondras Playa',
          email: 'facturas@example.com',
        ),
        GroupClient(
          id: 'client-no-email',
          name: 'Cliente sin correo',
        ),
      ];
}

class _InvoicesApi extends InvoicesApi {
  _InvoicesApi({this.previewRequest});

  final Completer<http.Response>? previewRequest;

  @override
  Future<List<Invoice>> listByGroup(
    String groupId, {
    String? status,
    String? linkStatus,
    String? seriesId,
    String? sortBy,
    String? sortDir,
  }) async {
    if (status == 'draft') return const [];
    return [
      Invoice(
        id: 'invoice-1',
        groupId: groupId,
        clientId: 'client-1',
        invoiceNumber: '382-26',
        status: 'issued',
        deliveryStatus: 'sent',
        sentAt: DateTime(2026, 10, 26, 10),
        issueDate: DateTime(2026, 10, 26),
        total: 1548.03,
        currency: 'EUR',
      ),
    ];
  }

  @override
  Future<http.Response> previewPdf(String id) {
    final request = previewRequest;
    if (request == null) {
      return Future<http.Response>.error(Exception('Preview unavailable'));
    }
    return request.future;
  }
}

class _HistoryInvoicesApi extends InvoicesApi {
  late final List<Invoice> invoices = [
    Invoice(
      id: 'invoice-current',
      groupId: 'group-1',
      clientId: 'client-1',
      invoiceNumber: '382-26',
      status: 'issued',
      deliveryStatus: 'sent',
      issueDate: DateTime(2026, 10, 26),
      subtotal: 120,
      taxTotal: 25.2,
      total: 145.2,
      currency: 'EUR',
      lines: const [
        InvoiceLine(
          invoiceId: 'invoice-current',
          position: 1,
          description: 'Mantenimiento actual',
          quantity: 2,
          unitPrice: 60,
        ),
      ],
    ),
    Invoice(
      id: 'invoice-history-delivered',
      groupId: 'group-1',
      clientId: 'client-1',
      invoiceNumber: '381-26',
      status: 'issued',
      deliveryStatus: 'delivered',
      issueDate: DateTime(2026, 9, 26),
      subtotal: 100,
      taxTotal: 21,
      total: 121,
      currency: 'EUR',
      lines: const [
        InvoiceLine(
          invoiceId: 'invoice-history-delivered',
          position: 1,
          description: 'Mantenimiento anterior',
          quantity: 1,
          unitPrice: 100,
        ),
      ],
    ),
    Invoice(
      id: 'invoice-history-unsent',
      groupId: 'group-1',
      clientId: 'client-1',
      invoiceNumber: '380-26',
      status: 'issued',
      deliveryStatus: 'not_sent',
      issueDate: DateTime(2026, 8, 26),
      subtotal: 80,
      taxTotal: 16.8,
      total: 96.8,
      currency: 'EUR',
    ),
  ];

  @override
  Future<List<Invoice>> listByGroup(
    String groupId, {
    String? status,
    String? linkStatus,
    String? seriesId,
    String? sortBy,
    String? sortDir,
  }) async =>
      status == 'draft' ? const [] : invoices;

  @override
  Future<Invoice> getById(String id) async =>
      invoices.firstWhere((invoice) => invoice.id == id);

  @override
  Future<http.Response> previewPdf(String id) async =>
      http.Response('%PDF-1.4', 200);
}

class _ReceiptsApi extends ReceiptsApi {
  @override
  Future<List<Receipt>> list({
    required String groupId,
    String? status,
  }) async =>
      const [];
}

class _PresupuestosApi extends PresupuestosApi {
  @override
  Future<List<Map<String, dynamic>>> listByGroup({
    required String groupId,
    String? clientId,
    PresupuestoKind? presupuestoKind,
    String? status,
    String? sortBy,
    String? sortDir,
    int? limit,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> listDocumentsByGroup(
    String groupId, {
    String? search,
  }) async =>
      const [];
}

Future<void> _selectFirstClient(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey('client-select-row-client-1')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('client without email can switch to manual recipient entry',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MailComposeScreen(
        groupId: 'group-1',
        clientsApi: _ClientsApi(),
        invoicesApi: _InvoicesApi(),
        receiptsApi: _ReceiptsApi(),
        presupuestosApi: _PresupuestosApi(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('client-select-row-client-no-email')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin correo registrado'), findsWidgets);
    expect(find.text('Introducir correo'), findsOneWidget);

    await tester.tap(find.text('Introducir correo'));
    await tester.pumpAndSettle();
    final editorSurface =
        find.byKey(const ValueKey('mail-compose-editor-surface'));
    final manualRecipient = find.descendant(
      of: editorSurface,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType == TextInputType.emailAddress,
      ),
    );
    expect(manualRecipient, findsOneWidget);
    await tester.enterText(manualRecipient, 'manual@example.com ');
    await tester.pump();
    expect(find.text('manual@example.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context modes share recipients and recent invoice selection',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MailComposeScreen(
        groupId: 'group-1',
        clientsApi: _ClientsApi(),
        invoicesApi: _InvoicesApi(),
        receiptsApi: _ReceiptsApi(),
        presupuestosApi: _PresupuestosApi(),
      ),
    ));
    await tester.pumpAndSettle();

    final initialClientRow =
        find.byKey(const ValueKey('client-select-row-client-1'));
    expect(initialClientRow, findsOneWidget);
    expect(
      find.descendant(
        of: initialClientRow,
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsNothing,
    );
    expect(find.text('382-26'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('mail-compose-mode-email')));
    await tester.pump();
    final options = find.byKey(
      const ValueKey('mail-compose-options-surface'),
    );
    final leftEmailInput = find
        .descendant(
          of: options,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.keyboardType == TextInputType.emailAddress,
          ),
        )
        .first;
    await tester.enterText(leftEmailInput, 'manual@example.com ');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('mail-compose-mode-recent')));
    await tester.pumpAndSettle();
    expect(find.text('382-26'), findsOneWidget);
    expect(find.textContaining('Las Alondras Playa'), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('mail-recent-invoice-invoice-1')),
    );
    await tester.pump();
    expect(find.text('Seleccionadas: 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mail-compose-mode-email')));
    await tester.pump();
    expect(find.text('manual@example.com'), findsWidgets);
    expect(find.text('facturas@example.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document preview icon reports async progress', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previewRequest = Completer<http.Response>();

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MailComposeScreen(
        groupId: 'group-1',
        clientsApi: _ClientsApi(),
        invoicesApi: _InvoicesApi(previewRequest: previewRequest),
        receiptsApi: _ReceiptsApi(),
        presupuestosApi: _PresupuestosApi(),
      ),
    ));
    await tester.pumpAndSettle();

    await _selectFirstClient(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    final previewButton = find.byKey(
      const ValueKey('mail-preview-invoice:invoice-1'),
    );
    expect(previewButton, findsOneWidget);

    await tester.tap(previewButton);
    await tester.pump();
    expect(
      find.descendant(
        of: previewButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    previewRequest.completeError(Exception('Preview unavailable'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: previewButton,
        matching: find.byIcon(Icons.visibility_outlined),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer edits preserve pending client and PDF selection',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MailComposeScreen(
        groupId: 'group-1',
        clientsApi: _ClientsApi(),
        invoicesApi: _InvoicesApi(),
        receiptsApi: _ReceiptsApi(),
        presupuestosApi: _PresupuestosApi(),
      ),
    ));
    await tester.pumpAndSettle();

    await _selectFirstClient(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('382-26'));
    await tester.pump();
    expect(find.text('Seleccionadas: 1'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    final selectedPreview = find.byKey(
      const ValueKey('mail-review-preview-invoice:invoice-1'),
    );
    expect(selectedPreview, findsOneWidget);

    final subjectSurface = find.byKey(
      const ValueKey('mail-compose-subject-input-surface'),
    );
    final subjectField = find.descendant(
      of: subjectSurface,
      matching: find.byType(TextField),
    );
    await tester.enterText(subjectField, 'Envío de factura');
    await tester.pumpAndSettle();

    expect(selectedPreview, findsOneWidget);
    expect(find.text('Las Alondras Playa'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review distinguishes selected and attached documents',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MailComposeScreen(
        groupId: 'group-1',
        clientsApi: _ClientsApi(),
        invoicesApi: _InvoicesApi(),
        receiptsApi: _ReceiptsApi(),
        presupuestosApi: _PresupuestosApi(),
      ),
    ));
    await tester.pumpAndSettle();

    await _selectFirstClient(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('382-26'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Documentos adjuntos'), findsOneWidget);
    expect(find.text('0 adjuntos'), findsOneWidget);
    expect(find.text('Seleccionada'), findsOneWidget);
    expect(find.text('Adjuntar 1 factura'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mail-compose-attached-document-summary')),
      findsOneWidget,
    );
    final editorBeforeAttach = tester.element(
      find.byKey(const ValueKey('mail-compose-message-editor')),
    );

    await tester.tap(find.text('Adjuntar 1 factura'));
    await tester.pumpAndSettle();

    expect(find.text('1 adjunto'), findsOneWidget);
    expect(find.text('Adjunto'), findsOneWidget);
    expect(find.text('Volver al correo'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mail-compose-attached-document-summary')),
      findsOneWidget,
    );
    expect(
      tester.element(find.byKey(
        const ValueKey('mail-compose-message-editor'),
      )),
      same(editorBeforeAttach),
    );
    expect(find.textContaining('Factura 382-26.pdf'), findsWidgets);

    await tester.tap(
      find.byKey(
        const ValueKey('mail-review-remove-invoice:invoice-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mail-compose-attached-document-summary')),
      findsOneWidget,
    );
    expect(find.text('1 adjunto'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review history is reference-only and compares invoice details',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MailComposeScreen(
        groupId: 'group-1',
        clientsApi: _ClientsApi(),
        invoicesApi: _HistoryInvoicesApi(),
        receiptsApi: _ReceiptsApi(),
        presupuestosApi: _PresupuestosApi(),
      ),
    ));
    await tester.pumpAndSettle();

    await _selectFirstClient(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('382-26'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adjuntar 1 factura'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Historial de facturas'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('mail-history-invoice-invoice-current')),
      findsNothing,
    );
    expect(find.text('381-26'), findsOneWidget);
    expect(find.text('380-26'), findsOneWidget);
    expect(find.byTooltip('Entregada'), findsOneWidget);
    expect(find.byTooltip('No enviada'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('mail-history-sent-filter')));
    await tester.pumpAndSettle();
    expect(find.text('381-26'), findsOneWidget);
    expect(find.text('380-26'), findsNothing);

    await tester.tap(find.byKey(
      const ValueKey('mail-history-compare-invoice-history-delivered'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Comparar facturas'), findsOneWidget);
    expect(find.text('Base imponible'), findsOneWidget);
    expect(find.text('Mantenimiento actual'), findsOneWidget);
    expect(find.text('Mantenimiento anterior'), findsOneWidget);
    expect(find.textContaining('+24,20'), findsOneWidget);

    expect(find.text('1 adjunto'), findsOneWidget);
    expect(find.textContaining('Factura 382-26.pdf'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
