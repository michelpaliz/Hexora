import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

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

class _ConflictClientsApi extends ClientsApi {
  _ConflictClientsApi(this.existingClient);

  final GroupClient existingClient;
  final releaseRequest = Completer<void>();
  int createCalls = 0;

  @override
  Future<GroupClient> create(GroupClient client) async {
    createCalls++;
    await releaseRequest.future;
    throw const ClientsApiException(
      statusCode: 409,
      message: 'Client name already exists in this group',
      responseData: {
        'error': 'Client name already exists in this group',
      },
    );
  }

  @override
  Future<List<GroupClient>> list({
    String? groupId,
    String? search,
    bool? active,
    bool includeCurrentMonthInvoiceFlag = false,
    bool? missingCurrentMonthInvoice,
  }) async =>
      [existingClient];
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(extensions: const [_typography]),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('loaded duplicate offers opening the existing client',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final existing = GroupClient(id: 'client-1', name: 'Cliente Existente');
    GroupClient? opened;

    await tester.pumpWidget(
      _app(
        AddClientSheet(
          groupId: 'group-1',
          api: ClientsApi(),
          existingClients: [existing],
          onOpenExisting: (client) => opened = client,
          closeOnSave: false,
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      '  CLIENTE EXISTENTE  ',
    );
    await tester.ensureVisible(find.text('Guardar cliente'));
    await tester.tap(find.text('Guardar cliente'));
    await tester.pump();

    expect(find.text('Este cliente ya existe.'), findsOneWidget);
    expect(find.text('CLIENTE EXISTENTE'), findsOneWidget);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump();
    expect(opened?.id, 'client-1');
  });

  testWidgets('rapid saves send one request and restore the form after 409',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final existing = GroupClient(id: 'client-1', name: 'Cliente Duplicado');
    final api = _ConflictClientsApi(existing);
    await tester.pumpWidget(
      _app(
        AddClientSheet(
          groupId: 'group-1',
          api: api,
          closeOnSave: false,
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      '  Cliente Duplicado  ',
    );
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(4), 'B12345678');
    await tester.enterText(fields.at(5), 'Calle Uno');
    await tester.enterText(fields.at(10), 'España');

    final saveText = find.text('Guardar cliente');
    await tester.ensureVisible(saveText);
    await tester.tap(saveText);
    await tester.tap(saveText);
    await tester.pump();

    expect(api.createCalls, 1);
    final filledButtons =
        find.byWidgetPredicate((widget) => widget is FilledButton);
    expect(
        tester.widgetList<FilledButton>(filledButtons).last.onPressed, isNull);

    api.releaseRequest.complete();
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe un cliente con este nombre en el grupo.'),
      findsOneWidget,
    );
    expect(find.text('Cliente Duplicado'), findsOneWidget);
    expect(
      tester.widgetList<FilledButton>(filledButtons).last.onPressed,
      isNotNull,
    );
  });
}
