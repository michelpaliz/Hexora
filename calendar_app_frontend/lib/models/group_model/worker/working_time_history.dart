class WorkingTimeHistoryResponse {
  const WorkingTimeHistoryResponse({
    required this.period,
    required this.granularity,
    required this.workerId,
    required this.buckets,
    required this.totals,
  });

  final WorkingTimeHistoryPeriod period;
  final String granularity;
  final String? workerId;
  final List<WorkingTimeHistoryBucket> buckets;
  final WorkingTimeHistoryTotals totals;

  factory WorkingTimeHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawBuckets = json['buckets'];
    return WorkingTimeHistoryResponse(
      period: WorkingTimeHistoryPeriod.fromJson(
        _asMap(json['period']),
      ),
      granularity: (json['granularity'] ?? 'day').toString().trim(),
      workerId: _asNullableString(json['workerId']),
      buckets: rawBuckets is List
          ? rawBuckets
              .whereType<Map>()
              .map(
                (item) => WorkingTimeHistoryBucket.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <WorkingTimeHistoryBucket>[],
      totals: WorkingTimeHistoryTotals.fromJson(
        _asMap(json['totals']),
      ),
    );
  }

  bool get hasAnyHours =>
      totals.totalHours > 0 ||
      buckets.any((bucket) => bucket.totalHours > 0);
}

class WorkingTimeHistoryPeriod {
  const WorkingTimeHistoryPeriod({
    required this.from,
    required this.to,
  });

  final DateTime? from;
  final DateTime? to;

  factory WorkingTimeHistoryPeriod.fromJson(Map<String, dynamic> json) {
    return WorkingTimeHistoryPeriod(
      from: _asDateTime(json['from']),
      to: _asDateTime(json['to']),
    );
  }
}

class WorkingTimeHistoryBucket {
  const WorkingTimeHistoryBucket({
    required this.key,
    required this.label,
    required this.from,
    required this.to,
    required this.entriesCount,
    required this.totalMinutes,
    required this.totalHours,
    required this.workers,
  });

  final String key;
  final String label;
  final DateTime? from;
  final DateTime? to;
  final int entriesCount;
  final int totalMinutes;
  final double totalHours;
  final List<WorkingTimeHistoryBucketWorker> workers;

  factory WorkingTimeHistoryBucket.fromJson(Map<String, dynamic> json) {
    final rawWorkers = json['workers'];
    return WorkingTimeHistoryBucket(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      from: _asDateTime(json['from']),
      to: _asDateTime(json['to']),
      entriesCount: _asInt(json['entriesCount']),
      totalMinutes: _asInt(json['totalMinutes']),
      totalHours: _asDouble(json['totalHours']),
      workers: rawWorkers is List
          ? rawWorkers
              .whereType<Map>()
              .map(
                (item) => WorkingTimeHistoryBucketWorker.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <WorkingTimeHistoryBucketWorker>[],
    );
  }
}

class WorkingTimeHistoryBucketWorker {
  const WorkingTimeHistoryBucketWorker({
    required this.workerId,
    required this.displayName,
    required this.status,
    required this.entriesCount,
    required this.totalMinutes,
    required this.totalHours,
  });

  final String workerId;
  final String displayName;
  final String status;
  final int entriesCount;
  final int totalMinutes;
  final double totalHours;

  factory WorkingTimeHistoryBucketWorker.fromJson(Map<String, dynamic> json) {
    return WorkingTimeHistoryBucketWorker(
      workerId: (json['workerId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      entriesCount: _asInt(json['entriesCount']),
      totalMinutes: _asInt(json['totalMinutes']),
      totalHours: _asDouble(json['totalHours']),
    );
  }
}

class WorkingTimeHistoryTotals {
  const WorkingTimeHistoryTotals({
    required this.entriesCount,
    required this.totalMinutes,
    required this.totalHours,
  });

  final int entriesCount;
  final int totalMinutes;
  final double totalHours;

  factory WorkingTimeHistoryTotals.fromJson(Map<String, dynamic> json) {
    return WorkingTimeHistoryTotals(
      entriesCount: _asInt(json['entriesCount']),
      totalMinutes: _asInt(json['totalMinutes']),
      totalHours: _asDouble(json['totalHours']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? 0;
}
