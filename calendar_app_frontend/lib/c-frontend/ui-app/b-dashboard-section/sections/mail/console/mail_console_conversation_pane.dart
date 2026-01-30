part of '../mail_console_screen.dart';

class _ConversationPane extends StatelessWidget {
  const _ConversationPane({
    required this.thread,
    required this.onReply,
    required this.replyController,
    required this.sendingReply,
    required this.onDownloadAttachment,
  });

  final MailThreadDetail thread;
  final Future<void> Function(List<MailMessage>) onReply;
  final TextEditingController replyController;
  final bool sendingReply;
  final ValueChanged<MailAttachment> onDownloadAttachment;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final messages = [...thread.messages]..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
    final subject = thread.subject.trim().isEmpty
        ? l.mailDetailNoSubject
        : thread.subject.trim();
    final participants =
        thread.participants.isEmpty ? '-' : thread.participants.join(', ');
    final latestSender = messages.isEmpty ? '-' : messages.last.fromAddress;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      participants,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _MessageCard(
                      message: messages[index],
                      onDownloadAttachment: onDownloadAttachment,
                    );
                  },
                ),
              ),
              _ReplyComposer(
                replyController: replyController,
                onReply: () => onReply(messages),
                sendingReply: sendingReply,
                replyToLabel: l.mailConversationReplyTo(latestSender),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatefulWidget {
  const _MessageCard({
    required this.message,
    required this.onDownloadAttachment,
  });

  final MailMessage message;
  final ValueChanged<MailAttachment> onDownloadAttachment;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  bool _showQuoted = false;
  bool _showSignature = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final message = widget.message;
    final fromLabel = message.fromAddress.isEmpty
        ? l.mailDetailUnknownSender
        : message.fromAddress;
    final toLabel =
        message.to.isEmpty ? '-' : message.to.map((e) => e.display).join(', ');
    final dateLabel = message.date == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).add_jm().format(message.date!);
    final htmlBody = message.htmlBody?.trim();
    final textBody = message.textBody?.trim();
    final hasHtml = htmlBody != null && htmlBody.isNotEmpty;
    final body = hasHtml ? htmlBody : (textBody ?? '');
    final split = _splitBody(body);
    final mainText = split.main;
    final quoted = split.quoted;
    final signature = split.signature;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fromLabel,
                        style:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.from?.address ?? '',
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: DefaultTextStyle(
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  height: 1.55,
                ),
                child: hasHtml
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
                    : Text(mainText.isEmpty ? body : mainText),
              ),
            ),
            if (!hasHtml && quoted.isNotEmpty) ...[
              const SizedBox(height: 8),
              _CollapsedSection(
                title: l.mailConversationPreviousMessage(1),
                isOpen: _showQuoted,
                onToggle: () => setState(() => _showQuoted = !_showQuoted),
                child: Text(
                  quoted,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (!hasHtml && signature.isNotEmpty) ...[
              const SizedBox(height: 6),
              _CollapsedSection(
                title: l.mailConversationSignature,
                isOpen: _showSignature,
                onToggle: () =>
                    setState(() => _showSignature = !_showSignature),
                child: Text(
                  signature,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.mailDetailAttachmentsLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              ...message.attachments.map(
                (attachment) => _AttachmentRow(
                  attachment: attachment,
                  onDownload: () => widget.onDownloadAttachment(attachment),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: null,
                  child: Text(l.mailConversationReply),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: null,
                  child: Text(l.mailConversationReplyAll),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: null,
                  child: Text(l.mailConversationForward),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.attachment, required this.onDownload});

  final MailAttachment attachment;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final filename = attachment.filename?.trim().isNotEmpty == true
        ? attachment.filename!.trim()
        : l.mailDetailAttachmentFallback;
    final sizeLabel = _formatBytes(attachment.size);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.attach_file, size: 18),
      title: Text(filename, style: t.bodySmall),
      subtitle: sizeLabel == null
          ? null
          : Text(sizeLabel,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
      trailing: IconButton(
        tooltip: l.mailDetailDownloadTooltip,
        icon: const Icon(Icons.download_outlined),
        onPressed: onDownload,
      ),
    );
  }
}

class _CollapsedSection extends StatelessWidget {
  const _CollapsedSection({
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOpen ? Icons.expand_more : Icons.chevron_right,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        if (isOpen) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: child,
          ),
        ],
      ],
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.replyController,
    required this.onReply,
    required this.sendingReply,
    required this.replyToLabel,
  });

  final TextEditingController replyController;
  final VoidCallback onReply;
  final bool sendingReply;
  final String replyToLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter):
            const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter):
            const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (!sendingReply) onReply();
              return null;
            },
          ),
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replyController,
                  maxLines: 2,
                  style: t.bodySmall,
                  decoration: InputDecoration(
                    hintText: replyToLabel,
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: sendingReply ? null : onReply,
                icon: sendingReply
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  sendingReply
                      ? AppLocalizations.of(context)!.mailConsoleReplySending
                      : AppLocalizations.of(context)!.mailConsoleReplySend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodySplit {
  const _BodySplit(this.main, this.quoted, this.signature);
  final String main;
  final String quoted;
  final String signature;
}

_BodySplit _splitBody(String body) {
  if (body.isEmpty) return const _BodySplit('', '', '');
  final lines = body.split('\n');
  final main = <String>[];
  final quoted = <String>[];
  final signature = <String>[];
  var inQuote = false;
  var inSignature = false;

  for (final raw in lines) {
    final line = raw.trimRight();
    if (!inQuote && !inSignature) {
      if (line.startsWith('>') ||
          line.contains('escribió:') ||
          line.contains('wrote:')) {
        inQuote = true;
      } else if (line == '--' || line == '__') {
        inSignature = true;
      }
    }

    if (inQuote) {
      quoted.add(line);
    } else if (inSignature) {
      signature.add(line);
    } else {
      main.add(line);
    }
  }

  return _BodySplit(
    main.join('\n').trim(),
    quoted.join('\n').trim(),
    signature.join('\n').trim(),
  );
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
          width: 70,
          child: Text(label,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
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
