class UserInviteStatus {
  /// The invited user's ID (MongoDB ObjectId string)
  String id;

  /// Whether the user accepted (`true`) or rejected (`false`) the invitation
  bool? invitationAnswer;

  /// The intended role of the invited user (e.g. "member", "co-admin", etc.)
  String role;

  /// When the invite was sent
  DateTime sendingDate;

  /// Human-readable status like "Pending", "Accepted", "Declined"
  String informationStatus;

  /// How many times the invite was sent
  int attempts;

  /// Backend general status field (used internally)
  String status;

  UserInviteStatus({
    required this.id,
    required this.invitationAnswer,
    required this.role,
    required this.sendingDate,
    required this.informationStatus,
    required this.attempts,
    required this.status,
  });

  // ---------- JSON ----------
  factory UserInviteStatus.fromJson(Map<String, dynamic> json) {
    return UserInviteStatus(
      id: json['id']?.toString() ?? '',
      invitationAnswer: json['invitationAnswer'] is bool
          ? json['invitationAnswer']
          : (json['invitationAnswer']?.toString().toLowerCase() == 'true'),
      role: json['role']?.toString() ?? 'member',
      sendingDate: json['sendingDate'] != null
          ? DateTime.tryParse(json['sendingDate'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      informationStatus:
          json['informationStatus']?.toString() ?? 'Pending', // fallback
      attempts: json['attempts'] is int
          ? json['attempts']
          : int.tryParse(json['attempts']?.toString() ?? '1') ?? 1,
      status: json['status']?.toString() ?? 'Unresolved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invitationAnswer': invitationAnswer,
      'role': role,
      'sendingDate': sendingDate.toIso8601String(),
      'informationStatus': informationStatus,
      'attempts': attempts,
      'status': status,
    };
  }

  // ---------- Helpers ----------
  UserInviteStatus copy() {
    return UserInviteStatus(
      id: id,
      invitationAnswer: invitationAnswer,
      role: role,
      sendingDate: DateTime.fromMillisecondsSinceEpoch(
        sendingDate.millisecondsSinceEpoch,
      ),
      informationStatus: informationStatus,
      attempts: attempts,
      status: status,
    );
  }

  bool isEqual(UserInviteStatus other) {
    return id == other.id &&
        invitationAnswer == other.invitationAnswer &&
        role == other.role &&
        sendingDate == other.sendingDate &&
        informationStatus == other.informationStatus &&
        attempts == other.attempts &&
        status == other.status;
  }

  @override
  String toString() {
    return 'UserInviteStatus{id: $id, invitationAnswer: $invitationAnswer, '
        'role: $role, sendingDate: $sendingDate, '
        'informationStatus: $informationStatus, attempts: $attempts, status: $status}';
  }
}
