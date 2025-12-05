// lib/a-models/user_model/json_folders/user_equality.dart

import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/user_model/user.dart';

bool userEquals(User a, Object other) {
  if (identical(a, other)) return true;
  if (other is! User) return false;

  return other.id == a.id &&
      other.email == a.email &&
      other.userName == a.userName &&
      other.emailVerified == a.emailVerified &&
      other.name == a.name &&
      other.displayName == a.displayName &&
      other.bio == a.bio &&
      other.phoneNumber == a.phoneNumber &&
      other.location == a.location &&
      listEquals(other.groupIds, a.groupIds) &&
      listEquals(other.sharedCalendars, a.sharedCalendars) &&
      listEquals(other.notifications, a.notifications) &&
      other.photoUrl == a.photoUrl &&
      other.photoBlobName == a.photoBlobName;
}

int userHashCode(User u) {
  return Object.hash(
    u.id,
    u.email,
    u.userName,
    u.emailVerified,
    u.name,
    u.displayName,
    u.bio,
    u.phoneNumber,
    u.location,
    Object.hashAll(u.groupIds),
    Object.hashAll(u.sharedCalendars),
    Object.hashAll(u.notifications),
    u.photoUrl,
    u.photoBlobName,
  );
}
