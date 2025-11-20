// lib/a-models/group_model/group/group_extensions.dart
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/group/group_features.dart';

extension GroupRolesExt on Group {
  // ---------- Role helpers ----------
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
}

extension GroupEqualityExt on Group {
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
}

// ---------- Private helpers for equality ----------

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _dtEq(DateTime? a, DateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.toIso8601String() == b.toIso8601String();
}

bool _featuresEq(GroupFeatures? a, GroupFeatures? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.toString() == b.toString();
}
