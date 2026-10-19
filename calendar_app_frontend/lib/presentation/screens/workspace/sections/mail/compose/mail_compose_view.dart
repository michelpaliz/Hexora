part of '../mail_compose_screen.dart';

class _MailComposeView extends StatelessWidget {
  const _MailComposeView({required this.state});

  final _MailComposeScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
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
      fillColor: cs.surfaceContainerLow,
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
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
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
          const SizedBox(height: 16),
          // ── Subject card ────────────────────────────────────────────────
          _composeSubjectCard(
              state: state, t: t, cs: cs, l: l, compact: compact),
          const SizedBox(height: 16),
          _composeMessageToolbar(
              state: state, t: t, cs: cs, l: l, compact: compact),
          _composeMessageEditor(
              state: state,
              t: t,
              cs: cs,
              l: l,
              compact: compact,
              isWideEmbedded: isWideEmbedded,
              inputDecoration: inputDecoration),

          const SizedBox(height: 16),
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
      final desktopBody = Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (state.widget.onClose != null ||
                    Navigator.of(context).canPop()) ...[
                  IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: state.widget.onClose ??
                          () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 20)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(l.mailComposeTitle,
                          style: t.titleLarge.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          state._isSpanishLocale
                              ? 'Envía facturas a tus clientes de forma rápida y personalizada.'
                              : 'Send invoices to your clients with a personal message.',
                          style:
                              t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                    ])),
              ])),
          Expanded(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Expanded(
                    flex: 6,
                    child: Container(
                        decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: .4))),
                        child: content)),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: _InlineInvoiceFlowPanel(state: state)),
              ])),
          const SizedBox(height: 12),
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
