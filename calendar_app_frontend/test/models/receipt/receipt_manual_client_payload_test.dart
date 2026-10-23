import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/models/receipt/receipt.dart';

void main() {
  const snapshot = ClientBilling(
    legalName: 'Cliente temporal',
    addressStreet: 'Calle Mar 1',
    addressCity: 'Almería',
    addressPostalCode: '04001',
    documentType: 'receipt',
  );

  const receipt = Receipt(
    id: 'receipt-1',
    groupId: 'group-1',
    clientId: '',
    clientName: 'Cliente temporal',
    clientSnapshot: snapshot,
    status: 'draft',
  );

  test('manual client address is preserved in create and update payloads', () {
    for (final payload in [
      receipt.toCreatePayload(),
      receipt.toUpdatePayload(),
    ]) {
      expect(payload['clientId'], isNull);
      expect(payload['clientName'], 'Cliente temporal');
      expect(payload['clientSnapshot'], {
        'legalName': 'Cliente temporal',
        'addressStreet': 'Calle Mar 1',
        'addressCity': 'Almería',
        'addressPostalCode': '04001',
        'documentType': 'receipt',
      });
    }
  });

  test('manual client address is restored from a saved receipt', () {
    final restored = Receipt.fromJson({
      '_id': 'receipt-1',
      'groupId': 'group-1',
      'clientId': '',
      'clientName': 'Cliente temporal',
      'clientSnapshot': snapshot.toJson(),
    });

    expect(restored.clientSnapshot?.addressStreet, 'Calle Mar 1');
    expect(restored.clientSnapshot?.addressCity, 'Almería');
    expect(restored.clientSnapshot?.addressPostalCode, '04001');
  });
}
