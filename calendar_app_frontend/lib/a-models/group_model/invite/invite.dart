// lib/a-models/invitation/invitation.dart
import 'dart:convert';

import 'package:hexora/b-backend/group_mng_flow/group/view_model/presentation/group_editor_state.dart/group_editor_state.dart';
import 'package:hexora/c-frontend/utils/enums/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/enums/invitation_status.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}

class Invitation {
  final String id;
  final String groupId;

  /// One of these identifies the invitee
  final String? userId; // null if invited by email only
  final String? email; // lowercase on backend

  final GroupRole role; // member | co-admin | admin
  final InvitationStatus
      status; // Pending | Accepted | Declined | Expired | Revoked

  final String invitedBy; // userId who sent it

  final int attempts;
  final DateTime sendingDate;
  final DateTime? respondedAt;

  // Magic link support
  final String? token; // typically a hash on server
  final DateTime? expiresAt;

  // Misc metadata from backend
  final Map<String, dynamic> meta;

  // Mongoose timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Invitation({
    required this.id,
    required this.groupId,
    required this.role,
    required this.status,
    required this.invitedBy,
    required this.attempts,
    required this.sendingDate,
    this.userId,
    this.email,
    this.respondedAt,
    this.token,
    this.expiresAt,
    this.meta = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        groupId: (json['groupId'] ?? '').toString(),
        userId: json['userId']?.toString(),
        email: (json['email'] as String?)?.toLowerCase(),
        role: GroupRoleX.from(json['role']?.toString()),
        status: InvitationStatusX.from(json['status']?.toString()),
        invitedBy: (json['invitedBy'] ?? '').toString(),
        attempts:
            (json['attempts'] is num) ? (json['attempts'] as num).toInt() : 0,
        sendingDate: _parseDate(json['sendingDate']) ??
            _parseDate(json['createdAt']) ??
            DateTime.now(),
        respondedAt: _parseDate(json['respondedAt']),
        token: json['token']?.toString(),
        expiresAt: _parseDate(json['expiresAt']),
        meta: (json['meta'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : <String, dynamic>{},
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        if (userId != null) 'userId': userId,
        if (email != null) 'email': email,
        'role': role.wire,
        'status': status.wire,
        'invitedBy': invitedBy,
        'attempts': attempts,
        'sendingDate': sendingDate.toIso8601String(),
        if (respondedAt != null) 'respondedAt': respondedAt!.toIso8601String(),
        if (token != null) 'token': token,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (meta.isNotEmpty) 'meta': meta,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  /// Minimal body for POST /invitations
  Map<String, dynamic> toCreatePayload() => {
        'groupId': groupId,
        if (userId != null) 'userId': userId,
        if (email != null) 'email': email,
        'role': role.wire,
        if (token != null) 'token': token,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
        if (meta.isNotEmpty) 'meta': meta,
      };

  Invitation copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? email,
    GroupRole? role,
    InvitationStatus? status,
    String? invitedBy,
    int? attempts,
    DateTime? sendingDate,
    DateTime? respondedAt,
    String? token,
    DateTime? expiresAt,
    Map<String, dynamic>? meta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Invitation(
        id: id ?? this.id,
        groupId: groupId ?? this.groupId,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        role: role ?? this.role,
        status: status ?? this.status,
        invitedBy: invitedBy ?? this.invitedBy,
        attempts: attempts ?? this.attempts,
        sendingDate: sendingDate ?? this.sendingDate,
        respondedAt: respondedAt ?? this.respondedAt,
        token: token ?? this.token,
        expiresAt: expiresAt ?? this.expiresAt,
        meta: meta ?? Map<String, dynamic>.from(this.meta),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // Convenience
  bool get isPending => status == InvitationStatus.pending;
  bool get isTerminal => status.isTerminal;

  @override
  String toString() => jsonEncode(toJson());
}
