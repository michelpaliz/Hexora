import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hexora/a-models/mail/mail_attachment.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MailDetailScreen extends StatefulWidget {
  const MailDetailScreen({super.key, required this.messageId});

  final String messageId;

  @override
  State<MailDetailScreen> createState() => _MailDetailScreenState();
}

class _MailDetailScreenState extends State<MailDetailScreen> {
  bool _busyAction = false;
  bool _didAutoMark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndMaybeMark();
    });
  }

  Future<void> _loadAndMaybeMark() async {
    final domain = context.read<MailDomain>();
    final message = await domain.loadMessage(widget.messageId);
    if (!mounted) return;
    if (_didAutoMark || message == null) return;
    if (message.unread) {
      _didAutoMark = true;
      try {
        await domain.markRead(message.id);
      } catch (_) {
        // Silent fail for auto-mark.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailDetailTitle),
      ),
      body: Consumer<MailDomain>(
        builder: (context, domain, _) {
          final state = domain.messageState(widget.messageId);
          if (state.loading && state.message == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.message == null) {
            return Center(
              child: Text(
                state.error!,
                style: t.bodySmall.copyWith(color: cs.error),
              ),
            );
          }

          final message = state.message;
          if (message == null) {
            return Center(
              child: Text(
                l.mailDetailNotFound,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            );
          }

          final subject = message.subject.trim().isEmpty
              ? l.mailDetailNoSubject
              : message.subject.trim();
          final fromName =
              message.from?.name?.trim().isNotEmpty == true
                  ? message.from!.name!.trim()
                  : (message.fromAddress.isEmpty
                      ? l.mailDetailUnknownSender
                      : message.fromAddress);
          final fromEmail = message.from?.address.trim().isNotEmpty == true
              ? message.from!.address.trim()
              : message.fromAddress;
          final toLabel = message.to.isEmpty
              ? '-'
              : message.to.map((e) => e.display).join(', ');
          final dateLabel = message.date == null
              ? '-'
              : DateFormat.yMMMd(l.localeName).add_jm().format(message.date!);
          final htmlBody = message.htmlBody?.trim();
          final textBody = message.textBody?.trim();
          final hasHtml = htmlBody != null && htmlBody.isNotEmpty;
          final body = hasHtml ? htmlBody : (textBody ?? '');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject,
                              style: t.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              fromName,
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fromEmail,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${l.mailDetailToLabel}: $toLabel',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (body.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: DefaultTextStyle(
                      style: t.bodySmall.copyWith(
                        color: cs.onSurface,
                        height: 1.6,
                      ),
                      child: hasHtml
                          ? Html(
                              data: body,
                              style: {
                                'body': Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  color: cs.onSurface,
                                  fontSize:
                                      FontSize(t.bodySmall.fontSize ?? 14),
                                  fontFamily: t.bodySmall.fontFamily,
                                ),
                                'p': Style(margin: Margins.only(bottom: 12)),
                              },
                            )
                          : SelectableText(body),
                    ),
                  ),
                const SizedBox(height: 20),
                if (message.attachments.isNotEmpty) ...[
                  Text(
                    l.mailDetailAttachmentsLabel,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...message.attachments.map(
                    (attachment) => _AttachmentRow(
                      attachment: attachment,
                      downloadLabel: l.mailDetailDownloadTooltip,
                      fallbackLabel: l.mailDetailAttachmentFallback,
                      onDownload: () => _downloadAttachment(
                        attachment,
                        domain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: Text(l.mailConversationReply),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      child: Text(l.mailConversationReplyAll),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {},
                      child: Text(l.mailConversationForward),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadAttachment(
    MailAttachment attachment,
    MailDomain domain,
  ) async {
    if (_busyAction) return;
    setState(() => _busyAction = true);
    try {
      final response = await domain.downloadAttachment(attachment.id);
      final bytes = response.bodyBytes;
      if (!kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.mailDetailDownloadUnsupported),
          ),
        );
        return;
      }
      final filename = attachment.filename?.trim().isNotEmpty == true
          ? attachment.filename!.trim()
          : 'attachment-${attachment.id}';
      final mimeType =
          response.headers['content-type'] ?? 'application/octet-stream';
      await launchFileDownload(
        Uint8List.fromList(bytes),
        fileName: filename,
        mimeType: mimeType,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .mailDetailDownloadFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachment,
    required this.downloadLabel,
    required this.fallbackLabel,
    required this.onDownload,
  });

  final MailAttachment attachment;
  final String downloadLabel;
  final String fallbackLabel;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final filename = attachment.filename?.trim().isNotEmpty == true
        ? attachment.filename!.trim()
        : fallbackLabel;
    final sizeLabel = _formatBytes(attachment.size);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      child: ListTile(
        leading: const Icon(Icons.attach_file),
        title: Text(filename, style: t.bodySmall),
        subtitle: sizeLabel == null
            ? null
            : Text(sizeLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
        trailing: IconButton(
          tooltip: downloadLabel,
          icon: const Icon(Icons.download_outlined),
          onPressed: onDownload,
        ),
      ),
    );
  }
}

String? _formatBytes(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '${bytes} B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(2)} GB';
}
