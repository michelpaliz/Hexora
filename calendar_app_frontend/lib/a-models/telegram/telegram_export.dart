/// Request payload for creating a Telegram export.
class TelegramExportRequest {
  const TelegramExportRequest({
    required this.chatId,
    required this.accountId,
    this.dateFrom,
    this.dateTo,
    this.messageLimit,
    this.mediaOnly,
    this.documentsOnly,
    this.senderId,
    this.downloadFiles,
    required this.exportFormat,
  });

  final String chatId;
  final String accountId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? messageLimit;
  final bool? mediaOnly;
  final bool? documentsOnly;
  final String? senderId;
  final bool? downloadFiles;
  final String exportFormat;

  factory TelegramExportRequest.fromJson(Map<String, dynamic> json) {
    return TelegramExportRequest(
      chatId: _readRequiredString(json, 'chatId', fallbackKey: 'chat_id'),
      accountId:
          _readRequiredString(json, 'accountId', fallbackKey: 'account_id'),
      dateFrom: _readDateTime(json['dateFrom'] ?? json['date_from']),
      dateTo: _readDateTime(json['dateTo'] ?? json['date_to']),
      messageLimit: _readInt(json['messageLimit'] ?? json['message_limit']),
      mediaOnly: _readBool(json['mediaOnly'] ?? json['media_only']),
      documentsOnly: _readBool(json['documentsOnly'] ?? json['documents_only']),
      senderId: _readString(json['senderId'] ?? json['sender_id']),
      downloadFiles: _readBool(json['downloadFiles'] ?? json['download_files']),
      exportFormat: _readRequiredString(
        json,
        'exportFormat',
        fallbackKey: 'export_format',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'accountId': accountId,
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'messageLimit': messageLimit,
      'mediaOnly': mediaOnly,
      'documentsOnly': documentsOnly,
      'senderId': senderId,
      'downloadFiles': downloadFiles,
      'exportFormat': exportFormat,
    };
  }

  TelegramExportRequest copyWith({
    String? chatId,
    String? accountId,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? messageLimit,
    bool? mediaOnly,
    bool? documentsOnly,
    String? senderId,
    bool? downloadFiles,
    String? exportFormat,
  }) {
    return TelegramExportRequest(
      chatId: chatId ?? this.chatId,
      accountId: accountId ?? this.accountId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      messageLimit: messageLimit ?? this.messageLimit,
      mediaOnly: mediaOnly ?? this.mediaOnly,
      documentsOnly: documentsOnly ?? this.documentsOnly,
      senderId: senderId ?? this.senderId,
      downloadFiles: downloadFiles ?? this.downloadFiles,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramExportRequest &&
        other.chatId == chatId &&
        other.accountId == accountId &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.messageLimit == messageLimit &&
        other.mediaOnly == mediaOnly &&
        other.documentsOnly == documentsOnly &&
        other.senderId == senderId &&
        other.downloadFiles == downloadFiles &&
        other.exportFormat == exportFormat;
  }

  @override
  int get hashCode => Object.hash(
        chatId,
        accountId,
        dateFrom,
        dateTo,
        messageLimit,
        mediaOnly,
        documentsOnly,
        senderId,
        downloadFiles,
        exportFormat,
      );
}

/// Export job status.
class TelegramExport {
  const TelegramExport({
    required this.id,
    required this.accountId,
    required this.chatId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.messagesScanned,
    required this.messagesExported,
    required this.filesDownloaded,
    required this.filesFailed,
    this.totalMessages,
    this.errorMessage,
    this.downloadUrl,
    required this.exportFormat,
  });

  final String id;
  final String accountId;
  final String chatId;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int messagesScanned;
  final int messagesExported;
  final int filesDownloaded;
  final int filesFailed;
  final int? totalMessages;
  final String? errorMessage;
  final String? downloadUrl;
  final String exportFormat;

  factory TelegramExport.fromJson(Map<String, dynamic> json) {
    return TelegramExport(
      id: _readRequiredString(json, 'id'),
      accountId:
          _readRequiredString(json, 'accountId', fallbackKey: 'account_id'),
      chatId: _readRequiredString(json, 'chatId', fallbackKey: 'chat_id'),
      status: _readRequiredString(json, 'status'),
      createdAt: _readRequiredDateTime(
        json,
        'createdAt',
        fallbackKey: 'created_at',
      ),
      completedAt: _readDateTime(json['completedAt'] ?? json['completed_at']),
      messagesScanned: _readRequiredInt(
        json,
        'messagesScanned',
        fallbackKey: 'messages_scanned',
      ),
      messagesExported: _readRequiredInt(
        json,
        'messagesExported',
        fallbackKey: 'messages_exported',
      ),
      filesDownloaded: _readRequiredInt(
        json,
        'filesDownloaded',
        fallbackKey: 'files_downloaded',
      ),
      filesFailed: _readRequiredInt(
        json,
        'filesFailed',
        fallbackKey: 'files_failed',
      ),
      totalMessages: _readInt(json['totalMessages'] ?? json['total_messages']),
      errorMessage: _readString(json['errorMessage'] ?? json['error_message']),
      downloadUrl: _readString(json['downloadUrl'] ?? json['download_url']),
      exportFormat: _readRequiredString(
        json,
        'exportFormat',
        fallbackKey: 'export_format',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'chatId': chatId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'messagesScanned': messagesScanned,
      'messagesExported': messagesExported,
      'filesDownloaded': filesDownloaded,
      'filesFailed': filesFailed,
      'totalMessages': totalMessages,
      'errorMessage': errorMessage,
      'downloadUrl': downloadUrl,
      'exportFormat': exportFormat,
    };
  }

  TelegramExport copyWith({
    String? id,
    String? accountId,
    String? chatId,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    int? messagesScanned,
    int? messagesExported,
    int? filesDownloaded,
    int? filesFailed,
    int? totalMessages,
    String? errorMessage,
    String? downloadUrl,
    String? exportFormat,
  }) {
    return TelegramExport(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      chatId: chatId ?? this.chatId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      messagesScanned: messagesScanned ?? this.messagesScanned,
      messagesExported: messagesExported ?? this.messagesExported,
      filesDownloaded: filesDownloaded ?? this.filesDownloaded,
      filesFailed: filesFailed ?? this.filesFailed,
      totalMessages: totalMessages ?? this.totalMessages,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramExport &&
        other.id == id &&
        other.accountId == accountId &&
        other.chatId == chatId &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.messagesScanned == messagesScanned &&
        other.messagesExported == messagesExported &&
        other.filesDownloaded == filesDownloaded &&
        other.filesFailed == filesFailed &&
        other.totalMessages == totalMessages &&
        other.errorMessage == errorMessage &&
        other.downloadUrl == downloadUrl &&
        other.exportFormat == exportFormat;
  }

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        chatId,
        status,
        createdAt,
        completedAt,
        messagesScanned,
        messagesExported,
        filesDownloaded,
        filesFailed,
        totalMessages,
        errorMessage,
        downloadUrl,
        exportFormat,
      );
}

extension TelegramExportExt on TelegramExport {
  bool get isPending => status == 'pending';
  bool get isRunning => status == 'running';
  bool get isCompleted => status == 'completed';
  bool get isError => status == 'error';
  bool get isCancelled => status == 'cancelled';

  bool get canCancel => isPending || isRunning;

  double get progressPercent {
    if (totalMessages == null || totalMessages == 0) {
      return messagesScanned > 0 ? 0.5 : 0.0;
    }
    return (messagesScanned / totalMessages!) * 100;
  }

  String get statusLabel =>
      status.replaceFirst(status[0], status[0].toUpperCase());

  String get progressText => '$messagesExported / $messagesScanned messages';
}

/// List response for exports.
class TelegramExportList {
  const TelegramExportList({
    required this.exports,
    required this.total,
  });

  final List<TelegramExport> exports;
  final int total;

  factory TelegramExportList.fromJson(Map<String, dynamic> json) {
    final rawList =
        json['exports'] ?? json['items'] ?? json['results'] ?? json['data'];
    final exports = rawList is List
        ? rawList
            .whereType<Map>()
            .map((item) => TelegramExport.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : const <TelegramExport>[];

    return TelegramExportList(
      exports: exports,
      total: _readInt(json['total']) ?? exports.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exports': exports.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  TelegramExportList copyWith({
    List<TelegramExport>? exports,
    int? total,
  }) {
    return TelegramExportList(
      exports: exports ?? this.exports,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramExportList &&
        _listEquals(other.exports, exports) &&
        other.total == total;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(exports), total);
}

String _readRequiredString(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = _readString(
      json[key] ?? (fallbackKey == null ? null : json[fallbackKey]));
  if (value == null) {
    throw FormatException('Missing required TelegramExport field: $key');
  }
  return value;
}

int _readRequiredInt(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value =
      _readInt(json[key] ?? (fallbackKey == null ? null : json[fallbackKey]));
  if (value == null) {
    throw FormatException('Missing required TelegramExport field: $key');
  }
  return value;
}

DateTime _readRequiredDateTime(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = _readDateTime(
    json[key] ?? (fallbackKey == null ? null : json[fallbackKey]),
  );
  if (value == null) {
    throw FormatException('Missing required TelegramExport field: $key');
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

bool _listEquals(List<TelegramExport> a, List<TelegramExport> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
