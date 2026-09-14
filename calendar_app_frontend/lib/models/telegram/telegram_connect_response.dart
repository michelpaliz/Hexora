import 'telegram_account.dart';

/// Response from `/api/telegram/connect/start`.
class TelegramConnectResponse {
  const TelegramConnectResponse({
    this.account,
    required this.nextStep,
    required this.requestId,
    this.qrLink,
    this.qrExpiresAt,
  });

  final TelegramAccount? account;
  final String nextStep;
  final String requestId;
  final String? qrLink;
  final DateTime? qrExpiresAt;

  factory TelegramConnectResponse.fromJson(Map<String, dynamic> json) {
    final accountJson = json['account'];

    return TelegramConnectResponse(
      account: accountJson is Map
          ? TelegramAccount.fromJson(
              Map<String, dynamic>.from(accountJson),
            )
          : null,
      nextStep: _readRequiredString(
        json,
        'nextStep',
        fallbackKey: 'next_step',
      ),
      requestId: _readRequiredString(
        json,
        'requestId',
        fallbackKey: 'request_id',
      ),
      qrLink: _readString(json['qrLink'] ?? json['qr_link']),
      qrExpiresAt: _readDateTime(json['qrExpiresAt'] ?? json['qr_expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (account != null) 'account': account!.toJson(),
      'nextStep': nextStep,
      'requestId': requestId,
      'qrLink': qrLink,
      'qrExpiresAt': qrExpiresAt?.toIso8601String(),
    };
  }

  TelegramConnectResponse copyWith({
    TelegramAccount? account,
    String? nextStep,
    String? requestId,
    String? qrLink,
    DateTime? qrExpiresAt,
  }) {
    return TelegramConnectResponse(
      account: account ?? this.account,
      nextStep: nextStep ?? this.nextStep,
      requestId: requestId ?? this.requestId,
      qrLink: qrLink ?? this.qrLink,
      qrExpiresAt: qrExpiresAt ?? this.qrExpiresAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TelegramConnectResponse &&
        other.account == account &&
        other.nextStep == nextStep &&
        other.requestId == requestId &&
        other.qrLink == qrLink &&
        other.qrExpiresAt == qrExpiresAt;
  }

  @override
  int get hashCode => Object.hash(
        account,
        nextStep,
        requestId,
        qrLink,
        qrExpiresAt,
      );
}

extension TelegramConnectResponseExt on TelegramConnectResponse {
  bool get hasQrLink => qrLink?.trim().isNotEmpty ?? false;
  bool get isQrStep => nextStep == 'scan_qr';
  bool get isQrReady => isQrStep && hasQrLink;
  bool get isCodeStep => nextStep == 'submit_code';
  bool get isPasswordStep => nextStep == 'submit_password';
  bool get isWaitingAuth => nextStep == 'wait_auth';

  bool get qrIsExpired =>
      qrExpiresAt != null && DateTime.now().isAfter(qrExpiresAt!);
}

String _readRequiredString(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final value = _readString(
      json[key] ?? (fallbackKey == null ? null : json[fallbackKey]));
  if (value == null) {
    throw FormatException(
      'Missing required TelegramConnectResponse field: $key',
    );
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
