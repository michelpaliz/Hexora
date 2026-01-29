import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/emails/email_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

String buildEmailHtmlFromText(String text) {
  final lines = text
      .split('\n')
      .map((line) => line.trim().isEmpty ? '<br/>' : line)
      .join('<br/>');
  return '<div style="white-space:pre-line;">$lines</div>';
}

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = bytes.toDouble();
  int unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  return '${size.toStringAsFixed(size >= 10 || unit == 0 ? 0 : 1)} ${units[unit]}';
}

class EmailStatusBadge extends StatelessWidget {
  final String status;
  const EmailStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    Color bg = cs.surfaceContainerHighest;
    Color fg = cs.onSurfaceVariant;
    if (normalized.contains('sent') ||
        normalized.contains('delivered') ||
        normalized.contains('success')) {
      bg = cs.primaryContainer;
      fg = cs.onPrimaryContainer;
    } else if (normalized.contains('fail') ||
        normalized.contains('error') ||
        normalized.contains('bounce')) {
      bg = cs.errorContainer;
      fg = cs.onErrorContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: t.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class EmailLogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  final String dateLabel;
  final bool canResend;
  final bool resending;
  final VoidCallback onResend;
  final VoidCallback onViewDetails;

  const EmailLogRow({
    super.key,
    required this.log,
    required this.dateLabel,
    required this.canResend,
    required this.resending,
    required this.onResend,
    required this.onViewDetails,
  });

  String _formatRecipients(dynamic v) {
    if (v == null) return '-';
    if (v is List) {
      return v.whereType<String>().join(', ');
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final status = (log['status'] ?? log['state'] ?? 'unknown').toString();
    final to = _formatRecipients(log['to'] ?? log['toEmail']);
    final cc = _formatRecipients(log['cc'] ?? log['ccEmail']);
    final subject = (log['subject'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmailStatusBadge(status: status),
              const Spacer(),
              Text(
                dateLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l.invoiceEmailLogToLabel}: $to',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          if (cc != '-' && cc.trim().isNotEmpty)
            Text(
              '${l.invoiceEmailLogCcLabel}: $cc',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          const SizedBox(height: 4),
          Text(
            subject,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onViewDetails,
                child: Text(l.invoiceEmailViewDetailsCta),
              ),
              const Spacer(),
              if (canResend)
                TextButton.icon(
                  onPressed: resending ? null : onResend,
                  icon: resending
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    resending
                        ? l.invoiceEmailResendingLabel
                        : l.invoiceEmailResendCta,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SendInvoiceSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final EmailApi emailApi;
  final String pdfLink;
  final Future<void> Function() onSent;

  const SendInvoiceSheet({
    super.key,
    required this.invoice,
    required this.client,
    required this.emailApi,
    required this.pdfLink,
    required this.onSent,
  });

  @override
  State<SendInvoiceSheet> createState() => _SendInvoiceSheetState();
}

class _SendInvoiceSheetState extends State<SendInvoiceSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;
  late final TabController _tabs;
  bool _templatesSeeded = false;

  bool _attachPdf = true;
  bool _previewLoading = false;
  String? _previewError;
  Map<String, dynamic>? _previewPayload;
  bool _sending = false;
  String? _sendMessage;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    final fallbackEmail = widget.client.billing?.email ?? widget.client.email;
    _toController = TextEditingController(text: fallbackEmail ?? '');
    _ccController = TextEditingController();
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && !_tabs.indexIsChanging) {
        _loadPreview();
      }
    });
    _toController.addListener(_clearPreview);
    _ccController.addListener(_clearPreview);
    _subjectController.addListener(_clearPreview);
    _messageController.addListener(_clearPreview);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templatesSeeded) return;
    final l = AppLocalizations.of(context)!;
    _subjectController.text =
        l.invoiceEmailSubjectTemplate(widget.invoice.invoiceNumber);
    _messageController.text = l.invoiceEmailMessageTemplate(
      widget.client.name,
      widget.invoice.invoiceNumber,
    );
    _templatesSeeded = true;
  }

  void _clearPreview() {
    if (_previewPayload == null && _previewError == null) return;
    setState(() {
      _previewPayload = null;
      _previewError = null;
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final text = _messageController.text.trim();
    return {
      'invoiceId': widget.invoice.id,
      'groupId': widget.invoice.groupId,
      'to': _toController.text.trim(),
      'cc': _ccController.text.trim().isEmpty ? null : _ccController.text.trim(),
      'subject': _subjectController.text.trim(),
      'text': text,
      'html': buildEmailHtmlFromText(text),
      'attachPdf': _attachPdf,
      'pdfLink': _attachPdf ? '' : widget.pdfLink,
    };
  }

  Future<void> _loadPreview() async {
    if (_previewLoading) return;
    setState(() {
      _previewLoading = true;
      _previewError = null;
      _previewPayload = null;
    });
    try {
      final data = await widget.emailApi.previewTemplate(_payload());
      if (!mounted) return;
      setState(() => _previewPayload = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _previewError = e.toString());
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _sendError = null;
      _sendMessage = null;
    });
    try {
      await widget.emailApi.sendInvoice(_payload());
      final now = DateTime.now();
      if (!mounted) return;
      setState(() {
        _sendMessage = AppLocalizations.of(context)!.invoiceEmailSentAtLabel(
          DateFormat.yMMMd().add_Hm().format(now.toLocal()),
        );
      });
      await widget.onSent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendError = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Map<String, dynamic>? _previewAttachment() {
    final payload = _previewPayload ?? {};
    final attachment = payload['attachment'];
    if (attachment is Map<String, dynamic>) return attachment;
    final attachments = payload['attachments'];
    if (attachments is List && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isReady = _toController.text.trim().isNotEmpty &&
        _subjectController.text.trim().isNotEmpty;
    final previewHtml = _previewPayload?['html']?.toString() ?? '';
    final attachment = _previewAttachment();
    final attachmentName = (attachment?['name'] ??
            attachment?['fileName'] ??
            attachment?['filename'])
        ?.toString();
    final attachmentSize = attachment?['size'] ?? attachment?['bytes'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.invoiceEmailSheetTitle,
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l.invoiceEmailSheetSubtitle,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ToggleButtons(
            isSelected: [_attachPdf, !_attachPdf],
            onPressed: (index) => setState(() => _attachPdf = index == 0),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 120),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.invoiceEmailAttachPdfLabel),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.invoiceEmailSendLinkLabel),
              ),
            ],
          ),
          if (!_attachPdf)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.pdfLink,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            tabs: [
              Tab(text: l.invoiceEmailTabEdit),
              Tab(text: l.invoiceEmailTabPreview),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 360,
            child: TabBarView(
              controller: _tabs,
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _toController,
                        decoration: InputDecoration(
                          labelText: l.invoiceEmailToLabel,
                          hintText: l.e_gEmail,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _ccController,
                        decoration: InputDecoration(
                          labelText: l.invoiceEmailCcLabel,
                          hintText: l.e_gEmail,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _subjectController,
                        decoration:
                            InputDecoration(labelText: l.invoiceEmailSubjectLabel),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _messageController,
                        decoration:
                            InputDecoration(labelText: l.invoiceEmailMessageLabel),
                        minLines: 5,
                        maxLines: 10,
                      ),
                    ],
                  ),
                ),
                _previewLoading
                    ? Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      )
                    : _previewError != null
                        ? Center(
                            child: Text(
                              _previewError!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            ),
                          )
                        : previewHtml.isEmpty
                            ? Center(
                                child: Text(
                                  l.invoiceEmailNoPreview,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    HtmlWidget(previewHtml),
                                    if (attachmentName != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                cs.surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.attach_file,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  attachmentName,
                                                  style: t.bodySmall.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              if (attachmentSize is int)
                                                Text(
                                                  formatBytes(attachmentSize),
                                                  style:
                                                      t.bodySmall.copyWith(
                                                    color:
                                                        cs.onSurfaceVariant,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_sendMessage != null)
            Text(
              _sendMessage!,
              style: t.bodySmall.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (_sendError != null)
            Text(
              _sendError!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.cancel),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _previewLoading ? null : _loadPreview,
                icon: const Icon(Icons.refresh),
                label: Text(l.invoiceEmailPreviewRefreshCta),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: (!_sending && isReady) ? _send : null,
                icon: _sending
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending ? l.invoiceEmailSendingLabel : l.invoiceEmailSendCta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
