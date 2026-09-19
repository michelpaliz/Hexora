import 'package:hexora/theme/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_compose_screen.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _GroupDomain extends ChangeNotifier implements GroupDomain {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Group? get currentGroup => Group(
      id: 'mobile-group',
      name: 'Group',
      ownerId: 'owner',
      userRoles: {},
      userIds: [],
      createdTime: DateTime(2026),
      description: '');
}

class _ClientsApi extends ClientsApi {
  String? requestedGroup;
  bool fail = false;
  int calls = 0;
  @override
  Future<List<GroupClient>> list(
      {String? groupId,
      String? search,
      bool? active,
      bool includeCurrentMonthInvoiceFlag = false,
      bool? missingCurrentMonthInvoice}) async {
    requestedGroup = groupId;
    calls++;
    if (fail) throw Exception('network failure');
    return [
      GroupClient(
          id: 'client', name: 'Las Alondras', email: 'office@example.com')
    ];
  }
}

Widget _app(_ClientsApi api) => ChangeNotifierProvider<GroupDomain>.value(
      value: _GroupDomain(),
      child: MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          quill.FlutterQuillLocalizations.delegate
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MailComposeScreen(clientsApi: api),
      ),
    );

void main() {
  testWidgets(
      'mobile client picker loads using active group without dashboard provider',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final api = _ClientsApi();
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    expect(api.requestedGroup, 'mobile-group');
    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay clientes'), findsNothing);
    await tester.tap(find.text('Las Alondras'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    final name = find.descendant(
        of: find.byType(Dialog), matching: find.text('Las Alondras'));
    expect(name, findsOneWidget);
    await tester.tap(name);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('office@example.com'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'client load failure offers retry instead of empty client message',
      (tester) async {
    final api = _ClientsApi()..fail = true;
    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar los clientes.'), findsOneWidget);
    expect(find.text('Aún no hay clientes'), findsNothing);
    api.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No se pudieron cargar los clientes.'), findsNothing);
    expect(find.text('Las Alondras'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
