part of 'package:hexora/a-models/user_model/user.dart';

User buildUserFromJson(Map<String, dynamic> raw, {String? fallbackId}) {
  final Map<String, dynamic> json = unwrapUser(raw);

  final id = optStringAny(json, ['id', '_id', 'userId']) ?? fallbackId;
  if (id == null || id.isEmpty) {
    throw FormatException(
        "Expected non-empty string for one of id/_id/userId, and no fallbackId was provided.");
  }

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

Map<String, dynamic> userToJson(User user) {
  return {
    '_id': user._id,
    'name': user._name,
    'displayName': user._displayName,
    'userName': user._userName,
    'email': user._email,
    'bio': user._bio,
    'phoneNumber': user._phoneNumber,
    'location': user._location,
    'photoUrl': user._photoUrl,
    'photoBlobName': user._photoBlobName,
    'groupIds': user._groupIds,
    'sharedCalendars': user._calendarsIds,
    'notifications': user._notificationsIds,
  };
}

User buildEmptyUser() {
  return User(
    id: '',
    name: '',
    displayName: '',
    email: '',
    userName: '',
    bio: '',
    phoneNumber: '',
    location: '',
    photoUrl: '',
    photoBlobName: '',
    groupIds: const [],
    sharedCalendars: const [],
    notifications: const [],
  );
}
