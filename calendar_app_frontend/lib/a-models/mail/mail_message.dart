import 'package:hexora/a-models/mail/mail_address.dart';
import 'package:hexora/a-models/mail/mail_attachment.dart';
import 'package:hexora/a-models/mail/mail_folder.dart';
import 'package:hexora/a-models/mail/mail_utils.dart';

class MailMessage {
  final String id;
  final String? threadKey;
  final String? folder;
  final String subject;
  final String? snippet;
  final DateTime? date;
  final MailAddress? from;
  final List<MailAddress> to;
  final List<MailAddress> cc;
  final List<MailAddress> bcc;
  final String? htmlBody;
  final String? textBody;
  final bool unread;
  final bool hasAttachments;
  final List<MailAttachment> attachments;
  final int? size;

  const MailMessage({
    required this.id,
    this.threadKey,
    this.folder,
    this.subject = '',
    this.snippet,
    this.date,
    this.from,
    this.to = const [],
    this.cc = const [],
    this.bcc = const [],
    this.htmlBody,
    this.textBody,
    this.unread = false,
    this.hasAttachments = false,
    this.attachments = const [],
    this.size,
  });

  MailFolder? get folderEnum => MailFolderWire.fromWire(folder);

  String get fromAddress => from?.display ?? '';

  MailMessage copyWith({
    String? id,
    String? threadKey,
    String? folder,
    String? subject,
    String? snippet,
    DateTime? date,
    MailAddress? from,
    List<MailAddress>? to,
    List<MailAddress>? cc,
    List<MailAddress>? bcc,
    String? htmlBody,
    String? textBody,
    bool? unread,
    bool? hasAttachments,
    List<MailAttachment>? attachments,
    int? size,
  }) {
    return MailMessage(
      id: id ?? this.id,
      threadKey: threadKey ?? this.threadKey,
      folder: folder ?? this.folder,
      subject: subject ?? this.subject,
      snippet: snippet ?? this.snippet,
      date: date ?? this.date,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      htmlBody: htmlBody ?? this.htmlBody,
      textBody: textBody ?? this.textBody,
      unread: unread ?? this.unread,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      attachments: attachments ?? this.attachments,
      size: size ?? this.size,
    );
  }

  factory MailMessage.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] ?? json['attachment'] ?? [];
    final attachments = attachmentsJson is List
        ? attachmentsJson
            .whereType<Map>()
            .map((e) => MailAttachment.fromJson(e.cast<String, dynamic>()))
            .toList()
        : const <MailAttachment>[];

    final hasAttachments =
        parseBool(json['has_attachments'] ?? json['hasAttachments']) ??
            attachments.isNotEmpty;

    final unread = parseBool(json['unread'] ?? json['is_unread'] ??
            json['isUnread']) ??
        !(parseBool(json['read'] ?? json['is_read'] ?? json['isRead']) ?? false);

    final from = MailAddress.parse(
        json['from'] ?? json['from_address'] ?? json['fromAddress']);

    return MailMessage(
      id: readId(json['id'] ?? json['_id'] ?? json['messageId']),
      threadKey: json['threadKey']?.toString() ??
          json['thread_key']?.toString() ??
          json['threadId']?.toString(),
      folder: json['folder']?.toString(),
      subject: (json['subject'] ?? '').toString(),
      snippet: json['snippet']?.toString() ?? json['preview']?.toString(),
      date: parseDate(
        json['date'] ??
            json['received_at'] ??
            json['sent_at'] ??
            json['createdAt'],
      ),
      from: from,
      to: MailAddress.parseList(
          json['to'] ?? json['to_address'] ?? json['toAddress']),
      cc: MailAddress.parseList(json['cc'] ?? json['cc_address'] ?? json['ccAddress']),
      bcc:
          MailAddress.parseList(json['bcc'] ?? json['bcc_address'] ?? json['bccAddress']),
      htmlBody: json['html_body']?.toString() ?? json['htmlBody']?.toString(),
      textBody: json['text_body']?.toString() ?? json['textBody']?.toString(),
      unread: unread,
      hasAttachments: hasAttachments,
      attachments: attachments,
      size: parseInt(json['size'] ?? json['bytes'] ?? json['length']),
    );
  }
}
