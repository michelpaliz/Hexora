class BackgroundJob {
  const BackgroundJob({
    required this.id,
    required this.type,
    required this.status,
    required this.progress,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.metadata,
    required this.resultSummary,
    required this.errorMessage,
    required this.createdAt,
    required this.startedAt,
    required this.completedAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String status;
  final double progress;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> resultSummary;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'pending' || status == 'processing';
  bool get isTerminal =>
      status == 'completed' ||
      status == 'failed' ||
      status == 'needs_review' ||
      status == 'cancelled';

  double get progressFraction {
    if (progress > 1) return (progress / 100).clamp(0, 1);
    if (progress > 0) return progress.clamp(0, 1);
    if (totalItems <= 0) return 0;
    return (processedItems / totalItems).clamp(0, 1);
  }

  factory BackgroundJob.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return BackgroundJob(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString().toLowerCase(),
      progress: parseDouble(json['progress']),
      totalItems: parseInt(json['totalItems']),
      processedItems: parseInt(json['processedItems']),
      failedItems: parseInt(json['failedItems']),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const <String, dynamic>{},
      resultSummary: json['resultSummary'] is Map
          ? Map<String, dynamic>.from(json['resultSummary'] as Map)
          : const <String, dynamic>{},
      errorMessage: (json['errorMessage'] ?? '').toString().trim().isEmpty
          ? null
          : (json['errorMessage'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
