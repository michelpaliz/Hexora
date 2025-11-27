// lib/a-models/user_model/user.dart

import 'package:hexora/a-models/user_model/json_folders/user_equality.dart';
import 'package:hexora/a-models/user_model/json_folders/user_json_mapper.dart';

class User {
  String _id;
  String _name; // legal / full name
  String? _displayName; // preferred display name
  final String _email;
  String _userName; // unique handle/login

  String? _photoUrl;
  String? _photoBlobName;

  String? _bio;
  String? _phoneNumber;
  String? _location;

  List<String> _groupIds;
  List<String> _calendarsIds;
  List<String> _notificationsIds;

  User({
    required String id,
    required String name,
    required String email,
    required String userName,
    required List<String> groupIds,
    String? displayName,
    String? bio,
    String? phoneNumber,
    String? location,
    String? photoUrl,
    String? photoBlobName,
    List<String>? sharedCalendars,
    List<String>? notifications,
  })  : _id = id,
        _name = name,
        _displayName = displayName,
        _email = email,
        _userName = userName,
        _bio = bio,
        _phoneNumber = phoneNumber,
        _location = location,
        _groupIds = groupIds,
        _photoUrl = photoUrl,
        _photoBlobName = photoBlobName,
        _calendarsIds = sharedCalendars ?? [],
        _notificationsIds = notifications ?? [];

  // Getters & setters
  String get id => _id;

  String get name => _name;
  set name(String v) => _name = v;

  String? get displayName => _displayName;
  set displayName(String? v) => _displayName = v;

  String get email => _email;

  String get userName => _userName;
  set userName(String v) => _userName = v;

  String? get photoUrl => _photoUrl;
  set photoUrl(String? v) => _photoUrl = v;

  String? get photoBlobName => _photoBlobName;
  set photoBlobName(String? v) => _photoBlobName = v;

  String? get bio => _bio;
  set bio(String? v) => _bio = v;

  String? get phoneNumber => _phoneNumber;
  set phoneNumber(String? v) => _phoneNumber = v;

  String? get location => _location;
  set location(String? v) => _location = v;

  List<String> get groupIds => _groupIds;
  set groupIds(List<String> v) => _groupIds = v;

  List<String> get sharedCalendars => _calendarsIds;
  set sharedCalendars(List<String>? v) => _calendarsIds = v ?? [];

  List<String> get notifications => _notificationsIds;
  set notifications(List<String>? v) => _notificationsIds = v ?? [];

  // JSON (delegated)
  Map<String, dynamic> toJson() => userToJson(this);

  factory User.fromJson(Map<String, dynamic> raw, {String? fallbackId}) =>
      userFromJson(raw, fallbackId: fallbackId);

  // copyWith
  User copyWith({
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
      id: id ?? _id,
      name: name ?? _name,
      displayName: displayName ?? _displayName,
      email: email ?? _email,
      userName: userName ?? _userName,
      bio: bio ?? _bio,
      phoneNumber: phoneNumber ?? _phoneNumber,
      location: location ?? _location,
      photoUrl: photoUrl ?? _photoUrl,
      photoBlobName: photoBlobName ?? _photoBlobName,
      groupIds: groupIds ?? _groupIds,
      sharedCalendars: sharedCalendars ?? _calendarsIds,
      notifications: notifications ?? _notificationsIds,
    );
  }

  // empty factory
  factory User.empty() {
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

  @override
  bool operator ==(Object other) => userEquals(this, other);

  @override
  int get hashCode => userHashCode(this);

}
