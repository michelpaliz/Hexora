class DownloadJob {
  const DownloadJob({
    required this.id,
    required this.groupId,
    required this.requestedByUserId,
    required this.requestedByUserName,
    required this.jobType,
    required this.title,
    required this.description,
    required this.status,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.errorMessage,
    required this.params,
    required this.notificationId,
    required this.expiresAt,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.downloadUrl,
    required this.canDownload,
  });

  final String id;
  final String groupId;
  final String requestedByUserId;
  final String requestedByUserName;
  final String jobType;
  final String title;
  final String description;
  final String status;
  final String fileName;
  final String mimeType;
  final int? size;
  final String errorMessage;
  final Map<String, dynamic> params;
  final String? notificationId;
  final DateTime? expiresAt;
  final DateTime? startedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String downloadUrl;
  final bool canDownload;

  bool get isPdf =>
      mimeType.toLowerCase() == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  bool get isActive => status == 'queued' || status == 'processing';
  bool get isFinal => status == 'ready' || status == 'failed' || status == 'expired';

  String get effectiveFileName {
    final trimmed = fileName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final titleTrimmed = title.trim();
    if (titleTrimmed.isNotEmpty) return titleTrimmed;
    return 'download';
  }

  factory DownloadJob.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '');
    }

    return DownloadJob(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      requestedByUserId: (json['requestedByUserId'] ?? '').toString(),
      requestedByUserName: (json['requestedByUserName'] ?? '').toString(),
      jobType: (json['jobType'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      mimeType: (json['mimeType'] ?? '').toString(),
      size: parseInt(json['size']),
      errorMessage: (json['errorMessage'] ?? '').toString(),
      params: json['params'] is Map
          ? Map<String, dynamic>.from(json['params'] as Map)
          : const <String, dynamic>{},
      notificationId: (json['notificationId'] ?? '').toString().trim().isEmpty
          ? null
          : (json['notificationId'] ?? '').toString(),
      expiresAt: parseDate(json['expiresAt']),
      startedAt: parseDate(json['startedAt']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(json['updatedAt']),
      completedAt: parseDate(json['completedAt']),
      downloadUrl: (json['downloadUrl'] ?? '').toString(),
      canDownload: json['canDownload'] == true,
    );
  }

  DownloadJob copyWith({
    String? id,
    String? groupId,
    String? requestedByUserId,
    String? requestedByUserName,
    String? jobType,
    String? title,
    String? description,
    String? status,
    String? fileName,
    String? mimeType,
    int? size,
    bool clearSize = false,
    String? errorMessage,
    Map<String, dynamic>? params,
    String? notificationId,
    bool clearNotificationId = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? downloadUrl,
    bool? canDownload,
  }) {
    return DownloadJob(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      requestedByUserId: requestedByUserId ?? this.requestedByUserId,
      requestedByUserName: requestedByUserName ?? this.requestedByUserName,
      jobType: jobType ?? this.jobType,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      size: clearSize ? null : (size ?? this.size),
      errorMessage: errorMessage ?? this.errorMessage,
      params: params ?? this.params,
      notificationId: clearNotificationId ? null : (notificationId ?? this.notificationId),
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      downloadUrl: downloadUrl ?? this.downloadUrl,
      canDownload: canDownload ?? this.canDownload,
    );
  }
}
