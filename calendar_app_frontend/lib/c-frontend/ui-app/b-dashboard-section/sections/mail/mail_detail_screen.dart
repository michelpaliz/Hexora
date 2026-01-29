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
          final fromLabel = message.fromAddress.isEmpty
              ? l.mailDetailUnknownSender
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style:
                              t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        _MetadataRow(
                          label: l.mailDetailFromLabel,
                          value: fromLabel,
                        ),
                        const SizedBox(height: 6),
                        _MetadataRow(
                          label: l.mailDetailToLabel,
                          value: toLabel,
                        ),
                        const SizedBox(height: 6),
                        _MetadataRow(
                          label: l.mailDetailDateLabel,
                          value: dateLabel,
                        ),
                        const SizedBox(height: 16),
                        _ActionBar(
                          unread: message.unread,
                          busy: _busyAction,
                          markReadLabel: l.mailDetailMarkRead,
                          markUnreadLabel: l.mailDetailMarkUnread,
                          archiveLabel: l.mailDetailArchive,
                          trashLabel: l.mailDetailTrash,
                          spamLabel: l.mailDetailSpam,
                          onMarkRead: () => _runAction(
                            () =>
                                context.read<MailDomain>().markRead(message.id),
                            success: l.mailDetailMarkedRead,
                          ),
                          onMarkUnread: () => _runAction(
                            () => context
                                .read<MailDomain>()
                                .markUnread(message.id),
                            success: l.mailDetailMarkedUnread,
                          ),
                          onArchive: () => _runAction(
                            () =>
                                context.read<MailDomain>().archive(message.id),
                            success: l.mailDetailArchived,
                          ),
                          onTrash: () => _runAction(
                            () => context.read<MailDomain>().trash(message.id),
                            success: l.mailDetailTrashed,
                          ),
                          onSpam: () => _runAction(
                            () => context.read<MailDomain>().spam(message.id),
                            success: l.mailDetailSpammed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (body.isNotEmpty) ...[
                  Text(
                    l.mailDetailBodyLabel,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  hasHtml
                      ? Html(
                          data: body,
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              color: cs.onSurface,
                              fontSize: FontSize(t.bodySmall.fontSize ?? 14),
                              fontFamily: t.bodySmall.fontFamily,
                            ),
                            'p': Style(margin: Margins.only(bottom: 10)),
                          },
                        )
                      : SelectableText(
                          body,
                          style: t.bodySmall.copyWith(color: cs.onSurface),
                        ),
                  const SizedBox(height: 20),
                ],
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
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String success,
  }) async {
    if (_busyAction) return;
    setState(() => _busyAction = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .mailDetailActionFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyAction = false);
      }
    }
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

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.unread,
    required this.busy,
    required this.markReadLabel,
    required this.markUnreadLabel,
    required this.archiveLabel,
    required this.trashLabel,
    required this.spamLabel,
    required this.onMarkRead,
    required this.onMarkUnread,
    required this.onArchive,
    required this.onTrash,
    required this.onSpam,
  });

  final bool unread;
  final bool busy;
  final String markReadLabel;
  final String markUnreadLabel;
  final String archiveLabel;
  final String trashLabel;
  final String spamLabel;
  final VoidCallback onMarkRead;
  final VoidCallback onMarkUnread;
  final VoidCallback onArchive;
  final VoidCallback onTrash;
  final VoidCallback onSpam;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: busy ? null : (unread ? onMarkRead : onMarkUnread),
          icon: Icon(unread ? Icons.mark_email_read : Icons.mark_email_unread),
          label: Text(unread ? markReadLabel : markUnreadLabel),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onArchive,
          icon: const Icon(Icons.archive_outlined),
          label: Text(archiveLabel),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onTrash,
          icon: const Icon(Icons.delete_outline),
          label: Text(trashLabel),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onSpam,
          icon: const Icon(Icons.report_outlined),
          label: Text(spamLabel),
        ),
      ],
    );
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
