import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/invoice/client_billing.dart';

void main() {
  const billing = ClientBilling(
    legalName: 'Client Co',
    email: 'accounts@client.test',
    phone: '+34 600 000 000',
    isComplete: true,
  );

  test('copyWith preserves, sets, and explicitly clears nullable fields', () {
    final unchanged = billing.copyWith();
    final set = billing.copyWith(email: 'new@client.test');
    final cleared = billing.copyWith(phone: null, isComplete: null);

    expect(unchanged.phone, billing.phone);
    expect(unchanged.isComplete, isTrue);
    expect(
      unchanged.toPayload(),
      containsPair('email', 'accounts@client.test'),
    );
    expect(set.email, 'new@client.test');
    expect(set.toPayload(), containsPair('email', 'new@client.test'));
    expect(cleared.phone, isNull);
    expect(cleared.isComplete, isNull);
    expect(cleared.toPayload(includeNulls: true), containsPair('phone', isNull));
  });
}
