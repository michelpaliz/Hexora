import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';

void main() {
  const profile = BillingProfile(
    id: 'billing-1',
    groupId: 'group-1',
    legalName: 'Acme Ltd',
    taxId: 'ES-A1',
    logoUrl: 'https://example.test/logo.png',
    email: 'billing@acme.test',
    isComplete: true,
  );

  test('copyWith preserves, sets, and explicitly clears nullable fields', () {
    final unchanged = profile.copyWith();
    final set = profile.copyWith(email: 'accounts@acme.test');
    final cleared = profile.copyWith(logoUrl: null, isComplete: null);

    expect(unchanged.logoUrl, profile.logoUrl);
    expect(unchanged.isComplete, isTrue);
    expect(
      unchanged.toPayload(),
      containsPair('email', 'billing@acme.test'),
    );
    expect(set.email, 'accounts@acme.test');
    expect(set.toPayload(), containsPair('email', 'accounts@acme.test'));
    expect(cleared.logoUrl, isNull);
    expect(cleared.isComplete, isNull);
    expect(cleared.toPayload(), containsPair('logoUrl', isNull));
  });
}
