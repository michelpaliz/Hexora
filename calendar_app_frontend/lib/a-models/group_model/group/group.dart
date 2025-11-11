import 'package:hexora/a-models/group_model/calendar/calendar.dart';
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
  GroupFeatures? features; // <— NEW (mirrors backend `features`)

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
    this.features, // <— NEW
  });

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

    // ✅ Normalize ids, lists, and userRoles keys/values
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
      if (features != null) 'features': features!.toJson(), // <— optional
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
      if (features != null) 'features': features!.toJson(), // <— optional
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
    GroupFeatures? features, // <— NEW
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
      features: features ?? this.features, // <— NEW
    );
  }

  // ---------- Helpers ----------
  bool isOwner(String userId) => ownerId == userId;

  String roleFor(String userId) {
    if (isOwner(userId)) return 'owner';
    final r = userRoles[userId];
    const valid = {'owner', 'admin', 'co-admin', 'member'};
    return valid.contains(r) ? r! : 'member';
  }

  List<String> get adminIds => userRoles.entries
      .where((e) => e.value == 'admin')
      .map((e) => e.key)
      .toList();

  List<String> get coAdminIds => userRoles.entries
      .where((e) => e.value == 'co-admin')
      .map((e) => e.key)
      .toList();

  List<String> get memberIds => userRoles.entries
      .where((e) => e.value == 'member')
      .map((e) => e.key)
      .toList();

  /// Primary way to get the calendar id
  String? get calendarId =>
      (defaultCalendarId != null && defaultCalendarId!.isNotEmpty)
          ? defaultCalendarId
          : defaultCalendar?.id;

  bool get hasCalendar => calendarId != null;

  // ---------- Equality ----------
  bool isEqual(Group other) {
    return id == other.id &&
        name == other.name &&
        ownerId == other.ownerId &&
        userRoles.toString() == other.userRoles.toString() &&
        _listEq(userIds, other.userIds) &&
        description == other.description &&
        photoUrl == other.photoUrl &&
        photoBlobName == other.photoBlobName &&
        computedPhotoUrl == other.computedPhotoUrl &&
        defaultCalendarId == other.defaultCalendarId &&
        inviteCount == other.inviteCount &&
        _dtEq(lastInviteAt, other.lastInviteAt) &&
        _featuresEq(features, other.features);
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _dtEq(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toIso8601String() == b.toIso8601String();
  }

  static bool _featuresEq(GroupFeatures? a, GroupFeatures? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toString() == b.toString(); // simple: relies on toString above
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
        // <— default mirrors backend defaults
        timeTracking: TimeTrackingSettings(
          enabled: false,
          roundingPreset: TimeRoundingPreset.nearest5_tie05_down,
          currency: 'EUR',
        ),
      ),
    );
  }

  @override
  String toString() {
    return 'Group{id: $id, name: $name, ownerId: $ownerId, '
        'userRoles: $userRoles, userIds: $userIds, description: $description, '
        'photoUrl: $photoUrl, photoBlobName: $photoBlobName, '
        'computedPhotoUrl: $computedPhotoUrl, inviteCount: $inviteCount, lastInviteAt: $lastInviteAt, '
        'defaultCalendarId: $defaultCalendarId, defaultCalendar: $defaultCalendar, '
        'features: $features}';
  }
}

// NOTE: you already define calendarId/hasCalendar inside the class,
// so avoid duplicating the same getters in an extension to prevent conflicts.
// If you still want the extension for ergonomics across types, remove the
// in-class getters first or rename the extension getters.
