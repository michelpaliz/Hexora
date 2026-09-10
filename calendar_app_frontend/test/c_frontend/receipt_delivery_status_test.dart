import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/receipt_delivery_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/receipts_view/receipt_delivery_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_compose_screen.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('receipt delivery badge', () {
    test('missing status defaults to not_sent and sentAt is parsed as UTC', () {
      final receipt = Receipt.fromJson(<String, dynamic>{
        '_id': 'receipt-1',
        'groupId': 'group-1',
        'clientId': 'client-1',
        'sentAt': '2026-09-10T10:30:00.000',
      });
      expect(receipt.deliveryStatus, 'not_sent');
      expect(receipt.sentAt?.isUtc, isTrue);
    });

    testWidgets('defaults to No enviado', (tester) async {
      await tester.pumpWidget(
        _app(const DeliveryStatusBadge(status: null)),
      );
      expect(find.text('No enviado'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
    });

    testWidgets('sent badge tooltip includes channel and local timestamp',
        (tester) async {
      await tester.pumpWidget(
        _app(
          DeliveryStatusBadge(
            status: 'sent',
            channel: 'email',
            sentAt: DateTime.utc(2026, 9, 10, 10, 30),
          ),
        ),
      );
      expect(find.text('Enviado'), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('Email'));
      expect(tooltip.message, contains('2026'));
    });

    testWidgets('failed badge exposes the backend error in its tooltip',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const DeliveryStatusBadge(
            status: 'failed',
            deliveryError: 'SMTP rechazado',
          ),
        ),
      );
      expect(find.text('Error de envío'), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('SMTP rechazado'));
    });
  });

  group('receipt delivery API and local update', () {
    test('mark-sent sends channel/timestamp and replaces the local receipt',
        () async {
      late http.Request captured;
      final api = ReceiptsApi(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode(<String, dynamic>{
              '_id': 'receipt-1',
              'groupId': 'group-1',
              'clientId': 'client-1',
              'status': 'issued',
              'deliveryStatus': 'sent',
              'deliveryChannel': 'email',
              'sentAt': '2026-09-10T10:30:00.000Z',
            }),
            200,
            request: request,
          );
        }),
      );
      const previous = Receipt(
        id: 'receipt-1',
        groupId: 'group-1',
        clientId: 'client-1',
        status: 'issued',
      );

      final updated = await api.markSent(
        previous.id,
        channel: 'email',
        sentAt: DateTime.utc(2026, 9, 10, 10, 30),
      );
      final local = replaceReceiptById(<Receipt>[previous], updated);

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/receipts/receipt-1/mark-sent');
      expect(jsonDecode(captured.body), <String, dynamic>{
        'channel': 'email',
        'sentAt': '2026-09-10T10:30:00.000Z',
      });
      expect(local.single.deliveryStatus, 'sent');
      expect(local.single.deliveryChannel, 'email');
      expect(local.single.sentAt?.isUtc, isTrue);
    });

    test('mark-unsent posts an empty body and returns not_sent', () async {
      late http.Request captured;
      final api = ReceiptsApi(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode(<String, dynamic>{
              '_id': 'receipt-1',
              'groupId': 'group-1',
              'clientId': 'client-1',
              'status': 'issued',
              'deliveryStatus': 'not_sent',
            }),
            200,
            request: request,
          );
        }),
      );

      final updated = await api.markUnsent('receipt-1');

      expect(captured.url.path, '/api/receipts/receipt-1/mark-unsent');
      expect(jsonDecode(captured.body), isEmpty);
      expect(updated.deliveryStatus, 'not_sent');
    });

    testWidgets('mark-unsent requires confirmation', (tester) async {
      bool? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ReceiptMarkUnsentDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Marcar como no enviado'), findsOneWidget);
      await tester.tap(find.byKey(
        const ValueKey('confirm-receipt-mark-unsent'),
      ));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  test('delivery filter works on already loaded issued receipts', () {
    final receipts = <Receipt>[
      const Receipt(
        id: 'not-sent',
        groupId: 'group-1',
        clientId: 'client-1',
      ),
      const Receipt(
        id: 'sent',
        groupId: 'group-1',
        clientId: 'client-1',
        deliveryStatus: 'sent',
      ),
      const Receipt(
        id: 'failed',
        groupId: 'group-1',
        clientId: 'client-1',
        deliveryStatus: 'failed',
      ),
    ];
    expect(
      filterReceiptsByDelivery(receipts, ReceiptDeliveryFilter.sent).single.id,
      'sent',
    );
    expect(
      filterReceiptsByDelivery(receipts, ReceiptDeliveryFilter.notSent)
          .single
          .id,
      'not-sent',
    );
  });

  test('draft and void receipts have no delivery actions', () {
    for (final status in const ['draft', 'void']) {
      final receipt = Receipt(
        id: 'receipt-$status',
        groupId: 'group-1',
        clientId: 'client-1',
        status: status,
      );
      expect(receiptCanMarkSent(receipt), isFalse);
      expect(receiptCanMarkUnsent(receipt), isFalse);
    }
  });

  group('email receipt synchronization', () {
    test('successful email refreshes attached receipt status', () async {
      var sent = false;
      final refreshed = await sendEmailAndRefreshReceipts(
        sendEmail: () async {
          sent = true;
        },
        receiptIds: const ['receipt-1'],
        loadReceipt: (id) async => Receipt(
          id: id,
          groupId: 'group-1',
          clientId: 'client-1',
          status: 'issued',
          deliveryStatus: 'sent',
          deliveryChannel: 'email',
        ),
      );
      expect(sent, isTrue);
      expect(refreshed.single.deliveryStatus, 'sent');
      expect(refreshed.single.deliveryChannel, 'email');
    });

    test('failed email does not refresh or mark the receipt', () async {
      var loadCalls = 0;
      await expectLater(
        sendEmailAndRefreshReceipts(
          sendEmail: () async => throw Exception('SMTP failed'),
          receiptIds: const ['receipt-1'],
          loadReceipt: (id) async {
            loadCalls++;
            throw StateError('must not load');
          },
        ),
        throwsException,
      );
      expect(loadCalls, 0);
    });
  });

  group('receipt delivery errors', () {
    test('maps permission and validation responses', () {
      expect(
          _message(403), 'No tienes permisos para cambiar el estado de envío.');
      expect(_message(400, message: 'Invalid channel'),
          'El canal de envío no es válido.');
      expect(_message(400, message: 'Invalid sentAt'),
          'La fecha de envío no es válida.');
      expect(_message(404), 'No se encontró el recibo.');
      expect(_message(409),
          'Solo los recibos emitidos pueden cambiar su estado de envío.');
      expect(_message(500),
          'No se pudo actualizar el estado de envío. Inténtalo de nuevo.');
    });
  });
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

String _message(int statusCode, {String message = 'error'}) {
  return receiptDeliveryErrorMessage(
    ReceiptsApiException(
      statusCode: statusCode,
      message: message,
      url: Uri.parse('https://example.test/api/receipts/receipt-1'),
      method: 'POST',
      responseBody: null,
      responseHeaders: null,
    ),
  );
}
