class TelegramChatForumInfo {
  const TelegramChatForumInfo({
    required this.isForum,
    this.supergroupId,
    this.viewAsTopics,
    this.raw = const <String, dynamic>{},
  });

  final bool isForum;
  final String? supergroupId;
  final bool? viewAsTopics;
  final Map<String, dynamic> raw;

  factory TelegramChatForumInfo.fromJson(Map<String, dynamic> json) {
    final source = Map<String, dynamic>.from(json);
    return TelegramChatForumInfo(
      isForum: _readBool(source['isForum'] ?? source['is_forum']) ?? false,
      supergroupId: _readString(
        source['supergroupId'] ?? source['supergroup_id'],
      ),
      viewAsTopics: _readBool(
        source['viewAsTopics'] ?? source['view_as_topics'],
      ),
      raw: source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'isForum': isForum,
      'supergroupId': supergroupId,
      'viewAsTopics': viewAsTopics,
    };
  }

  TelegramChatForumInfo copyWith({
    bool? isForum,
    String? supergroupId,
    bool? viewAsTopics,
    Map<String, dynamic>? raw,
  }) {
    return TelegramChatForumInfo(
      isForum: isForum ?? this.isForum,
      supergroupId: supergroupId ?? this.supergroupId,
      viewAsTopics: viewAsTopics ?? this.viewAsTopics,
      raw: raw ?? this.raw,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramChatForumInfo &&
        other.isForum == isForum &&
        other.supergroupId == supergroupId &&
        other.viewAsTopics == viewAsTopics;
  }

  @override
  int get hashCode => Object.hash(isForum, supergroupId, viewAsTopics);
}

class TelegramForumTopic {
  const TelegramForumTopic({
    required this.forumTopicId,
    required this.chatId,
    required this.name,
    this.icon,
    this.creationDate,
    this.isGeneral = false,
    this.isOutgoing = false,
    this.isClosed = false,
    this.isHidden = false,
    this.isNameImplicit = false,
    this.order,
    this.isPinned = false,
    this.unreadCount = 0,
    this.unreadMentionCount = 0,
    this.unreadReactionCount = 0,
    this.lastMessageId,
    this.lastMessageAt,
    this.raw = const <String, dynamic>{},
  });

  final String forumTopicId;
  final String chatId;
  final String name;
  final Map<String, dynamic>? icon;
  final DateTime? creationDate;
  final bool isGeneral;
  final bool isOutgoing;
  final bool isClosed;
  final bool isHidden;
  final bool isNameImplicit;
  final String? order;
  final bool isPinned;
  final int unreadCount;
  final int unreadMentionCount;
  final int unreadReactionCount;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final Map<String, dynamic> raw;

  factory TelegramForumTopic.fromJson(Map<String, dynamic> json) {
    final source = _unwrapTopicJson(json);
    return TelegramForumTopic(
      forumTopicId: _readRequiredString(
        source,
        'forumTopicId',
        fallbackKeys: const ['forum_topic_id', 'topicId', 'topic_id', 'id'],
      ),
      chatId: _readRequiredString(
        source,
        'chatId',
        fallbackKeys: const ['chat_id'],
      ),
      name: _readString(source['name'] ?? source['title']) ?? 'Untitled topic',
      icon: source['icon'] is Map
          ? Map<String, dynamic>.from(source['icon'] as Map)
          : null,
      creationDate: _readDateTime(
        source['creationDate'] ?? source['creation_date'],
      ),
      isGeneral:
          _readBool(source['isGeneral'] ?? source['is_general']) ?? false,
      isOutgoing:
          _readBool(source['isOutgoing'] ?? source['is_outgoing']) ?? false,
      isClosed: _readBool(source['isClosed'] ?? source['is_closed']) ?? false,
      isHidden: _readBool(source['isHidden'] ?? source['is_hidden']) ?? false,
      isNameImplicit: _readBool(
            source['isNameImplicit'] ?? source['is_name_implicit'],
          ) ??
          false,
      order: _readString(source['order']),
      isPinned: _readBool(source['isPinned'] ?? source['is_pinned']) ?? false,
      unreadCount:
          _readInt(source['unreadCount'] ?? source['unread_count']) ?? 0,
      unreadMentionCount: _readInt(
            source['unreadMentionCount'] ?? source['unread_mention_count'],
          ) ??
          0,
      unreadReactionCount: _readInt(
            source['unreadReactionCount'] ?? source['unread_reaction_count'],
          ) ??
          0,
      lastMessageId: _readString(
        source['lastMessageId'] ?? source['last_message_id'],
      ),
      lastMessageAt: _readDateTime(
        source['lastMessageAt'] ?? source['last_message_at'],
      ),
      raw: source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'forumTopicId': forumTopicId,
      'chatId': chatId,
      'name': name,
      'icon': icon,
      'creationDate': creationDate?.toIso8601String(),
      'isGeneral': isGeneral,
      'isOutgoing': isOutgoing,
      'isClosed': isClosed,
      'isHidden': isHidden,
      'isNameImplicit': isNameImplicit,
      'order': order,
      'isPinned': isPinned,
      'unreadCount': unreadCount,
      'unreadMentionCount': unreadMentionCount,
      'unreadReactionCount': unreadReactionCount,
      'lastMessageId': lastMessageId,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }
}

class TelegramForumTopicsResponse {
  const TelegramForumTopicsResponse({
    required this.chatId,
    required this.isForum,
    required this.topics,
    this.totalCount,
    this.nextOffset,
    this.requestId,
  });

  final String chatId;
  final bool isForum;
  final List<TelegramForumTopic> topics;
  final int? totalCount;
  final String? nextOffset;
  final String? requestId;

  factory TelegramForumTopicsResponse.fromJson(Map<String, dynamic> json) {
    final source = _unwrapTopicJson(json);
    final rawTopics = source['topics'] ?? source['items'] ?? source['data'];
    return TelegramForumTopicsResponse(
      chatId: _readRequiredString(
        source,
        'chatId',
        fallbackKeys: const ['chat_id'],
      ),
      isForum: _readBool(source['isForum'] ?? source['is_forum']) ?? false,
      topics: rawTopics is List
          ? rawTopics
              .whereType<Map>()
              .map(
                (entry) => TelegramForumTopic.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList()
          : const <TelegramForumTopic>[],
      totalCount: _readInt(source['totalCount'] ?? source['total_count']),
      nextOffset: _readString(source['nextOffset'] ?? source['next_offset']),
      requestId: _readString(source['requestId'] ?? source['request_id']),
    );
  }
}

extension TelegramForumTopicExt on TelegramForumTopic {
  bool get hasUnread =>
      unreadCount > 0 || unreadMentionCount > 0 || unreadReactionCount > 0;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (isGeneral) return 'General';
    return 'Untitled topic';
  }
}

Map<String, dynamic> _unwrapTopicJson(Map<String, dynamic> json) {
  final nested = json['topic'] ?? json['item'] ?? json['data'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

String _readRequiredString(
  Map<String, dynamic> json,
  String key, {
  List<String> fallbackKeys = const [],
}) {
  final value = _readString(json[key] ?? _readFromFallbacks(json, fallbackKeys));
  if (value == null) {
    throw FormatException('Missing required Telegram topic field: $key');
  }
  return value;
}

String? _readString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool? _readBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

dynamic _readFromFallbacks(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }
  return null;
}
