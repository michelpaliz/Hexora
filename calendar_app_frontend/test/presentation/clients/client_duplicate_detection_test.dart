import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';

void main() {
  test('finds a loaded client using a trimmed case-insensitive name', () {
    final clients = [
      GroupClient(id: 'client-1', name: 'Camos Molla Promociones SL'),
    ];

    final match = findClientByTrimmedName(
      clients,
      '  CAMOS MOLLA PROMOCIONES SL  ',
    );

    expect(match?.id, 'client-1');
    expect(match?.name, 'Camos Molla Promociones SL');
  });

  test('does not return an excluded client while editing', () {
    final clients = [
      GroupClient(id: 'client-1', name: 'Existing client'),
    ];

    final match = findClientByTrimmedName(
      clients,
      'Existing client',
      excludeClientId: 'client-1',
    );

    expect(match, isNull);
  });
}
