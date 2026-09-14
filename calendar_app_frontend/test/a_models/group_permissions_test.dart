import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/group/group_permissions.dart';

void main() {
  final testGroup = Group(
    id: 'group-1',
    name: 'Test group',
    ownerId: 'owner',
    userRoles: const {
      'admin': 'admin',
      'co-admin': 'co-admin',
      'member': 'member',
      'unknown': 'future-role',
    },
    userIds: const ['owner', 'admin', 'co-admin', 'member', 'unknown'],
    createdTime: DateTime.utc(2026),
    description: '',
  );

  group('GroupPermissions', () {
    test('resolves owner, admin, co-admin, member, and unknown roles', () {
      expect(
        GroupPermissions.roleFor(testGroup, 'owner'),
        GroupMemberRole.owner,
      );
      expect(
        GroupPermissions.roleFor(testGroup, 'admin'),
        GroupMemberRole.admin,
      );
      expect(
        GroupPermissions.roleFor(testGroup, 'co-admin'),
        GroupMemberRole.coAdmin,
      );
      expect(
        GroupPermissions.roleFor(testGroup, 'member'),
        GroupMemberRole.member,
      );
      expect(
        GroupPermissions.roleFor(testGroup, 'unknown'),
        GroupMemberRole.member,
      );
    });

    test('grants group management only to management roles', () {
      for (final userId in ['owner', 'admin', 'co-admin']) {
        expect(GroupPermissions.canManageGroup(testGroup, userId), isTrue);
        expect(GroupPermissions.canAddEvents(testGroup, userId), isTrue);
        expect(GroupPermissions.canEditGroup(testGroup, userId), isTrue);
        expect(GroupPermissions.canManageInvoices(testGroup, userId), isTrue);
      }

      for (final userId in ['member', 'unknown']) {
        expect(GroupPermissions.canManageGroup(testGroup, userId), isFalse);
        expect(GroupPermissions.canAddEvents(testGroup, userId), isFalse);
        expect(GroupPermissions.canEditGroup(testGroup, userId), isFalse);
        expect(GroupPermissions.canManageInvoices(testGroup, userId), isFalse);
      }
    });

    test('limits invoice email sending to owner and co-admin', () {
      expect(GroupPermissions.canSendInvoiceEmails(testGroup, 'owner'), isTrue);
      expect(GroupPermissions.canSendInvoiceEmails(testGroup, 'admin'), isFalse);
      expect(
        GroupPermissions.canSendInvoiceEmails(testGroup, 'co-admin'),
        isTrue,
      );
      expect(GroupPermissions.canSendInvoiceEmails(testGroup, 'member'), isFalse);
      expect(
        GroupPermissions.canSendInvoiceEmails(testGroup, 'unknown'),
        isFalse,
      );
    });
  });
}
