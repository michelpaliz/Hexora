import 'package:hexora/models/event/event_utils.dart' as utils;
import 'package:hexora/models/recurrence_rule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/models/recurrence_rule/utils_recurrence_rule/custom_day_week.dart';
import 'package:hexora/models/notification/updateInfo.dart';

/// A simple mutable Event model without code generation.
class Event {
  // -------- Core (existing) --------
  String id;
  DateTime startDate;
  DateTime endDate;
  String title;
  String? groupId;
  String? calendarId;
  LegacyRecurrenceRule? recurrence_rule;
  String? localization;
  String? note;
  String? description;
  int eventColorIndex;
  bool allDay;
  int? reminderTime;
  bool isDone;
  DateTime? completedAt;
  List<String> recipients;
  String ownerId;
  List<UpdateInfo> updateHistory;
  final String? rawRuleId;
  String? status; // pending | in_progress | done | cancelled | overdue

  // -------- Legacy categorization (keep for SIMPLE events) --------
  String? categoryId; // parent category
  String? subcategoryId; // child under categoryId

  // -------- NEW: Work-visit modeling --------
  /// Event form/validation type: 'simple' | 'work_visit'
  String type;

  /// For type='work_visit'
  String? clientId;
  String? primaryServiceId; // must appear in visitServices
  String? stopId; // optional grouping of back-to-back events
  List<VisitService> visitServices;

  /// Whether the owner should receive notifications (default true).
  bool notifyOwner;

  // -------- NEW: Completion evidence (photos) --------
  /// Manager-configured; OFF by default. Only gates "mark as finished".
  CompletionRequirements completionRequirements;

  /// Server-managed; photos can always be uploaded regardless of the toggle above.
  List<CompletionPhoto> completionPhotos;

  /// Server-managed; who pressed "mark as finished".
  String? completedByUserId;

  Event({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.title,
    this.groupId,
    this.calendarId,
    this.recurrence_rule,
    this.rawRuleId,
    this.localization,
    this.note,
    this.description,
    this.eventColorIndex = 0,
    this.allDay = false,
    this.reminderTime,
    this.isDone = false,
    this.completedAt,
    List<String>? recipients,
    required this.ownerId,
    List<UpdateInfo>? updateHistory,
    this.status,
    this.categoryId,
    this.subcategoryId,
    this.notifyOwner = true,

    // NEW
    this.type = 'simple',
    this.clientId,
    this.primaryServiceId,
    this.stopId,
    List<VisitService>? visitServices,
    CompletionRequirements? completionRequirements,
    List<CompletionPhoto>? completionPhotos,
    this.completedByUserId,
  })  : recipients = recipients ?? [],
        updateHistory = updateHistory ?? [],
        visitServices = visitServices ?? [],
        completionRequirements =
            completionRequirements ?? CompletionRequirements.disabled(),
        completionPhotos = completionPhotos ?? [];

  // -------- Convenience --------
  bool get ownerMuted => notifyOwner == false;
  bool get isCompleted =>
      isDone == true ||
      completedAt != null ||
      (status?.toLowerCase() == 'done');

  bool get isWorkVisit => (type.toLowerCase() == 'work_visit');

  /// Whether "mark as finished" should stay locked pending more photo evidence.
  bool get needsMorePhotosToComplete =>
      completionRequirements.requirePhotos &&
      (completionPhotos.length < completionRequirements.minPhotos ||
          (completionRequirements.requireBeforeAfterPhotos &&
              (!completionPhotos.any((p) => p.photoType == 'before') ||
                  !completionPhotos.any((p) => p.photoType == 'after'))));

  /// Adds an update record.
  void addUpdate(String userId) {
    updateHistory.add(UpdateInfo(userId: userId, updatedAt: DateTime.now()));
  }

  // -------- Copy --------
  Event copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? title,
    String? groupId,
    String? calendarId,
    LegacyRecurrenceRule? recurrence_rule,
    String? rawRuleId,
    String? localization,
    String? note,
    String? description,
    int? eventColorIndex,
    bool? allDay,
    int? reminderTime,
    bool? isDone,
    DateTime? completedAt,
    List<String>? recipients,
    String? ownerId,
    List<UpdateInfo>? updateHistory,
    String? status,
    String? categoryId,
    String? subcategoryId,
    bool? notifyOwner,

    // NEW
    String? type,
    String? clientId,
    String? primaryServiceId,
    String? stopId,
    List<VisitService>? visitServices,
    CompletionRequirements? completionRequirements,
    List<CompletionPhoto>? completionPhotos,
    String? completedByUserId,
  }) {
    return Event(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      title: title ?? this.title,
      groupId: groupId ?? this.groupId,
      calendarId: calendarId ?? this.calendarId,
      recurrence_rule: recurrence_rule ?? this.recurrence_rule,
      rawRuleId: rawRuleId ?? this.rawRuleId,
      localization: localization ?? this.localization,
      note: note ?? this.note,
      description: description ?? this.description,
      eventColorIndex: eventColorIndex ?? this.eventColorIndex,
      allDay: allDay ?? this.allDay,
      reminderTime: reminderTime ?? this.reminderTime,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      recipients: recipients ?? List<String>.from(this.recipients),
      ownerId: ownerId ?? this.ownerId,
      updateHistory: updateHistory != null
          ? List<UpdateInfo>.from(updateHistory.map((u) => u.copyWith()))
          : List<UpdateInfo>.from(this.updateHistory),
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      notifyOwner: notifyOwner ?? this.notifyOwner,

      // NEW
      type: type ?? this.type,
      clientId: clientId ?? this.clientId,
      primaryServiceId: primaryServiceId ?? this.primaryServiceId,
      stopId: stopId ?? this.stopId,
      visitServices: visitServices != null
          ? List<VisitService>.from(visitServices.map((v) => v.copyWith()))
          : List<VisitService>.from(this.visitServices),
      completionRequirements:
          completionRequirements ?? this.completionRequirements.copyWith(),
      completionPhotos: completionPhotos != null
          ? List<CompletionPhoto>.from(completionPhotos)
          : List<CompletionPhoto>.from(this.completionPhotos),
      completedByUserId: completedByUserId ?? this.completedByUserId,
    );
  }

  // -------- Serialization (app map) --------
  Map<String, dynamic> toMap() => {
        'id': id,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'title': title,
        'groupId': groupId,
        'calendarId': calendarId,
        'recurrence_rule': utils.mapRule(recurrence_rule),
        'rawRuleId': rawRuleId,
        'localization': localization,
        'note': note,
        'description': description,
        'eventColorIndex': eventColorIndex,
        'allDay': allDay,
        'reminderTime': reminderTime,
        'isDone': isDone,
        'completedAt': completedAt?.toUtc().toIso8601String(),
        'recipients': recipients,
        'ownerId': ownerId,
        'updateHistory': updateHistory.map((u) => u.toMap()).toList(),
        'notifyOwner': notifyOwner,
        'status': status,

        // Legacy (simple)
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,

        // NEW (work_visit)
        'type': type,
        'clientId': clientId,
        'primaryServiceId': primaryServiceId,
        'stopId': stopId,
        'visitServices': visitServices.map((v) => v.toMap()).toList(),

        // NEW (completion evidence)
        'completionRequirements': completionRequirements.toMap(),
        'completionPhotos': completionPhotos.map((p) => p.toMap()).toList(),
        'completedByUserId': completedByUserId,
      };

  /// Deserializes from an API map.
  factory Event.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['_id'];
    if (rawId == null) {
      throw Exception("❌ Missing 'id' and '_id' in map: $map");
    }

    DateTime parseApiDate(String raw) {
      final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
      final parsed = DateTime.parse(raw);
      if (hasOffset) {
        return parsed.isUtc ? parsed.toLocal() : parsed;
      }
      final asUtc = DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
      return asUtc.toLocal();
    }

    // Recurrence
    final raw = map['recurrence_rule'];
    LegacyRecurrenceRule? rule;
    if (raw != null) {
      if (raw is Map<String, dynamic>) {
        rule = LegacyRecurrenceRule.fromJson(raw);
      } else if (raw is Map) {
        rule = LegacyRecurrenceRule.fromJson(raw.cast<String, dynamic>());
      }
    }

    // Legacy categories
    final String? catId = map['categoryId']?.toString();
    final String? subId = map['subcategoryId']?.toString();

    // NEW: work-visit fields
    final String type = (map['type'] as String?)?.toLowerCase() ?? 'simple';
    final String? clientId = map['clientId']?.toString();
    final String? primaryServiceId = map['primaryServiceId']?.toString();
    final String? stopId = map['stopId']?.toString();

    final List<VisitService> visitServices = (map['visitServices'] as List?)
            ?.map((e) => VisitService.fromMap(
                  (e as Map).cast<String, dynamic>(),
                ))
            .toList() ??
        <VisitService>[];

    // NEW: completion evidence
    final CompletionRequirements completionRequirements =
        map['completionRequirements'] is Map
            ? CompletionRequirements.fromMap(
                (map['completionRequirements'] as Map).cast<String, dynamic>(),
              )
            : CompletionRequirements.disabled();

    final List<CompletionPhoto> completionPhotos =
        (map['completionPhotos'] as List?)
                ?.map((e) => CompletionPhoto.fromMap(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList() ??
            <CompletionPhoto>[];

    final String? completedByUserId = map['completedByUserId']?.toString();

    final start = parseApiDate(map['startDate'] as String);
    final end = parseApiDate(map['endDate'] as String);
    final completedRaw = map['completedAt'] != null
        ? parseApiDate(map['completedAt'] as String)
        : null;

    return Event(
      id: rawId.toString(),
      startDate: start,
      endDate: end,
      title: map['title'] as String? ?? '',
      groupId: map['groupId'] as String?,
      calendarId: map['calendarId'] as String?,
      recurrence_rule: rule,
      rawRuleId: map['rawRuleId'] as String?,
      localization: map['localization'] as String?,
      note: map['note'] as String?,
      description: map['description'] as String?,
      eventColorIndex: map['eventColorIndex'] as int? ?? 0,
      allDay: map['allDay'] as bool? ?? false,
      reminderTime: map['reminderTime'] as int?,
      isDone: map['isDone'] as bool? ?? false,
      completedAt: completedRaw,
      recipients: List<String>.from(map['recipients'] ?? []),
      ownerId: map['ownerId'] as String? ?? '',
      updateHistory: (map['updateHistory'] as List?)
              ?.map((e) => UpdateInfo.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notifyOwner: map['notifyOwner'] as bool? ?? true,
      status: (map['status'] as String?)?.toLowerCase(),

      // legacy
      categoryId: catId,
      subcategoryId: subId,

      // NEW
      type: type,
      clientId: clientId,
      primaryServiceId: primaryServiceId,
      stopId: stopId,
      visitServices: visitServices,

      // NEW
      completionRequirements: completionRequirements,
      completionPhotos: completionPhotos,
      completedByUserId: completedByUserId,
    );
  }

  String? get rule => recurrence_rule?.toRRuleString(startDate);

  // JSON helpers
  factory Event.fromJson(Map<String, dynamic> json) => Event.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  /// Payload to backend (create/update).
  Map<String, dynamic> toBackendJson() {
    // --- Recurrence: send as ObjectId when it looks like one; otherwise embed the rule object ---
    final recurrence_ruleJson = recurrence_rule == null
        ? null
        : RegExp(r'^[a-f0-9]{24}$').hasMatch(recurrence_rule!.id)
            ? recurrence_rule!.id
            : utils.mapRule(recurrence_rule);

    // --- Status normalization (server expects these tokens) ---
    const validStatuses = {
      'pending',
      'in_progress',
      'done',
      'cancelled',
      'overdue'
    };
    String? cleanStatus;
    if (status != null) {
      final s = status!.trim().toLowerCase().replaceAll(' ', '_');
      if (validStatuses.contains(s)) cleanStatus = s;
    }

    // --- Detect work-visit intent from actual selections ---
    final hasClient = (clientId != null && clientId!.isNotEmpty);
    final hasPrimaryService =
        (primaryServiceId != null && primaryServiceId!.isNotEmpty);
    final hasVisitServices = visitServices.isNotEmpty;
    final hasWork = hasClient || hasPrimaryService || hasVisitServices;

    // --- Effective type: promote to work_visit if any work fields are present ---
    final String effectiveType = hasWork
        ? 'work_visit'
        : (type.toLowerCase() == 'work_visit' ? 'work_visit' : 'simple');

    // --- Ensure visitServices contains primaryServiceId if provided ---
    List<VisitService> vsOut = visitServices;
    if (hasPrimaryService) {
      final containsPrimary =
          visitServices.any((v) => v.serviceId == primaryServiceId);
      if (!containsPrimary) {
        vsOut = <VisitService>[
          VisitService(serviceId: primaryServiceId!),
          ...visitServices
        ];
      }
    }

    // --- Build base payload ---
    final map = <String, dynamic>{
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'title': title,
      'groupId': groupId,
      'calendarId': calendarId,
      'recurrence_rule': recurrence_ruleJson,
      'localization': localization,
      'note': note,
      'description': description,
      'eventColorIndex': eventColorIndex,
      'allDay': allDay,
      'reminderTime': reminderTime,
      'isDone': isDone,
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'recipients': recipients,
      'ownerId': ownerId,
      'updateHistory': updateHistory.map((u) => u.toMap()).toList(),
      'notifyOwner': notifyOwner,

      // Type + work-visit fields
      'type': effectiveType,
      'clientId': hasClient ? clientId : null,
      'primaryServiceId': hasPrimaryService ? primaryServiceId : null,
      'stopId': stopId,
      'visitServices': vsOut.map((v) => v.toMap()).toList(),

      // Legacy categories only meaningful for simple events; null them otherwise
      'categoryId': effectiveType == 'simple' ? categoryId : null,
      'subcategoryId': effectiveType == 'simple' ? subcategoryId : null,

      // Completion requirements (manager-configured; server owns completionPhotos/completedByUserId)
      'completionRequirements': completionRequirements.toMap(),
    };

    if (cleanStatus != null) {
      map['status'] = cleanStatus;
    }

    return map;
  }

  @override
  String toString() {
    return 'Event{'
        'id: $id, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'title: $title, '
        'groupId: $groupId, '
        'calendarId: $calendarId, '
        'type: $type, '
        'clientId: $clientId, '
        'primaryServiceId: $primaryServiceId, '
        'stopId: $stopId, '
        'recurrence_rule: $recurrence_rule, '
        'localization: $localization, '
        'note: $note, '
        'description: $description, '
        'eventColorIndex: $eventColorIndex, '
        'allDay: $allDay, '
        'reminderTime: $reminderTime, '
        'isDone: $isDone, '
        'completedAt: $completedAt, '
        'recipients: $recipients, '
        'ownerId: $ownerId, '
        'notifyOwner: $notifyOwner, '
        'status: $status, '
        'categoryId: $categoryId, '
        'subcategoryId: $subcategoryId, '
        'visitServices: $visitServices, '
        'updateHistory: $updateHistory'
        '}';
  }

  @override
  bool operator ==(Object other) {
    return other is Event &&
        other.id == id &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.title == title &&
        other.calendarId == calendarId &&
        other.eventColorIndex == eventColorIndex &&
        other.type == type &&
        other.clientId == clientId;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      title.hashCode ^
      calendarId.hashCode ^
      eventColorIndex.hashCode ^
      type.hashCode ^
      (clientId?.hashCode ?? 0);

  /// Returns a human-readable recurrence summary string.
  String get recurrenceDescription {
    final rule = recurrence_rule;
    if (rule == null) return '';
    final buffer = StringBuffer('Repeats ');
    switch (rule.recurrenceType) {
      case RecurrenceType.Daily:
        buffer.write('every ${rule.repeatInterval ?? 1} day(s)');
        break;
      case RecurrenceType.Weekly:
        buffer.write('weekly');
        if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
          final days = rule.daysOfWeek!.map((d) => d.shortName).join(', ');
          buffer.write(' on $days');
        }
        break;
      case RecurrenceType.Monthly:
        if (rule.dayOfMonth != null) {
          buffer.write('monthly on day ${rule.dayOfMonth}');
        } else {
          buffer.write('monthly');
        }
        break;
      case RecurrenceType.Yearly:
        if (rule.month != null && rule.dayOfMonth != null) {
          buffer.write('yearly on ${rule.month}/${rule.dayOfMonth}');
        } else {
          buffer.write('yearly');
        }
        break;
    }
    if (rule.untilDate != null) {
      final dateStr =
          rule.untilDate!.toLocal().toIso8601String().split('T').first;
      buffer.write(' until $dateStr');
    }
    return buffer.toString();
  }
}

/// NEW: per-event service entry (ties an event to one Service)
class VisitService {
  final String serviceId;
  final int? plannedMinutes;
  final int? actualMinutes;
  final String? notes;

  const VisitService({
    required this.serviceId,
    this.plannedMinutes,
    this.actualMinutes,
    this.notes,
  });

  VisitService copyWith({
    String? serviceId,
    int? plannedMinutes,
    int? actualMinutes,
    String? notes,
  }) {
    return VisitService(
      serviceId: serviceId ?? this.serviceId,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'serviceId': serviceId,
        'plannedMinutes': plannedMinutes,
        'actualMinutes': actualMinutes,
        'notes': notes,
      };

  factory VisitService.fromMap(Map<String, dynamic> map) {
    return VisitService(
      serviceId: map['serviceId']?.toString() ?? '',
      plannedMinutes: map['plannedMinutes'] is num
          ? (map['plannedMinutes'] as num).toInt()
          : null,
      actualMinutes: map['actualMinutes'] is num
          ? (map['actualMinutes'] as num).toInt()
          : null,
      notes: map['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'VisitService(serviceId: $serviceId, planned: $plannedMinutes, actual: $actualMinutes)';
}

/// NEW: manager-configured completion evidence requirement. OFF by default.
class CompletionRequirements {
  final bool requirePhotos;
  final int minPhotos;
  final bool requireBeforeAfterPhotos;

  const CompletionRequirements({
    required this.requirePhotos,
    required this.minPhotos,
    this.requireBeforeAfterPhotos = false,
  });

  const CompletionRequirements.disabled()
      : requirePhotos = false,
        minPhotos = 1,
        requireBeforeAfterPhotos = false;

  CompletionRequirements copyWith({
    bool? requirePhotos,
    int? minPhotos,
    bool? requireBeforeAfterPhotos,
  }) {
    return CompletionRequirements(
      requirePhotos: requirePhotos ?? this.requirePhotos,
      minPhotos: minPhotos ?? this.minPhotos,
      requireBeforeAfterPhotos:
          requireBeforeAfterPhotos ?? this.requireBeforeAfterPhotos,
    );
  }

  Map<String, dynamic> toMap() => {
        'requirePhotos': requirePhotos,
        'minPhotos': minPhotos,
        'requireBeforeAfterPhotos': requireBeforeAfterPhotos,
      };

  factory CompletionRequirements.fromMap(Map<String, dynamic> map) {
    final rawMin = map['minPhotos'];
    final parsedMin = rawMin is num ? rawMin.toInt() : int.tryParse('$rawMin');
    return CompletionRequirements(
      requirePhotos: map['requirePhotos'] as bool? ?? false,
      minPhotos: (parsedMin ?? 1) < 1 ? 1 : (parsedMin ?? 1),
      requireBeforeAfterPhotos:
          map['requireBeforeAfterPhotos'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'CompletionRequirements(requirePhotos: $requirePhotos, minPhotos: $minPhotos)';
}

/// NEW: a single completion evidence photo uploaded by a worker.
class CompletionPhoto {
  final String? id;
  final String blobName;
  final String? mimeType;
  final String photoType;
  final String uploadedByUserId;
  final DateTime? uploadedAt;

  const CompletionPhoto({
    this.id,
    required this.blobName,
    this.mimeType,
    this.photoType = 'general',
    required this.uploadedByUserId,
    this.uploadedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'blobName': blobName,
        'mimeType': mimeType,
        'photoType': photoType,
        'uploadedByUserId': uploadedByUserId,
        'uploadedAt': uploadedAt?.toUtc().toIso8601String(),
      };

  factory CompletionPhoto.fromMap(Map<String, dynamic> map) {
    final rawUploadedAt = map['uploadedAt'] as String?;
    return CompletionPhoto(
      id: (map['id'] ?? map['_id'])?.toString(),
      blobName: map['blobName']?.toString() ?? '',
      mimeType: map['mimeType'] as String?,
      photoType: map['photoType']?.toString() ?? 'general',
      uploadedByUserId: map['uploadedByUserId']?.toString() ?? '',
      uploadedAt:
          rawUploadedAt != null ? DateTime.tryParse(rawUploadedAt) : null,
    );
  }

  @override
  String toString() =>
      'CompletionPhoto(blobName: $blobName, uploadedByUserId: $uploadedByUserId, uploadedAt: $uploadedAt)';
}
