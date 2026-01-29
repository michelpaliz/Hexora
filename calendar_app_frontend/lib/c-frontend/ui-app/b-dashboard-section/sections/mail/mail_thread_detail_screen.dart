import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hexora/a-models/mail/mail_attachment.dart';
import 'package:hexora/a-models/mail/mail_message.dart';
import 'package:hexora/b-backend/mail/domain/mail_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MailThreadDetailScreen extends StatefulWidget {
  const MailThreadDetailScreen({super.key, required this.threadKey});

  final String threadKey;

  @override
  State<MailThreadDetailScreen> createState() => _MailThreadDetailScreenState();
}

class _MailThreadDetailScreenState extends State<MailThreadDetailScreen> {
  bool _downloading = false;
  bool _busyAction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MailDomain>().loadThreadDetail(widget.threadKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailThreadDetailTitle),
      ),
      body: Consumer<MailDomain>(
        builder: (context, domain, _) {
          final state = domain.threadState(widget.threadKey);
          if (state.loading && state.thread == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.thread == null) {
            return Center(
              child: Text(
                state.error!,
                style: t.bodySmall.copyWith(color: cs.error),
              ),
            );
          }

          final thread = state.thread;
          if (thread == null) {
            return Center(
              child: Text(
                l.mailThreadNotFound,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            );
          }

          final subject = thread.subject.trim().isEmpty
              ? l.mailDetailNoSubject
              : thread.subject.trim();
          final participants = thread.participants.isEmpty
              ? '-'
              : thread.participants.join(', ');
          final messages = [...thread.messages]
            ..sort((a, b) {
              final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
              return aDate.compareTo(bDate);
            });

          return ListView(
            padding: const EdgeInsets.all(16),
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
                        style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      _MetadataRow(
                        label: l.mailThreadParticipantsLabel,
                        value: participants,
                      ),
                      const SizedBox(height: 6),
                      _MetadataRow(
                        label: l.mailThreadMessageCountLabel,
                        value: '${thread.messageCount}',
                      ),
                      if (thread.unreadCount > 0) ...[
                        const SizedBox(height: 6),
                        _MetadataRow(
                          label: l.mailThreadUnreadCountLabel,
                          value: '${thread.unreadCount}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (messages.isEmpty)
                Center(
                  child: Text(
                    l.mailThreadNoMessages,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                )
              else
                ...messages.map(
                  (message) => _ThreadMessageCard(
                    message: message,
                    onDownload: (attachment) =>
                        _downloadAttachment(attachment, domain),
                    onOpenMessage: () => Navigator.of(context)
                        .pushNamed('/mail/${message.id}'),
                    onMarkRead: () => _runMessageAction(
                      () => domain.markRead(message.id),
                      l.mailDetailMarkedRead,
                    ),
                    onMarkUnread: () => _runMessageAction(
                      () => domain.markUnread(message.id),
                      l.mailDetailMarkedUnread,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadAttachment(
    MailAttachment attachment,
    MailDomain domain,
  ) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final response = await domain.downloadAttachment(attachment.id);
      final bytes = response.bodyBytes;
      if (!kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.mailDetailDownloadUnsupported),
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
            AppLocalizations.of(context)!.mailDetailDownloadFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _runMessageAction(
    Future<void> Function() action,
    String success,
  ) async {
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
          content: Text(
            AppLocalizations.of(context)!.mailDetailActionFailed(e.toString()),
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

class _ThreadMessageCard extends StatelessWidget {
  const _ThreadMessageCard({
    required this.message,
    required this.onDownload,
    required this.onOpenMessage,
    required this.onMarkRead,
    required this.onMarkUnread,
  });

  final MailMessage message;
  final ValueChanged<MailAttachment> onDownload;
  final VoidCallback onOpenMessage;
  final VoidCallback onMarkRead;
  final VoidCallback onMarkUnread;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenMessage,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fromLabel,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _MetadataRow(label: l.mailDetailToLabel, value: toLabel),
              const SizedBox(height: 10),
              if (body.isNotEmpty)
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
                    : Text(
                        body,
                        style: t.bodySmall.copyWith(color: cs.onSurface),
                      ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onOpenMessage,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l.mailThreadOpenMessage),
                  ),
                  TextButton.icon(
                    onPressed: message.unread ? onMarkRead : onMarkUnread,
                    icon: Icon(
                      message.unread
                          ? Icons.mark_email_read
                          : Icons.mark_email_unread,
                      size: 18,
                    ),
                    label: Text(
                      message.unread
                          ? l.mailDetailMarkRead
                          : l.mailDetailMarkUnread,
                    ),
                  ),
                ],
              ),
              if (message.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l.mailDetailAttachmentsLabel,
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...message.attachments.map(
                  (attachment) => _AttachmentRow(
                    attachment: attachment,
                    downloadLabel: l.mailDetailDownloadTooltip,
                    fallbackLabel: l.mailDetailAttachmentFallback,
                    onDownload: () => onDownload(attachment),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
          width: 80,
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

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.attach_file, size: 20),
      title: Text(filename, style: t.bodySmall),
      subtitle: sizeLabel == null
          ? null
          : Text(sizeLabel, style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
      trailing: IconButton(
        tooltip: downloadLabel,
        icon: const Icon(Icons.download_outlined),
        onPressed: onDownload,
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
