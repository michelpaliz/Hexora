import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/groups/group.dart';

Group _group({String? photoUrl, String? computedPhotoUrl}) => Group(
      id: 'group-1',
      name: 'Business',
      ownerId: 'owner-1',
      userRoles: const {},
      userIds: const [],
      createdTime: DateTime(2026),
      description: '',
      photoUrl: photoUrl,
      computedPhotoUrl: computedPhotoUrl,
    );

void main() {
  test('saved photo URL takes precedence over an older computed URL', () {
    final group = _group(
      photoUrl: 'https://cdn.example/new.jpg',
      computedPhotoUrl: 'https://cdn.example/old.jpg',
    );

    expect(group.displayPhotoUrl, 'https://cdn.example/new.jpg');
  });

  test('computed photo URL remains the fallback for private storage', () {
    final group = _group(
      photoUrl: '  ',
      computedPhotoUrl: ' https://signed.example/photo.jpg ',
    );

    expect(group.displayPhotoUrl, 'https://signed.example/photo.jpg');
  });
}
