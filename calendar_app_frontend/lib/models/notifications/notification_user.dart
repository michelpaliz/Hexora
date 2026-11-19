import 'package:flutter/foundation.dart' show debugPrint;

enum NotificationType { alert, reminder, message, update }

enum PriorityLevel { low, medium, high }

enum Category {
  groupCreation,
  groupUpdate,
  groupInvitation,
  userRemoval,
  userInvitation,
  eventReminder,
  taskUpdate,
  message,
  systemAlert,
  actionRequired,
  achievement,
  billing,
  systemUpdate,
  feedbackRequest,
  errorReport,
  // Wire category 15, emitted when an event transitions to started.
  eventStarted,
}

class NotificationUser {
  final String id;
  final String senderId;
  final String recipientId;

  // Localized keys
  final String titleKey;
  final String messageKey;

  // Fallbacks
  final String fallbackTitle;
  final String fallbackMessage;

  final Map<String, dynamic> args; // ✅ for {groupName}, etc.
  final DateTime _timestamp;
  final Map<String, String> questionsAndAnswers;
  final String groupId;
  bool isRead;

  final NotificationType type;
  final PriorityLevel priority;
  final Category category;

  NotificationUser({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.titleKey,
    required this.messageKey,
    required this.fallbackTitle,
    required this.fallbackMessage,
    required this.args,
    required DateTime timestamp,
    this.questionsAndAnswers = const {},
    required this.groupId,
    this.isRead = false,
    this.type = NotificationType.message,
    this.priority = PriorityLevel.medium,
    required this.category,
  }) : _timestamp = timestamp;

  DateTime get timestamp => _timestamp;

  factory NotificationUser.fromJson(Map<String, dynamic> json) {
    try {
      return NotificationUser(
        id: json['id'] ?? json['_id'] ?? '',
        senderId: json['senderId'] ?? '',
        recipientId: json['recipientId'] ?? '',
        titleKey: json['titleKey'] ?? '',
        messageKey: json['messageKey'] ?? '',
        fallbackTitle: json['fallbackTitle'] ?? '',
        fallbackMessage: json['fallbackMessage'] ?? '',
        args: _notificationArgs(json),
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        questionsAndAnswers: json['questionsAndAnswers'] != null
            ? Map<String, String>.from(json['questionsAndAnswers'])
            : {},
        groupId: (json['groupId'] ??
                (json['args'] is Map
                    ? (json['args'] as Map)['groupId']
                    : null) ??
                '')
            .toString(),
        isRead: json['isRead'] ?? false,

        // ✅ Robust enum parsing for type
        type: _parseEnum<NotificationType>(
          json['type'],
          NotificationType.values,
          NotificationType.message,
        ),

        // ✅ Robust enum parsing for priority
        priority: _parseEnum<PriorityLevel>(
          json['priority'],
          PriorityLevel.values,
          PriorityLevel.medium,
        ),

        // ✅ Robust enum parsing for category
        category: _parseNotificationCategory(json),
      );
    } catch (e) {
      debugPrint('❌ Error parsing NotificationUser from JSON: $e');
      return NotificationUser(
        id: '',
        senderId: '',
        recipientId: '',
        titleKey: '',
        messageKey: '',
        fallbackTitle: 'Unknown',
        fallbackMessage: 'Error in notification',
        args: {},
        timestamp: DateTime.now(),
        questionsAndAnswers: {},
        groupId: '',
        isRead: false,
        type: NotificationType.message,
        priority: PriorityLevel.medium,
        category: Category.message,
      );
    }
  }

  Map<String, dynamic> toJson() {
    final map = {
      'senderId': senderId,
      'recipientId': recipientId,
      'titleKey': titleKey,
      'messageKey': messageKey,
      'fallbackTitle': fallbackTitle,
      'fallbackMessage': fallbackMessage,
      'args': args,
      'timestamp': _timestamp.toIso8601String(),
      'questionsAndAnswers': questionsAndAnswers,
      'groupId': groupId,
      'isRead': isRead,
      'type': type.index,
      'priority': priority.index,
      'category': category.index,
    };

    if (id.isNotEmpty) {
      map['_id'] = id;
    }

    return map;
  }

  Map<String, dynamic> toJsonForCreation() {
    final map = toJson();
    map.remove('_id');
    return map;
  }
}

Map<String, dynamic> _notificationArgs(Map<String, dynamic> json) {
  final args = json['args'] is Map
      ? Map<String, dynamic>.from(json['args'] as Map)
      : <String, dynamic>{};
  // Invitation payloads have existed in both top-level and args-based forms.
  // Normalize them so every notification surface uses the same action path.
  for (final key in const [
    'invitationId',
    'inviteId',
    'invitation_id',
    'invitation',
    'groupId',
  ]) {
    if (!args.containsKey(key) && json[key] != null) args[key] = json[key];
  }
  return args;
}

Category _parseNotificationCategory(Map<String, dynamic> json) {
  final titleKey = (json['titleKey'] ?? '').toString();
  final messageKey = (json['messageKey'] ?? '').toString();
  bool hasKey(String stem) =>
      titleKey == '$stem.title' || messageKey == '$stem.message';

  // Earlier activity notifications used numeric categories that conflict with
  // the shared wire enum. Use their stable localization keys for old records.
  if (const [
    'notification.invoice.issued',
    'notification.receipt.issued',
    'notification.presupuesto.issued',
    'notification.recurringInvoice.draftCreated',
    'notification.recurring.invoice.draft.created',
    'notification.recurringDraftInvoice.created',
  ].any(hasKey)) {
    return Category.billing;
  }
  if (const [
    'notification.bankExpensesDetected',
    'notification.bank.expenses.detected',
    'notification.suspectExpenses.detected',
    'notification.statement.expenseDetected',
  ].any(hasKey)) {
    return Category.systemUpdate;
  }
  if (hasKey('notification.event.concurrentCreated')) {
    return Category.actionRequired;
  }
  return _parseEnum<Category>(
    json['category'],
    Category.values,
    Category.message,
  );
}

T _parseEnum<T>(dynamic value, List<T> enumValues, T fallback) {
  if (value is int && value >= 0 && value < enumValues.length) {
    return enumValues[value];
  } else if (value is String) {
    try {
      return enumValues.firstWhere(
        (e) => e.toString().split('.').last == value,
        orElse: () => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }
  return fallback;
}
