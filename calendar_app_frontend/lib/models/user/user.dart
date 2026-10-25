// lib/models/user/user.dart

import 'package:hexora/models/user/user_equality.dart';
import 'package:hexora/models/user/user_json_mapper.dart';

const _unchanged = Object();

class User {
  String _id;
  String name; // legal / full name
  String? displayName; // preferred display name
  final String _email;
  String userName; // unique handle/login
  bool emailVerified;

  String? photoUrl;
  String? photoBlobName;

  String? bio;
  String? phoneNumber;
  String? location;

  bool autoStatementImportEnabled;

  List<String> groupIds;
  List<String> _calendarsIds;
  List<String> _notificationsIds;

  User({
    required String id,
    required this.name,
    required String email,
    required this.userName,
    required this.groupIds,
    required this.emailVerified,
    this.displayName,
    this.bio,
    this.phoneNumber,
    this.location,
    this.photoUrl,
    this.photoBlobName,
    List<String>? sharedCalendars,
    List<String>? notifications,
    this.autoStatementImportEnabled = false,
  })  : _id = id,
        _email = email,
        _calendarsIds = sharedCalendars ?? [],
        _notificationsIds = notifications ?? [];

  // Getters & setters
  String get id => _id;

  String get email => _email;

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
    Object? displayName = _unchanged,
    String? email,
    String? userName,
    bool? emailVerified,
    Object? bio = _unchanged,
    Object? phoneNumber = _unchanged,
    Object? location = _unchanged,
    Object? photoUrl = _unchanged,
    Object? photoBlobName = _unchanged,
    List<String>? groupIds,
    List<String>? sharedCalendars,
    List<String>? notifications,
    bool? autoStatementImportEnabled,
  }) {
    return User(
      id: id ?? _id,
      name: name ?? this.name,
      displayName: identical(displayName, _unchanged)
          ? this.displayName
          : displayName as String?,
      email: email ?? _email,
      userName: userName ?? this.userName,
      emailVerified: emailVerified ?? this.emailVerified,
      bio: identical(bio, _unchanged) ? this.bio : bio as String?,
      phoneNumber: identical(phoneNumber, _unchanged)
          ? this.phoneNumber
          : phoneNumber as String?,
      location:
          identical(location, _unchanged) ? this.location : location as String?,
      autoStatementImportEnabled:
          autoStatementImportEnabled ?? this.autoStatementImportEnabled,
      photoUrl:
          identical(photoUrl, _unchanged) ? this.photoUrl : photoUrl as String?,
      photoBlobName: identical(photoBlobName, _unchanged)
          ? this.photoBlobName
          : photoBlobName as String?,
      groupIds: groupIds ?? this.groupIds,
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
      emailVerified: false,
      bio: '',
      phoneNumber: '',
      location: '',
      autoStatementImportEnabled: false,
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
