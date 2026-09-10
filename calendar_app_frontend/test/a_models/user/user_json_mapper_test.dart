import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/user_model/user.dart';

void main() {
  Map<String, dynamic> profile({Object? email = 'member@example.com'}) => {
        '_id': 'user-123',
        'name': 'Calendar Member',
        'displayName': 'Member',
        'userName': 'calendar_member',
        'email': email,
      };

  test('accepts a privacy-redacted group member email', () {
    final user = User.fromJson(profile(email: null));

    expect(user.id, 'user-123');
    expect(user.email, isEmpty);
    expect(user.userName, 'calendar_member');
  });

  test('accepts alternate email field names', () {
    final json = profile(email: null)..['emailAddress'] = 'member@example.com';

    final user = User.fromJson(json);

    expect(user.email, 'member@example.com');
  });

  test('keeps identity fields required', () {
    final json = profile(email: null)..remove('_id');

    expect(() => User.fromJson(json), throwsFormatException);
  });
}
