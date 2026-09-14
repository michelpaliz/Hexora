import 'package:flutter/foundation.dart';

enum WorkerStatus { active, archived }

WorkerStatus _statusFromJson(String? v) {
  switch ((v ?? 'active').toLowerCase()) {
    case 'archived':
      return WorkerStatus.archived;
    case 'active':
    default:
      return WorkerStatus.active;
  }
}

String _statusToJson(WorkerStatus s) {
  switch (s) {
    case WorkerStatus.archived:
      return 'archived';
    case WorkerStatus.active:
      return 'active';
  }
}

/// Mirrors backend models/worker.js (after its toJSON transform).
@immutable
class Worker {
  static const Object _unset = Object();

  final String id; // backend sets `id` (string) in toJSON
  final String groupId; // route param on create, but returned in payloads
  final String? userId; // can be null (external worker)
  final String? displayName; // optional or override
  final WorkerStatus status; // "active" | "archived"
  final double? defaultHourlyRate;
  final double? advanceAmount;
  final String? currency; // e.g., "EUR"
  final String? externalId;
  final String? roleTag; // e.g., "barista"
  final String? notes; // <= 1000 chars
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Worker({
    required this.id,
    required this.groupId,
    required this.status,
    this.userId,
    this.displayName,
    this.defaultHourlyRate,
    this.advanceAmount,
    this.currency,
    this.externalId,
    this.roleTag,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory for brand-new, not-yet-saved workers (handy for UI forms).
  /// Note: `id` is empty until server returns it.
  factory Worker.newExternal({
    required String groupId,
    String? displayName,
    double? defaultHourlyRate,
    double? advanceAmount,
    String? currency,
    String? externalId,
    String? roleTag,
    String? notes,
  }) =>
      Worker(
        id: '',
        groupId: groupId,
        status: WorkerStatus.active,
        userId: null,
        displayName: displayName,
        defaultHourlyRate: defaultHourlyRate,
        advanceAmount: advanceAmount,
        currency: currency,
        externalId: externalId,
        roleTag: roleTag,
        notes: notes,
      );

  factory Worker.newLinkedUser({
    required String groupId,
    required String userId,
    double? defaultHourlyRate,
    double? advanceAmount,
    String? currency,
    String? roleTag,
    String? notes,
  }) =>
      Worker(
        id: '',
        groupId: groupId,
        status: WorkerStatus.active,
        userId: userId,
        displayName: null,
        defaultHourlyRate: defaultHourlyRate,
        advanceAmount: advanceAmount,
        currency: currency,
        externalId: null,
        roleTag: roleTag,
        notes: notes,
      );

  /// Nullable fields use the model update convention documented in
  /// `docs/nullable_update_convention.md`.
  Worker copyWith({
    String? id,
    String? groupId,
    Object? userId = _unset,
    Object? displayName = _unset,
    WorkerStatus? status,
    Object? defaultHourlyRate = _unset,
    Object? advanceAmount = _unset,
    Object? currency = _unset,
    Object? externalId = _unset,
    Object? roleTag = _unset,
    Object? notes = _unset,
    Object? createdAt = _unset,
    Object? updatedAt = _unset,
  }) {
    return Worker(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      displayName: identical(displayName, _unset)
          ? this.displayName
          : displayName as String?,
      status: status ?? this.status,
      defaultHourlyRate: identical(defaultHourlyRate, _unset)
          ? this.defaultHourlyRate
          : defaultHourlyRate as double?,
      advanceAmount: identical(advanceAmount, _unset)
          ? this.advanceAmount
          : advanceAmount as double?,
      currency:
          identical(currency, _unset) ? this.currency : currency as String?,
      externalId: identical(externalId, _unset)
          ? this.externalId
          : externalId as String?,
      roleTag:
          identical(roleTag, _unset) ? this.roleTag : roleTag as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      userId: json['userId'] as String?,
      displayName: json['displayName'] as String?,
      status: _statusFromJson(json['status'] as String?),
      defaultHourlyRate: (json['defaultHourlyRate'] as num?)?.toDouble(),
      advanceAmount: (json['advanceAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      externalId: json['externalId'] as String?,
      roleTag: json['roleTag'] as String?,
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] != null)
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: (json['updatedAt'] != null)
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// For CREATE calls (backend route is strict; groupId comes from the URL).
  /// Send only allowed updatable/creatable fields.
  Map<String, dynamic> toCreateJson() {
    return {
      if (userId != null) 'userId': userId,
      if (displayName != null) 'displayName': displayName,
      if (defaultHourlyRate != null) 'defaultHourlyRate': defaultHourlyRate,
      if (advanceAmount != null) 'advanceAmount': advanceAmount,
      if (currency != null) 'currency': currency,
      if (externalId != null) 'externalId': externalId,
      if (roleTag != null) 'roleTag': roleTag,
      if (notes != null) 'notes': notes,
      // status is optional on create; backend defaults to "active"
    };
  }

  /// For UPDATE/PATCH calls.
  Map<String, dynamic> toUpdateJson() {
    return {
      'displayName': displayName,
      'status': _statusToJson(status),
      'defaultHourlyRate': defaultHourlyRate,
      if (advanceAmount != null) 'advanceAmount': advanceAmount,
      if (currency != null) 'currency': currency,
      if (externalId != null) 'externalId': externalId,
      'roleTag': roleTag,
      'notes': notes,
    };
  }
}
