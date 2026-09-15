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
  bool _isRead;

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
    bool isRead = false,
    this.type = NotificationType.message,
    this.priority = PriorityLevel.medium,
    required this.category,
  })  : _timestamp = timestamp,
        _isRead = isRead;

  DateTime get timestamp => _timestamp;
  bool get isRead => _isRead;
  set isRead(bool value) {
    _isRead = value;
  }

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
        args:
            json['args'] != null ? Map<String, dynamic>.from(json['args']) : {},
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        questionsAndAnswers: json['questionsAndAnswers'] != null
            ? Map<String, String>.from(json['questionsAndAnswers'])
            : {},
        groupId: json['groupId']?.toString() ?? '',
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
        category: _parseEnum<Category>(
          json['category'],
          Category.values,
          Category.message,
        ),
      );
    } catch (e) {
      print('❌ Error parsing NotificationUser from JSON: $e');
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
      'isRead': _isRead,
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
