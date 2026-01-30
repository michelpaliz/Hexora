part of '../mail_compose_screen.dart';

class _MailComposeView extends StatelessWidget {
  const _MailComposeView({required this.state});

  final _MailComposeScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final canSend = state._toList.isNotEmpty &&
        state._quillController.document.toPlainText().trim().isNotEmpty &&
        state._subjectCtrl.text.trim().isNotEmpty;

    final inputDecoration = InputDecoration(
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.widget.embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.mailComposeTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (state.widget.onClose != null)
                  IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: state.widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
          ],
          Text(
            l.mailComposeToLabel,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          _EmailChipsInput(
            controller: state._toCtrl,
            values: state._toList,
            hint: l.mailComposeToHint,
            enabled: !state._sending,
            decoration: inputDecoration,
            onChanged: (next) => state.setState(() => state._toList
              ..clear()
              ..addAll(next)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (!state._showCc)
                TextButton(
                  onPressed: () => state.setState(() => state._showCc = true),
                  child: Text(l.mailComposeAddCc),
                ),
              if (!state._showBcc)
                TextButton(
                  onPressed: () => state.setState(() => state._showBcc = true),
                  child: Text(l.mailComposeAddBcc),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                if (state._showCc || state._showBcc) ...[
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final showBoth = state._showCc && state._showBcc;
                      final useRow = showBoth && constraints.maxWidth >= 720;

                      Widget ccField() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.mailComposeCcLabel,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _EmailChipsInput(
                              controller: state._ccCtrl,
                              values: state._ccList,
                              hint: l.mailComposeCcHint,
                              enabled: !state._sending,
                              decoration: inputDecoration,
                              onChanged: (next) => state.setState(() => state._ccList
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
                              ),
                            ),
                            const SizedBox(height: 6),
                            _EmailChipsInput(
                              controller: state._bccCtrl,
                              values: state._bccList,
                              hint: l.mailComposeBccHint,
                              enabled: !state._sending,
                              decoration: inputDecoration,
                              onChanged: (next) => state.setState(() => state._bccList
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
                            if (state._showCc) Expanded(child: ccField()),
                            if (state._showCc && state._showBcc)
                              const SizedBox(width: 12),
                            if (state._showBcc) Expanded(child: bccField()),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state._showCc) ccField(),
                          if (state._showCc && state._showBcc)
                            const SizedBox(height: 12),
                          if (state._showBcc) bccField(),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: state._subjectCtrl,
            enabled: !state._sending,
            maxLines: 1,
            decoration: inputDecoration.copyWith(
              labelText: l.mailComposeSubjectLabel,
              hintText: l.mailComposeSubjectHint,
            ),
            onChanged: (_) => state.setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.mailComposeBodyLabel,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => state._quillController
                    .formatSelection(quill.Attribute.bold),
                icon: const Icon(Icons.format_bold_rounded),
                color: cs.onSurface,
                tooltip: 'Bold',
              ),
              IconButton(
                onPressed: () => state._quillController
                    .formatSelection(quill.Attribute.italic),
                icon: const Icon(Icons.format_italic_rounded),
                color: cs.onSurface,
                tooltip: 'Italic',
              ),
              IconButton(
                onPressed: state._promptLink,
                icon: const Icon(Icons.link_rounded),
                color: cs.onSurface,
                tooltip: 'Link',
              ),
              const SizedBox(width: 6),
              Text(
                l.mailComposeFormat,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: inputDecoration.fillColor ?? cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: DefaultTextStyle(
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  height: 1.55,
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
                        expands: true,
                        placeholder: l.mailComposeTextHint,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CollapsedPanel(
            title: l.mailComposeAttachmentsLabel,
            expanded: state._attachmentsExpanded,
            onToggle: () => state.setState(
              () => state._attachmentsExpanded = !state._attachmentsExpanded,
            ),
            trailing: TextButton.icon(
              onPressed: state._sending || state._uploadingAttachment
                  ? null
                  : state._showAttachmentActions,
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
                        onDeleted: () =>
                            state.setState(() => state._attachments.removeAt(index)),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 8),
          _CollapsedPanel(
            title: l.mailComposeInvoiceOptions,
            expanded: state._invoiceExpanded,
            onToggle: () =>
                state.setState(() => state._invoiceExpanded = !state._invoiceExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: state._invoiceIdsCtrl,
                  enabled: !state._sending,
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
                SwitchListTile.adaptive(
                  value: state._attachInvoicePdf,
                  title: Text(l.mailComposeAttachInvoicePdf),
                  secondary: const Icon(Icons.picture_as_pdf_outlined),
                  onChanged: state._sending
                      ? null
                      : (value) => state.setState(() => state._attachInvoicePdf = value),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: state._includeInvoiceLinks,
                  title: Text(l.mailComposeIncludeInvoiceLinks),
                  secondary: const Icon(Icons.link_outlined),
                  onChanged: state._sending
                      ? null
                      : (value) => state.setState(() => state._includeInvoiceLinks = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (state.widget.embedded) {
      return Column(
        children: [
          Expanded(child: content),
          _ComposeBottomBar(
            sending: state._sending,
            enabled: canSend,
            onSend: state._send,
            label: state._sending ? l.mailComposeSending : l.mailComposeSend,
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mailComposeTitle),
      ),
      body: content,
      bottomNavigationBar: _ComposeBottomBar(
        sending: state._sending,
        enabled: canSend,
        onSend: state._send,
        label: state._sending ? l.mailComposeSending : l.mailComposeSend,
      ),
    );
  }
}
