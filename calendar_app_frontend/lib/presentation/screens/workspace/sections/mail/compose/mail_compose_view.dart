part of '../mail_compose_screen.dart';

class _MailComposeView extends StatelessWidget {
  const _MailComposeView({required this.state});

  final _MailComposeScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final inputFill =
        theme.inputDecorationTheme.fillColor ?? cs.surfaceContainerLow;
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final isWideEmbedded = MediaQuery.of(context).size.width >= 1200;
    final canSend = state._hasRecipientCandidate() &&
        state._quillController.document.toPlainText().trim().isNotEmpty &&
        state._subjectCtrl.text.trim().isNotEmpty;
    final hasRecipient = state._hasRecipientCandidate();
    final hasSubject = state._subjectCtrl.text.trim().isNotEmpty;
    final hasMessage =
        state._quillController.document.toPlainText().trim().isNotEmpty;
    final sendLabel = state._isSpanishLocale ? 'Enviar correo' : 'Send email';
    final disabledSendHint = !hasRecipient
        ? (state._isSpanishLocale
            ? 'Selecciona un destinatario para enviar.'
            : 'Select a recipient to send.')
        : !hasSubject && !hasMessage
            ? (state._isSpanishLocale
                ? 'Introduce un asunto y un mensaje para enviar.'
                : 'Enter a subject and message to send.')
            : !hasSubject
                ? (state._isSpanishLocale
                    ? 'Introduce un asunto para enviar.'
                    : 'Enter a subject to send.')
                : !hasMessage
                    ? (state._isSpanishLocale
                        ? 'Escribe un mensaje para enviar.'
                        : 'Write a message to send.')
                    : null;
    final recipientClients = state._recipientClientsWithEmail();

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: inputFill,
      isDense: true,
      labelStyle:
          t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 12),
      hintStyle: t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 12),
      helperStyle:
          t.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );

    final recipientInput = !state._useClientMode
        ? _EmailChipsInput(
            controller: state._toCtrl,
            values: state._toList,
            hint: l.mailComposeToHint,
            enabled: !state._sending,
            decoration: inputDecoration.copyWith(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (next) => state.update(() => state._toList
              ..clear()
              ..addAll(next)),
          )
        : _ClientSearchField(
            clients: recipientClients,
            selectedClientId: state._recipientClientId,
            loading: state._loadingRecipientClients,
            enabled: !state._sending && state._recipientClientError == null,
            onChanged: (value) => state.update(
              () => state._recipientClientId = value,
            ),
          );
    final recipientMode = _RecipientModeToggle(
      clientMode: state._useClientMode,
      enabled: !state._sending,
      emailLabel: 'Email',
      clientLabel: 'Cliente',
      recentLabel: state._isSpanishLocale ? 'Recientes' : 'Recent',
      recentLoading: state._loadingRecentInvoices,
      onChanged: (v) {
        state.update(() => state._useClientMode = v);
        if (v) state._loadRecipientClientsIfNeeded();
      },
      onRecentTap: state._openRecentIssuedInvoicesPicker,
    );

    final content = SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recipients card ──────────────────────────────────────────────
          _composeRecipientsCard(
              state: state,
              context: context,
              t: t,
              cs: cs,
              l: l,
              compact: compact,
              recipientClients: recipientClients,
              inputDecoration: inputDecoration,
              recipientInput: recipientInput,
              recipientMode: recipientMode),
          const SizedBox(height: 8),
          // ── Subject card ────────────────────────────────────────────────
          _composeSubjectCard(
              state: state,
              t: t,
              cs: cs,
              l: l,
              compact: compact,
              inputFill: inputFill),
          const SizedBox(height: 8),
          _composeMessageToolbar(
              state: state,
              t: t,
              cs: cs,
              l: l,
              compact: compact,
              inputFill: inputFill),
          _composeMessageEditor(
              state: state,
              t: t,
              cs: cs,
              l: l,
              compact: compact,
              isWideEmbedded: isWideEmbedded,
              inputDecoration: inputDecoration),

          const SizedBox(height: 8),
          _composeAttachmentsCard(
              state: state, t: t, cs: cs, l: l, compact: compact), // Container
          if (!isWideEmbedded) ...[
            const SizedBox(height: 8),
            _composeInvoiceOptions(
                state: state,
                t: t,
                cs: cs,
                l: l,
                inputDecoration: inputDecoration), // Container
          ],
        ],
      ),
    );

    if (compact) {
      final mobileBody = Column(children: [
        Expanded(child: content),
        _ComposeBottomBar(
            sending: state._sending,
            enabled: canSend,
            onSend: state._send,
            label: state._sending ? l.mailComposeSending : sendLabel,
            disabledHint: disabledSendHint),
      ]);
      if (state.widget.embedded) return mobileBody;
      return Scaffold(
        appBar: AppBar(title: Text(l.mailComposeTitle)),
        body: SafeArea(top: false, bottom: false, child: mobileBody),
      );
    }

    if (isWideEmbedded) {
      final composeHeader = SizedBox(
        key: const ValueKey('mail-compose-editor-header'),
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (state.widget.onClose != null || Navigator.of(context).canPop())
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: state.widget.onClose ??
                    () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(32, 32),
                ),
              ),
            Expanded(
              child: Text(
                l.mailComposeTitle,
                style: t.bodySmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      final desktopBody = Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Expanded(
                  flex: 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NavigationSurface(
                      key: const ValueKey('mail-compose-options-surface'),
                      builder: (context) =>
                          _InlineInvoiceFlowPanel(state: state),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      composeHeader,
                      Expanded(
                        child: Container(
                          key: const ValueKey('mail-compose-editor-surface'),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: .4),
                            ),
                          ),
                          child: content,
                        ),
                      ),
                    ],
                  ),
                ),
              ])),
          const SizedBox(height: 10),
          _ComposeBottomBar(
              sending: state._sending,
              enabled: canSend,
              onSend: state._send,
              label: state._sending ? l.mailComposeSending : sendLabel,
              disabledHint: disabledSendHint),
        ]),
      );
      if (state.widget.embedded) return desktopBody;
      return Scaffold(body: SafeArea(child: desktopBody));
    }
    if (state.widget.embedded) {
      return Column(
        children: [
          Expanded(
            child: FolderSectionCard(
              label: l.mailComposeTitle,
              showTitle: false,
              leftTabOffset: 0,
              child: Column(
                children: [
                  Expanded(child: content),
                  _ComposeBottomBar(
                    sending: state._sending,
                    enabled: canSend,
                    onSend: state._send,
                    label: state._sending ? l.mailComposeSending : sendLabel,
                    disabledHint: disabledSendHint,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailComposeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FolderSectionCard(
          label: l.mailComposeTitle,
          showTitle: false,
          leftTabOffset: 0,
          child: content,
        ),
      ),
      bottomNavigationBar: _ComposeBottomBar(
        sending: state._sending,
        enabled: canSend,
        onSend: state._send,
        label: state._sending ? l.mailComposeSending : sendLabel,
        disabledHint: disabledSendHint,
      ),
    );
  }
}

// ── Template picker dialog ────────────────────────────────────────────────────

// ── Recipient mode toggle (Email / Cliente) ───────────────────────────────────

// ── Searchable client picker ──────────────────────────────────────────────────

// ── Client picker dialog ──────────────────────────────────────────────────────

// ── Inline CC / BCC row ───────────────────────────────────────────────────────
