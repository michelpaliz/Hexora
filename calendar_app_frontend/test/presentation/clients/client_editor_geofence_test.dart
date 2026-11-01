import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/add_client_controller.dart';
import 'package:hexora/services/clients/client_api.dart';

void main() {
  test('an unconfigured client does not default to an enabled geofence', () {
    final controller = AddClientController(
      api: ClientsApi(),
      groupId: 'group-1',
    );
    addTearDown(controller.dispose);

    expect(controller.serviceLocationEnabled, isFalse);
  });

  test('zero coordinates cannot be saved as a service location', () {
    final controller = AddClientController(
      api: ClientsApi(),
      groupId: 'group-1',
    );
    addTearDown(controller.dispose);
    controller.serviceLatitude.text = '0';
    controller.serviceLongitude.text = '0';
    controller.serviceRadius.text = '75';

    expect(controller.serviceLocationValidationError(), contains('0,0'));

    controller.serviceLatitude.text = '38.8401';
    controller.serviceLongitude.text = '0.1057';
    expect(controller.serviceLocationValidationError(), isNull);
  });
}
