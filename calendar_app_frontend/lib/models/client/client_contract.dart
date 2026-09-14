class ClientContract {
  final String id;
  final String clientId;
  final String? groupId;
  final String? uploadedBy;
  final String fileName;
  final String? blobName;
  final String? mimeType;
  final int? size;
  final String? contractType;
  final String? status;
  final String? title;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? renewalDate;
  final DateTime? signedAt;
  final String? notes;
  final List<String> tags;
  final String? version;
  final bool isCurrent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientContract({
    required this.id,
    required this.clientId,
    required this.fileName,
    this.groupId,
    this.uploadedBy,
    this.blobName,
    this.mimeType,
    this.size,
    this.contractType,
    this.status,
    this.title,
    this.startDate,
    this.endDate,
    this.renewalDate,
    this.signedAt,
    this.notes,
    this.tags = const <String>[],
    this.version,
    this.isCurrent = false,
    this.createdAt,
    this.updatedAt,
  });

  String get displayTitle {
    final trimmed = (title ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    return fileName.trim().isNotEmpty ? fileName.trim() : id;
  }

  ClientContract copyWith({
    String? id,
    String? clientId,
    String? groupId,
    String? uploadedBy,
    String? fileName,
    String? blobName,
    String? mimeType,
    int? size,
    String? contractType,
    String? status,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? renewalDate,
    DateTime? signedAt,
    String? notes,
    List<String>? tags,
    String? version,
    bool? isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientContract(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      fileName: fileName ?? this.fileName,
      groupId: groupId ?? this.groupId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      blobName: blobName ?? this.blobName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      contractType: contractType ?? this.contractType,
      status: status ?? this.status,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      renewalDate: renewalDate ?? this.renewalDate,
      signedAt: signedAt ?? this.signedAt,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ClientContract.fromJson(Map<String, dynamic> json) {
    return ClientContract(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      clientId: (json['clientId'] ?? '').toString(),
      groupId: _asTrimmedString(json['groupId']),
      uploadedBy: _asTrimmedString(json['uploadedBy']),
      fileName: _asTrimmedString(json['fileName']) ?? '',
      blobName: _asTrimmedString(json['blobName']),
      mimeType: _asTrimmedString(json['mimeType']),
      size: _asInt(json['size']),
      contractType: _asTrimmedString(json['contractType']),
      status: _asTrimmedString(json['status']),
      title: _asTrimmedString(json['title']),
      startDate: _asDate(json['startDate']),
      endDate: _asDate(json['endDate']),
      renewalDate: _asDate(json['renewalDate']),
      signedAt: _asDate(json['signedAt']),
      notes: _asTrimmedString(json['notes']),
      tags: _parseTags(json['tags']),
      version: _asTrimmedString(json['version']),
      isCurrent: _asBool(json['isCurrent']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is List) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return const <String>[];
    if (text.startsWith('[') && text.endsWith(']')) {
      final normalized = text
          .substring(1, text.length - 1)
          .split(',')
          .map((part) => part.replaceAll('"', '').replaceAll("'", '').trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (normalized.isNotEmpty) return normalized;
    }
    return text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  static String? _asTrimmedString(dynamic raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || value == 'null') return null;
    return value;
  }

  static int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static bool _asBool(dynamic raw) {
    if (raw is bool) return raw;
    final value = raw?.toString().trim().toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  static DateTime? _asDate(dynamic raw) {
    final value = _asTrimmedString(raw);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}

class ClientContractFileRef {
  final String url;
  final String? blobName;
  final String? fileName;
  final String? mimeType;
  final int? size;

  const ClientContractFileRef({
    required this.url,
    this.blobName,
    this.fileName,
    this.mimeType,
    this.size,
  });

  factory ClientContractFileRef.fromJson(Map<String, dynamic> json) {
    return ClientContractFileRef(
      url: (json['url'] ?? '').toString(),
      blobName: json['blobName']?.toString(),
      fileName: json['fileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      size: json['size'] is int
          ? json['size'] as int
          : int.tryParse('${json['size'] ?? ''}'),
    );
  }
}
