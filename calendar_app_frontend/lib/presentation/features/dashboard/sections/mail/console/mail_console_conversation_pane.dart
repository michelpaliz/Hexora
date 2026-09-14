part of '../mail_console_screen.dart';

// ── Conversation pane ────────────────────────────────────────────────────────

class _ConversationPane extends StatelessWidget {
  const _ConversationPane({
    required this.thread,
    required this.onReply,
    required this.replyController,
    required this.sendingReply,
    required this.onDownloadAttachment,
    this.hideSubjectBar = false,
  });

  final MailThreadDetail thread;
  final Future<void> Function(List<MailMessage>) onReply;
  final TextEditingController replyController;
  final bool sendingReply;
  final ValueChanged<MailAttachment> onDownloadAttachment;
  final bool hideSubjectBar;

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

    String resolvedSubject = thread.subject.trim();
    if (resolvedSubject.isEmpty) {
      for (final message in messages.reversed) {
        final candidate = message.subject.trim();
        if (candidate.isNotEmpty) {
          resolvedSubject = candidate;
          break;
        }
      }
    }
    final subject =
        resolvedSubject.isEmpty ? l.mailDetailNoSubject : resolvedSubject;
    final participants = thread.participants.join(', ').trim();
    final latestSender = messages.isEmpty ? '-' : messages.last.fromAddress;

    return Column(
      children: [
        // ── Compact sticky subject bar ────────────────────────────
        if (!hideSubjectBar) Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (participants.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  participants,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // ── Message list + sticky reply composer ─────────────────
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _MessageCard(
                    message: messages[index],
                    onDownloadAttachment: onDownloadAttachment,
                  ),
                ),
              ),
              _ReplyComposer(
                replyController: replyController,
                onReply: _asyncCallback(() => onReply(messages)),
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

// ── Message card ─────────────────────────────────────────────────────────────

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
  bool _showLegal = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final message = widget.message;

    // ── Sender info ───────────────────────────────────────────────
    final fromLabel = message.fromAddress.isEmpty
        ? l.mailDetailUnknownSender
        : message.fromAddress;
    final fromAddressOnly = (message.from?.address ?? '').trim();
    final showFromAddressOnly = fromAddressOnly.isNotEmpty &&
        !fromLabel.toLowerCase().contains(fromAddressOnly.toLowerCase());
    final toAddresses = message.to.isEmpty
        ? <String>['-']
        : message.to.map((e) => e.display).toList();
    final ccAddresses = message.cc.map((e) => e.display).toList();
    final dateLabel = message.date == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).add_jm().format(message.date!);

    // ── Body preparation ──────────────────────────────────────────
    final htmlBody = message.htmlBody?.trim();
    final textBody = message.textBody?.trim();
    final hasHtml = htmlBody != null && htmlBody.isNotEmpty;
    final rawBody = hasHtml ? htmlBody : (textBody ?? '');

    final htmlSplit = hasHtml ? _splitHtmlAtLegal(rawBody) : null;
    final mainHtml = htmlSplit?.main ?? rawBody;
    final legalHtml = htmlSplit?.legal ?? '';

    final split = hasHtml ? const _BodySplit('', '', '', '') : _splitBody(rawBody);
    final mainText = split.main;
    final quoted = split.quoted;
    final signature = split.signature;
    final legalText = split.legal;

    final hasLegal = legalHtml.isNotEmpty || legalText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header zone ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SenderAvatar(address: fromLabel),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fromLabel,
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (showFromAddressOnly) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    fromAddressOnly,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              dateLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      _MetaChipRow(
                        label: l.mailDetailToLabel,
                        addresses: toAddresses,
                      ),
                      if (ccAddresses.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _MetaChipRow(
                          label: 'CC',
                          addresses: ccAddresses,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
          // ── Body zone ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: DefaultTextStyle(
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  height: 1.6,
                  fontSize: 14,
                ),
                child: hasHtml
                    ? MailHtmlContent(
                        html: mainHtml,
                        textColor: cs.onSurface,
                        linkColor: cs.primary,
                        fontFamily: t.bodySmall.fontFamily,
                        fontSize: 14,
                        lineHeight: 1.6,
                        paragraphSpacing: 12,
                      )
                    : Text(mainText.isEmpty ? rawBody : mainText),
              ),
            ),
          ),
          // ── Legal notice (if detected) ───────────────────────────
          if (hasLegal)
            _LegalSection(
              isOpen: _showLegal,
              showLabel: l.mailLegalNoticeShow,
              hideLabel: l.mailLegalNoticeHide,
              onToggle: () => setState(() => _showLegal = !_showLegal),
              child: hasHtml
                  ? MailHtmlContent(
                      html: legalHtml,
                      textColor: cs.onSurfaceVariant,
                      linkColor: cs.primary,
                      fontFamily: t.bodySmall.fontFamily,
                      fontSize: 11,
                      lineHeight: 1.4,
                      paragraphSpacing: 6,
                    )
                  : Text(
                      legalText,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                        fontSize: 11,
                      ),
                    ),
            ),
          // ── Quoted messages ──────────────────────────────────────
          if (!hasHtml && quoted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: _CollapsedSection(
                title: l.mailConversationPreviousMessage(1),
                isOpen: _showQuoted,
                onToggle: () => setState(() => _showQuoted = !_showQuoted),
                child: Text(
                  quoted,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // ── Signature ────────────────────────────────────────────
          if (!hasHtml && signature.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: _CollapsedSection(
                title: l.mailConversationSignature,
                isOpen: _showSignature,
                onToggle: () =>
                    setState(() => _showSignature = !_showSignature),
                child: Text(
                  signature,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // ── Attachments ──────────────────────────────────────────
          if (message.attachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.mailDetailAttachmentsLabel,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...message.attachments.map(
                    (a) => _AttachmentRow(
                      attachment: a,
                      onDownload: () => widget.onDownloadAttachment(a),
                    ),
                  ),
                ],
              ),
            ),
          // ── Footer action buttons ────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                _ActionChipBtn(
                  icon: Icons.reply_rounded,
                  label: l.mailConversationReply,
                ),
                const SizedBox(width: 6),
                _ActionChipBtn(
                  icon: Icons.reply_all_rounded,
                  label: l.mailConversationReplyAll,
                ),
                const SizedBox(width: 6),
                _ActionChipBtn(
                  icon: Icons.forward_rounded,
                  label: l.mailConversationForward,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sender avatar ─────────────────────────────────────────────────────────────

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.address});

  final String address;

  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
  ];

  Color get _color {
    if (address.trim().isEmpty) return _palette[0];
    final hash = address.codeUnits.fold(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        address.trim().isEmpty ? '?' : address.trim()[0].toUpperCase();
    final color = _color;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── Metadata chip row ─────────────────────────────────────────────────────────

class _MetaChipRow extends StatelessWidget {
  const _MetaChipRow({required this.label, required this.addresses});

  final String label;
  final List<String> addresses;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (addresses.isEmpty) return const SizedBox.shrink();

    const maxVisible = 3;
    final visible = addresses.take(maxVisible).toList();
    final overflow = addresses.length - maxVisible;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label ',
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              ...visible.map((v) => _EmailChip(value: v)),
              if (overflow > 0) _EmailChip(value: '+$overflow', muted: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmailChip extends StatelessWidget {
  const _EmailChip({required this.value, this.muted = false});

  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: muted
            ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
            : cs.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: t.bodySmall.copyWith(
          fontSize: 10,
          color: muted ? cs.onSurfaceVariant : cs.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Legal section ─────────────────────────────────────────────────────────────

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.isOpen,
    required this.showLabel,
    required this.hideLabel,
    required this.onToggle,
    required this.child,
  });

  final bool isOpen;
  final String showLabel;
  final String hideLabel;
  final VoidCallback onToggle;
  final Widget child;

  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gavel_rounded,
                      size: 13, color: _amber),
                  const SizedBox(width: 5),
                  Text(
                    isOpen ? hideLabel : showLabel,
                    style: t.bodySmall.copyWith(
                      fontSize: 11,
                      color: _amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: _amber.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _amber.withValues(alpha: 0.2),
                ),
              ),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Attachment row ────────────────────────────────────────────────────────────

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.attach_file, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              sizeLabel != null ? '$filename ($sizeLabel)' : filename,
              style: t.bodySmall.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: l.mailDetailDownloadTooltip,
              icon: Icon(Icons.download_outlined,
                  size: 16, color: cs.onSurfaceVariant),
              onPressed: onDownload,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Collapsed section ─────────────────────────────────────────────────────────

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

// ── Reply composer ────────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            border: Border(
              top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: replyController,
                  maxLines: 2,
                  style: t.bodySmall.copyWith(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: replyToLabel,
                    hintStyle: t.bodySmall.copyWith(
                        fontSize: 12, color: cs.onSurfaceVariant),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: t.bodySmall.copyWith(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: sendingReply ? null : onReply,
                icon: sendingReply
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
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

// ── Action chip button ────────────────────────────────────────────────────────

class _ActionChipBtn extends StatelessWidget {
  const _ActionChipBtn({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Body split helpers ────────────────────────────────────────────────────────

class _BodySplit {
  const _BodySplit(this.main, this.quoted, this.signature, this.legal);
  final String main;
  final String quoted;
  final String signature;
  final String legal;
}

_BodySplit _splitBody(String body) {
  if (body.isEmpty) return const _BodySplit('', '', '', '');
  final lines = body.split('\n');
  final main = <String>[];
  final quoted = <String>[];
  final signature = <String>[];
  final legal = <String>[];
  var inQuote = false;
  var inSignature = false;
  var inLegal = false;

  final legalPatterns = [
    RegExp(r'AVISO\s+LEGAL', caseSensitive: false),
    RegExp(r'AVISO\s+DE\s+CONFIDENCIALIDAD', caseSensitive: false),
    RegExp(r'DISCLAIMER', caseSensitive: false),
    RegExp(r'LEGAL\s+NOTICE', caseSensitive: false),
    RegExp(r'ESTE MENSAJE ES CONFIDENCIAL', caseSensitive: false),
    RegExp(r'THIS EMAIL IS CONFIDENTIAL', caseSensitive: false),
  ];

  for (final raw in lines) {
    final line = raw.trimRight();
    if (!inQuote && !inSignature && !inLegal) {
      if (legalPatterns.any((p) => p.hasMatch(line))) {
        inLegal = true;
      } else if (line.startsWith('>') ||
          line.contains('escribió:') ||
          line.contains('wrote:')) {
        inQuote = true;
      } else if (line == '--' || line == '__') {
        inSignature = true;
      }
    }
    if (inLegal) {
      legal.add(line);
    } else if (inQuote) {
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
    legal.join('\n').trim(),
  );
}

/// Splits raw HTML at the first detected legal/disclaimer block.
/// Returns `(main: ..., legal: ...)` — legal is empty if none found.
({String main, String legal}) _splitHtmlAtLegal(String html) {
  final lowerHtml = html.toLowerCase();
  const patterns = [
    'aviso legal',
    'aviso de confidencialidad',
    'disclaimer',
    'legal notice',
    'este mensaje es confidencial',
    'this email is confidential',
    'este correo es confidencial',
  ];

  var earliestIdx = html.length;
  for (final p in patterns) {
    final idx = lowerHtml.indexOf(p);
    if (idx >= 0 && idx < earliestIdx) earliestIdx = idx;
  }

  if (earliestIdx == html.length) return (main: html, legal: '');

  // Walk back to the nearest preceding block-level tag boundary
  final before = html.substring(0, earliestIdx).toLowerCase();
  int boundary = -1;
  for (final tag in ['<hr', '<p', '<div', '<br']) {
    final idx = before.lastIndexOf(tag);
    if (idx > boundary) boundary = idx;
  }

  final splitAt = boundary >= 0 ? boundary : earliestIdx;
  return (
    main: html.substring(0, splitAt).trim(),
    legal: html.substring(splitAt).trim(),
  );
}
