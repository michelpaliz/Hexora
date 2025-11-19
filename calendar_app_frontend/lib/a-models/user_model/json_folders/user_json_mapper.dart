// lib/a-models/user_model/json_folders/user_json_mapper.dart

import 'package:hexora/a-models/user_model/json_folders/json_helpers.dart';
import 'package:hexora/a-models/user_model/user.dart';

Map<String, dynamic> userToJson(User u) {
  return {
    '_id': u.id,
    'name': u.name,
    'displayName': u.displayName,
    'userName': u.userName,
    'email': u.email,
    'bio': u.bio,
    'phoneNumber': u.phoneNumber,
    'location': u.location,
    'photoUrl': u.photoUrl,
    'photoBlobName': u.photoBlobName,
    'groupIds': u.groupIds,
    'sharedCalendars': u.sharedCalendars,
    'notifications': u.notifications,
  };
}

User userFromJson(Map<String, dynamic> raw, {String? fallbackId}) {
  final Map<String, dynamic> json = unwrapUser(raw);

  final id = optStringAny(json, ['id', '_id', 'userId']) ?? fallbackId;
  if (id == null || id.isEmpty) {
    throw const FormatException(
      "Expected non-empty string for one of id/_id/userId, and no fallbackId was provided.",
    );
  }

  // name: prefer 'name' / 'fullName' / 'displayName'
  final name = requireStringAny(json, ['name', 'fullName', 'displayName']);

  // displayName: true display field if present; else try name/userName
  final displayName = optStringAny(json, ['displayName']) ??
      optStringAny(json, ['name']) ??
      optStringAny(json, ['userName']);

  final email = requireString(json, 'email');

  final userName = requireStringAny(json, ['userName', 'username']);

  final bio = optStringAny(json, ['bio', 'about', 'description']);
  final phoneNumber = optStringAny(json, ['phoneNumber', 'phone']);
  final location = optStringAny(json, ['location', 'city']);

  return User(
    id: id,
    name: name,
    displayName: displayName,
    email: email,
    userName: userName,
    bio: bio,
    phoneNumber: phoneNumber,
    location: location,
    groupIds: optStringList(json, 'groupIds'),
    photoUrl: optString(json, 'photoUrl'),
    photoBlobName: optString(json, 'photoBlobName'),
    sharedCalendars: optStringList(json, 'sharedCalendars'),
    notifications: optStringList(json, 'notifications'),
  );
}
