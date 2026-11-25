// lib/models/groups/group.dart
import 'package:hexora/models/calendar/calendar.dart';
import 'package:hexora/models/groups/group_business_hours.dart';
import 'package:hexora/models/groups/group_features.dart';
import 'package:hexora/models/groups/role_meta.dart';
import 'package:hexora/presentation/utils/roles/id_normalizer.dart';

class Group {
  // ---------- Core ----------
  final String id;
  String name;
  final String ownerId;

  /// userRoles is keyed by **userId**, not username.
  /// Values: "owner", "admin", "co-admin", "member"
  final Map<String, String> userRoles;

  /// Role assignment metadata keyed by userId.
  /// Populated when the backend returns `userRolesMeta` (members endpoint or group endpoint).
  final Map<String, RoleMeta> userRolesMeta;

  List<String> userIds;
  DateTime createdTime;
  String description;
  String? businessType;
  String? defaultInvoiceLanguage;
  final Map<String, dynamic>? creationBillingProfile;
  final List<Map<String, dynamic>>? creationInvitations;
  final Map<String, dynamic>? invitationSummary;

  // ---------- Media ----------
  String? photoUrl; // CDN/public URL if AVATARS_PUBLIC
  String? photoBlobName; // e.g. "groups/<id>/<uuid>.jpg"
  String? computedPhotoUrl; // backend virtual

  /// Best URL for displaying the current business image.
  ///
  /// Photo uploads persist [photoUrl]. The computed URL is a backend fallback
  /// for private-storage deployments, so it must not override a newly saved
  /// non-empty public URL.
  String? get displayPhotoUrl {
    for (final candidate in [photoUrl, computedPhotoUrl]) {
      final normalized = candidate?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }

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
    this.userRolesMeta = const {},
    required this.userIds,
    required this.createdTime,
    required this.description,
    this.businessType,
    this.defaultInvoiceLanguage,
    this.creationBillingProfile,
    this.creationInvitations,
    this.invitationSummary,
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
    } else if (json['calendars'] is List) {
      final calendars = json['calendars'] as List<dynamic>;
      if (calendars.isNotEmpty && calendars.first is Map<String, dynamic>) {
        defaultCal = Calendar.fromJson(
          calendars.first as Map<String, dynamic>,
        );
      }
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

    // Parse optional userRolesMeta (keyed by userId)
    final Map<String, RoleMeta> roleMeta = {};
    if (json['userRolesMeta'] is Map) {
      (json['userRolesMeta'] as Map).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          roleMeta[k.toString()] = RoleMeta.fromJson(v);
        }
      });
    }

    return Group(
      id: normalizeId(json['_id'] ?? json['id']),
      name: (json['name'] ?? '').toString(),
      ownerId: normalizeId(json['ownerId']),
      userRoles: normalizedUserRoles,
      userRolesMeta: roleMeta,
      userIds: normalizeIdList(json['userIds']),
      createdTime: _parseDate(json['createdTime']) ?? DateTime.now(),
      description: (json['description'] ?? '').toString(),
      businessType: json['businessType']?.toString(),
      defaultInvoiceLanguage: json['defaultInvoiceLanguage']?.toString(),
      invitationSummary: json['invitationSummary'] is Map
          ? Map<String, dynamic>.from(json['invitationSummary'] as Map)
          : null,
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
      if (businessType != null) 'businessType': businessType,
      if (defaultInvoiceLanguage != null)
        'defaultInvoiceLanguage': defaultInvoiceLanguage,
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
      if (businessType != null) 'businessType': businessType,
      if (defaultInvoiceLanguage != null)
        'defaultInvoiceLanguage': defaultInvoiceLanguage,
      if (creationBillingProfile != null)
        'billingProfile': creationBillingProfile,
      if (creationInvitations != null && creationInvitations!.isNotEmpty)
        'invitations': creationInvitations,
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
    Map<String, RoleMeta>? userRolesMeta,
    List<String>? userIds,
    DateTime? createdTime,
    String? description,
    String? businessType,
    String? defaultInvoiceLanguage,
    Map<String, dynamic>? creationBillingProfile,
    List<Map<String, dynamic>>? creationInvitations,
    Map<String, dynamic>? invitationSummary,
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
      userRolesMeta:
          userRolesMeta ?? Map<String, RoleMeta>.from(this.userRolesMeta),
      userIds: userIds ?? List<String>.from(this.userIds),
      createdTime: createdTime ?? this.createdTime,
      description: description ?? this.description,
      businessType: businessType ?? this.businessType,
      defaultInvoiceLanguage:
          defaultInvoiceLanguage ?? this.defaultInvoiceLanguage,
      creationBillingProfile:
          creationBillingProfile ?? this.creationBillingProfile,
      creationInvitations:
          creationInvitations ?? this.creationInvitations,
      invitationSummary: invitationSummary ?? this.invitationSummary,
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
          roundingPreset: TimeRoundingPreset.nearest5Tie05Down,
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
        'businessType: $businessType, defaultInvoiceLanguage: $defaultInvoiceLanguage, '
        'photoUrl: $photoUrl, photoBlobName: $photoBlobName, '
        'computedPhotoUrl: $computedPhotoUrl, inviteCount: $inviteCount, lastInviteAt: $lastInviteAt, '
        'defaultCalendarId: $defaultCalendarId, defaultCalendar: $defaultCalendar, '
        'features: $features, businessHours: $businessHours}';
  }
}
