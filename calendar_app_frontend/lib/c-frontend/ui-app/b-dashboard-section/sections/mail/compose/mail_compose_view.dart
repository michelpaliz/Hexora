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
      fillColor: cs.surface,
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
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.widget.embedded) ...[
            const SizedBox(height: 6),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
          ],
          // Recipients Section Card
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header + mode toggle ─────────────────────────────
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      l.mailComposeToLabel,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    SegmentedButton<bool>(
                      selected: {state._useClientMode},
                      onSelectionChanged: state._sending
                          ? null
                          : (v) => state.update(
                                () => state._useClientMode = v.first,
                              ),
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: Text(
                            'Email',
                            style: t.bodySmall.copyWith(fontSize: 11),
                          ),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: const Icon(Icons.person_outline, size: 14),
                          label: Text(
                            'Cliente',
                            style: t.bodySmall.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 6),
                        ),
                      ),
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Direct email mode ────────────────────────────────
                if (!state._useClientMode) ...[
                  _EmailChipsInput(
                    controller: state._toCtrl,
                    values: state._toList,
                    hint: l.mailComposeToHint,
                    enabled: !state._sending,
                    decoration: inputDecoration,
                    onChanged: (next) => state.update(() => state._toList
                      ..clear()
                      ..addAll(next)),
                  ),
                  if (state._toList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l.mailComposeToHelper,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                // ── Client picker mode ───────────────────────────────
                if (state._useClientMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: recipientClients
                                  .any((c) => c.id == state._recipientClientId)
                              ? state._recipientClientId
                              : null,
                          isExpanded: true,
                          selectedItemBuilder: (context) => recipientClients
                              .map(
                                (client) => Text(
                                  (client.email ?? '').trim().isNotEmpty
                                      ? '${client.name} · ${(client.email ?? '').trim()}'
                                      : client.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          decoration: inputDecoration.copyWith(
                            hintText: state._loadingRecipientClients
                                ? 'Cargando...'
                                : l.selectClientFirst,
                            prefixIcon: state._loadingRecipientClients
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: cs.onSurfaceVariant,
                                  ),
                          ),
                          items: recipientClients
                              .map(
                                (client) => DropdownMenuItem<String>(
                                  value: client.id,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        client.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall.copyWith(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if ((client.email ?? '').trim().isNotEmpty)
                                        Text(
                                          (client.email ?? '').trim(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged:
                              state._sending || state._loadingRecipientClients
                                  ? null
                                  : (value) => state.update(
                                        () => state._recipientClientId = value,
                                      ),
                        ),
                      ),
                    ],
                  ),
                  if ((state._recipientClientError ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 14, color: cs.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              state._recipientClientError!,
                              style: t.bodySmall.copyWith(
                                color: cs.error,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!state._loadingRecipientClients && recipientClients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l.noClientsYet,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Resolved email preview
                  if (state._selectedRecipientClientEmail() != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14,
                              color: cs.primary.withValues(alpha: 0.8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Se enviará a: ${state._selectedRecipientClientEmail()}',
                              style: t.bodySmall.copyWith(
                                color: cs.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                // ── CC / BCC toggle + fields (inside card) ──────────────
                if (!state._showCc || !state._showBcc) ...[
                  const SizedBox(height: 6),
                  Divider(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                    height: 1,
                  ),
                  Row(
                    children: [
                      if (!state._showCc)
                        TextButton.icon(
                          onPressed: state._sending
                              ? null
                              : () => state.update(() => state._showCc = true),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(l.mailComposeAddCc),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: cs.onSurfaceVariant,
                            textStyle: t.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      if (!state._showCc && !state._showBcc)
                        const SizedBox(width: 4),
                      if (!state._showBcc)
                        TextButton.icon(
                          onPressed: state._sending
                              ? null
                              : () =>
                                  state.update(() => state._showBcc = true),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(l.mailComposeAddBcc),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: cs.onSurfaceVariant,
                            textStyle: t.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state._showCc || state._showBcc) ...[
                        const SizedBox(height: 6),
                        Divider(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                          height: 1,
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final showBoth = state._showCc && state._showBcc;
                            final useRow =
                                showBoth && constraints.maxWidth >= 720;

                            Widget ccField() {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.mailComposeCcLabel,
                                    style: t.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _EmailChipsInput(
                                    controller: state._ccCtrl,
                                    values: state._ccList,
                                    hint: l.mailComposeCcHint,
                                    enabled: !state._sending,
                                    decoration: inputDecoration,
                                    onChanged: (next) =>
                                        state.update(() => state._ccList
                                          ..clear()
                                          ..addAll(next)),
                                  ),
                                ],
                              );
                            }

                            Widget bccField() {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.mailComposeBccLabel,
                                    style: t.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _EmailChipsInput(
                                    controller: state._bccCtrl,
                                    values: state._bccList,
                                    hint: l.mailComposeBccHint,
                                    enabled: !state._sending,
                                    decoration: inputDecoration,
                                    onChanged: (next) =>
                                        state.update(() => state._bccList
                                          ..clear()
                                          ..addAll(next)),
                                  ),
                                ],
                              );
                            }

                            if (useRow) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state._showCc)
                                    Expanded(child: ccField()),
                                  if (state._showCc && state._showBcc)
                                    const SizedBox(width: 12),
                                  if (state._showBcc)
                                    Expanded(child: bccField()),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state._showCc) ccField(),
                                if (state._showCc && state._showBcc)
                                  const SizedBox(height: 10),
                                if (state._showBcc) bccField(),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: state._subjectCtrl,
            enabled: !state._sending,
            maxLines: 1,
            style: t.bodySmall.copyWith(color: cs.onSurface, fontSize: 12),
            decoration: inputDecoration.copyWith(
              labelText: l.mailComposeSubjectLabel,
              hintText: l.mailComposeSubjectHint,
              helperText: l.mailComposeSubjectHelper,
            ),
            onChanged: (_) => state.update(() {}),
          ),
          const SizedBox(height: 6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
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
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            color:
                                cs.outlineVariant.withValues(alpha: 0.6),
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
                                  .containsKey(
                                      quill.Attribute.italic.key);
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
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8)),
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
                constraints: const BoxConstraints(minHeight: 140),
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
          if (state._quillController.document.toPlainText().trim().isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l.mailComposeBodyHelper,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 8),
          _CollapsedPanel(
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
          if (!isWideEmbedded) ...[
            const SizedBox(height: 8),
            _CollapsedPanel(
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
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,\\s-]')),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                          ._splitValues(
                              state._normalizeInvoiceIds(state._invoiceIdsCtrl.text))
                          .where((id) => id.trim().isNotEmpty)
                          .toList();

                      if (invoiceIds.isEmpty) return const SizedBox.shrink();

                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.3),
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
                                            .where((existing) => existing != id)
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
                                    color: cs.tertiary.withValues(alpha: 0.15),
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
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    secondary: const Icon(Icons.picture_as_pdf_outlined),
                    onChanged: state._sending
                        ? null
                        : (value) =>
                            state.update(() => state._attachInvoicePdf = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: state._includeInvoiceLinks,
                    title: Text(
                      l.mailComposeIncludeInvoiceLinks,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
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
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
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

