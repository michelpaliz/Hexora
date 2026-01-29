import 'package:hexora/a-models/mail/mail_utils.dart';

class MailAttachment {
  final String id;
  final String? filename;
  final String? contentType;
  final int? size;
  final bool inline;
  final String? contentId;
  final String? downloadUrl;

  const MailAttachment({
    required this.id,
    this.filename,
    this.contentType,
    this.size,
    this.inline = false,
    this.contentId,
    this.downloadUrl,
  });

  factory MailAttachment.fromJson(Map<String, dynamic> json) {
    final id = readId(json['_id'] ?? json['id'] ?? json['attachmentId']);
    final filename = json['filename'] ??
        json['file_name'] ??
        json['name'] ??
        json['fileName'] ??
        json['title'];
    final contentType =
        json['contentType'] ?? json['content_type'] ?? json['mime_type'];
    final size = parseInt(json['size'] ?? json['bytes'] ?? json['length']);
    final inline = parseBool(json['inline'] ?? json['is_inline']) ?? false;
    final contentId = json['contentId'] ?? json['content_id'] ?? json['cid'];
    final downloadUrl = json['downloadUrl'] ?? json['url'] ?? json['href'];
    return MailAttachment(
      id: id,
      filename: filename?.toString(),
      contentType: contentType?.toString(),
      size: size,
      inline: inline,
      contentId: contentId?.toString(),
      downloadUrl: downloadUrl?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (filename != null) 'filename': filename,
      if (contentType != null) 'contentType': contentType,
      if (size != null) 'size': size,
      if (inline) 'inline': true,
      if (contentId != null) 'contentId': contentId,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
    };
  }
}
