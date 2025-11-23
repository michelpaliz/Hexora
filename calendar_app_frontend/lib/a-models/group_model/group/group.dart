// lib/a-models/group_model/group/group.dart
import 'package:hexora/a-models/group_model/calendar/calendar.dart';
import 'package:hexora/a-models/group_model/group/group_business_hours.dart';
import 'package:hexora/a-models/group_model/group/group_features.dart';
import 'package:hexora/c-frontend/utils/roles/id_normalize/id_normalizer.dart';

class Group {
  // ---------- Core ----------
  final String id;
  String name;
  final String ownerId;

  /// userRoles is keyed by **userId**, not username.
  /// Values: "owner", "admin", "co-admin", "member"
  final Map<String, String> userRoles;

  List<String> userIds;
  DateTime createdTime;
  String description;

  // ---------- Media ----------
  String? photoUrl; // CDN/public URL if AVATARS_PUBLIC
  String? photoBlobName; // e.g. "groups/<id>/<uuid>.jpg"
  String? computedPhotoUrl; // backend virtual

  // ---------- Invite stats (denormalized) ----------
  int inviteCount;
  DateTime? lastInviteAt;

  // ---------- Calendar ----------
  String? defaultCalendarId; // set by backend
  Calendar? defaultCalendar; // optional snapshot

  // ---------- Features / Plugins ----------
  GroupFeatures? features; // mirrors backend `features`
  GroupBusinessHours? businessHours;

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.userRoles,
    required this.userIds,
    required this.createdTime,
    required this.description,
    this.photoUrl,
    this.photoBlobName,
    this.computedPhotoUrl,
    this.inviteCount = 0,
    this.lastInviteAt,
    this.defaultCalendarId,
    this.defaultCalendar,
    this.features,
    this.businessHours,
  });

  /// Primary way to get the calendar id
  String? get calendarId =>
      (defaultCalendarId != null && defaultCalendarId!.isNotEmpty)
          ? defaultCalendarId
          : defaultCalendar?.id;

  bool get hasCalendar => calendarId != null;

  // Small date helper (works with "$date", ISO string, DateTime)
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Map && v[r'$date'] != null) {
      final raw = v[r'$date'];
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    if (v is String) return DateTime.tryParse(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }

  // ---------- JSON ----------
  factory Group.fromJson(Map<String, dynamic> json) {
    // Normalize nested calendar if present
    Calendar? defaultCal;
    if (json['defaultCalendar'] is Map<String, dynamic>) {
      defaultCal = Calendar.fromJson(json['defaultCalendar']);
    }

    // Normalize features
    GroupFeatures? fx;
    if (json['features'] is Map<String, dynamic>) {
      fx = GroupFeatures.fromJson(json['features'] as Map<String, dynamic>);
    }

    GroupBusinessHours? hours;
    if (json['businessHours'] is Map<String, dynamic>) {
      hours = GroupBusinessHours.fromJson(
        json['businessHours'] as Map<String, dynamic>,
      );
    } else if (json['features'] is Map<String, dynamic>) {
      final fxJson = json['features'] as Map<String, dynamic>;
      final nested = fxJson['businessHours'];
      if (nested is Map<String, dynamic>) {
        hours = GroupBusinessHours.fromJson(nested);
      }
    }

    // Normalize ids, lists, and userRoles keys/values
    final normalizedUserRoles =
        normalizeUserRoleWireMap(json['userRoles'] as Map?);

    return Group(
      id: normalizeId(json['_id'] ?? json['id']),
      name: (json['name'] ?? '').toString(),
      ownerId: normalizeId(json['ownerId']),
      userRoles: normalizedUserRoles,
      userIds: normalizeIdList(json['userIds']),
      createdTime: _parseDate(json['createdTime']) ?? DateTime.now(),
      description: (json['description'] ?? '').toString(),
      photoUrl: json['photoUrl']?.toString(),
      photoBlobName: json['photoBlobName']?.toString(),
      computedPhotoUrl: json['computedPhotoUrl']?.toString(),
      inviteCount: (json['inviteCount'] is num)
          ? (json['inviteCount'] as num).toInt()
          : 0,
      lastInviteAt: _parseDate(json['lastInviteAt']),
      defaultCalendarId: normalizeId(json['defaultCalendarId']),
      defaultCalendar: defaultCal,
      features: fx,
      businessHours: hours,
    );
  }

  /// For group updates (matches backend whitelist)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoBlobName != null) 'photoBlobName': photoBlobName,
      'userRoles': userRoles, // userId -> role
      'userIds': userIds,
      if (features != null) 'features': features!.toJson(),
      if (businessHours != null) 'businessHours': businessHours!.toJson(),
      // inviteCount/lastInviteAt are server-managed; omit on updates
    };
  }

  /// For group creation (backend assigns calendar & manages invite stats)
  Map<String, dynamic> toJsonForCreation() {
    return {
      'name': name,
      'ownerId': ownerId,
      'userRoles': userRoles, // userId -> role
      'userIds': userIds,
      'description': description,
      'createdTime': createdTime.toIso8601String(),
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoBlobName != null) 'photoBlobName': photoBlobName,
      if (features != null) 'features': features!.toJson(),
      if (businessHours != null) 'businessHours': businessHours!.toJson(),
    };
  }

  // ---------- Copy ----------
  Group copyWith({
    String? id,
    String? name,
    String? ownerId,
    Map<String, String>? userRoles,
    List<String>? userIds,
    DateTime? createdTime,
    String? description,
    String? photoUrl,
    String? photoBlobName,
    String? computedPhotoUrl,
    int? inviteCount,
    DateTime? lastInviteAt,
    String? defaultCalendarId,
    Calendar? defaultCalendar,
    GroupFeatures? features,
    GroupBusinessHours? businessHours,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      userRoles: userRoles ?? Map<String, String>.from(this.userRoles),
      userIds: userIds ?? List<String>.from(this.userIds),
      createdTime: createdTime ?? this.createdTime,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBlobName: photoBlobName ?? this.photoBlobName,
      computedPhotoUrl: computedPhotoUrl ?? this.computedPhotoUrl,
      inviteCount: inviteCount ?? this.inviteCount,
      lastInviteAt: lastInviteAt ?? this.lastInviteAt,
      defaultCalendarId: defaultCalendarId ?? this.defaultCalendarId,
      defaultCalendar: defaultCalendar ?? this.defaultCalendar,
      features: features ?? this.features,
      businessHours: businessHours ?? this.businessHours,
    );
  }

  // ---------- Defaults ----------
  static Group createDefaultGroup() {
    return Group(
      id: 'default_id',
      name: 'Default Group Name',
      ownerId: 'default_owner_id',
      userRoles: const {},
      userIds: const [],
      createdTime: DateTime.now(),
      description: 'Default Description',
      inviteCount: 0,
      lastInviteAt: null,
      features: const GroupFeatures(
        // default mirrors backend defaults
        timeTracking: TimeTrackingSettings(
          enabled: false,
          roundingPreset: TimeRoundingPreset.nearest5_tie05_down,
          currency: 'EUR',
        ),
      ),
      businessHours: null,
    );
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, ownerId: $ownerId, '
        'userRoles: $userRoles, userIds: $userIds, description: $description, '
        'photoUrl: $photoUrl, photoBlobName: $photoBlobName, '
        'computedPhotoUrl: $computedPhotoUrl, inviteCount: $inviteCount, lastInviteAt: $lastInviteAt, '
        'defaultCalendarId: $defaultCalendarId, defaultCalendar: $defaultCalendar, '
        'features: $features, businessHours: $businessHours}';
  }
}
