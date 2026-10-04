import 'package:hexora/models/notifications/notification_user.dart';
import 'notification_payload_helper.dart';

enum NotificationDestination {
  information,
  invitation,
  event,
  document,
  invoiceDraft,
  expenses,
  members,
  group,
  download
}

NotificationDestination resolveNotificationDestination(NotificationUser n) {
  bool key(String stem) =>
      n.titleKey == '$stem.title' || n.messageKey == '$stem.message';
  // Removed resources and revoked access never link back to that resource.
  if ([
        'notification.groupDeleted',
        'notification.groupDeletedAll',
        'notification.userRemoved',
        'notification.event.deleted'
      ].any(key) ||
      n.args['action'] == 'deleted') {
    return NotificationDestination.information;
  }
  if (n.category == Category.groupInvitation ||
      key('notification.invitation')) {
    return NotificationDestination.invitation;
  }
  if (isInvoiceZipNotification(n)) {
    return NotificationDestination.download;
  }
  if (isIssuedDocumentNotification(n)) {
    return NotificationDestination.document;
  }
  if ([
    'notification.recurringInvoice.draftCreated',
    'notification.recurring.invoice.draft.created',
    'notification.recurringDraftInvoice.created'
  ].any(key)) {
    return NotificationDestination.invoiceDraft;
  }
  if ((n.args['eventId']?.toString().trim() ?? '').isNotEmpty) {
    return NotificationDestination.event;
  }
  if ([
    'notification.bankExpensesDetected',
    'notification.bank.expenses.detected'
  ].any(key)) {
    return NotificationDestination.expenses;
  }
  if ([
    'notification.userAccepted',
    'notification.adminUserRemoved',
    'notification.userLeft'
  ].any(key)) {
    return NotificationDestination.members;
  }
  if (key('notification.joinedGroup') ||
      n.category == Category.groupCreation ||
      n.category == Category.groupUpdate) {
    return NotificationDestination.group;
  }
  return NotificationDestination.information;
}
