import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/maps/widgets/azure_maps_document.dart';

void main() {
  test('configures anonymous Azure Maps authentication for tile requests', () {
    final document = buildAzureMapsDocument(
      instanceId: 'map-test',
      clientId: 'maps-account-client-id',
      accessToken: 'Bearer access-token',
      pins: const [],
      selectedPinId: 'client-1',
      selection: null,
      userLocation: null,
    );

    expect(document, contains('authType:atlas.AuthenticationType.anonymous'));
    expect(document, contains('clientId:mapClientId'));
    expect(document, contains("headers:{'x-ms-client-id':mapClientId}"));
    expect(document, contains(r'replace(/^Bearer\s+/i'));
    expect(document, contains("data.action === 'selected-pin'"));
  });
}
