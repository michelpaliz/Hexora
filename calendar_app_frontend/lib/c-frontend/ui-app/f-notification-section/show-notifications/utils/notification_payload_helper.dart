import 'package:hexora/a-models/notification_model/notification_user.dart';

bool isConcurrentEventNotification(NotificationUser notification) {
  return notification.titleKey == 'notification.event.concurrentCreated.title' ||
      notification.messageKey == 'notification.event.concurrentCreated.message';
}

bool isIssuedDocumentNotification(NotificationUser notification) {
  return const <String>{
        'notification.invoice.issued.title',
        'notification.receipt.issued.title',
        'notification.presupuesto.issued.title',
      }.contains(notification.titleKey) ||
      const <String>{
        'notification.invoice.issued.message',
        'notification.receipt.issued.message',
        'notification.presupuesto.issued.message',
      }.contains(notification.messageKey);
}

enum IssuedDocumentType {
  invoice,
  receipt,
  presupuesto,
  unknown,
}

class ConcurrentEventNotificationData {
  const ConcurrentEventNotificationData({
    required this.senderId,
    required this.senderName,
    required this.eventId,
    required this.eventTitle,
    required this.startDate,
    required this.endDate,
    required this.groupId,
    required this.overlapCount,
    required this.overlappingEventIds,
  });

  final String? senderId;
  final String? senderName;
  final String? eventId;
  final String? eventTitle;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? groupId;
  final int? overlapCount;
  final List<String> overlappingEventIds;
}

class IssuedDocumentNotificationData {
  const IssuedDocumentNotificationData({
    required this.senderId,
    required this.senderName,
    required this.documentType,
    required this.documentId,
    required this.documentNumber,
    required this.clientName,
    required this.amount,
    required this.currency,
    required this.issuedAt,
    required this.groupId,
    required this.alreadyResolvedStatus,
  });

  final String? senderId;
  final String? senderName;
  final IssuedDocumentType documentType;
  final String? documentId;
  final String? documentNumber;
  final String? clientName;
  final double? amount;
  final String? currency;
  final DateTime? issuedAt;
  final String? groupId;
  final String? alreadyResolvedStatus;
}

ConcurrentEventNotificationData concurrentEventNotification(
  NotificationUser notification,
) {
  final args = notification.args;
  final overlapIds = _stringList(args['overlappingEventIds']);
  final overlapCount =
      _readInt(args['overlapCount']) ?? (overlapIds.isNotEmpty ? overlapIds.length : null);
  return ConcurrentEventNotificationData(
    senderId: _readString(args['senderId']) ?? _readString(notification.senderId),
    senderName: _readString(args['createdByName']) ??
        _readString(args['creatorName']) ??
        _readString(args['createdBy']) ??
        _readString(args['ownerName']) ??
        _readString(args['senderName']) ??
        _readString(args['createdByUserName']) ??
        _readString(args['createdByUsername']),
    eventId: _readString(args['eventId']),
    eventTitle: _readString(args['eventTitle']),
    startDate: _readDate(args['startDate']),
    endDate: _readDate(args['endDate']),
    groupId: _readString(args['groupId']) ?? _readString(notification.groupId),
    overlapCount: overlapCount,
    overlappingEventIds: overlapIds,
  );
}

IssuedDocumentNotificationData documentIssuedNotification(
  NotificationUser notification,
) {
  final args = notification.args;
  return IssuedDocumentNotificationData(
    senderId: _readString(args['senderId']) ?? _readString(notification.senderId),
    senderName: _readString(args['senderName']),
    documentType: _readDocumentType(
      _readString(args['documentType']),
      notification.titleKey,
    ),
    documentId: _readString(args['documentId']),
    documentNumber: _readString(args['documentNumber']),
    clientName: _readString(args['clientName']),
    amount: _readDouble(args['amount']),
    currency: _readString(args['currency']),
    issuedAt: _readDate(args['issuedAt']),
    groupId: _readString(args['groupId']) ?? _readString(notification.groupId),
    alreadyResolvedStatus: _readString(args['status']),
  );
}

IssuedDocumentType _readDocumentType(String? raw, String titleKey) {
  final normalized = raw?.trim().toLowerCase();
  switch (normalized) {
    case 'invoice':
    case 'factura':
      return IssuedDocumentType.invoice;
    case 'receipt':
    case 'recibo':
      return IssuedDocumentType.receipt;
    case 'presupuesto':
    case 'budget':
      return IssuedDocumentType.presupuesto;
  }
  if (titleKey.contains('.invoice.')) return IssuedDocumentType.invoice;
  if (titleKey.contains('.receipt.')) return IssuedDocumentType.receipt;
  if (titleKey.contains('.presupuesto.')) return IssuedDocumentType.presupuesto;
  return IssuedDocumentType.unknown;
}

String? _readString(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? null : stringValue;
}

double? _readDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map(_readString)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}
