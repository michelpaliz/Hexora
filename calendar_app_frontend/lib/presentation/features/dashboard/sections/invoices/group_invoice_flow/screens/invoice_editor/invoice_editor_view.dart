part of 'invoice_editor_screen.dart';

class _InvoiceEditorView extends StatelessWidget {
  const _InvoiceEditorView({required this.state});

  final _InvoiceEditorScreenState state;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: state._c,
      builder: (context, _) {
        final l = AppLocalizations.of(context)!;
        final hasClient = state._c.clientId != null;
        final hasLines = state._c.hasBillableEntries;
        final invoiceDate = state._c.invoiceDate.value;
        final dueDate = state._c.dueDate.value;
        final datesComplete = invoiceDate != null;
        final invalidDates = invoiceDate != null &&
            dueDate != null &&
            dueDate.isBefore(invoiceDate);
        final hasSavedDraft = state._c.savedInvoice != null;
        final step1Complete =
            hasClient && datesComplete && hasLines && !invalidDates;
        final canSaveDraft = !state._c.saving;
        final canPreview = step1Complete && hasSavedDraft;
        final canCompleteDraft = !state._c.saving &&
            step1Complete &&
            (state._c.editingIssued || state._c.previewedPdf);
        final reinforceDraft = canCompleteDraft && state._c.previewedPdf;

        final step1Missing = <String>[
          if (!hasClient) l.invoicePreviewNeedsClient,
          if (!datesComplete) l.invoicePreviewNeedsDate,
          if (invalidDates) l.invoicePreviewInvalidDates,
          if (!hasLines) l.invoicePreviewNeedsLines,
        ];
        final previewReason = !canPreview
            ? (step1Missing.isNotEmpty
                ? step1Missing.first
                : (hasSavedDraft ? '' : l.invoicePreviewNeedsDraft))
            : null;
        final draftCompletionReason = !canCompleteDraft
            ? (!state._c.previewedPdf
                ? l.invoiceReviewPdfBeforeDraft
                : (step1Missing.isNotEmpty ? step1Missing.first : ''))
            : null;

        // ignore: unused_element
        void showStep1Missing() {
          if (step1Missing.isEmpty) return;
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l.invoiceStepCreateTitle),
              content: Text(step1Missing.map((e) => '• $e').join('\n')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            ),
          );
        }

        final content = Scaffold(
          backgroundColor: cs.surface,
          appBar: kIsWeb
              ? null
              : InvoiceEditorAppBar(
                  titleStyle: t.titleLarge,
                  saving: state._c.saving,
                  onSaveDraft: () => state._c.handleSaveDraft(context),
                  showClose: state.widget.embedded,
                  onClose: state.widget.embedded ? state._requestClose : null,
                ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              const headerLeft = SizedBox.shrink();

              final saved = state._c.savedInvoice;
              final savedStatus = (saved?.status ?? '').toLowerCase();
              final isSavedDraft = saved != null &&
                  (savedStatus.isEmpty || savedStatus.contains('draft'));
              final draft = isSavedDraft ? saved : null;
              final editingDraftId = state._c.editingDraftId;
              final pendingDrafts = state._c.pendingDrafts
                  .where((inv) =>
                      (inv.status ?? '').toLowerCase().contains('draft') ||
                      (inv.status ?? '').trim().isEmpty)
                  .where((inv) => draft == null || inv.id != draft.id)
                  .where((inv) =>
                      editingDraftId == null || inv.id != editingDraftId)
                  .toList();
              final draftBannerInline = draft == null
                  ? null
                  : _DraftBanner(
                      draft: draft,
                      previewing: state._c.previewedPdf,
                      deleting: state._c.deletingDraft,
                      onPreview: () => state._c.previewPdf(context),
                      onDelete: () => state._c.deleteDraft(context),
                      showActions: false,
                      compact: true,
                    );

              final selectedClientName = state._c.clientId == null
                  ? l.invoiceSelectClientLabel
                  : state.widget.clients
                      .firstWhere(
                        (c) => c.id == state._c.clientId,
                        orElse: () => GroupClient(
                          id: state._c.clientId!,
                          name: l.invoiceSelectClientLabel,
                          isActive: true,
                        ),
                      )
                      .name;

              final currency = state._c.currency.text.trim().isEmpty
                  ? 'EUR'
                  : state._c.currency.text.trim();
              final euroFmt = NumberFormat.currency(
                locale: l.localeName,
                symbol: 'EUR ',
              );
              final rawSubtotal = state._c.rawSubtotal;
              final discountAmount = state._c.effectiveDiscountAmount;
              final baseAfterDiscount = state._c.subtotalAfterDiscount;
              final taxAfterDiscount = state._c.taxAfterDiscount;
              final showDiscountRows = discountAmount > 0;

              final headerBar = _InvoiceEditorHeaderSection(
                state: state,
                l: l,
                t: t,
                cs: cs,
                headerLeft: headerLeft,
                stepsHeader: const SizedBox.shrink(),
                stepChipsRow: const SizedBox.shrink(),
                draftBanner: null,
                pendingDrafts: pendingDrafts,
                hasBlockingDrafts: false,
                selectedClientName: selectedClientName,
                currency: currency,
                invoiceDate: invoiceDate,
                dueDate: dueDate,
                canSaveDraft: canSaveDraft,
                canPreview: canPreview,
                canIssue: canCompleteDraft,
                reinforceIssue: reinforceDraft,
                previewReason: previewReason,
                issueReason: draftCompletionReason,
              );

              final linesSection = InvoiceContentSection(
                useBlocks: state._c.useBlocks,
                onModeChanged: state._c.setUseBlocks,
                blocks: state._c.blocks,
                lines: state._c.lines,
                onChanged: state._c.notifyUi,
                total: state._c.total,
                controller: state._c,
                ocrState: state._c.ocrState,
                onPickImageForLineExtraction: () =>
                    state._c.extractLinesFromImage(context),
                onApplyExtractedLines: state._c.applyExtractedLinesToDraft,
                onClearExtractedLines: state._c.clearExtractedLines,
              );

              final gatedLinesSection = state._c.financialFieldsReadOnly
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cs.tertiary.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'es'
                                ? 'Esta es una factura de liquidacion final. Los importes, descuentos y conceptos no se pueden editar directamente; la fecha, el cliente y las notas siguen disponibles.'
                                : 'This is a final-settlement invoice. Amounts, discounts and concepts cannot be edited directly; date, client and notes remain available.',
                            style: t.bodySmall.copyWith(
                              color: cs.onTertiaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: AbsorbPointer(
                            child: Opacity(opacity: 0.72, child: linesSection),
                          ),
                        ),
                      ],
                    )
                  : linesSection;

              List<Map<String, Object>> buildSummaryRows() {
                final rows = <Map<String, Object>>[];
                if (state._c.useBlocks) {
                  for (final block in state._c.blocks) {
                    if (!block.isBillableLine) continue;
                    final desc = block.isSection || block.isChecklist
                        ? block.title.text.trim()
                        : block.description.text.trim();
                    if (desc.isEmpty) continue;
                    final qty = block.qty ?? 0;
                    final price = block.unitPrice ?? 0;
                    final tax = block.taxRate ?? 0;
                    final total = qty * price * (1 + (tax / 100));
                    rows.add({
                      'desc': desc,
                      'qty': qty,
                      'price': price,
                      'tax': tax,
                      'total': total,
                    });
                  }
                } else {
                  for (final line in state._c.lines) {
                    final desc = line.description.text.trim();
                    if (desc.isEmpty) continue;
                    final qty = line.quantity ?? 0;
                    final price = line.unitPrice ?? 0;
                    final tax = line.taxRate ?? 0;
                    final total = qty * price * (1 + (tax / 100));
                    rows.add({
                      'desc': desc,
                      'qty': qty,
                      'price': price,
                      'tax': tax,
                      'total': total,
                    });
                  }
                }
                return rows;
              }

              final summaryRows = buildSummaryRows();

              // ignore: unused_element
              Widget discountEditorCard() {
                final readOnly = state._c.discountReadOnly;
                final usePercent = state._c.useDiscountPercent;

                Widget modeBtn({
                  required String label,
                  required bool selected,
                  required VoidCallback onTap,
                  bool isFirst = false,
                  bool isLast = false,
                }) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: selected
                              ? cs.primaryContainer.withValues(alpha: 0.55)
                              : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            left: isFirst
                                ? const Radius.circular(7)
                                : Radius.zero,
                            right:
                                isLast ? const Radius.circular(7) : Radius.zero,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              Icon(Icons.check_rounded,
                                  size: 11, color: cs.primary),
                              const SizedBox(width: 3),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                String? validateActive(String? raw) {
                  final text = (raw ?? '').trim();
                  if (text.isEmpty) return null;
                  final parsed = num.tryParse(text.replaceAll(',', '.'));
                  if (parsed == null) {
                    return usePercent
                        ? 'Porcentaje inválido'
                        : 'Importe inválido';
                  }
                  if (parsed < 0) return 'Debe ser ≥ 0';
                  if (usePercent && parsed > 100) return '0 – 100';
                  return null;
                }

                return Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 20, 12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Descuento',
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          if (!readOnly)
                            Container(
                              height: 28,
                              width: 136,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  modeBtn(
                                    label: 'Importe €',
                                    selected: !usePercent,
                                    isFirst: true,
                                    onTap: () =>
                                        state._c.setDiscountModePercent(false),
                                  ),
                                  Container(
                                      width: 1,
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.35)),
                                  modeBtn(
                                    label: 'Porcentaje %',
                                    selected: usePercent,
                                    isLast: true,
                                    onTap: () =>
                                        state._c.setDiscountModePercent(true),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 152,
                        child: TextFormField(
                          controller: usePercent
                              ? state._c.discountPercentCtrl
                              : state._c.discountAmountCtrl,
                          enabled: !readOnly,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: validateActive,
                          decoration: InputDecoration(
                            labelText:
                                usePercent ? 'Porcentaje (%)' : 'Importe (€)',
                            hintText: '0.00',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                          ),
                          onChanged: usePercent
                              ? state._c.setDiscountPercentText
                              : state._c.setDiscountAmountText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Se aplica antes de IVA.',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }

              Widget totalsSummary() {
                if (summaryRows.isEmpty) {
                  return Text(
                    l.invoicePreviewNeedsLines,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  );
                }
                final currencyFmt = NumberFormat.currency(
                  locale: l.localeName,
                  symbol: 'EUR ',
                );
                Widget totalsBreakdownRow(String label, String value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              l.descriptionLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l.lineQuantity,
                              textAlign: TextAlign.right,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l.lineUnitPrice,
                              textAlign: TextAlign.right,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l.lineTaxRate,
                              textAlign: TextAlign.right,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l.invoiceTotalLabel,
                              textAlign: TextAlign.right,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: cs.outlineVariant),
                      const SizedBox(height: 8),
                      ...summaryRows.map((row) {
                        final rawDesc = (row['desc'] ?? '').toString();
                        final descParts = rawDesc
                            .split('\n')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        final descTitle =
                            descParts.isEmpty ? rawDesc : descParts.first;
                        final descList = descParts.length > 1
                            ? descParts.sublist(1)
                            : const <String>[];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      descTitle,
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (descList.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      ...descList.map(
                                        (line) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            line,
                                            style: t.bodySmall.copyWith(
                                              color: cs.onSurfaceVariant
                                                  .withValues(
                                                alpha: 0.85,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  (row['qty'] ?? 0).toString(),
                                  textAlign: TextAlign.right,
                                  style: t.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFmt.format(row['price'] ?? 0).trim(),
                                  textAlign: TextAlign.right,
                                  style: t.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  (row['tax'] ?? 0).toString(),
                                  textAlign: TextAlign.right,
                                  style: t.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFmt.format(row['total'] ?? 0).trim(),
                                  textAlign: TextAlign.right,
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      Divider(height: 1, color: cs.outlineVariant),
                      const SizedBox(height: 10),
                      totalsBreakdownRow(
                        'Total parcial',
                        currencyFmt.format(rawSubtotal).trim(),
                      ),
                      if (showDiscountRows)
                        totalsBreakdownRow(
                          'Descuento',
                          '-${currencyFmt.format(discountAmount).trim()}',
                        ),
                      if (showDiscountRows)
                        totalsBreakdownRow(
                          'Base imponible',
                          currencyFmt.format(baseAfterDiscount).trim(),
                        ),
                      totalsBreakdownRow(
                        'IVA',
                        currencyFmt.format(taxAfterDiscount).trim(),
                      ),
                      totalsBreakdownRow(
                        l.invoiceTotalLabel,
                        currencyFmt.format(state._c.total).trim(),
                      ),
                    ],
                  ),
                );
              }

              final previewBytes = state._c.previewPdfBytes;
              final isPreviewStepActive = state._tabController.index == 3;
              // Refresh button shown only when PDF is loaded (spinner lives in Expanded)
              final previewToolbar = Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canPreview &&
                      previewBytes != null &&
                      !state._c.previewing)
                    IconButton(
                      tooltip: l.refreshAction,
                      onPressed: () => state._c.previewPdf(context),
                      icon: const Icon(Icons.refresh),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              );

              Widget summaryRow(String label, String value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final issuePanel = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.invoiceSummaryTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        summaryRow(
                          l.invoiceCustomerTitle,
                          selectedClientName,
                        ),
                        summaryRow(
                          l.invoiceNumberLabel,
                          state._c.previewInvoiceNumber,
                        ),
                        summaryRow(
                          l.invoiceDateLabel,
                          invoiceDate == null
                              ? '-'
                              : DateFormat.yMMMd(l.localeName)
                                  .format(invoiceDate),
                        ),
                        summaryRow(
                          l.invoiceDueDateLabel,
                          dueDate == null
                              ? '-'
                              : DateFormat.yMMMd(l.localeName).format(dueDate),
                        ),
                        summaryRow(
                          l.currencyLabel,
                          currency,
                        ),
                        summaryRow(
                          l.invoiceTotalLabel,
                          euroFmt.format(state._c.total).trim(),
                        ),
                        if (showDiscountRows)
                          summaryRow(
                            'Descuento',
                            '-${euroFmt.format(discountAmount).trim()}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  totalsSummary(),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: canCompleteDraft
                        ? () => state._c.handleSaveDraft(
                              context,
                              confirmIfEditing: false,
                            )
                        : null,
                    style: reinforceDraft
                        ? FilledButton.styleFrom(
                            elevation: 3,
                            shadowColor: cs.primary.withValues(alpha: 0.35),
                          )
                        : null,
                    icon: state._c.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state._c.saving
                          ? l.savingLabel
                          : state._c.editingIssued
                              ? (Localizations.localeOf(context).languageCode ==
                                      'es'
                                  ? 'Guardar cambios'
                                  : 'Save changes')
                              : l.invoiceSaveDraftCta,
                    ),
                  ),
                  if (!canCompleteDraft && draftCompletionReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      draftCompletionReason,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );

              final tabs = [
                l.invoiceCustomerTitle,
                l.invoiceDatesTitle,
                l.invoiceLinesTitle,
                l.invoiceStepPreviewShort,
              ];

              return Form(
                key: state._c.formKey,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    children: [
                      headerBar,
                      const SizedBox(height: 2),
                      AnimatedBuilder(
                        animation: state._tabController,
                        builder: (context, _) {
                          final current = state._tabController.index;
                          final steps = List<Step>.generate(
                            tabs.length,
                            (index) => Step(
                              title: Text(tabs[index]),
                              content: const SizedBox.shrink(),
                              state: current > index
                                  ? StepState.complete
                                  : StepState.indexed,
                              isActive: current >= index,
                            ),
                          );
                          return Row(
                            children: [
                              if (state.widget.embedded) ...[
                                OutlinedButton.icon(
                                  onPressed: state._handleClose,
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: Text(l.budgetBackCta),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: WizardStepsHeader(
                                  steps: steps,
                                  currentStep: current,
                                  isWide:
                                      MediaQuery.of(context).size.width >= 900,
                                  onStepTapped: (i) {
                                    state._c.setCurrentStepIndex(i);
                                    state._tabController.animateTo(i);
                                  },
                                ),
                              ),
                              if (draftBannerInline != null) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 200,
                                  child: draftBannerInline,
                                ),
                              ],
                              const SizedBox(width: 8),
                              _InvoiceDraftStatusChip(
                                controller: state._c,
                                t: t,
                                cs: cs,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  selectedClientName,
                                  style: t.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: TabBarView(
                          controller: state._tabController,
                          children: [
                            _buildInvoiceClientStep(context, state, l, t, cs),
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  InvoiceHeaderFields(
                                    clients: state.widget.clients,
                                    clientId: state._c.clientId,
                                    onClientChanged: state._c.setClientId,
                                    currencyController: state._c.currency,
                                    invoiceDate: state._c.invoiceDate,
                                    dueDate: state._c.dueDate,
                                    onPickInvoiceDate: () => state._c.pickDate(
                                        context, state._c.invoiceDate),
                                    onPickDueDate: () => state._c
                                        .pickDate(context, state._c.dueDate),
                                    onCurrencyChanged: (_) =>
                                        state._c.notifyUi(),
                                    showDates: true,
                                    showClient: false,
                                    showCurrency: true,
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: state._c.notes,
                                    minLines: 3,
                                    maxLines: 5,
                                    onChanged: (_) => state._c.notifyUi(),
                                    decoration: InputDecoration(
                                      labelText: Localizations.localeOf(context)
                                                  .languageCode ==
                                              'es'
                                          ? 'Notas'
                                          : 'Notes',
                                      prefixIcon:
                                          const Icon(Icons.notes_rounded),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            gatedLinesSection,
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Left: summary + actions ──────────────
                                  Expanded(
                                    flex: 4,
                                    child: SingleChildScrollView(
                                      child: issuePanel,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // ── Right: PDF preview ───────────────────
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        previewToolbar,
                                        Expanded(
                                          child: previewBytes != null &&
                                                  (!kIsWeb ||
                                                      isPreviewStepActive)
                                              ? LayoutBuilder(
                                                  builder: (ctx, constraints) =>
                                                      PdfInlinePreview(
                                                    bytes: previewBytes,
                                                    height:
                                                        constraints.maxHeight,
                                                  ),
                                                )
                                              : !canPreview &&
                                                      previewReason != null
                                                  ? Center(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(24),
                                                        child: Text(
                                                          previewReason,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: t.bodySmall
                                                              .copyWith(
                                                            color: cs
                                                                .onSurfaceVariant,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        if (state.widget.embedded) return content;

        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async {
            await state._requestClose();
            return false;
          },
          child: content,
        );
      },
    );
  }

  Widget _buildInvoiceClientStep(
    BuildContext context,
    _InvoiceEditorScreenState state,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final selectedClient = state._c.clientId == null
        ? null
        : state.widget.clients.cast<GroupClient?>().firstWhere(
              (c) => c?.id == state._c.clientId,
              orElse: () => null,
            );

    Widget listCard({required double maxListHeight}) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Text(
                    l.receiptSelectClientLabel,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${state.widget.clients.length}',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: ClientSearchSelect(
                  clients: state.widget.clients,
                  selectedClientId: state._c.clientId,
                  onClientChanged: state._c.setClientId,
                  useDefaultPropertyKind: false,
                  showAdvancedFilters: false,
                  maxListHeight: maxListHeight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget previewCard() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selectedClient != null
              ? cs.primary.withValues(alpha: 0.04)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedClient != null
                ? cs.primary.withValues(alpha: 0.28)
                : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: selectedClient == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                              cs.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person_search_outlined,
                          size: 26,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isEs
                            ? 'Selecciona un cliente\npara continuar'
                            : 'Select a client\nto continue',
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                selectedClient.name.trim().isEmpty
                                    ? '?'
                                    : selectedClient.name
                                        .trim()[0]
                                        .toUpperCase(),
                                style: t.titleLarge.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selectedClient.name,
                            style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if ((selectedClient.email ?? '').trim().isNotEmpty)
                          _InvoiceClientChip(
                            icon: Icons.email_outlined,
                            label: selectedClient.email!.trim(),
                          ),
                        if ((selectedClient.phone ?? '').trim().isNotEmpty)
                          _InvoiceClientChip(
                            icon: Icons.phone_outlined,
                            label: selectedClient.phone!.trim(),
                          ),
                        if ((selectedClient.entityType ?? '').trim().isNotEmpty)
                          _InvoiceClientChip(
                            icon: Icons.business_outlined,
                            label: selectedClient.entityType!.trim(),
                          ),
                        if ((selectedClient.propertyKind ?? '')
                            .trim()
                            .isNotEmpty)
                          _InvoiceClientChip(
                            icon: Icons.home_work_outlined,
                            label: selectedClient.propertyKind!.trim(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _InvoiceClientStatsBox(
                        issuedCount: state._c.issuedThisMonthCount,
                        draftCount: state._c.clientDraftCount,
                        loading: state._c.loadingClientStats,
                        pastInvoices: state._c.clientPastInvoices,
                        onPreview: (inv) async {
                          final bytes =
                              await state._c.fetchHistoricalPdf(inv.id);
                          final fileName = 'invoice-${inv.invoiceNumber}.pdf';
                          await pdf_launcher.launchPdfPreview(bytes,
                              fileName: fileName);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state._c.editingIssued) ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            _editIssuedBillingDetails(context, state),
                        icon: const Icon(Icons.badge_outlined, size: 18),
                        label: Text(
                          isEs
                              ? 'Editar datos fiscales'
                              : 'Edit billing details',
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      onPressed: () {
                        state._c.setCurrentStepIndex(1);
                        state._tabController.animateTo(1);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        isEs ? 'Continuar → Fechas' : 'Continue → Dates',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        if (!wide) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 430,
                  child: listCard(maxListHeight: 340),
                ),
                if (selectedClient != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () {
                      state._c.setCurrentStepIndex(1);
                      state._tabController.animateTo(1);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      isEs ? 'Continuar → Fechas' : 'Continue → Dates',
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: listCard(maxListHeight: double.infinity)),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: previewCard()),
          ],
        );
      },
    );
  }

  Future<void> _editIssuedBillingDetails(
    BuildContext context,
    _InvoiceEditorScreenState state,
  ) async {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final clientFields = <String, String>{
      'legalName': isEs ? 'Razon social' : 'Legal name',
      'taxId': isEs ? 'CIF / NIF' : 'Tax ID',
      'addressStreet': isEs ? 'Direccion' : 'Address',
      'addressCity': isEs ? 'Ciudad' : 'City',
      'addressProvince': isEs ? 'Provincia' : 'Province',
      'addressPostalCode': isEs ? 'Codigo postal' : 'Postal code',
      'addressCountry': isEs ? 'Pais' : 'Country',
      'email': 'Email',
      'phone': isEs ? 'Telefono' : 'Phone',
    };
    final issuerFields = <String, String>{
      'legalName': isEs ? 'Razon social' : 'Legal name',
      'taxId': isEs ? 'CIF / NIF' : 'Tax ID',
      'addressStreet': isEs ? 'Direccion' : 'Address',
      'addressCity': isEs ? 'Ciudad' : 'City',
      'addressProvince': isEs ? 'Provincia' : 'Province',
      'addressPostalCode': isEs ? 'Codigo postal' : 'Postal code',
      'addressCountry': isEs ? 'Pais' : 'Country',
      'email': 'Email',
      'website': 'Web',
      'iban': 'IBAN',
    };
    final clientControllers = {
      for (final entry in clientFields.entries)
        entry.key: TextEditingController(
          text: state._c.issuedClientSnapshot[entry.key]?.toString() ?? '',
        ),
    };
    final issuerControllers = {
      for (final entry in issuerFields.entries)
        entry.key: TextEditingController(
          text: state._c.issuedIssuerSnapshot[entry.key]?.toString() ?? '',
        ),
    };
    try {
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(isEs
              ? 'Datos fiscales de la factura'
              : 'Invoice billing details'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEs ? 'Cliente' : 'Client',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final entry in clientFields.entries)
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: clientControllers[entry.key],
                            decoration: InputDecoration(labelText: entry.value),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(isEs ? 'Emisor' : 'Issuer',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final entry in issuerFields.entries)
                        SizedBox(
                          width: 220,
                          child: TextField(
                            controller: issuerControllers[entry.key],
                            decoration: InputDecoration(labelText: entry.value),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isEs ? 'Aplicar' : 'Apply'),
            ),
          ],
        ),
      );
      if (save != true) return;
      Map<String, dynamic> values(Map<String, TextEditingController> source) =>
          {
            for (final entry in source.entries)
              entry.key: entry.value.text.trim(),
          };
      state._c.setIssuedBillingSnapshots(
        client: values(clientControllers),
        issuer: values(issuerControllers),
      );
    } finally {
      for (final controller in [
        ...clientControllers.values,
        ...issuerControllers.values,
      ]) {
        controller.dispose();
      }
    }
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

String _invoiceMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
}

class _InvoiceClientChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InvoiceClientChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceClientStatsBox extends StatefulWidget {
  final int issuedCount;
  final int draftCount;
  final bool loading;
  final List<Invoice> pastInvoices;
  final Future<void> Function(Invoice)? onPreview;

  const _InvoiceClientStatsBox({
    required this.issuedCount,
    required this.draftCount,
    required this.loading,
    required this.pastInvoices,
    this.onPreview,
  });

  @override
  State<_InvoiceClientStatsBox> createState() => _InvoiceClientStatsBoxState();
}

class _InvoiceClientStatsBoxState extends State<_InvoiceClientStatsBox>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Invoice? _previewingInvoice;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: TabBar(
              controller: _tab,
              dividerColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStatePropertyAll(
                cs.primary.withValues(alpha: 0.06),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              indicatorPadding: const EdgeInsets.symmetric(vertical: 3),
              labelColor: cs.onPrimaryContainer,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: t.bodySmall
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: t.bodySmall
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
              tabs: [
                Tab(text: isEs ? 'Este mes' : 'This month'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isEs ? 'Historial' : 'History'),
                      if (widget.pastInvoices.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${widget.pastInvoices.length}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildThisMonthTab(context, isEs, t, cs),
                _buildHistoryTab(context, isEs, t, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisMonthTab(
      BuildContext context, bool isEs, AppTypography t, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEs ? 'Facturas este mes' : 'Invoices this month',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: cs.tertiary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  isEs ? 'Mes recurrente' : 'Recurrent month',
                  style: t.bodySmall.copyWith(
                    fontSize: 9,
                    color: cs.tertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.loading)
            const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _InvoiceStatCell(
                    label: isEs ? 'Emitidas' : 'Issued',
                    count: widget.issuedCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InvoiceStatCell(
                    label: isEs ? 'Borradores' : 'Drafts',
                    count: widget.draftCount,
                    icon: Icons.edit_note_rounded,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
      BuildContext context, bool isEs, AppTypography t, ColorScheme cs) {
    final locale = Localizations.localeOf(context).toString();

    if (widget.loading) {
      return const Center(
        child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (widget.pastInvoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isEs ? 'Sin facturas anteriores' : 'No previous invoices',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final items = <Object>[];
    String? lastKey;
    for (final inv in widget.pastInvoices) {
      final date = inv.registeredAt ?? inv.issueDate;
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        items.add(date == null ? '—' : _invoiceMonthLabel(date, locale));
        lastKey = key;
      }
      items.add(inv);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) {
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10, bottom: 4),
            child: Text(
              item,
              style: t.bodySmall.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }
        final inv = item as Invoice;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _InvoiceHistoryItem(
            invoice: inv,
            isPreviewing: _previewingInvoice?.id == inv.id,
            onPreview: widget.onPreview == null
                ? null
                : () async {
                    setState(() => _previewingInvoice = inv);
                    try {
                      await widget.onPreview!(inv);
                    } finally {
                      if (mounted) setState(() => _previewingInvoice = null);
                    }
                  },
          ),
        );
      },
    );
  }
}

class _InvoiceStatCell extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _InvoiceStatCell({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count',
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceHistoryItem extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback? onPreview;
  final bool isPreviewing;

  const _InvoiceHistoryItem({
    required this.invoice,
    this.onPreview,
    this.isPreviewing = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    final date = invoice.registeredAt ?? invoice.issueDate;
    final dateLabel = date != null
        ? DateFormat.yMMMd(l.localeName).format(date.toLocal())
        : '—';
    final number = invoice.invoiceNumber.trim().isNotEmpty
        ? invoice.invoiceNumber.trim()
        : (isEs ? 'Borrador' : 'Draft');
    final isIssued = (invoice.status ?? '').contains('issue');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isIssued ? Icons.receipt_long_rounded : Icons.edit_note_rounded,
            size: 14,
            color: isIssued
                ? cs.primary.withValues(alpha: 0.7)
                : cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  dateLabel,
                  style: t.bodySmall.copyWith(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onPreview != null)
            isPreviewing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : IconButton(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined),
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    tooltip: isEs ? 'Vista previa' : 'Preview',
                    color: cs.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
        ],
      ),
    );
  }
}
