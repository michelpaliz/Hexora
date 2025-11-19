import 'package:flutter/foundation.dart';
part 'user_operations.dart';
part 'user_serialization.dart';

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

  // Convert to JSON
  Map<String, dynamic> toJson() => userToJson(this);

  // Create from JSON (SAFE)
  factory User.fromJson(Map<String, dynamic> raw, {String? fallbackId}) =>
      buildUserFromJson(raw, fallbackId: fallbackId);

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
  }) =>
      copyUser(
        this,
        id: id,
        name: name,
        displayName: displayName,
        email: email,
        userName: userName,
        bio: bio,
        phoneNumber: phoneNumber,
        location: location,
        photoUrl: photoUrl,
        photoBlobName: photoBlobName,
        groupIds: groupIds,
        sharedCalendars: sharedCalendars,
        notifications: notifications,
      );

  // empty factory
  factory User.empty() => buildEmptyUser();

  @override
  bool operator ==(Object other) => userEquals(this, other);

  @override
  int get hashCode => userHashCode(this);
}
