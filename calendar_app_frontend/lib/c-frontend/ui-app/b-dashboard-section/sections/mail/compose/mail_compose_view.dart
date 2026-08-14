part of '../mail_compose_screen.dart';

class _MailComposeView extends StatelessWidget {
  const _MailComposeView({required this.state});

  final _MailComposeScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isWideEmbedded =
        state.widget.embedded && MediaQuery.of(context).size.width >= 1200;
    final canSend = state._hasRecipientCandidate() &&
        state._quillController.document.toPlainText().trim().isNotEmpty &&
        state._subjectCtrl.text.trim().isNotEmpty;
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

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.widget.embedded) ...[
            const SizedBox(height: 2),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
          ],
          // ── Recipients card ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── To row ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // "Para" label
                      SizedBox(
                        width: 42,
                        child: Text(
                          l.mailComposeToLabel,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // Input area
                      Expanded(
                        child: !state._useClientMode
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
                                onChanged: (next) =>
                                    state.update(() => state._toList
                                      ..clear()
                                      ..addAll(next)),
                              )
                            : _ClientSearchField(
                                clients: recipientClients,
                                selectedClientId: state._recipientClientId,
                                loading: state._loadingRecipientClients,
                                enabled: !state._sending,
                                onChanged: (value) => state.update(
                                  () => state._recipientClientId = value,
                                ),
                              ),
                      ),
                      const SizedBox(width: 6),
                      // Compact mode toggle
                      _RecipientModeToggle(
                        clientMode: state._useClientMode,
                        enabled: !state._sending,
                        emailLabel: 'Email',
                        clientLabel: 'Cliente',
                        recentLabel:
                            state._isSpanishLocale ? 'Recientes' : 'Recent',
                        recentLoading: state._loadingRecentInvoices,
                        onChanged: (v) =>
                            state.update(() => state._useClientMode = v),
                        onRecentTap: state._openRecentIssuedInvoicesPicker,
                      ),
                    ],
                  ),
                ),
                // Sub-hints for email / client mode
                if (!state._useClientMode && state._toList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 12, 6),
                    child: Text(
                      l.mailComposeToHelper,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (state._useClientMode) ...[
                  if ((state._recipientClientError ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 0, 12, 6),
                      child: Row(children: [
                        Icon(Icons.error_outline, size: 13, color: cs.error),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(state._recipientClientError!,
                              style: t.bodySmall
                                  .copyWith(color: cs.error, fontSize: 11)),
                        ),
                      ]),
                    ),
                  if (!state._loadingRecipientClients &&
                      recipientClients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 0, 12, 6),
                      child: Text(
                        l.noClientsYet,
                        style: t.bodySmall
                            .copyWith(color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                    ),
                  if (state._selectedRecipientClientEmail() != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 0, 12, 6),
                      child: Row(children: [
                        Icon(Icons.send_rounded,
                            size: 12, color: cs.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            state._selectedRecipientClientEmail()!,
                            style: t.bodySmall.copyWith(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ]),
                    ),
                ],
                // ── CC / BCC expanded fields ──────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state._showCc) ...[
                        Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.35)),
                        _InlineRecipientRow(
                          label: l.mailComposeCcLabel,
                          controller: state._ccCtrl,
                          values: state._ccList,
                          hint: l.mailComposeCcHint,
                          enabled: !state._sending,
                          inputDecoration: inputDecoration,
                          onChanged: (next) => state.update(() => state._ccList
                            ..clear()
                            ..addAll(next)),
                          onRemove: () =>
                              state.update(() => state._showCc = false),
                        ),
                      ],
                      if (state._showBcc) ...[
                        Divider(
                            height: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.35)),
                        _InlineRecipientRow(
                          label: l.mailComposeBccLabel,
                          controller: state._bccCtrl,
                          values: state._bccList,
                          hint: l.mailComposeBccHint,
                          enabled: !state._sending,
                          inputDecoration: inputDecoration,
                          onChanged: (next) => state.update(() => state._bccList
                            ..clear()
                            ..addAll(next)),
                          onRemove: () =>
                              state.update(() => state._showBcc = false),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── CC / BCC toggle footer ────────────────────────────────
                if (!state._showCc || !state._showBcc) ...[
                  Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        if (!state._showCc)
                          TextButton(
                            onPressed: state._sending
                                ? null
                                : () =>
                                    state.update(() => state._showCc = true),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: cs.onSurfaceVariant,
                              textStyle: t.bodySmall.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.w500),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            child: Text(l.mailComposeAddCc),
                          ),
                        if (!state._showBcc)
                          TextButton(
                            onPressed: state._sending
                                ? null
                                : () =>
                                    state.update(() => state._showBcc = true),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: cs.onSurfaceVariant,
                              textStyle: t.bodySmall.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.w500),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                            child: Text(l.mailComposeAddBcc),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Subject card ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject row — inline label + borderless field + template btn
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          l.mailComposeSubjectLabel,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: TextField(
                          controller: state._subjectCtrl,
                          enabled: !state._sending,
                          maxLines: 1,
                          style: t.bodySmall
                              .copyWith(color: cs.onSurface, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: l.mailComposeSubjectHint,
                            hintStyle: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => state.update(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Template picker button
                      if (state._composeTemplatesLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        IconButton(
                          onPressed:
                              state._sending ? null : state._showTemplatePicker,
                          tooltip: state._selectedComposeTemplateName != null
                              ? (state._isSpanishLocale
                                  ? 'Cambiar plantilla'
                                  : 'Change template')
                              : (state._isSpanishLocale
                                  ? 'Usar plantilla'
                                  : 'Use template'),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            state._selectedComposeTemplateName != null
                                ? Icons.description_rounded
                                : Icons.description_outlined,
                            size: 18,
                            color: state._selectedComposeTemplateName != null
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Active template chip — only when a template is applied
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topLeft,
                  child: state._selectedComposeTemplateName != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                              child: Row(
                                children: [
                                  // Chip
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: state._sending
                                          ? null
                                          : state._showTemplatePicker,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 13,
                                            color: cs.primary,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              state
                                                  ._selectedComposeTemplateName!,
                                              style: t.bodySmall.copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: cs.primary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: state._sending
                                                ? null
                                                : () => state.update(() {
                                                      state._selectedComposeTemplateId =
                                                          null;
                                                      state._selectedComposeTemplateName =
                                                          null;
                                                    }),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 13,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: state._sending
                                        ? null
                                        : state._showTemplatePicker,
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: cs.onSurfaceVariant,
                                      textStyle: t.bodySmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                    child: const Text('Cambiar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation:
                Listenable.merge([state._quillController, state._bodyFocus]),
            builder: (context, _) {
              final canUndo = state._quillController.hasUndo;
              final canRedo = state._quillController.hasRedo;
              final showTools = state._bodyFocus.hasFocus;

              Widget toolBtn({
                required IconData icon,
                required String tooltip,
                VoidCallback? onPressed,
                bool active = false,
              }) {
                return SizedBox(
                  width: 26,
                  height: 26,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 16,
                    onPressed: onPressed,
                    icon: Icon(icon),
                    color: active ? cs.primary : cs.onSurface,
                    tooltip: tooltip,
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  border: Border.all(
                    color: showTools
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.outlineVariant.withValues(alpha: 0.5),
                    width: showTools ? 1.3 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      l.mailComposeBodyLabel,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: showTools ? 1 : 0.45,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          toolBtn(
                            icon: Icons.undo_rounded,
                            tooltip: 'Undo',
                            onPressed: canUndo
                                ? () => state._quillController.undo()
                                : null,
                          ),
                          toolBtn(
                            icon: Icons.redo_rounded,
                            tooltip: 'Redo',
                            onPressed: canRedo
                                ? () => state._quillController.redo()
                                : null,
                          ),
                          Container(
                            width: 1,
                            height: 16,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            color: cs.outlineVariant.withValues(alpha: 0.6),
                          ),
                          toolBtn(
                            icon: Icons.format_bold_rounded,
                            tooltip: 'Bold',
                            onPressed: () {
                              final isBold = state._quillController
                                  .getSelectionStyle()
                                  .attributes
                                  .containsKey(quill.Attribute.bold.key);
                              state._quillController.formatSelection(
                                isBold
                                    ? quill.Attribute.clone(
                                        quill.Attribute.bold, null)
                                    : quill.Attribute.bold,
                              );
                            },
                          ),
                          toolBtn(
                            icon: Icons.format_italic_rounded,
                            tooltip: 'Italic',
                            onPressed: () {
                              final isItalic = state._quillController
                                  .getSelectionStyle()
                                  .attributes
                                  .containsKey(quill.Attribute.italic.key);
                              state._quillController.formatSelection(
                                isItalic
                                    ? quill.Attribute.clone(
                                        quill.Attribute.italic, null)
                                    : quill.Attribute.italic,
                              );
                            },
                          ),
                          toolBtn(
                            icon: Icons.link_rounded,
                            tooltip: 'Link',
                            onPressed: state._promptLink,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            l.mailComposeFormat,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: state._bodyFocus,
            builder: (context, _) {
              final focused = state._bodyFocus.hasFocus;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: inputDecoration.fillColor ?? cs.surface,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(8)),
                  border: Border(
                    left: BorderSide(
                      color: focused ? cs.primary : cs.outlineVariant,
                      width: focused ? 1.3 : 1,
                    ),
                    right: BorderSide(
                      color: focused ? cs.primary : cs.outlineVariant,
                      width: focused ? 1.3 : 1,
                    ),
                    bottom: BorderSide(
                      color: focused ? cs.primary : cs.outlineVariant,
                      width: focused ? 1.3 : 1,
                    ),
                  ),
                ),
                constraints: BoxConstraints(
                  minHeight: isWideEmbedded ? 300 : 180,
                ),
                child: DefaultTextStyle(
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontSize: 12,
                    height: 1.45,
                  ),
                  child: Builder(
                    builder: (context) {
                      state._quillController.readOnly = state._sending;
                      return quill.QuillEditor(
                        controller: state._quillController,
                        scrollController: state._bodyScroll,
                        focusNode: state._bodyFocus,
                        config: quill.QuillEditorConfig(
                          padding: EdgeInsets.zero,
                          autoFocus: false,
                          expands: false,
                          placeholder: l.mailComposeTextHint,
                          customStyles: quill.DefaultStyles(
                            placeHolder: quill.DefaultTextBlockStyle(
                              t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              const quill.HorizontalSpacing(0, 0),
                              quill.VerticalSpacing.zero,
                              quill.VerticalSpacing.zero,
                              null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: _CollapsedPanel(
              title: state._attachments.isEmpty
                  ? l.mailComposeAttachmentsLabel
                  : '${l.mailComposeAttachmentsLabel} (${state._attachments.length})',
              expanded: state._attachmentsExpanded,
              onToggle: () => state.update(
                () => state._attachmentsExpanded = !state._attachmentsExpanded,
              ),
              trailing: TextButton.icon(
                onPressed: state._sending || state._uploadingAttachment
                    ? null
                    : state._showAttachmentActions,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  textStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                icon: state._uploadingAttachment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file, size: 18),
                label: Text(l.mailComposeAddAttachment),
              ),
              child: state._attachments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l.mailComposeAttachmentsEmpty,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state._attachments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final attachment = entry.value;
                        final label =
                            attachment.filename ?? attachment.storageKey ?? '-';
                        return InputChip(
                          label: Text(label, style: t.bodySmall),
                          onDeleted: () => state
                              .update(() => state._attachments.removeAt(index)),
                        );
                      }).toList(),
                    ),
            ),
          ), // Container
          if (!isWideEmbedded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: _CollapsedPanel(
                title: l.mailComposeInvoiceOptions,
                expanded: state._invoiceExpanded,
                onToggle: () => state.update(
                    () => state._invoiceExpanded = !state._invoiceExpanded),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.mailComposeInvoiceOptionsHelper,
                      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: state._invoiceIdsCtrl,
                      enabled: !state._sending,
                      style: t.bodySmall.copyWith(color: cs.onSurface),
                      decoration: inputDecoration.copyWith(
                        labelText: l.mailComposeInvoiceIdsLabel,
                        hintText: l.mailComposeInvoiceIdsHint,
                        helperText: l.mailComposeInvoiceIdsHint,
                        prefixIcon: const Icon(Icons.receipt_long_outlined),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9,\\s-]')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: state._sending || state._openingInvoicePicker
                            ? null
                            : state._openInvoicePicker,
                        icon: state._openingInvoicePicker
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(l.searchPerson),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Visual feedback for selected invoices
                    Builder(
                      builder: (context) {
                        final invoiceIds = state
                            ._splitValues(state._normalizeInvoiceIds(
                                state._invoiceIdsCtrl.text))
                            .where((id) => id.trim().isNotEmpty)
                            .toList();

                        if (invoiceIds.isEmpty) return const SizedBox.shrink();

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    cs.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                        color: cs.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${l.invoicesListTitle} PDF (${invoiceIds.length})',
                                          style: t.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (state._attachInvoicePdf)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cs.primary
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: cs.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'PDF adjunto',
                                                style: t.bodySmall.copyWith(
                                                  color: cs.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: invoiceIds.map((id) {
                                      return Chip(
                                        label: Text(
                                          id,
                                          style: t.bodySmall,
                                        ),
                                        deleteIcon: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: cs.onSurfaceVariant,
                                        ),
                                        onDeleted: () => state.update(() {
                                          final remaining = invoiceIds
                                              .where(
                                                  (existing) => existing != id)
                                              .toList();
                                          state._invoiceIdsCtrl.text =
                                              remaining.join(',');
                                        }),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                    if (state._selectedPresupuestoIds.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_outlined,
                                  size: 18,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${l.budgetsMenuSection} PDF (${state._selectedPresupuestoIds.length})',
                                    style: t.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                if (state._attachInvoicePdf)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: cs.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PDF adjunto',
                                          style: t.bodySmall.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: state._selectedPresupuestoIds.map((id) {
                                return Chip(
                                  label: Text(
                                    id,
                                    style: t.bodySmall,
                                  ),
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  onDeleted: () => state.update(() {
                                    state._selectedPresupuestoIds.remove(id);
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Visual feedback for selected receipts
                    if (state._selectedReceiptIds.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.tertiaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.receipt_outlined,
                                  size: 18,
                                  color: cs.tertiary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Recibos PDF (${state._selectedReceiptIds.length})',
                                    style: t.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                if (state._attachInvoicePdf)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          cs.tertiary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: cs.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PDF adjunto',
                                          style: t.bodySmall.copyWith(
                                            color: cs.tertiary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: state._selectedReceiptIds.map((id) {
                                return Chip(
                                  label: Text(
                                    id,
                                    style: t.bodySmall,
                                  ),
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  onDeleted: () => state.update(() {
                                    state._selectedReceiptIds.remove(id);
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SwitchListTile.adaptive(
                      value: state._attachInvoicePdf,
                      title: Text(
                        l.mailComposeAttachInvoicePdf,
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      secondary: const Icon(Icons.picture_as_pdf_outlined),
                      onChanged: state._sending
                          ? null
                          : (value) => state
                              .update(() => state._attachInvoicePdf = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile.adaptive(
                      value: state._includeInvoiceLinks,
                      title: Text(
                        l.mailComposeIncludeInvoiceLinks,
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      secondary: const Icon(Icons.link_outlined),
                      onChanged: state._sending
                          ? null
                          : (value) => state
                              .update(() => state._includeInvoiceLinks = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile.adaptive(
                      value: state._applyDefaultFooter,
                      title: Text(
                        l.mailComposeApplyFooterLabel,
                        style:
                            t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l.mailComposeApplyFooterHelper,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                      secondary: const Icon(Icons.notes_outlined),
                      onChanged: state._sending
                          ? null
                          : (value) => state
                              .update(() => state._applyDefaultFooter = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ), // Container
          ],
        ],
      ),
    );

    if (state.widget.embedded) {
      if (isWideEmbedded) {
        return FolderSectionCard(
          label: l.mailComposeTitle,
          leftTabOffset: 0,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: content,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: _InlineInvoiceFlowPanel(state: state),
                    ),
                  ],
                ),
              ),
              _ComposeBottomBar(
                sending: state._sending,
                enabled: canSend,
                onSend: state._send,
                label:
                    state._sending ? l.mailComposeSending : l.mailComposeSend,
              ),
            ],
          ),
        );
      }
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
                    label: state._sending
                        ? l.mailComposeSending
                        : l.mailComposeSend,
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
        label: state._sending ? l.mailComposeSending : l.mailComposeSend,
      ),
    );
  }
}

// ── Template picker dialog ────────────────────────────────────────────────────

class _ComposeTemplatePicker extends StatelessWidget {
  const _ComposeTemplatePicker({
    required this.templates,
    required this.selectedId,
    required this.onSelect,
    this.onClear,
  });

  final List<Map<String, dynamic>> templates;
  final String? selectedId;
  final void Function(Map<String, dynamic>) onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccionar plantilla',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onClear != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.remove_circle_outline, size: 14),
                    label: const Text('Quitar'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                      textStyle: t.bodySmall.copyWith(fontSize: 12),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // ── Template list ────────────────────────────────────────────────
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final tpl = templates[index];
                final id = (tpl['id'] ?? tpl['_id'])?.toString().trim() ?? '';
                final name = (tpl['name'] ?? '').toString().trim();
                final subject = (tpl['subject'] ?? '').toString().trim();
                final preview = (tpl['text'] ?? '').toString().trim();
                final isSelected = id == selectedId;
                final isDefault = tpl['isDefault'] == true;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(tpl),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer.withValues(alpha: 0.45)
                          : cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.6)
                            : cs.outlineVariant.withValues(alpha: 0.45),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.description_outlined,
                            size: 18,
                            color:
                                isSelected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name.isEmpty ? 'Template' : name,
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isDefault)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            cs.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: t.bodySmall.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (subject.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subject,
                                  style: t.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (preview.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  preview,
                                  style: t.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recipient mode toggle (Email / Cliente) ───────────────────────────────────

class _RecipientModeToggle extends StatelessWidget {
  const _RecipientModeToggle({
    required this.clientMode,
    required this.enabled,
    required this.emailLabel,
    required this.clientLabel,
    required this.recentLabel,
    required this.recentLoading,
    required this.onChanged,
    required this.onRecentTap,
  });

  final bool clientMode;
  final bool enabled;
  final String emailLabel;
  final String clientLabel;
  final String recentLabel;
  final bool recentLoading;
  final void Function(bool) onChanged;
  final VoidCallback onRecentTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget tab({
      required bool value,
      required IconData icon,
      required String label,
    }) {
      final selected = clientMode == value;
      return GestureDetector(
        onTap: enabled && !selected ? () => onChanged(value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget recentTab() {
      return GestureDetector(
        onTap: enabled && !recentLoading ? onRecentTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recentLoading)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              else
                Icon(Icons.history_rounded, size: 13, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                recentLabel,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: recentLoading ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(value: false, icon: Icons.edit_outlined, label: emailLabel),
          tab(value: true, icon: Icons.person_outline, label: clientLabel),
          recentTab(),
        ],
      ),
    );
  }
}

class _RecentIssuedInvoicesDialog extends StatelessWidget {
  const _RecentIssuedInvoicesDialog({
    required this.invoices,
    required this.clients,
    required this.isSpanish,
    required this.formatDate,
    required this.formatTotal,
  });

  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final bool isSpanish;
  final String Function(DateTime value) formatDate;
  final String Function(Invoice invoice) formatTotal;

  GroupClient? _clientFor(Invoice invoice) {
    final clientId = invoice.clientId.trim();
    if (clientId.isEmpty) return null;
    return clients.cast<GroupClient?>().firstWhere(
          (client) => client?.id == clientId,
          orElse: () => null,
        );
  }

  DateTime _invoiceDate(Invoice invoice) {
    return (invoice.issueDate ??
            invoice.issuedAtResolved ??
            invoice.registeredAt ??
            DateTime.fromMillisecondsSinceEpoch(0))
        .toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = isSpanish ? 'Facturas emitidas hoy' : 'Today issued invoices';
    final empty = isSpanish
        ? 'No hay facturas emitidas hoy.'
        : 'No invoices issued today.';

    return AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: SizedBox(
        width: 520,
        child: invoices.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  empty,
                  style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final client = _clientFor(invoice);
                    final clientName = (client?.name.trim().isNotEmpty == true
                            ? client!.name
                            : invoice.clientName ?? '')
                        .trim();
                    final number = invoice.invoiceNumber.trim().isEmpty
                        ? invoice.id
                        : invoice.invoiceNumber.trim();
                    final email =
                        (client?.billing?.email ?? client?.email ?? '').trim();
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(invoice),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    cs.primaryContainer.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: cs.primary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#$number · ${clientName.isEmpty ? '-' : clientName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      formatDate(_invoiceDate(invoice)),
                                      if (email.isNotEmpty) email,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatTotal(invoice),
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isSpanish ? 'Cerrar' : 'Close'),
        ),
      ],
    );
  }
}

// ── Searchable client picker ──────────────────────────────────────────────────

class _ClientSearchField extends StatelessWidget {
  const _ClientSearchField({
    required this.clients,
    required this.selectedClientId,
    required this.loading,
    required this.enabled,
    required this.onChanged,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;
  final bool loading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  GroupClient? get _selected => selectedClientId == null
      ? null
      : clients.cast<GroupClient?>().firstWhere(
            (c) => c?.id == selectedClientId,
            orElse: () => null,
          );

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ClientPickerDialog(
        clients: clients,
        selectedClientId: selectedClientId,
      ),
    );
    // result == '' means "clear selection"
    if (result != null) onChanged(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final selected = _selected;
    final hasSelection = selected != null;
    final email = (selected?.billing?.email ?? selected?.email ?? '').trim();

    if (loading) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(width: 8),
          Text(
            l.expenseBatchStatLoading,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? () => _openPicker(context) : null,
      child: Container(
        padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5, right: 6),
        decoration: BoxDecoration(
          color: hasSelection
              ? cs.primaryContainer.withValues(alpha: 0.55)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: hasSelection
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 13,
              color: hasSelection ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasSelection
                    ? (email.isNotEmpty
                        ? '${selected.name} · $email'
                        : selected.name)
                    : l.selectClientFirst,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: hasSelection
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (hasSelection)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? () => onChanged(null) : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Client picker dialog ──────────────────────────────────────────────────────

class _ClientPickerDialog extends StatefulWidget {
  const _ClientPickerDialog({
    required this.clients,
    required this.selectedClientId,
  });

  final List<GroupClient> clients;
  final String? selectedClientId;

  @override
  State<_ClientPickerDialog> createState() => _ClientPickerDialogState();
}

class _ClientPickerDialogState extends State<_ClientPickerDialog> {
  final TextEditingController _search = TextEditingController();
  late List<GroupClient> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.clients;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final lower = q.trim().toLowerCase();
    setState(() {
      _filtered = lower.isEmpty
          ? widget.clients
          : widget.clients.where((c) {
              final name = c.name.toLowerCase();
              final email = (c.email ?? '').toLowerCase();
              return name.contains(lower) || email.contains(lower);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 10),
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 17, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.recurringInvoicesClientFilterLabel,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: l.clientSearchHint,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.4),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            _onSearch('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                style: t.bodySmall.copyWith(fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),

            // Client list
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 32,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.noClientsYet,
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final client = _filtered[i];
                        final isSel = client.id == widget.selectedClientId;
                        final email = (client.email ?? '').trim();
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: isSel
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            child: isSel
                                ? Icon(Icons.check_rounded,
                                    size: 14, color: cs.primary)
                                : Text(
                                    client.name.isNotEmpty
                                        ? client.name[0].toUpperCase()
                                        : '?',
                                    style: t.bodySmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                          title: Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w600,
                              color: isSel ? cs.primary : cs.onSurface,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: email.isNotEmpty
                              ? Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () => Navigator.pop(context, client.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Inline CC / BCC row ───────────────────────────────────────────────────────

class _InlineRecipientRow extends StatelessWidget {
  const _InlineRecipientRow({
    required this.label,
    required this.controller,
    required this.values,
    required this.hint,
    required this.enabled,
    required this.inputDecoration,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final TextEditingController controller;
  final List<String> values;
  final String hint;
  final bool enabled;
  final InputDecoration inputDecoration;
  final void Function(List<String>) onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _EmailChipsInput(
              controller: controller,
              values: values,
              hint: hint,
              enabled: enabled,
              decoration: inputDecoration.copyWith(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
          if (values.isEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: enabled ? onRemove : null,
              visualDensity: VisualDensity.compact,
              color: cs.onSurfaceVariant,
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}
