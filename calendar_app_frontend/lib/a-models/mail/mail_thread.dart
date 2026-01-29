import 'package:hexora/a-models/mail/mail_address.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/a-models/mail/mail_utils.dart';

class MailThread {
  final String threadKey;
  final String subject;
  final String? snippet;
  final bool hasAttachments;
  final List<String> participants;
  final DateTime? latestDate;
  final int unreadCount;
  final int messageCount;

  const MailThread({
    required this.threadKey,
    this.subject = '',
    this.snippet,
    this.hasAttachments = false,
    this.participants = const [],
    this.latestDate,
    this.unreadCount = 0,
    this.messageCount = 0,
  });

  factory MailThread.fromJson(Map<String, dynamic> json) {
    final participantsRaw = json['participants'] ?? json['from'] ?? json['to'];
    final participants = _parseParticipants(participantsRaw);

    return MailThread(
      threadKey: (json['threadKey'] ??
              json['thread_key'] ??
              json['threadId'] ??
              json['id'] ??
              json['_id'])
          .toString(),
      subject: (json['subject'] ?? '').toString(),
      snippet: (json['snippet'] ??
              json['preview'] ??
              json['body_preview'] ??
              json['bodyPreview'])
          ?.toString(),
      hasAttachments: _parseAttachmentsFlag(json),
      participants: participants,
      latestDate: parseDate(
        json['latestDate'] ?? json['latest_date'] ?? json['date'],
      ),
      unreadCount:
          parseInt(json['unreadCount'] ?? json['unread_count']) ?? 0,
      messageCount:
          parseInt(json['messageCount'] ?? json['message_count'] ?? json['count']) ??
              0,
    );
  }
}

class MailThreadDetail {
  final String threadKey;
  final String subject;
  final List<String> participants;
  final List<MailMessage> messages;
  final DateTime? latestDate;
  final int unreadCount;
  final int messageCount;

  const MailThreadDetail({
    required this.threadKey,
    this.subject = '',
    this.participants = const [],
    this.messages = const [],
    this.latestDate,
    this.unreadCount = 0,
    this.messageCount = 0,
  });

  factory MailThreadDetail.fromJson(Map<String, dynamic> json) {
    final base = MailThread.fromJson(json);
    final listJson = json['messages'] ?? json['items'] ?? json['data'] ?? [];
    final messages = listJson is List
        ? listJson
            .whereType<Map>()
            .map((e) => MailMessage.fromJson(e.cast<String, dynamic>()))
            .toList()
        : const <MailMessage>[];

    return MailThreadDetail(
      threadKey: base.threadKey,
      subject: base.subject,
      participants: base.participants,
      latestDate: base.latestDate,
      unreadCount: base.unreadCount,
      messageCount: base.messageCount == 0 ? messages.length : base.messageCount,
      messages: messages,
    );
  }
}

List<String> _parseParticipants(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    final asAddresses = raw
        .map(MailAddress.parse)
        .whereType<MailAddress>()
        .map((e) => e.display)
        .toList();
    if (asAddresses.isNotEmpty) return asAddresses;
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  final single = MailAddress.parse(raw);
  if (single != null) return [single.display];
  final fallback = raw.toString().trim();
  return fallback.isEmpty ? const [] : [fallback];
}

bool _parseAttachmentsFlag(Map<String, dynamic> json) {
  final raw = json['has_attachments'] ?? json['hasAttachments'];
  final parsed = parseBool(raw);
  if (parsed != null) return parsed;
  final attachments = json['attachments'];
  if (attachments is List) return attachments.isNotEmpty;
  return false;
}
