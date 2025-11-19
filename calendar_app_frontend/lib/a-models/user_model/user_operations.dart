part of 'package:hexora/a-models/user_model/user.dart';

User copyUser(
  User source, {
  String? id,
  String? name,
  String? displayName,
  String? email,
  String? userName,
  String? bio,
  String? phoneNumber,
  String? location,
  String? photoUrl,
  String? photoBlobName,
  List<String>? groupIds,
  List<String>? sharedCalendars,
  List<String>? notifications,
}) {
  return User(
    id: id ?? source._id,
    name: name ?? source._name,
    displayName: displayName ?? source._displayName,
    email: email ?? source._email,
    userName: userName ?? source._userName,
    bio: bio ?? source._bio,
    phoneNumber: phoneNumber ?? source._phoneNumber,
    location: location ?? source._location,
    photoUrl: photoUrl ?? source._photoUrl,
    photoBlobName: photoBlobName ?? source._photoBlobName,
    groupIds: groupIds ?? source._groupIds,
    sharedCalendars: sharedCalendars ?? source._calendarsIds,
    notifications: notifications ?? source._notificationsIds,
  );
}

bool userEquals(User user, Object other) {
  if (identical(user, other)) return true;
  if (other is! User) return false;
  return other._id == user._id &&
      other._email == user._email &&
      other._userName == user._userName &&
      other._name == user._name &&
      other._displayName == user._displayName &&
      other._bio == user._bio &&
      other._phoneNumber == user._phoneNumber &&
      other._location == user._location &&
      listEquals(other._groupIds, user._groupIds) &&
      listEquals(other._calendarsIds, user._calendarsIds) &&
      listEquals(other._notificationsIds, user._notificationsIds) &&
      other._photoUrl == user._photoUrl &&
      other._photoBlobName == user._photoBlobName;
}

int userHashCode(User user) {
  return Object.hash(
    user._id,
    user._email,
    user._userName,
    user._name,
    user._displayName,
    user._bio,
    user._phoneNumber,
    user._location,
    Object.hashAll(user._groupIds),
    Object.hashAll(user._calendarsIds),
    Object.hashAll(user._notificationsIds),
    user._photoUrl,
    user._photoBlobName,
  );
}
