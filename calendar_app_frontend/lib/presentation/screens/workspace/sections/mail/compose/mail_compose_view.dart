part of '../mail_compose_screen.dart';

class _MailComposeView extends StatelessWidget {
  const _MailComposeView({required this.state});

  final _MailComposeScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final workspaceCanvas = theme.brightness == Brightness.dark
        ? theme.scaffoldBackgroundColor
        : AppColors.workspaceCanvas;
    final inputFill =
        theme.inputDecorationTheme.fillColor ?? cs.surfaceContainerLow;
    final l = AppLocalizations.of(context)!;
    final compact = MediaQuery.sizeOf(context).width < 600;
    // The embedded composer shares the viewport with the mail navigation.
    // Reserve the split preparation/editor layout for genuinely wide screens.
    final isWideEmbedded = MediaQuery.of(context).size.width >= 1400;
    final canSend = state._hasRecipientCandidate() &&
        state._quillController.document.toPlainText().trim().isNotEmpty &&
        state._subjectCtrl.text.trim().isNotEmpty;
    final hasRecipient = state._hasRecipientCandidate();
    final hasSubject = state._subjectCtrl.text.trim().isNotEmpty;
    final hasMessage =
        state._quillController.document.toPlainText().trim().isNotEmpty;
    final isReply = state.widget.replyToMessage != null;
    final composeTitle = isReply
        ? (state._isSpanishLocale ? 'Responder' : 'Reply')
        : l.mailComposeTitle;
    final sendLabel = isReply
        ? (state._isSpanishLocale ? 'Enviar respuesta' : 'Send reply')
        : (state._isSpanishLocale ? 'Enviar correo' : 'Send email');
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

    final recipientInput = (!state._useClientMode || isWideEmbedded)
        ? _EmailChipsInput(
            controller: state._toCtrl,
            values: state._toList,
            hint: l.mailComposeToHint,
            enabled: !state._sending && (!isReply || state._toList.isEmpty),
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
            onChanged: (value) {
              if (value != null) state._selectRecipientClient(value);
            },
          );
    final recipientMode = isWideEmbedded
        ? const SizedBox.shrink()
        : _RecipientModeToggle(
            clientMode: state._useClientMode,
            enabled: !state._sending && !isReply,
            emailLabel: state._isSpanishLocale ? 'Manual' : 'Manual',
            clientLabel: state._isSpanishLocale ? 'Selectivo' : 'Selective',
            recentLabel: state._isSpanishLocale ? 'Recientes' : 'Recent',
            recentLoading: state._loadingRecentInvoices,
            onChanged: (v) {
              state._setRecipientSelectionMode(
                v,
                loadClientWorkflow: !v,
              );
              if (v) unawaited(state._openDocumentSelectionWorkflow());
            },
            onRecentTap: state._openRecentIssuedInvoicesPicker,
          );

    final content = LayoutBuilder(
      builder: (context, viewport) {
        final editorMinHeight = compact ? 160.0 : 220.0;
        final fields = <Widget>[
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
          if (!isReply &&
              !state._useClientMode &&
              !state._manualRecipientHintDismissed) ...[
            const SizedBox(height: 4),
            _ManualRecipientHint(
              isSpanish: state._isSpanishLocale,
              onSelectClients: () => state._setRecipientSelectionMode(true),
              onDismiss: () => state
                  .update(() => state._manualRecipientHintDismissed = true),
            ),
          ],
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .45)),
          // ── Subject card ────────────────────────────────────────────────
          _composeSubjectCard(
              state: state, t: t, cs: cs, l: l, compact: compact),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .45)),
          _composeAttachmentsCard(
              state: state, t: t, cs: cs, l: l, compact: compact),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .45)),
        ];

        if (isWideEmbedded && viewport.hasBoundedHeight) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...fields,
                _composeMessageToolbar(
                    state: state,
                    t: t,
                    cs: cs,
                    l: l,
                    compact: compact,
                    inputFill: inputFill),
                Expanded(
                  child: _composeMessageEditor(
                      state: state,
                      t: t,
                      cs: cs,
                      l: l,
                      compact: compact,
                      expands: true,
                      minHeight: 0,
                      inputDecoration: inputDecoration),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...fields,
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
                  expands: false,
                  minHeight: editorMinHeight,
                  inputDecoration: inputDecoration),
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
      },
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
        appBar: AppBar(title: Text(composeTitle)),
        body: SafeArea(top: false, bottom: false, child: mobileBody),
      );
    }

    if (isWideEmbedded) {
      Widget composeHeader(BuildContext headerContext) {
        final headerTypography = AppTypography.of(headerContext);
        final headerColors = Theme.of(headerContext).colorScheme;
        return SizedBox(
          key: const ValueKey('mail-compose-editor-header'),
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (state.widget.onClose != null ||
                  Navigator.of(context).canPop())
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: state.widget.onClose ??
                      () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  style: IconButton.styleFrom(
                    foregroundColor: headerColors.onSurface,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              Expanded(
                child: Text(
                  composeTitle,
                  style: headerTypography.bodySmall.copyWith(
                    color: headerColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isReply)
                _ComposeRecipientModeSelector(
                  selective: state._useClientMode,
                  enabled: !state._sending,
                  onChanged: state._setRecipientSelectionMode,
                ),
            ],
          ),
        );
      }

      final desktopBody = ColoredBox(
        key: const ValueKey('mail-compose-desktop-frame'),
        color: workspaceCanvas,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final selectorWidth =
                        (constraints.maxWidth * .42).clamp(360.0, 560.0);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            key: const ValueKey('mail-compose-editor-surface'),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: .4),
                              ),
                            ),
                            child: Builder(
                              builder: (editorContext) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: composeHeader(editorContext),
                                  ),
                                  Divider(
                                    height: 1,
                                    color: Theme.of(editorContext)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: .35),
                                  ),
                                  Expanded(child: content),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 190),
                          curve: Curves.easeInOutCubic,
                          width: state._useClientMode ? 12 : 0,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 190),
                          curve: Curves.easeInOutCubic,
                          width: state._useClientMode ? selectorWidth : 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ColoredBox(
                              key: const ValueKey(
                                  'mail-compose-options-surface'),
                              color: workspaceCanvas,
                              child: Offstage(
                                offstage: !state._useClientMode,
                                child: _InlineInvoiceFlowPanel(
                                  state: state,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _ComposeBottomBar(
                  sending: state._sending,
                  enabled: canSend,
                  onSend: state._send,
                  label: state._sending ? l.mailComposeSending : sendLabel,
                  disabledHint: disabledSendHint),
            ],
          ),
        ),
      );
      if (state.widget.embedded) return desktopBody;
      return Scaffold(body: SafeArea(child: desktopBody));
    }
    if (state.widget.embedded) {
      return Column(
        children: [
          Expanded(
            child: FolderSectionCard(
              label: composeTitle,
              showTitle: false,
              leftTabOffset: 0,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Text(
                        composeTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
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
        title: Text(composeTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: FolderSectionCard(
          label: composeTitle,
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
