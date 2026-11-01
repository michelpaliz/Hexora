import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/business_chat/business_chat_api.dart';

void main() {
  test('business chat member parses presence and last active timestamp', () {
    final member = BusinessChatMember.fromJson({
      'id': 'member-1',
      'name': 'Ana',
      'isOnline': true,
      'photoUrl': 'https://example.com/ana.png',
      'lastActiveAt': '2026-11-01T18:30:00.000Z',
    });

    expect(member.id, 'member-1');
    expect(member.name, 'Ana');
    expect(member.isOnline, isTrue);
    expect(member.photoUrl, 'https://example.com/ana.png');
    expect(member.lastActiveAt, DateTime.utc(2026, 11, 1, 18, 30));
  });

  test('business chat member tolerates missing optional presence fields', () {
    final member = BusinessChatMember.fromJson({
      'id': 'member-2',
      'name': 'Luis',
      'isOnline': false,
    });

    expect(member.isOnline, isFalse);
    expect(member.photoUrl, isNull);
    expect(member.lastActiveAt, isNull);
  });
}
