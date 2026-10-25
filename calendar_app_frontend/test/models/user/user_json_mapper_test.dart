import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user/user.dart';

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

  test('copyWith preserves profile fields and only changes requested values',
      () {
    final original = User.fromJson({
      ...profile(),
      'emailVerified': true,
      'bio': 'Maintenance team',
      'phoneNumber': '+34000000000',
      'location': 'Denia',
      'photoUrl': 'https://example.com/avatar.png',
      'photoBlobName': 'avatar.png',
      'groupIds': ['group-1'],
      'sharedCalendars': ['calendar-1'],
      'notifications': ['notification-1'],
      'autoStatementImportEnabled': true,
    });

    expect(original.copyWith().toJson(), original.toJson());
    final changed = original.copyWith(
      name: 'Updated member',
      emailVerified: false,
      autoStatementImportEnabled: false,
    );
    expect(changed.toJson(), {
      ...original.toJson(),
      'name': 'Updated member',
      'emailVerified': false,
      'autoStatementImportEnabled': false,
    });
    expect(original.name, 'Calendar Member');
  });

  test('copyWith can clear optional profile fields', () {
    final original = User.fromJson({
      ...profile(),
      'bio': 'Old bio',
      'phoneNumber': '123',
      'location': 'Denia',
    });

    final cleared = original.copyWith(
      displayName: null,
      bio: null,
      phoneNumber: null,
      location: null,
    );

    expect(cleared.displayName, isNull);
    expect(cleared.bio, isNull);
    expect(cleared.phoneNumber, isNull);
    expect(cleared.location, isNull);
  });
}
