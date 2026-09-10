import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/a-models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/telegram/components/telegram_issued_presupuesto_picker_dialog.dart';

void main() {
  testWidgets('shows and filters draft and issued presupuestos',
      (tester) async {
    final api = _FakePresupuestosApi([
      {
        '_id': 'draft-1',
        'presupuestoKind': 'structured',
        'status': 'draft',
        'title': 'Trabajo pendiente',
        'presupuestoNumber': null,
        'createdAt': '2026-09-05T12:00:00Z',
      },
      {
        '_id': 'issued-1',
        'presupuestoKind': 'structured',
        'status': 'issued',
        'title': 'Trabajo emitido',
        'presupuestoNumber': '025-26',
        'issueDate': '2026-09-03T12:00:00Z',
      },
      {
        '_id': 'document-1',
        'presupuestoKind': 'document',
        'status': 'draft',
        'title': 'Presupuesto tipo documento',
        'documentTitle': 'Presupuesto tipo documento',
        'templateKey': 'garden_pool_annual_maintenance',
        'createdAt': '2026-09-06T12:00:00Z',
      },
    ]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SizedBox(
            width: 720,
            height: 640,
            child: TelegramIssuedPresupuestoPickerDialog(
              groupId: 'group-1',
              api: api,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Presupuestos'), findsOneWidget);
    expect(find.text('Trabajo pendiente'), findsOneWidget);
    expect(find.text('Trabajo emitido'), findsOneWidget);
    expect(find.text('Presupuesto tipo documento'), findsOneWidget);
    expect(find.text('Borrador'), findsNWidgets(2));
    expect(find.text('Partidas'), findsNWidgets(3));
    expect(find.text('Documento'), findsOneWidget);
    expect(find.text('Emitido'), findsOneWidget);
    expect(find.textContaining('BORRADOR'), findsNWidgets(2));
    expect(find.textContaining('05/09/2026'), findsOneWidget);

    await tester.tap(find.text('Borradores'));
    await tester.pumpAndSettle();

    expect(find.text('Trabajo pendiente'), findsOneWidget);
    expect(find.text('Trabajo emitido'), findsNothing);
    expect(find.text('Presupuesto tipo documento'), findsOneWidget);

    await tester.tap(find.text('Partidas').first);
    await tester.pumpAndSettle();

    expect(find.text('Trabajo pendiente'), findsOneWidget);
    expect(find.text('Presupuesto tipo documento'), findsNothing);

    await tester.tap(find.text('Trabajo pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('¿Enviar borrador?'), findsOneWidget);
    expect(find.text('Enviar borrador'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Presupuestos'), findsOneWidget);
  });

  testWidgets('draft confirmation returns the selected id unchanged',
      (tester) async {
    final api = _FakePresupuestosApi([
      {
        '_id': 'budget/7',
        'presupuestoKind': 'document',
        'status': 'draft',
        'title': 'Propuesta pendiente',
        'presupuestoNumber': null,
        'createdAt': '2026-09-06T12:00:00Z',
      },
    ]);
    TelegramIssuedPresupuestoSelection? selection;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selection = await showTelegramIssuedPresupuestoPickerDialog(
                context,
                groupId: 'group-1',
                api: api,
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Propuesta pendiente'));
    await tester.pumpAndSettle();

    expect(selection, isNull);
    expect(
      find.text(
        'Este presupuesto todavía es un borrador. ¿Quieres enviarlo igualmente?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Enviar borrador'));
    await tester.pumpAndSettle();

    expect(selection?.id, 'budget/7');
    expect(selection?.kind, PresupuestoKind.document);
  });
}

class _FakePresupuestosApi extends PresupuestosApi {
  _FakePresupuestosApi(this.documents);

  final List<Map<String, dynamic>> documents;

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
      documents;
}
