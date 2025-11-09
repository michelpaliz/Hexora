// lib/a-models/enums/invitation_status.dart

/// Keep these in sync with your backend enums (models/invitation.js)
enum InvitationStatus { pending, accepted, declined, expired, revoked }

extension InvitationStatusX on InvitationStatus {
  /// Canonical wire/string value used by your APIs/DB
  String get wire => switch (this) {
        InvitationStatus.pending => 'Pending',
        InvitationStatus.accepted => 'Accepted',
        InvitationStatus.declined => 'Declined',
        InvitationStatus.expired => 'Expired',
        InvitationStatus.revoked => 'Revoked',
      };

  /// Whether the status is terminal (no further transitions)
  bool get isTerminal => switch (this) {
        InvitationStatus.accepted => true,
        InvitationStatus.declined => true,
        InvitationStatus.expired => true,
        InvitationStatus.revoked => true,
        InvitationStatus.pending => false,
      };

  static InvitationStatus from(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'expired':
        return InvitationStatus.expired;
      case 'revoked':
        return InvitationStatus.revoked;
      default:
        return InvitationStatus.pending;
    }
  }
}
