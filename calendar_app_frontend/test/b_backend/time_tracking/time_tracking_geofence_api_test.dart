import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/time_tracking_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('implements the complete geofenced visit API flow', () async {
    final requests = <http.Request>[];
    final api = TimeTrackingApiClient(
      client: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        if (path.endsWith('/location-tracking/start')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'trackingSession': <String, dynamic>{'id': 'session-1'},
            }),
            201,
          );
        }
        if (path.endsWith('/client-locations')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'locations': <Map<String, dynamic>>[
                <String, dynamic>{
                  'clientId': 'client-1',
                  'clientName': 'Piscina principal',
                  'latitude': 38.8401,
                  'longitude': 0.1057,
                  'radiusMeters': 75,
                  'isEnabled': true,
                },
                <String, dynamic>{
                  'clientId': 'client-disabled',
                  'latitude': 1,
                  'longitude': 1,
                  'radiusMeters': 50,
                  'isEnabled': false,
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/location-events')) {
          return http.Response('{}', 201);
        }
        if (path.endsWith('/session-1/stop')) {
          return http.Response('', 204);
        }
        if (path.endsWith('/worker-visits')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'visits': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'visit-1',
                  'clientId': 'client-1',
                  'arrivedAt': '2026-09-04T08:32:00Z',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      }),
    );

    final session = await api.startLocationTracking(
      'group-1',
      'token-1',
      deviceId: 'phone-1',
      platform: 'android',
    );
    final locations = await api.getClientLocations('group-1', 'token-1');
    final event = LocationBoundaryEvent(
      trackingSessionId: session.id,
      eventId: 'event-1',
      clientId: 'client-1',
      eventType: 'arrival',
      latitude: 38.8401,
      longitude: 0.1057,
      accuracyMeters: 18,
      recordedAt: DateTime.utc(2026, 9, 4, 8, 32),
    );
    await api.sendLocationEvent('group-1', 'token-1', event);
    await api.stopLocationTracking('group-1', session.id, 'token-1');
    final visits = await api.getWorkerVisits(
      'group-1',
      'token-1',
      from: DateTime.utc(2026, 9, 1),
      to: DateTime.utc(2026, 10, 1),
      workerId: 'worker-1',
    );

    expect(session.id, 'session-1');
    expect(locations.map((item) => item.clientId), <String>['client-1']);
    expect(visits.single.id, 'visit-1');
    expect(
      requests.map((request) => request.url.path),
      <String>[
        '/api/groups/group-1/time-tracking/location-tracking/start',
        '/api/groups/group-1/time-tracking/client-locations',
        '/api/groups/group-1/time-tracking/location-events',
        '/api/groups/group-1/time-tracking/location-tracking/session-1/stop',
        '/api/groups/group-1/time-tracking/worker-visits',
      ],
    );
    expect(jsonDecode(requests[0].body), <String, dynamic>{
      'deviceId': 'phone-1',
      'platform': 'android',
    });
    expect(jsonDecode(requests[2].body), event.toJson());
    expect(
        requests[4].url.queryParameters, containsPair('workerId', 'worker-1'));
    expect(
        requests.every(
            (request) => request.headers['Authorization'] == 'Bearer token-1'),
        isTrue);
  });
}
