class MailOutgoingAttachment {
  final String? id;
  final String? storageKey;
  final String? filename;
  final String? contentType;
  final int? size;

  const MailOutgoingAttachment({
    this.id,
    this.storageKey,
    this.filename,
    this.contentType,
    this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (storageKey != null) 'storageKey': storageKey,
      if (filename != null) 'filename': filename,
      if (contentType != null) 'contentType': contentType,
      if (size != null) 'size': size,
    };
  }
}

class MailSendRequest {
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String? textBody;
  final String? htmlBody;
  final List<MailOutgoingAttachment> attachments;
  final List<String> invoiceIds;
  final bool? attachInvoicePdf;
  final bool? includeInvoiceLinks;
  final bool? applyDefaultFooter;

  const MailSendRequest({
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    required this.subject,
    this.textBody,
    this.htmlBody,
    this.attachments = const [],
    this.invoiceIds = const [],
    this.attachInvoicePdf,
    this.includeInvoiceLinks,
    this.applyDefaultFooter,
  });

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      if (cc.isNotEmpty) 'cc': cc,
      if (bcc.isNotEmpty) 'bcc': bcc,
      'subject': subject,
      if (textBody != null) 'text': textBody,
      if (htmlBody != null) 'html': htmlBody,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((e) => e.toJson()).toList(),
      if (invoiceIds.isNotEmpty) 'invoiceIds': invoiceIds,
      if (attachInvoicePdf != null) 'attachInvoicePdf': attachInvoicePdf,
      if (includeInvoiceLinks != null)
        'includeInvoiceLinks': includeInvoiceLinks,
      if (applyDefaultFooter != null)
        'applyDefaultFooter': applyDefaultFooter,
    };
  }
}

class MailReplyRequest {
  final String? textBody;
  final String? htmlBody;
  final List<MailOutgoingAttachment> attachments;

  const MailReplyRequest({
    this.textBody,
    this.htmlBody,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (textBody != null) 'text': textBody,
      if (htmlBody != null) 'html': htmlBody,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((e) => e.toJson()).toList(),
    };
  }
}

class MailForwardRequest {
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String? textBody;
  final String? htmlBody;
  final bool? includeOriginalAttachments;
  final List<MailOutgoingAttachment> additionalAttachments;

  const MailForwardRequest({
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    this.textBody,
    this.htmlBody,
    this.includeOriginalAttachments,
    this.additionalAttachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'to': to,
      if (cc.isNotEmpty) 'cc': cc,
      if (bcc.isNotEmpty) 'bcc': bcc,
      if (textBody != null) 'text': textBody,
      if (htmlBody != null) 'html': htmlBody,
      if (includeOriginalAttachments != null)
        'includeOriginalAttachments': includeOriginalAttachments,
      if (additionalAttachments.isNotEmpty)
        'additionalAttachments':
            additionalAttachments.map((e) => e.toJson()).toList(),
    };
  }
}
