part of '../mail_console_screen.dart';

// ── Conversation pane ────────────────────────────────────────────────────────

class _ConversationPane extends StatefulWidget {
  const _ConversationPane({
    required this.thread,
    required this.folder,
    required this.replyTarget,
    required this.onStartReply,
    required this.onReply,
    required this.onCloseReply,
    required this.replySubjectController,
    required this.replyController,
    required this.replyFocus,
    required this.sendingReply,
    required this.onDownloadAttachment,
    this.hideSubjectBar = false,
  });

  final MailThreadDetail thread;
  final MailFolder folder;
  final MailMessage? replyTarget;
  final ValueChanged<MailMessage> onStartReply;
  final Future<void> Function(MailMessage) onReply;
  final VoidCallback onCloseReply;
  final TextEditingController replySubjectController;
  final TextEditingController replyController;
  final FocusNode replyFocus;
  final bool sendingReply;
  final ValueChanged<MailAttachment> onDownloadAttachment;
  final bool hideSubjectBar;

  @override
  State<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends State<_ConversationPane> {
  // Newest-first matches how most users scan a thread; kept as pane state
  // (not per-widget-instance) so the choice survives switching threads.
  bool _newestFirst = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final messages = [...widget.thread.messages]..sort((a, b) {
        final aDate = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return _newestFirst ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
      });
    final newestMessageId = widget.thread.messages.isEmpty
        ? null
        : ([
            ...widget.thread.messages
          ]..sort((a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(a.date ?? DateTime.fromMillisecondsSinceEpoch(0))))
            .first
            .id;

    String resolvedSubject = widget.thread.subject.trim();
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
    String replyRecipientDisplay(MailMessage message) {
      final isSent = message.folderEnum == MailFolder.sent ||
          (message.folderEnum == null && widget.folder == MailFolder.sent);
      if (isSent) {
        final recipients =
            message.to.map((address) => address.display).toList();
        return recipients.isEmpty ? '-' : recipients.join(', ');
      }
      final sender = message.fromAddress.trim();
      return sender.isEmpty ? '-' : sender;
    }

    if (MediaQuery.sizeOf(context).width < 650) {
      return _MobileConversation(pane: widget, messages: messages);
    }

    return Column(
      children: [
        // Outside the scrolling list so the compact thread header stays put.
        if (!widget.hideSubjectBar)
          _ConversationHeader(
            subject: subject,
            messageCount: messages.length,
            newestFirst: _newestFirst,
            onSortChanged: (value) {
              if (value == _newestFirst) return;
              setState(() => _newestFirst = value);
            },
          ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 3, 10, 4),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _MessageCard(
                    key: ValueKey(messages[index].id),
                    message: messages[index],
                    initiallyExpanded: messages[index].id == newestMessageId,
                    onReply: () => widget.onStartReply(messages[index]),
                    onDownloadAttachment: widget.onDownloadAttachment,
                  ),
                ),
              ),
              if (widget.replyTarget != null)
                _ReplyComposer(
                  subjectController: widget.replySubjectController,
                  replyController: widget.replyController,
                  replyFocus: widget.replyFocus,
                  onReply:
                      _asyncCallback(() => widget.onReply(widget.replyTarget!)),
                  onClose: widget.onCloseReply,
                  sendingReply: widget.sendingReply,
                  replyToLabel: l.mailConversationReplyTo(
                    replyRecipientDisplay(widget.replyTarget!),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sticky conversation header ───────────────────────────────────────────────

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.subject,
    required this.messageCount,
    required this.newestFirst,
    required this.onSortChanged,
  });

  final String subject;
  final int messageCount;
  final bool newestFirst;
  final ValueChanged<bool> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('mail-conversation-header'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  l.mailConversationMessageCount(messageCount),
                  maxLines: 1,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (messageCount > 1) ...[
            const SizedBox(width: 10),
            _SortOrderToggle(
              newestFirst: newestFirst,
              onChanged: onSortChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _SortOrderToggle extends StatelessWidget {
  const _SortOrderToggle({required this.newestFirst, required this.onChanged});

  final bool newestFirst;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final label = newestFirst
        ? l.mailConversationSortNewestFirst
        : l.mailConversationSortOldestFirst;
    return PopupMenuButton<bool>(
      key: const ValueKey('mail-conversation-sort'),
      tooltip: label,
      initialValue: newestFirst,
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: true,
          child: Text(l.mailConversationSortNewestFirst),
        ),
        PopupMenuItem(
          value: false,
          child: Text(l.mailConversationSortOldestFirst),
        ),
      ],
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              newestFirst
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded,
                size: 15, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Message card ─────────────────────────────────────────────────────────────

class _MessageCard extends StatefulWidget {
  const _MessageCard({
    super.key,
    required this.message,
    required this.initiallyExpanded,
    required this.onReply,
    required this.onDownloadAttachment,
  });

  final MailMessage message;
  final bool initiallyExpanded;
  final VoidCallback onReply;
  final ValueChanged<MailAttachment> onDownloadAttachment;

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  late bool _expanded;
  bool _showQuoted = false;
  bool _showSignature = false;
  bool _showLegal = false;
  bool _showComplete = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

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

    final htmlQuoteSplit = hasHtml ? _splitHtmlAtQuoted(rawBody) : null;
    final quotedHtml = htmlQuoteSplit?.quoted ?? '';
    final htmlSplit =
        hasHtml ? _splitHtmlAtLegal(htmlQuoteSplit?.main ?? rawBody) : null;
    final mainHtml = htmlSplit?.main ?? rawBody;
    final legalHtml = htmlSplit?.legal ?? '';

    final split =
        hasHtml ? const _BodySplit('', '', '', '') : _splitBody(rawBody);
    final mainText = split.main;
    final quoted = split.quoted;
    final signature = split.signature;
    final legalText = split.legal;

    final hasLegal = legalHtml.isNotEmpty || legalText.isNotEmpty;
    final hasQuoted = quotedHtml.isNotEmpty || quoted.isNotEmpty;
    final hasCompactSections = hasLegal || hasQuoted || signature.isNotEmpty;
    final preview = _messagePreview(message);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
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
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              key: ValueKey('mail-message-header-${message.id}'),
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SenderAvatar(address: fromLabel),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MessageHeaderLayout(
                            sender: Column(
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
                            date: Text(
                              dateLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_expanded) ...[
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
                          ] else if (preview.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
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
                    height: 1.35,
                    fontSize: 14,
                  ),
                  child: hasHtml
                      ? MailHtmlContent(
                          html: _showComplete ? rawBody : mainHtml,
                          textColor: cs.onSurface,
                          linkColor: cs.primary,
                          fontFamily: t.bodySmall.fontFamily,
                          fontSize: 14,
                          lineHeight: 1.35,
                          paragraphSpacing: 4,
                        )
                      : Text(
                          _showComplete
                              ? rawBody
                              : (mainText.isEmpty ? rawBody : mainText),
                        ),
                ),
              ),
            ),
            if (hasCompactSections)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: TextButton.icon(
                  key: ValueKey('mail-complete-${message.id}'),
                  onPressed: () =>
                      setState(() => _showComplete = !_showComplete),
                  icon: Icon(
                    _showComplete
                        ? Icons.compress_rounded
                        : Icons.open_in_full_rounded,
                    size: 14,
                  ),
                  label: Text(
                    _showComplete
                        ? l.mailConversationViewCompact
                        : l.mailConversationViewComplete,
                  ),
                ),
              ),
            // ── Legal notice (if detected) ───────────────────────────
            if (!_showComplete && hasLegal)
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
            if (!_showComplete && hasQuoted)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: _CollapsedSection(
                  title: _showQuoted
                      ? l.mailConversationHideQuoted
                      : l.mailConversationShowQuoted,
                  isOpen: _showQuoted,
                  onToggle: () => setState(() => _showQuoted = !_showQuoted),
                  child: hasHtml
                      ? MailHtmlContent(
                          html: quotedHtml,
                          textColor: cs.onSurfaceVariant,
                          linkColor: cs.primary,
                          fontFamily: t.bodySmall.fontFamily,
                          fontSize: 12,
                          lineHeight: 1.35,
                          paragraphSpacing: 4,
                        )
                      : Text(
                          quoted,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            // ── Signature ────────────────────────────────────────────
            if (!_showComplete && !hasHtml && signature.isNotEmpty)
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
            // Desktop quick actions; mobile uses the conversation action bar.
            if (MediaQuery.sizeOf(context).width >= 650)
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
                      onTap: widget.onReply,
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gavel_rounded, size: 13, color: _amber),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(
                    isOpen ? hideLabel : showLabel,
                    style: t.bodySmall.copyWith(
                      fontSize: 14,
                      color: _amber,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: l.mailDetailDownloadTooltip,
              icon: Icon(Icons.download_outlined,
                  size: 22, color: cs.onSurfaceVariant),
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
    required this.subjectController,
    required this.replyController,
    required this.replyFocus,
    required this.onReply,
    required this.onClose,
    required this.sendingReply,
    required this.replyToLabel,
  });

  final TextEditingController subjectController;
  final TextEditingController replyController;
  final FocusNode replyFocus;
  final VoidCallback onReply;
  final VoidCallback onClose;
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
              if (!sendingReply && replyController.text.trim().isNotEmpty) {
                onReply();
              }
              return null;
            },
          ),
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    size: 15,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      replyToLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: sendingReply ? null : onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: subjectController,
                enabled: !sendingReply,
                maxLines: 1,
                textInputAction: TextInputAction.next,
                style: t.bodySmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)!.mailComposeSubjectLabel,
                  hintText:
                      AppLocalizations.of(context)!.mailComposeSubjectHint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
              const SizedBox(height: 8),
              TextField(
                controller: replyController,
                focusNode: replyFocus,
                readOnly: sendingReply,
                minLines: 5,
                maxLines: 9,
                keyboardType: TextInputType.multiline,
                style: t.bodySmall.copyWith(fontSize: 16, height: 1.4),
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context)!.mailConsoleReplyPlaceholder,
                  hintStyle: t.bodySmall.copyWith(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(12),
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: replyController,
                  builder: (context, value, _) => FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      textStyle: t.bodySmall.copyWith(fontSize: 14),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: sendingReply || value.text.trim().isEmpty
                        ? null
                        : onReply,
                    icon: sendingReply
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      sendingReply
                          ? AppLocalizations.of(context)!
                              .mailConsoleReplySending
                          : AppLocalizations.of(context)!.mailConsoleReplySend,
                    ),
                  ),
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
  const _ActionChipBtn({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
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
    RegExp(r'ADVERTENCIA\s+LEGAL', caseSensitive: false),
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
      } else if (_isQuotedTextBoundary(line)) {
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

bool _isQuotedTextBoundary(String line) {
  final value = line.trim();
  if (value.startsWith('>')) return true;
  return RegExp(
        r'^(?:On .+ wrote:|El .+ escribió:)\s*$',
        caseSensitive: false,
      ).hasMatch(value) ||
      RegExp(
        r'^-{2,}\s*(?:Original Message|Mensaje original)\s*-{2,}$',
        caseSensitive: false,
      ).hasMatch(value);
}

/// Splits only at well-known quoted-history markers. The complete-message
/// control remains available in case a provider uses an unusual structure.
({String main, String quoted}) _splitHtmlAtQuoted(String html) {
  final patterns = <RegExp>[
    RegExp(
      r'''<(?:div|section)\b[^>]*(?:class|id)\s*=\s*["'][^"']*(?:gmail_quote|yahoo_quoted|moz-cite-prefix|divRplyFwdMsg|replyForwardMsg)[^"']*["']''',
      caseSensitive: false,
    ),
    RegExp(
      r'''<blockquote\b[^>]*type\s*=\s*["']?cite["']?''',
      caseSensitive: false,
    ),
  ];
  var splitAt = html.length;
  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    if (match != null && match.start < splitAt) splitAt = match.start;
  }
  if (splitAt == html.length) return (main: html, quoted: '');
  return (
    main: html.substring(0, splitAt).trim(),
    quoted: html.substring(splitAt).trim(),
  );
}

String _messagePreview(MailMessage message) {
  var value = (message.snippet ?? '').trim();
  if (value.isEmpty) value = (message.textBody ?? '').trim();
  if (value.isEmpty) value = (message.htmlBody ?? '').trim();
  if (value.isEmpty) return '';

  value = value
      .replaceAll(
        RegExp(
          r'<(?:style|script)\b[^>]*>[\s\S]*?</(?:style|script)>',
          caseSensitive: false,
        ),
        ' ',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return value.length > 140 ? '${value.substring(0, 140)}…' : value;
}

/// Splits raw HTML at the first detected legal/disclaimer block.
/// Returns `(main: ..., legal: ...)` — legal is empty if none found.
({String main, String legal}) _splitHtmlAtLegal(String html) {
  final lowerHtml = html.toLowerCase();
  const patterns = [
    'aviso legal',
    'advertencia legal',
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
