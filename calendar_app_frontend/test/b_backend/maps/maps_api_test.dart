import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/maps/maps_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test('loads a short-lived map token and uses it for address search',
      () async {
    final requests = <http.Request>[];
    final api = MapsApi(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/maps/token')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'accessToken': 'Bearer azure-token',
              'clientId': 'azure-client-id',
              'expiresAt': '2099-09-05T18:00:00Z',
            }),
            200,
          );
        }
        if (request.url.path == '/geocode') {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'type': 'FeatureCollection',
              'features': <Map<String, dynamic>>[
                <String, dynamic>{
                  'geometry': <String, dynamic>{
                    'type': 'Point',
                    'coordinates': <double>[0.1057, 38.8408],
                  },
                  'properties': <String, dynamic>{
                    'address': <String, dynamic>{
                      'formattedAddress': 'Entrada principal, Denia',
                    },
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      }),
    );

    final results = await api.searchAddress('Entrada principal');

    expect(results, hasLength(1));
    expect(results.single.address, 'Entrada principal, Denia');
    expect(results.single.latitude, 38.8408);
    expect(results.single.longitude, 0.1057);
    final geocodeRequest = requests.last;
    expect(geocodeRequest.headers['authorization'], 'Bearer azure-token');
    expect(geocodeRequest.headers['x-ms-client-id'], 'azure-client-id');
    expect(
      requests.where((request) => request.url.path.endsWith('/maps/token')),
      hasLength(1),
    );
  });
}
