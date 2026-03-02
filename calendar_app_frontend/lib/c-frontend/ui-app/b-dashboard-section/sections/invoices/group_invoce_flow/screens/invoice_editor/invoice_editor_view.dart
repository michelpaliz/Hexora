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
        final canIssue =
            !state._c.issuing && step1Complete && state._c.previewedPdf;
        final reinforceIssue = canIssue && state._c.previewedPdf;

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
        final issueReason = !canIssue
            ? (!state._c.previewedPdf
                ? l.invoiceIssueNeedsPreview
                : (step1Missing.isNotEmpty ? step1Missing.first : ''))
            : null;

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
                  issuing: state._c.issuing,
                  onSaveDraft: () => state._c.handleSaveDraft(context),
                  onIssue: () => state._c.issue(context),
                  showClose: state.widget.embedded,
                  onClose: state.widget.embedded ? state._handleClose : null,
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
                canIssue: canIssue,
                reinforceIssue: reinforceIssue,
                previewReason: previewReason,
                issueReason: issueReason,
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

              final gatedLinesSection = linesSection;

              final saveDraftButton = FilledButton.tonalIcon(
                onPressed: canSaveDraft && state._c.confirmSaveDraft
                    ? () => state._c.handleSaveDraft(context)
                    : null,
                icon: state._c.saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  state._c.saving ? l.savingLabel : l.invoiceSaveDraftCta,
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );

              final totalsCard = Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.invoiceTotalsTitle,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      euroFmt.format(state._c.total),
                      style: t.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );

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

              Widget discountEditorCard() {
                String? validateAmount(String? raw) {
                  if (state._c.useDiscountPercent) return null;
                  final text = (raw ?? '').trim();
                  if (text.isEmpty) return null;
                  final parsed = num.tryParse(text.replaceAll(',', '.'));
                  if (parsed == null) return 'Importe inválido';
                  if (parsed < 0) return 'Debe ser mayor o igual a 0';
                  return null;
                }

                String? validatePercent(String? raw) {
                  if (!state._c.useDiscountPercent) return null;
                  final text = (raw ?? '').trim();
                  if (text.isEmpty) return null;
                  final parsed = num.tryParse(text.replaceAll(',', '.'));
                  if (parsed == null) return 'Porcentaje inválido';
                  if (parsed < 0 || parsed > 100) {
                    return 'Debe estar entre 0 y 100';
                  }
                  return null;
                }

                final readOnly = state._c.discountReadOnly;
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Descuento',
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Importe fijo (€)'),
                            selected: !state._c.useDiscountPercent,
                            onSelected: readOnly
                                ? null
                                : (_) => state._c.setDiscountModePercent(false),
                          ),
                          ChoiceChip(
                            label: const Text('Porcentaje (%)'),
                            selected: state._c.useDiscountPercent,
                            onSelected: readOnly
                                ? null
                                : (_) => state._c.setDiscountModePercent(true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: state._c.discountAmountCtrl,
                              enabled: !readOnly && !state._c.useDiscountPercent,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: validateAmount,
                              decoration: const InputDecoration(
                                labelText: 'Importe fijo (€)',
                                hintText: '0.00',
                              ),
                              onChanged: state._c.setDiscountAmountText,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: state._c.discountPercentCtrl,
                              enabled: !readOnly && state._c.useDiscountPercent,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: validatePercent,
                              decoration: const InputDecoration(
                                labelText: 'Porcentaje (%)',
                                hintText: '0.00',
                              ),
                              onChanged: state._c.setDiscountPercentText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El descuento se aplica antes de IVA.',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
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
              final previewPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canPreview) ...[
                        if (state._c.previewing || previewBytes == null)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            tooltip: l.refreshAction,
                            onPressed: state._c.previewing
                                ? null
                                : () => state._c.previewPdf(context),
                            icon: const Icon(Icons.refresh),
                          ),
                      ],
                    ],
                  ),
                  if (!canPreview && previewReason != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          previewReason,
                          textAlign: TextAlign.center,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (previewBytes != null) ...[
                    const SizedBox(height: 12),
                    PdfInlinePreview(bytes: previewBytes, height: 520),
                  ],
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
                    onPressed: canIssue ? () => state._c.issue(context) : null,
                    style: reinforceIssue
                        ? FilledButton.styleFrom(
                            elevation: 3,
                            shadowColor: cs.primary.withValues(alpha: 0.35),
                          )
                        : null,
                    icon: state._c.issuing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      state._c.issuing
                          ? l.invoiceIssuingLabel
                          : l.invoiceIssueCta,
                    ),
                  ),
                  if (!canIssue && issueReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      issueReason,
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
                l.invoiceTotalsTitle,
                l.invoiceStepPreviewShort,
                l.invoiceStepIssueShort,
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
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClientSearchSelect(
                                    clients: state.widget.clients,
                                    selectedClientId: state._c.clientId,
                                    onClientChanged: state._c.setClientId,
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(
                              child: InvoiceHeaderFields(
                                clients: state.widget.clients,
                                clientId: state._c.clientId,
                                onClientChanged: state._c.setClientId,
                                currencyController: state._c.currency,
                                invoiceDate: state._c.invoiceDate,
                                dueDate: state._c.dueDate,
                                onPickInvoiceDate: () => state._c
                                    .pickDate(context, state._c.invoiceDate),
                                onPickDueDate: () => state._c
                                    .pickDate(context, state._c.dueDate),
                                showDates: true,
                                showClient: false,
                                showCurrency: false,
                              ),
                            ),
                            SingleChildScrollView(
                              child: gatedLinesSection,
                            ),
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  discountEditorCard(),
                                  const SizedBox(height: 12),
                                  totalsCard,
                                  const SizedBox(height: 12),
                                  totalsSummary(),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: cs.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cs.outlineVariant
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: state._c.confirmSaveDraft,
                                              onChanged: (v) => state._c
                                                  .setConfirmSaveDraft(
                                                      v ?? false),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                l.invoicePreviewNeedsDraft,
                                                style: t.bodySmall.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: saveDraftButton,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SingleChildScrollView(child: previewPanel),
                            SingleChildScrollView(child: issuePanel),
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

        return WillPopScope(
          onWillPop: () async {
            state._handleClose();
            return false;
          },
          child: content,
        );
      },
    );
  }
}
