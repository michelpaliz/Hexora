import 'telegram_topic.dart';

class TelegramChatListState {
  const TelegramChatListState({
    required this.isArchived,
    this.inMainList,
    this.inArchiveList,
    this.mainOrder,
    this.archiveOrder,
    this.mainPinned = false,
    this.archivePinned = false,
    this.raw = const <String, dynamic>{},
  });

  final bool isArchived;
  final bool? inMainList;
  final bool? inArchiveList;
  final String? mainOrder;
  final String? archiveOrder;
  final bool mainPinned;
  final bool archivePinned;
  final Map<String, dynamic> raw;

  factory TelegramChatListState.fromJson(Map<String, dynamic> json) {
    final source = Map<String, dynamic>.from(json);
    return TelegramChatListState(
      isArchived:
          _readBool(source['isArchived'] ?? source['is_archived']) ?? false,
      inMainList: _readBool(source['inMainList'] ?? source['in_main_list']),
      inArchiveList:
          _readBool(source['inArchiveList'] ?? source['in_archive_list']),
      mainOrder: _readString(source['mainOrder'] ?? source['main_order']),
      archiveOrder:
          _readString(source['archiveOrder'] ?? source['archive_order']),
      mainPinned:
          _readBool(source['mainPinned'] ?? source['main_pinned']) ?? false,
      archivePinned: _readBool(
            source['archivePinned'] ?? source['archive_pinned'],
          ) ??
          false,
      raw: source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'isArchived': isArchived,
      'inMainList': inMainList,
      'inArchiveList': inArchiveList,
      'mainOrder': mainOrder,
      'archiveOrder': archiveOrder,
      'mainPinned': mainPinned,
      'archivePinned': archivePinned,
    };
  }

  TelegramChatListState copyWith({
    bool? isArchived,
    bool? inMainList,
    bool? inArchiveList,
    String? mainOrder,
    String? archiveOrder,
    bool? mainPinned,
    bool? archivePinned,
    Map<String, dynamic>? raw,
  }) {
    return TelegramChatListState(
      isArchived: isArchived ?? this.isArchived,
      inMainList: inMainList ?? this.inMainList,
      inArchiveList: inArchiveList ?? this.inArchiveList,
      mainOrder: mainOrder ?? this.mainOrder,
      archiveOrder: archiveOrder ?? this.archiveOrder,
      mainPinned: mainPinned ?? this.mainPinned,
      archivePinned: archivePinned ?? this.archivePinned,
      raw: raw ?? this.raw,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramChatListState &&
        other.isArchived == isArchived &&
        other.inMainList == inMainList &&
        other.inArchiveList == inArchiveList &&
        other.mainOrder == mainOrder &&
        other.archiveOrder == archiveOrder &&
        other.mainPinned == mainPinned &&
        other.archivePinned == archivePinned;
  }

  @override
  int get hashCode => Object.hash(
        isArchived,
        inMainList,
        inArchiveList,
        mainOrder,
        archiveOrder,
        mainPinned,
        archivePinned,
      );
}

/// Represents a Telegram chat/group/channel the account has access to.
class TelegramChat {
  const TelegramChat({
    required this.id,
    this.chatId,
    required this.title,
    this.description,
    required this.type,
    this.username,
    this.unreadCount = 0,
    this.lastMessageId,
    this.photoPath,
    this.membersCount,
    this.lastMessageDate,
    this.messageCount,
    this.listState,
    this.isArchived,
    this.isMuted,
    this.forum,
  });

  final String id;
  final String? chatId;
  final String title;
  final String? description;
  final String type;
  final String? username;
  final int unreadCount;
  final String? lastMessageId;
  final String? photoPath;
  final int? membersCount;
  final DateTime? lastMessageDate;
  final int? messageCount;
  final TelegramChatListState? listState;
  final bool? isArchived;
  final bool? isMuted;
  final TelegramChatForumInfo? forum;

  factory TelegramChat.fromJson(Map<String, dynamic> json) {
    final source = _unwrapChatJson(json);
    final listStateJson = source['listState'] ?? source['list_state'];
    final listState = listStateJson is Map
        ? TelegramChatListState.fromJson(
            Map<String, dynamic>.from(listStateJson),
          )
        : null;
    final forumJson = source['forum'];
    final forum = forumJson is Map
        ? TelegramChatForumInfo.fromJson(
            Map<String, dynamic>.from(forumJson),
          )
        : null;
    final chatId = _readRequiredString(
      source,
      'id',
      fallbackKeys: const [
        'chatId',
        'chat_id',
        'telegramChatId',
        'telegram_chat_id',
      ],
    );

    return TelegramChat(
      id: chatId,
      chatId: _readString(
        source['chatId'] ??
            source['chat_id'] ??
            source['telegramChatId'] ??
            source['telegram_chat_id'],
      ),
      title: _readChatTitle(source, fallbackId: chatId),
      description: _readString(
        source['description'] ?? source['about'] ?? source['subtitle'],
      ),
      type: _readChatType(source),
      username: _readString(source['username']),
      unreadCount: _readInt(
            source['unreadCount'] ??
                source['unread_count'] ??
                source['unreadMessagesCount'] ??
                source['unread_messages_count'],
          ) ??
          0,
      lastMessageId: _readString(
        source['lastMessageId'] ?? source['last_message_id'],
      ),
      photoPath: _readString(
        source['photoPath'] ??
            source['photo_path'] ??
            source['photoUrl'] ??
            source['photo_url'],
      ),
      membersCount: _readInt(
        source['membersCount'] ??
            source['members_count'] ??
            source['memberCount'] ??
            source['member_count'],
      ),
      lastMessageDate: _readDateTime(
        source['lastMessageDate'] ??
            source['last_message_date'] ??
            source['lastMessageAt'] ??
            source['last_message_at'] ??
            source['updatedAt'] ??
            source['updated_at'],
      ),
      messageCount: _readInt(
        source['messageCount'] ??
            source['message_count'] ??
            source['messagesCount'] ??
            source['messages_count'],
      ),
      listState: listState,
      isArchived: listState?.isArchived ??
          _readBool(source['isArchived'] ?? source['is_archived']),
      isMuted: _readBool(source['isMuted'] ?? source['is_muted']),
      forum: forum,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'title': title,
      'description': description,
      'type': type,
      'username': username,
      'unreadCount': unreadCount,
      'lastMessageId': lastMessageId,
      'photoPath': photoPath,
      'membersCount': membersCount,
      'lastMessageDate': lastMessageDate?.toIso8601String(),
      'messageCount': messageCount,
      'listState': listState?.toJson(),
      'isArchived': isArchived,
      'isMuted': isMuted,
      'forum': forum?.toJson(),
    };
  }

  TelegramChat copyWith({
    String? id,
    String? chatId,
    String? title,
    String? description,
    String? type,
    String? username,
    int? unreadCount,
    String? lastMessageId,
    String? photoPath,
    int? membersCount,
    DateTime? lastMessageDate,
    int? messageCount,
    TelegramChatListState? listState,
    bool? isArchived,
    bool? isMuted,
    TelegramChatForumInfo? forum,
  }) {
    return TelegramChat(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      username: username ?? this.username,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      photoPath: photoPath ?? this.photoPath,
      membersCount: membersCount ?? this.membersCount,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      messageCount: messageCount ?? this.messageCount,
      listState: listState ?? this.listState,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      forum: forum ?? this.forum,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramChat &&
        other.id == id &&
        other.chatId == chatId &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.username == username &&
        other.unreadCount == unreadCount &&
        other.lastMessageId == lastMessageId &&
        other.photoPath == photoPath &&
        other.membersCount == membersCount &&
        other.lastMessageDate == lastMessageDate &&
        other.messageCount == messageCount &&
        other.listState == listState &&
        other.isArchived == isArchived &&
        other.isMuted == isMuted &&
        other.forum == forum;
  }

  @override
  int get hashCode => Object.hash(
        id,
        chatId,
        title,
        description,
        type,
        username,
        unreadCount,
        lastMessageId,
        photoPath,
        membersCount,
        lastMessageDate,
        messageCount,
        listState,
        isArchived,
        isMuted,
        forum,
      );
}

extension TelegramChatExt on TelegramChat {
  bool get isArchivedChat => listState?.isArchived ?? isArchived == true;
  bool get isForumChat => forum?.isForum == true;
  bool get isGroup {
    final normalized = _normalizeChatType(type);
    return normalized == 'group' || normalized == 'supergroup';
  }

  bool get isChannel => _normalizeChatType(type) == 'channel';
  bool get isPrivate => _normalizeChatType(type) == 'private';
  bool get inMainList => listState?.inMainList ?? !isArchivedChat;
  bool get inArchiveList => listState?.inArchiveList ?? isArchivedChat;
  bool get isPinned =>
      listState?.mainPinned == true || listState?.archivePinned == true;

  String get typeLabel => isPrivate
      ? 'Private Chat'
      : isChannel
          ? 'Channel'
          : isForumChat
              ? 'Forum'
          : 'Group';
}

/// Chat details with message count and stats.
class TelegramChatDetail {
  const TelegramChatDetail({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.photoPath,
    this.membersCount,
    this.lastMessageDate,
    required this.messageCount,
    required this.photoCount,
    required this.videoCount,
    required this.documentCount,
    required this.mediaCount,
    this.isArchived,
    this.isMuted,
    this.forum,
  });

  final String id;
  final String title;
  final String? description;
  final String type;
  final String? photoPath;
  final int? membersCount;
  final DateTime? lastMessageDate;
  final int messageCount;
  final int photoCount;
  final int videoCount;
  final int documentCount;
  final int mediaCount;
  final bool? isArchived;
  final bool? isMuted;
  final TelegramChatForumInfo? forum;

  factory TelegramChatDetail.fromJson(Map<String, dynamic> json) {
    final source = _unwrapChatJson(json);
    final chatId = _readRequiredString(
      source,
      'id',
      fallbackKeys: const [
        'chatId',
        'chat_id',
        'telegramChatId',
        'telegram_chat_id',
      ],
    );

    return TelegramChatDetail(
      id: chatId,
      title: _readChatTitle(source, fallbackId: chatId),
      description: _readString(
        source['description'] ?? source['about'] ?? source['subtitle'],
      ),
      type: _readChatType(source),
      photoPath: _readString(
        source['photoPath'] ??
            source['photo_path'] ??
            source['photoUrl'] ??
            source['photo_url'],
      ),
      membersCount: _readInt(
        source['membersCount'] ??
            source['members_count'] ??
            source['memberCount'] ??
            source['member_count'],
      ),
      lastMessageDate: _readDateTime(
        source['lastMessageDate'] ??
            source['last_message_date'] ??
            source['lastMessageAt'] ??
            source['last_message_at'] ??
            source['updatedAt'] ??
            source['updated_at'],
      ),
      messageCount: _readPreferredInt(
            source,
            'messageCount',
            'message_count',
            fallbackKeys: const ['messagesCount', 'messages_count'],
          ) ??
          0,
      photoCount: _readPreferredInt(source, 'photoCount', 'photo_count') ?? 0,
      videoCount: _readPreferredInt(source, 'videoCount', 'video_count') ?? 0,
      documentCount:
          _readPreferredInt(source, 'documentCount', 'document_count') ?? 0,
      mediaCount: _readPreferredInt(source, 'mediaCount', 'media_count') ?? 0,
      isArchived: _readBool(source['isArchived'] ?? source['is_archived']),
      isMuted: _readBool(source['isMuted'] ?? source['is_muted']),
      forum: source['forum'] is Map
          ? TelegramChatForumInfo.fromJson(
              Map<String, dynamic>.from(source['forum'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'photoPath': photoPath,
      'membersCount': membersCount,
      'lastMessageDate': lastMessageDate?.toIso8601String(),
      'messageCount': messageCount,
      'photoCount': photoCount,
      'videoCount': videoCount,
      'documentCount': documentCount,
      'mediaCount': mediaCount,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'forum': forum?.toJson(),
    };
  }

  TelegramChatDetail copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? photoPath,
    int? membersCount,
    DateTime? lastMessageDate,
    int? messageCount,
    int? photoCount,
    int? videoCount,
    int? documentCount,
    int? mediaCount,
    bool? isArchived,
    bool? isMuted,
    TelegramChatForumInfo? forum,
  }) {
    return TelegramChatDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      photoPath: photoPath ?? this.photoPath,
      membersCount: membersCount ?? this.membersCount,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      messageCount: messageCount ?? this.messageCount,
      photoCount: photoCount ?? this.photoCount,
      videoCount: videoCount ?? this.videoCount,
      documentCount: documentCount ?? this.documentCount,
      mediaCount: mediaCount ?? this.mediaCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      forum: forum ?? this.forum,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramChatDetail &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.type == type &&
        other.photoPath == photoPath &&
        other.membersCount == membersCount &&
        other.lastMessageDate == lastMessageDate &&
        other.messageCount == messageCount &&
        other.photoCount == photoCount &&
        other.videoCount == videoCount &&
        other.documentCount == documentCount &&
        other.mediaCount == mediaCount &&
        other.isArchived == isArchived &&
        other.isMuted == isMuted &&
        other.forum == forum;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        type,
        photoPath,
        membersCount,
        lastMessageDate,
        messageCount,
        photoCount,
        videoCount,
        documentCount,
        mediaCount,
        isArchived,
        isMuted,
        forum,
      );
}

String _readRequiredString(
  Map<String, dynamic> json,
  String key, {
  List<String> fallbackKeys = const [],
}) {
  final value =
      _readString(json[key] ?? _readFromFallbacks(json, fallbackKeys));
  if (value == null) {
    throw FormatException('Missing required TelegramChat field: $key');
  }
  return value;
}

int? _readPreferredInt(
  Map<String, dynamic> json,
  String camelKey,
  String snakeKey, {
  List<String> fallbackKeys = const [],
}) {
  return _readInt(
    json[camelKey] ?? json[snakeKey] ?? _readFromFallbacks(json, fallbackKeys),
  );
}

String? _readString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _readBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
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

Map<String, dynamic> _unwrapChatJson(Map<String, dynamic> json) {
  final nested = json['chat'] ?? json['item'] ?? json['data'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

String _readChatTitle(
  Map<String, dynamic> json, {
  required String fallbackId,
}) {
  final direct = _readString(
    json['title'] ??
        json['name'] ??
        json['chatTitle'] ??
        json['chat_title'] ??
        json['displayName'] ??
        json['display_name'] ??
        json['label'] ??
        json['username'] ??
        json['phoneNumber'] ??
        json['phone_number'],
  );
  if (direct != null) return direct;

  final firstName = _readString(json['firstName'] ?? json['first_name']);
  final lastName = _readString(json['lastName'] ?? json['last_name']);
  final joined = [firstName, lastName]
      .where((value) => value != null && value.isNotEmpty)
      .cast<String>()
      .join(' ')
      .trim();
  if (joined.isNotEmpty) return joined;

  return 'Chat $fallbackId';
}

String _readChatType(Map<String, dynamic> json) {
  final explicit = _readString(
    json['type'] ?? json['chatType'] ?? json['chat_type'] ?? json['kind'],
  );
  if (explicit != null) {
    return _normalizeChatType(explicit);
  }

  if (_readBool(json['isChannel'] ?? json['is_channel']) == true) {
    return 'channel';
  }
  if (_readBool(json['isSupergroup'] ?? json['is_supergroup']) == true) {
    return 'supergroup';
  }
  if (_readBool(json['isGroup'] ?? json['is_group']) == true) {
    return 'group';
  }
  return 'private';
}

String _normalizeChatType(String value) {
  final normalized =
      value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  switch (normalized) {
    case 'user':
    case 'dm':
    case 'direct':
    case 'direct_message':
      return 'private';
    case 'group_chat':
      return 'group';
    default:
      return normalized;
  }
}
