/// Represents a linked Telegram account.
class TelegramAccount {
  const TelegramAccount({
    required this.id,
    required this.status,
    this.telegramUserId,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.username,
    this.linkedAt,
    this.lastAuthenticatedAt,
    this.disconnectedAt,
    this.accountLabel,
    this.error,
  });

  final String id;
  final String status;
  final String? telegramUserId;
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? username;
  final DateTime? linkedAt;
  final DateTime? lastAuthenticatedAt;
  final DateTime? disconnectedAt;
  final String? accountLabel;
  final String? error;

  factory TelegramAccount.fromJson(Map<String, dynamic> json) {
    final source = _unwrapAccountJson(json);
    return TelegramAccount(
      id: _readRequiredString(source, 'id'),
      status: _readRequiredString(source, 'status'),
      telegramUserId: _readString(
        source['telegramUserId'] ?? source['telegram_user_id'],
      ),
      phoneNumber: _readString(
        source['phoneNumber'] ?? source['phone_number'],
      ),
      firstName: _readString(source['firstName'] ?? source['first_name']),
      lastName: _readString(source['lastName'] ?? source['last_name']),
      username: _readString(source['username']),
      lastAuthenticatedAt: _readDateTime(
        source['lastAuthenticatedAt'] ?? source['last_authenticated_at'],
      ),
      disconnectedAt: _readDateTime(
        source['disconnectedAt'] ?? source['disconnected_at'],
      ),
      linkedAt: _readDateTime(
        source['linkedAt'] ??
            source['linked_at'] ??
            source['lastAuthenticatedAt'] ??
            source['last_authenticated_at'] ??
            source['updatedAt'] ??
            source['updated_at'] ??
            source['createdAt'] ??
            source['created_at'],
      ),
      accountLabel: _readString(
        source['accountLabel'] ?? source['account_label'],
      ),
      error: _readString(
        source['error'] ??
            source['authError']?['message'] ??
            source['auth_error']?['message'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'telegramUserId': telegramUserId,
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'linkedAt': linkedAt?.toIso8601String(),
      'lastAuthenticatedAt': lastAuthenticatedAt?.toIso8601String(),
      'disconnectedAt': disconnectedAt?.toIso8601String(),
      'accountLabel': accountLabel,
      'error': error,
    };
  }

  TelegramAccount copyWith({
    String? id,
    String? status,
    String? telegramUserId,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? username,
    DateTime? linkedAt,
    DateTime? lastAuthenticatedAt,
    DateTime? disconnectedAt,
    String? accountLabel,
    String? error,
  }) {
    return TelegramAccount(
      id: id ?? this.id,
      status: status ?? this.status,
      telegramUserId: telegramUserId ?? this.telegramUserId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      linkedAt: linkedAt ?? this.linkedAt,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      accountLabel: accountLabel ?? this.accountLabel,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramAccount &&
        other.id == id &&
        other.status == status &&
        other.telegramUserId == telegramUserId &&
        other.phoneNumber == phoneNumber &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.username == username &&
        other.linkedAt == linkedAt &&
        other.lastAuthenticatedAt == lastAuthenticatedAt &&
        other.disconnectedAt == disconnectedAt &&
        other.accountLabel == accountLabel &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
        id,
        status,
        telegramUserId,
        phoneNumber,
        firstName,
        lastName,
        username,
        linkedAt,
        lastAuthenticatedAt,
        disconnectedAt,
        accountLabel,
        error,
      );
}

extension TelegramAccountExt on TelegramAccount {
  bool get isActive {
    final normalized = _normalizedStatus(status);
    if (disconnectedAt == null &&
        (telegramUserId?.isNotEmpty ?? false || lastAuthenticatedAt != null)) {
      return true;
    }
    switch (normalized) {
      case 'active':
      case 'connected':
      case 'linked':
      case 'authenticated':
      case 'ready':
        return true;
      default:
        return false;
    }
  }

  bool get isConnecting {
    if (isActive) return false;

    switch (_normalizedStatus(status)) {
      case 'awaiting_qr':
      case 'scan_qr':
      case 'wait_auth':
      case 'waiting_for_confirmation':
      case 'pending':
      case 'authorizing':
      case 'connecting':
        return true;
      default:
        return false;
    }
  }

  bool get needsReconnect {
    switch (_normalizedStatus(status)) {
      case 'reconnect_required':
      case 'disconnected':
      case 'expired':
        return true;
      default:
        return false;
    }
  }

  bool get isError {
    switch (_normalizedStatus(status)) {
      case 'error':
      case 'failed':
      case 'auth_error':
        return true;
      default:
        return false;
    }
  }

  String get displayName {
    if (username != null) return '@$username';
    final joined = <String?>[firstName, lastName]
        .where((value) => value?.isNotEmpty ?? false)
        .join(' ')
        .trim();
    return joined.isEmpty ? (phoneNumber ?? 'Unknown') : joined;
  }

  String get fullName {
    final joined = <String?>[firstName, lastName]
        .where((value) => value?.isNotEmpty ?? false)
        .join(' ')
        .trim();
    return joined.isEmpty ? 'Telegram Account' : joined;
  }
}

String _readRequiredString(Map<String, dynamic> json, String key) {
  final value = _readString(json[key]);
  if (value == null) {
    throw FormatException('Missing required TelegramAccount field: $key');
  }
  return value;
}

String? _readString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

Map<String, dynamic> _unwrapAccountJson(Map<String, dynamic> json) {
  final nested = json['account'];
  if (nested is Map) {
    return Map<String, dynamic>.from(nested);
  }
  return json;
}

String _normalizedStatus(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}
