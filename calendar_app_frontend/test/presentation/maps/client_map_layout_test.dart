import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/time_tracking/geofenced_visit.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/maps/maps_api.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/time_tracking/api/i_time_tracking_api_client.dart';
import 'package:hexora/presentation/screens/workspace/sections/maps/client_map_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/maps/widgets/azure_maps_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';

class _User extends ChangeNotifier implements UserDomain {
  @override
  Future<String> getAuthToken({bool forceRefresh = false}) async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Maps extends MapsApi {
  @override
  Future<AzureMapsToken> getToken({bool forceRefresh = false}) async =>
      AzureMapsToken(
          accessToken: 'test', clientId: 'test', expiresAt: DateTime(2099));
}

class _Clients extends ClientsApi {
  @override
  Future<List<GroupClient>> list(
          {String? groupId,
          String? search,
          bool? active,
          bool includeCurrentMonthInvoiceFlag = false,
          bool? missingCurrentMonthInvoice}) async =>
      [
        GroupClient(id: 'located', name: 'Alqueria'),
        GroupClient(id: 'missing', name: 'Sin dirección'),
      ];
}

class _Visits implements ITimeTrackingApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getClientLocations) {
      return Future.value(<ClientServiceLocation>[
        const ClientServiceLocation(
            clientId: 'located',
            latitude: 38.8,
            longitude: .1,
            radiusMeters: 75,
            label: 'Calle principal'),
      ]);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  for (final width in [390.0, 1500.0]) {
    testWidgets('map selection, filters and panel at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (_) async => false);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<UserDomain>(create: (_) => _User()),
            Provider<ITimeTrackingApiClient>(create: (_) => _Visits()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ClientMapScreen(
              group: Group(
                  id: 'g',
                  name: 'Group',
                  ownerId: 'u',
                  userRoles: {},
                  userIds: [],
                  createdTime: DateTime(2026),
                  description: ''),
              mapsApi: _Maps(),
              clientsApi: _Clients(),
            ),
          )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      AzureMapsView map() =>
          tester.widget<AzureMapsView>(find.byType(AzureMapsView));
      expect(map().darkMode, isTrue);
      map().onPinTapped('located');
      await tester.pumpAndSettle();
      expect(map().selectedPinId, 'located');
      expect(map().cameraTarget?.latitude, 38.8);
      await tester.tap(find.byTooltip('Clientes'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsNothing);
      await tester.tap(find.byTooltip('Clientes'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .onChanged!('missing');
      await tester.pumpAndSettle();
      expect(find.text('Alqueria'), findsNothing);
      expect(find.text('Sin dirección'), findsOneWidget);
      map().onPinTapped('located');
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<DropdownButton<String>>(
                  find.byType(DropdownButton<String>))
              .value,
          'all');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
