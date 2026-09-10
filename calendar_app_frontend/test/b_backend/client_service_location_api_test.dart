import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('client JSON keeps the service location without helper fields', () {
    final json = GroupClient(
      id: 'client-1',
      name: 'Piscina principal',
      serviceLocation: const ClientServiceLocation(
        clientId: 'client-1',
        clientName: 'Piscina principal',
        latitude: 38.8401,
        longitude: 0.1057,
        radiusMeters: 75,
      ),
    ).toJson();

    expect(json['id'], 'client-1');
    expect(json['serviceLocation'], <String, dynamic>{
      'latitude': 38.8401,
      'longitude': 0.1057,
      'radiusMeters': 75.0,
      'isEnabled': true,
    });
  });

  test('updates the pinned client service location', () async {
    late http.Request captured;
    final api = ClientsApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'serviceLocation': <String, dynamic>{
              'latitude': 38.8401,
              'longitude': 0.1057,
              'radiusMeters': 75,
              'label': 'Entrada principal',
              'isEnabled': true,
            },
          }),
          200,
        );
      }),
    );
    const location = ClientServiceLocation(
      clientId: 'client-1',
      latitude: 38.8401,
      longitude: 0.1057,
      radiusMeters: 75,
      label: 'Entrada principal',
    );

    final result = await api.updateServiceLocation('client-1', location);

    expect(captured.method, 'PATCH');
    expect(captured.url.path, endsWith('/clients/client-1/service-location'));
    expect(jsonDecode(captured.body), <String, dynamic>{
      'latitude': 38.8401,
      'longitude': 0.1057,
      'radiusMeters': 75.0,
      'label': 'Entrada principal',
      'isEnabled': true,
    });
    expect(result.clientId, 'client-1');
    expect(result.label, 'Entrada principal');
  });

  test('clears the pinned client service location', () async {
    late http.Request captured;
    final api = ClientsApi(
      client: MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      }),
    );

    await api.clearServiceLocation('client id');

    expect(captured.method, 'PATCH');
    expect(
      captured.url.path,
      endsWith('/clients/client%20id/service-location'),
    );
    expect(jsonDecode(captured.body), const <String, dynamic>{'clear': true});
  });
}
