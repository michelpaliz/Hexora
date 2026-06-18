/// Paged Telegram chat messages response.
class TelegramChatMessagesResponse {
  const TelegramChatMessagesResponse({
    required this.mode,
    required this.messages,
    required this.paging,
    this.requestId,
  });

  final String mode;
  final List<TelegramChatMessage> messages;
  final TelegramChatMessagePaging paging;
  final String? requestId;

  factory TelegramChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final source = _unwrapMessageEnvelope(json);
    final rawMessages =
        source['messages'] ?? source['items'] ?? source['data'] ?? const [];
    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map>()
            .map((entry) => TelegramChatMessage.fromJson(
                  Map<String, dynamic>.from(entry),
                ))
            .toList()
        : <TelegramChatMessage>[];

    return TelegramChatMessagesResponse(
      mode: _readString(source['mode']) ?? 'history',
      messages: messages,
      paging: TelegramChatMessagePaging.fromJson(
        Map<String, dynamic>.from(
          source['paging'] is Map ? source['paging'] as Map : const {},
        ),
      ),
      requestId: _readString(source['requestId'] ?? source['request_id']),
    );
  }
}

/// Cursor metadata for paged Telegram chat messages.
class TelegramChatMessagePaging {
  const TelegramChatMessagePaging({
    this.beforeMessageId,
    this.afterMessageId,
    this.hasMoreHistory = false,
    this.pollCursor,
  });

  final String? beforeMessageId;
  final String? afterMessageId;
  final bool hasMoreHistory;
  final String? pollCursor;

  factory TelegramChatMessagePaging.fromJson(Map<String, dynamic> json) {
    return TelegramChatMessagePaging(
      beforeMessageId:
          _readString(json['beforeMessageId'] ?? json['before_message_id']),
      afterMessageId:
          _readString(json['afterMessageId'] ?? json['after_message_id']),
      hasMoreHistory: _readBool(
            json['hasMoreHistory'] ?? json['has_more_history'],
          ) ??
          false,
      pollCursor: _readString(json['pollCursor'] ?? json['poll_cursor']),
    );
  }

  TelegramChatMessagePaging copyWith({
    String? beforeMessageId,
    String? afterMessageId,
    bool? hasMoreHistory,
    String? pollCursor,
  }) {
    return TelegramChatMessagePaging(
      beforeMessageId: beforeMessageId ?? this.beforeMessageId,
      afterMessageId: afterMessageId ?? this.afterMessageId,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      pollCursor: pollCursor ?? this.pollCursor,
    );
  }
}

/// Single Telegram message.
class TelegramChatMessage {
  const TelegramChatMessage({
    required this.messageId,
    this.timestamp,
    this.editTimestamp,
    this.sender,
    this.displayTextValue,
    this.text,
    this.caption,
    this.topic,
    this.replyTo,
    this.forwardInfo,
    required this.messageType,
    this.media,
    this.attachments = const <TelegramChatMessageAttachment>[],
  });

  final String messageId;
  final DateTime? timestamp;
  final DateTime? editTimestamp;
  final TelegramChatMessageSender? sender;
  final String? displayTextValue;
  final String? text;
  final String? caption;
  final TelegramChatMessageTopic? topic;
  final TelegramChatMessageReplyTo? replyTo;
  final TelegramChatMessageForwardInfo? forwardInfo;
  final String messageType;
  final TelegramChatMessageMedia? media;
  final List<TelegramChatMessageAttachment> attachments;

  factory TelegramChatMessage.fromJson(Map<String, dynamic> json) {
    final source = _unwrapMessageEnvelope(json);
    final sender = source['sender'];
    final topic = source['topic'];
    final replyTo = source['replyTo'] ?? source['reply_to'];
    final forwardInfo = source['forwardInfo'] ?? source['forward_info'];
    final media = source['media'] ??
        source['document'] ??
        source['file'] ??
        source['attachment'];
    final rawAttachments =
        source['attachments'] ?? source['files'] ?? source['mediaFiles'];

    return TelegramChatMessage(
      messageId: _readRequiredString(
        source,
        'messageId',
        fallbackKeys: const ['message_id', 'id'],
      ),
      timestamp: _readDateTime(source['timestamp'] ?? source['date']),
      editTimestamp:
          _readDateTime(source['editTimestamp'] ?? source['edit_timestamp']),
      sender: sender is Map
          ? TelegramChatMessageSender.fromJson(
              Map<String, dynamic>.from(sender),
            )
          : null,
      displayTextValue:
          _readString(source['displayText'] ?? source['display_text']),
      text: _readString(source['text']),
      caption: _readString(source['caption']),
      topic: topic is Map
          ? TelegramChatMessageTopic.fromJson(
              Map<String, dynamic>.from(topic),
            )
          : null,
      replyTo: replyTo is Map
          ? TelegramChatMessageReplyTo.fromJson(
              Map<String, dynamic>.from(replyTo),
            )
          : null,
      forwardInfo: forwardInfo is Map
          ? TelegramChatMessageForwardInfo.fromJson(
              Map<String, dynamic>.from(forwardInfo),
            )
          : null,
      messageType: _readString(
            source['messageType'] ?? source['message_type'] ?? source['type'],
          ) ??
          'unknown',
      media: media is Map
          ? TelegramChatMessageMedia.fromJson(
              Map<String, dynamic>.from(media),
            )
          : null,
      attachments: rawAttachments is List
          ? rawAttachments
              .whereType<Map>()
              .map(
                (entry) => TelegramChatMessageAttachment.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList()
          : const <TelegramChatMessageAttachment>[],
    );
  }
}

class TelegramChatMessageTopic {
  const TelegramChatMessageTopic({
    this.type,
    this.forumTopicId,
  });

  final String? type;
  final String? forumTopicId;

  factory TelegramChatMessageTopic.fromJson(Map<String, dynamic> json) {
    return TelegramChatMessageTopic(
      type: _readString(json['type']),
      forumTopicId: _readString(
        json['forumTopicId'] ?? json['forum_topic_id'],
      ),
    );
  }
}

class TelegramChatMessageSender {
  const TelegramChatMessageSender({
    this.id,
    this.type,
    this.displayName,
    this.username,
  });

  final String? id;
  final String? type;
  final String? displayName;
  final String? username;

  factory TelegramChatMessageSender.fromJson(Map<String, dynamic> json) {
    return TelegramChatMessageSender(
      id: _readString(json['id']),
      type: _readString(json['type']),
      displayName: _readString(
          json['displayName'] ?? json['display_name'] ?? json['name']),
      username: _readString(json['username']),
    );
  }
}

class TelegramChatMessageReplyTo {
  const TelegramChatMessageReplyTo({
    this.messageId,
    this.displayName,
    this.textPreview,
  });

  final String? messageId;
  final String? displayName;
  final String? textPreview;

  factory TelegramChatMessageReplyTo.fromJson(Map<String, dynamic> json) {
    return TelegramChatMessageReplyTo(
      messageId:
          _readString(json['messageId'] ?? json['message_id'] ?? json['id']),
      displayName: _readString(
        json['displayName'] ??
            json['display_name'] ??
            json['senderDisplayName'] ??
            json['sender_display_name'] ??
            json['title'],
      ),
      textPreview: _readString(
        json['text'] ??
            json['caption'] ??
            json['preview'] ??
            json['messageText'] ??
            json['message_text'],
      ),
    );
  }
}

class TelegramChatMessageForwardInfo {
  const TelegramChatMessageForwardInfo({
    this.sourceName,
    this.authorName,
    this.timestamp,
  });

  final String? sourceName;
  final String? authorName;
  final DateTime? timestamp;

  factory TelegramChatMessageForwardInfo.fromJson(Map<String, dynamic> json) {
    return TelegramChatMessageForwardInfo(
      sourceName: _readString(
        json['sourceName'] ??
            json['source_name'] ??
            json['title'] ??
            json['chatTitle'] ??
            json['chat_title'],
      ),
      authorName: _readString(
        json['authorName'] ??
            json['author_name'] ??
            json['displayName'] ??
            json['display_name'],
      ),
      timestamp: _readDateTime(json['timestamp'] ?? json['date']),
    );
  }
}

class TelegramChatMessageMedia {
  const TelegramChatMessageMedia({
    this.type,
    this.fileName,
    this.displayName,
    this.mimeType,
    this.fileSize,
    this.url,
    this.downloadUrl,
    this.thumbnailUrl,
    this.isPdf = false,
    this.fileCount,
    this.files = const <TelegramChatMessageAttachment>[],
  });

  final String? type;
  final String? fileName;
  final String? displayName;
  final String? mimeType;
  final int? fileSize;
  final String? url;
  final String? downloadUrl;
  final String? thumbnailUrl;
  final bool isPdf;
  final int? fileCount;
  final List<TelegramChatMessageAttachment> files;

  factory TelegramChatMessageMedia.fromJson(Map<String, dynamic> json) {
    final document = _readNestedMap(
      json['document'] ?? json['file'] ?? json['attachment'],
    );
    final thumb = _readNestedMap(
      json['thumbnail'] ??
          json['thumb'] ??
          document?['thumbnail'] ??
          document?['thumb'],
    );
    final rawFiles = json['files'] ?? document?['files'];

    return TelegramChatMessageMedia(
      type: _readString(
        json['type'] ??
            json['mediaType'] ??
            json['media_type'] ??
            document?['type'] ??
            document?['mediaType'] ??
            document?['media_type'],
      ),
      fileName: _readString(
        json['fileName'] ??
            json['displayName'] ??
            json['display_name'] ??
            json['file_name'] ??
            json['filename'] ??
            json['name'] ??
            document?['fileName'] ??
            document?['displayName'] ??
            document?['display_name'] ??
            document?['file_name'] ??
            document?['filename'] ??
            document?['name'],
      ),
      displayName: _readString(
        json['displayName'] ??
            json['display_name'] ??
            document?['displayName'] ??
            document?['display_name'],
      ),
      mimeType: _readString(
        json['mimeType'] ??
            json['mime_type'] ??
            document?['mimeType'] ??
            document?['mime_type'],
      ),
      fileSize: _readInt(
        json['fileSize'] ??
            json['file_size'] ??
            document?['fileSize'] ??
            document?['file_size'],
      ),
      url: _readString(
        json['url'] ?? document?['url'],
      ),
      downloadUrl: _readString(
        json['downloadUrl'] ??
            json['download_url'] ??
            document?['downloadUrl'] ??
            document?['download_url'],
      ),
      thumbnailUrl: _readString(
        json['thumbnailUrl'] ??
            json['thumbnail_url'] ??
            thumb?['url'] ??
            thumb?['downloadUrl'] ??
            thumb?['download_url'] ??
            document?['thumbnailUrl'] ??
            document?['thumbnail_url'],
      ),
      isPdf: _readBool(
            json['isPdf'] ??
                json['is_pdf'] ??
                document?['isPdf'] ??
                document?['is_pdf'],
          ) ??
          ((_readString(
                        json['mimeType'] ??
                            json['mime_type'] ??
                            document?['mimeType'] ??
                            document?['mime_type'],
                      ) ??
                      '')
                  .toLowerCase() ==
              'application/pdf'),
      fileCount: _readInt(
        json['fileCount'] ??
            json['file_count'] ??
            document?['fileCount'] ??
            document?['file_count'],
      ),
      files: rawFiles is List
          ? rawFiles
              .whereType<Map>()
              .map(
                (entry) => TelegramChatMessageAttachment.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList()
          : const <TelegramChatMessageAttachment>[],
    );
  }
}

class TelegramChatMessageAttachment {
  const TelegramChatMessageAttachment({
    this.id,
    this.fileName,
    this.displayName,
    this.mimeType,
    this.url,
    this.downloadUrl,
    this.size,
    this.expectedSize,
    this.localPath,
    this.isPdf = false,
  });

  final String? id;
  final String? fileName;
  final String? displayName;
  final String? mimeType;
  final String? url;
  final String? downloadUrl;
  final int? size;
  final int? expectedSize;
  final String? localPath;
  final bool isPdf;

  factory TelegramChatMessageAttachment.fromJson(Map<String, dynamic> json) {
    final mimeType = _readString(json['mimeType'] ?? json['mime_type']);
    return TelegramChatMessageAttachment(
      id: _readString(json['id']),
      fileName: _readString(
        json['fileName'] ??
            json['file_name'] ??
            json['filename'] ??
            json['name'],
      ),
      displayName: _readString(
          json['displayName'] ?? json['display_name'] ?? json['title']),
      mimeType: mimeType,
      url: _readString(json['url']),
      downloadUrl: _readString(json['downloadUrl'] ?? json['download_url']),
      size: _readInt(json['size']),
      expectedSize: _readInt(json['expectedSize'] ?? json['expected_size']),
      localPath: _readString(json['localPath'] ?? json['local_path']),
      isPdf: _readBool(json['isPdf'] ?? json['is_pdf']) ??
          ((mimeType ?? '').toLowerCase() == 'application/pdf'),
    );
  }
}

extension TelegramChatMessageExt on TelegramChatMessage {
  TelegramChatMessageAttachment? get primaryAttachment {
    if (attachments.isNotEmpty) return attachments.first;
    final mediaFiles = media?.files ?? const <TelegramChatMessageAttachment>[];
    if (mediaFiles.isNotEmpty) return mediaFiles.first;
    return null;
  }

  bool get hasMeaningfulMediaMetadata {
    final mediaValue = media;
    final attachment = primaryAttachment;
    if (mediaValue == null && attachment == null) return false;
    return (mediaValue?.fileName?.trim().isNotEmpty ?? false) ||
        (mediaValue?.displayName?.trim().isNotEmpty ?? false) ||
        (mediaValue?.mimeType?.trim().isNotEmpty ?? false) ||
        (mediaValue?.url?.trim().isNotEmpty ?? false) ||
        (mediaValue?.downloadUrl?.trim().isNotEmpty ?? false) ||
        (mediaValue?.thumbnailUrl?.trim().isNotEmpty ?? false) ||
        mediaValue?.fileSize != null ||
        (attachment?.fileName?.trim().isNotEmpty ?? false) ||
        (attachment?.displayName?.trim().isNotEmpty ?? false) ||
        (attachment?.mimeType?.trim().isNotEmpty ?? false) ||
        (attachment?.url?.trim().isNotEmpty ?? false) ||
        (attachment?.downloadUrl?.trim().isNotEmpty ?? false) ||
        attachment?.size != null;
  }

  bool get isSystemThreadEvent {
    final candidates = <String>[
      messageType,
      media?.type ?? '',
    ];

    for (final candidate in candidates) {
      final normalized = candidate.trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (normalized.startsWith('messagechat') ||
          normalized.startsWith('messageforumtopic') ||
          normalized == 'messagepinmessage') {
        return true;
      }
    }
    return false;
  }

  String? get displayText {
    final backendDisplayText = displayTextValue?.trim();
    if (backendDisplayText != null && backendDisplayText.isNotEmpty) {
      return backendDisplayText;
    }
    final textValue = text?.trim();
    if (textValue != null && textValue.isNotEmpty) {
      return textValue;
    }
    final captionValue = caption?.trim();
    if (captionValue != null && captionValue.isNotEmpty) {
      return captionValue;
    }
    return null;
  }

  String get senderLabel {
    final display = sender?.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return display;
    }
    final username = sender?.username?.trim();
    if (username != null && username.isNotEmpty) {
      return '@$username';
    }
    return 'Unknown sender';
  }

  bool get isEdited => editTimestamp != null;
  bool get hasMedia => media != null || primaryAttachment != null;
  bool get hasText => displayText != null;
  bool get isDocumentMessage {
    final normalized = (media?.type ?? messageType).trim().toLowerCase();
    final mimeType = (primaryAttachment?.mimeType ?? media?.mimeType ?? '')
        .trim()
        .toLowerCase();
    final fileName = (primaryAttachment?.fileName ??
            primaryAttachment?.displayName ??
            media?.displayName ??
            media?.fileName ??
            '')
        .trim()
        .toLowerCase();
    return normalized.contains('document') ||
        normalized.contains('file') ||
        mimeType.isNotEmpty ||
        fileName.endsWith('.pdf');
  }

  bool get isPdfDocument {
    final fileName = documentDisplayName.trim().toLowerCase();
    return primaryAttachment?.isPdf == true ||
        media?.isPdf == true ||
        ((primaryAttachment?.mimeType ?? media?.mimeType ?? '').toLowerCase() ==
            'application/pdf') ||
        fileName.endsWith('.pdf');
  }

  String get documentDisplayName {
    final attachment = primaryAttachment;
    return attachment?.displayName?.trim().isNotEmpty == true
        ? attachment!.displayName!.trim()
        : attachment?.fileName?.trim().isNotEmpty == true
            ? attachment!.fileName!.trim()
            : media?.displayName?.trim().isNotEmpty == true
                ? media!.displayName!.trim()
                : media?.fileName?.trim().isNotEmpty == true
                    ? media!.fileName!.trim()
                    : 'Document';
  }

  String get documentSubtitleLabel => isPdfDocument ? 'PDF' : 'Document';

  String? get documentPreviewUrl {
    final attachment = primaryAttachment;
    final candidates = <String?>[
      media?.url,
      media?.downloadUrl,
      attachment?.downloadUrl,
      attachment?.url,
    ];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String get previewText {
    final textValue = displayText;
    if (textValue != null && textValue.isNotEmpty) {
      return textValue;
    }
    final mediaValue = media;
    if (mediaValue != null) {
      final fileName = documentDisplayName.trim();
      if (fileName.isNotEmpty) {
        return fileName;
      }
      final mediaType = _humanizeMessageType(mediaValue.type ?? messageType);
      if (mediaType.isNotEmpty) {
        return mediaType;
      }
    }
    final typeLabel = _humanizeMessageType(messageType);
    if (typeLabel.isNotEmpty) {
      return typeLabel;
    }
    return unsupportedLabel;
  }

  bool get shouldRenderMediaPlaceholder {
    final mediaValue = media;
    final attachment = primaryAttachment;
    if (mediaValue == null && attachment == null) return false;

    final hasMetadata = hasMeaningfulMediaMetadata;

    if (!hasMetadata && hasText) return false;

    return hasMetadata || !hasText;
  }

  String get unsupportedLabel {
    final normalized = messageType.trim();
    if (normalized.isEmpty || normalized == 'unknown') {
      return 'Unsupported Telegram message';
    }
    return 'Unsupported message type: $normalized';
  }
}

String _humanizeMessageType(String raw) {
  var cleaned = raw.trim();
  if (cleaned.isEmpty || cleaned.toLowerCase() == 'unknown') {
    return '';
  }
  cleaned = cleaned.replaceFirst(RegExp(r'^message', caseSensitive: false), '');
  if (cleaned.isEmpty) {
    return 'Message';
  }
  cleaned = cleaned
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => ' ${match[0]}',
      )
      .trim();
  if (cleaned.isEmpty) {
    return raw;
  }
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

Map<String, dynamic> _unwrapMessageEnvelope(Map<String, dynamic> json) {
  final nested = json['message'] ?? json['item'] ?? json['data'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

Map<String, dynamic>? _readNestedMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _readRequiredString(
  Map<String, dynamic> json,
  String key, {
  List<String> fallbackKeys = const [],
}) {
  final value =
      _readString(json[key] ?? _readFromFallbacks(json, fallbackKeys));
  if (value == null) {
    throw FormatException('Missing required Telegram message field: $key');
  }
  return value;
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
