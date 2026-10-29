import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_client_step.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  final clients = <GroupClient>[
    GroupClient(id: 'client-1', name: 'Alqueria', email: 'a@example.com'),
    GroupClient(id: 'client-2', name: 'Belman'),
  ];

  Widget app(Widget child) => MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox.expand(child: child)),
      );

  testWidgets('switches modes and keeps existing and manual client values',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(_ClientStepHarness(clients: clients)));
    expect(find.text('Alqueria'), findsOneWidget);

    await tester.tap(find.text('Alqueria'));
    await tester.pump();
    expect(find.text('DETAIL-client-1'), findsOneWidget);

    await tester.tap(find.text('Cliente manual').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Cliente temporal');
    await tester.enterText(find.byType(TextField).at(1), 'Calle Mar 1');

    await tester.tap(find.text('Cliente existente').last);
    await tester.pumpAndSettle();
    expect(find.text('DETAIL-client-1'), findsOneWidget);

    await tester.tap(find.text('Cliente manual').last);
    await tester.pumpAndSettle();
    expect(find.text('Cliente temporal'), findsOneWidget);
    expect(find.text('Calle Mar 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual mode supports optional fields and validation feedback',
      (tester) async {
    final name = TextEditingController();
    final address = TextEditingController();
    final city = TextEditingController();
    final postal = TextEditingController();
    addTearDown(name.dispose);
    addTearDown(address.dispose);
    addTearDown(city.dispose);
    addTearDown(postal.dispose);

    await tester.pumpWidget(app(DocumentClientStep(
      clients: clients,
      selectedClientId: null,
      onClientChanged: (_) {},
      mode: DocumentClientMode.manual,
      onModeChanged: (_) {},
      selectedDetails: null,
      manual: DocumentManualClientConfig(
        nameController: name,
        addressController: address,
        cityController: city,
        postalCodeController: postal,
        nameErrorText: 'Nombre obligatorio',
        onChanged: () {},
      ),
    )));

    expect(find.text('Nombre obligatorio'), findsOneWidget);
    expect(find.text('Dirección'), findsOneWidget);
    expect(find.text('Ciudad'), findsOneWidget);
    expect(find.text('CP'), findsOneWidget);
    expect(find.text('DETAIL-client-1'), findsNothing);
  });

  testWidgets('existing mode adapts to a narrow one-column viewport',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final manualName = TextEditingController();
    addTearDown(manualName.dispose);
    await tester.pumpWidget(app(DocumentClientStep(
      clients: clients,
      selectedClientId: 'client-1',
      onClientChanged: (_) {},
      mode: DocumentClientMode.existing,
      onModeChanged: (_) {},
      selectedDetails: const Center(child: Text('DETAIL-client-1')),
      manual: DocumentManualClientConfig(
        nameController: manualName,
        onChanged: () {},
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Alqueria'), findsOneWidget);
    expect(find.text('DETAIL-client-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finds clients by PDF alias and shows canonical metadata',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final aliasClients = <GroupClient>[
      GroupClient(
        id: 'client-alias',
        name: 'Comunidad Legal Norte',
        pdfAlias: 'Residencial Norte',
        customerType: 'community',
        propertyType: 'building',
      ),
      GroupClient(id: 'client-other', name: 'Cliente diferente'),
    ];

    await tester.pumpWidget(app(DocumentClientStep(
      clients: aliasClients,
      selectedClientId: null,
      onClientChanged: (_) {},
      mode: DocumentClientMode.existing,
      onModeChanged: (_) {},
      selectedDetails: null,
      allowManual: false,
    )));

    expect(find.textContaining('Residencial Norte'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'residencial norte');
    await tester.pump();

    expect(find.text('Comunidad Legal Norte'), findsOneWidget);
    expect(find.text('Cliente diferente'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _ClientStepHarness extends StatefulWidget {
  const _ClientStepHarness({required this.clients});

  final List<GroupClient> clients;

  @override
  State<_ClientStepHarness> createState() => _ClientStepHarnessState();
}

class _ClientStepHarnessState extends State<_ClientStepHarness> {
  final name = TextEditingController();
  final address = TextEditingController();
  final city = TextEditingController();
  final postal = TextEditingController();
  DocumentClientMode mode = DocumentClientMode.existing;
  String? selectedId;

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    city.dispose();
    postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DocumentClientStep(
        clients: widget.clients,
        selectedClientId: selectedId,
        onClientChanged: (value) => setState(() => selectedId = value),
        mode: mode,
        onModeChanged: (value) => setState(() => mode = value),
        selectedDetails: selectedId == null
            ? null
            : Center(child: Text('DETAIL-$selectedId')),
        manual: DocumentManualClientConfig(
          nameController: name,
          addressController: address,
          cityController: city,
          postalCodeController: postal,
          onChanged: () => setState(() {}),
        ),
      );
}
