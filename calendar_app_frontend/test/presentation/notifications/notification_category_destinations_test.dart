import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/notifications/notification_user.dart';
import 'package:hexora/presentation/enums/category/broad_category.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_category_meta.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_destination.dart';
import 'package:hexora/presentation/screens/notifications/show-notifications/utils/notification_payload_helper.dart';

NotificationUser notice(Category category,
        {String key = '', Map<String, dynamic> args = const {}}) =>
    NotificationUser.fromJson(
        {'id': 'n', 'category': category.index, 'titleKey': key, 'args': args});
void main() {
  test('legacy activity categories resolve from notification keys', () {
    for (final entry in <String, (int, Category)>{
      'notification.invoice.issued': (5, Category.billing),
      'notification.event.concurrentCreated': (6, Category.actionRequired),
      'notification.bankExpensesDetected': (7, Category.systemUpdate),
      'notification.recurringInvoice.draftCreated': (8, Category.billing),
    }.entries) {
      final notification = NotificationUser.fromJson({
        'id': 'legacy',
        'titleKey': '${entry.key}.title',
        'category': entry.value.$1,
      });
      expect(notification.category, entry.value.$2, reason: entry.key);
    }
  });

  test('routine activity uses document and banking icons, not warning icons',
      () {
    const colors = ColorScheme.light();
    final draft = notice(Category.systemAlert,
        key: 'notification.recurringInvoice.draftCreated.title');
    final bank = notice(Category.message,
        key: 'notification.bankExpensesDetected.title');
    expect(resolveNotifMeta(draft, colors).icon, Icons.receipt_long_rounded);
    expect(resolveNotifMeta(bank, colors).icon,
        Icons.account_balance_wallet_outlined);
  });

  const expectations = {
    Category.groupCreation: (
      BroadCategory.group,
      NotificationDestination.group
    ),
    Category.groupUpdate: (BroadCategory.group, NotificationDestination.group),
    Category.groupInvitation: (
      BroadCategory.group,
      NotificationDestination.invitation
    ),
    Category.userRemoval: (
      BroadCategory.user,
      NotificationDestination.information
    ),
    Category.userInvitation: (
      BroadCategory.user,
      NotificationDestination.information
    ),
    Category.message: (BroadCategory.user, NotificationDestination.information),
    Category.systemAlert: (
      BroadCategory.system,
      NotificationDestination.information
    ),
    Category.systemUpdate: (
      BroadCategory.system,
      NotificationDestination.information
    ),
    Category.errorReport: (
      BroadCategory.system,
      NotificationDestination.information
    ),
    Category.eventReminder: (
      BroadCategory.other,
      NotificationDestination.information
    ),
    Category.eventStarted: (
      BroadCategory.other,
      NotificationDestination.information
    ),
    Category.taskUpdate: (
      BroadCategory.other,
      NotificationDestination.information
    ),
    Category.achievement: (
      BroadCategory.other,
      NotificationDestination.information
    ),
    Category.billing: (
      BroadCategory.other,
      NotificationDestination.information
    ),
    Category.actionRequired: (
      BroadCategory.other,
      NotificationDestination.information
    ),
    Category.feedbackRequest: (
      BroadCategory.other,
      NotificationDestination.information
    ),
  };
  test('every category has an explicit tab and safe default action', () {
    expect(expectations.keys.toSet(), Category.values.toSet());
    for (final entry in expectations.entries) {
      final n = notice(entry.key);
      expect(resolveBroadCategoryForNotification(n), entry.value.$1,
          reason: '${entry.key}');
      expect(resolveNotificationDestination(n), entry.value.$2,
          reason: '${entry.key}');
    }
  });
  test('deleted resources and revoked membership never open stale destinations',
      () {
    for (final stem in [
      'groupDeleted',
      'groupDeletedAll',
      'userRemoved',
      'event.deleted'
    ]) {
      expect(
          resolveNotificationDestination(notice(Category.groupUpdate,
              key: 'notification.$stem.title', args: {'eventId': 'old'})),
          NotificationDestination.information);
    }
  });
  test(
      'member activity opens members while legacy invitation remains actionable',
      () {
    for (final stem in ['userAccepted', 'adminUserRemoved', 'userLeft']) {
      expect(
          resolveNotificationDestination(
              notice(Category.message, key: 'notification.$stem.title')),
          NotificationDestination.members);
    }
    expect(
        resolveNotificationDestination(notice(Category.userInvitation,
            key: 'notification.invitation.title')),
        NotificationDestination.invitation);
  });
  test('all document types preserve document and group IDs', () {
    for (final entry in {
      'invoice': IssuedDocumentType.invoice,
      'receipt': IssuedDocumentType.receipt,
      'presupuesto': IssuedDocumentType.presupuesto
    }.entries) {
      final n = notice(Category.systemAlert,
          key: 'notification.${entry.key}.issued.title',
          args: {'documentId': 'doc-1', 'groupId': 'group-1'});
      expect(
          resolveNotificationDestination(n), NotificationDestination.document);
      expect(resolveBroadCategoryForNotification(n), BroadCategory.other);
      final data = documentIssuedNotification(n);
      expect(data.documentType, entry.value);
      expect(data.documentId, 'doc-1');
      expect(data.groupId, 'group-1');
    }
  });
  test(
      'event, expense, recurring draft and ZIP payloads select their destination',
      () {
    expect(
        resolveNotificationDestination(
            notice(Category.systemAlert, args: {'eventId': 'event'})),
        NotificationDestination.event);
    for (final stem in [
      'bankExpensesDetected',
      'bank.expenses.detected',
      'suspectExpenses.detected',
      'statement.expenseDetected'
    ]) {
      expect(
          resolveNotificationDestination(
              notice(Category.systemAlert, key: 'notification.$stem.title')),
          NotificationDestination.expenses);
    }
    for (final stem in [
      'recurringInvoice.draftCreated',
      'recurring.invoice.draft.created',
      'recurringDraftInvoice.created'
    ]) {
      expect(
          resolveNotificationDestination(
              notice(Category.billing, key: 'notification.$stem.title')),
          NotificationDestination.invoiceDraft);
    }
    expect(
        resolveNotificationDestination(
            notice(Category.systemAlert, args: {'jobType': 'invoice_zip'})),
        NotificationDestination.download);
  });
}
