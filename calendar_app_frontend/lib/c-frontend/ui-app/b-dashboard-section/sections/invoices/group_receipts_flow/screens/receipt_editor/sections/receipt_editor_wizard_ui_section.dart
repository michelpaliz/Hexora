part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardUiSection on _ReceiptEditorWizardScreenState {
  Widget _buildStepIndicator(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final labels = [
      l.invoiceBillToLabel,
      l.receiptLinesTitle,
      l.receiptSummaryTitle,
      l.preview,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        final active = index == _step;
        final complete = index < _step;
        final canTap = index <= _step || index == _step + 1;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: canTap ? () => _tryGoToStep(index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: complete
                  ? cs.primaryContainer
                  : active
                      ? cs.secondaryContainer
                      : cs.surfaceContainerHighest.withValues(alpha: 0.55),
              border: Border.all(
                color: active || complete
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  complete ? Icons.check_rounded : Icons.circle,
                  size: 14,
                  color: complete
                      ? cs.onPrimaryContainer
                      : active
                          ? cs.primary
                          : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  labels[index],
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color:
                        active || complete ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildClientStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.receiptSelectClientLabel,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ClientSearchSelect(
              clients: widget.clients,
              selectedClientId: _clientId,
              onClientChanged: (value) => setState(() => _clientId = value),
              useDefaultPropertyKind: false,
              maxListHeight: 300,
            ),
            if (_selectedClient != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedClient!.name,
                        style:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final dateLabel = _issueDate == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).format(_issueDate!);

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptIssueDateLabel,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickIssueDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(dateLabel),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l.invoiceNotesLabel,
                hintText: l.receiptNotesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptLinesTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: !_isManualLinesMode
                      ? null
                      : () =>
                          setState(() => _lines.add(ReceiptLineDraft.empty())),
                  icon: const Icon(Icons.add),
                  label: Text(l.addLine),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: DefaultTabController(
                length: 2,
                initialIndex: _linesInputTabIndex,
                child: TabBar(
                  onTap: (index) {
                    setState(() {
                      _linesInputTabIndex = index;
                      _jsonImportError = null;
                    });
                  },
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: cs.onPrimaryContainer,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: l.invoiceLinesModeManual),
                    Tab(text: l.invoiceLinesModeJson),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isManualLinesMode)
              ReceiptLinesEditor(
                lines: _lines,
                canEdit: true,
                onRemove: (index) {
                  setState(() {
                    _lines.removeAt(index).dispose();
                    if (_lines.isEmpty) _lines.add(ReceiptLineDraft.empty());
                  });
                },
                onChanged: () => setState(() {}),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinesJsonImportPanel(
                    loading: _jsonImporting,
                    loadingPrompt: _jsonPromptLoading,
                    disabled: false,
                    fileName: _jsonImportFileName,
                    errorText: _jsonImportError,
                    onPickFile: _pickJsonImportFile,
                    onClearFile: _clearJsonImportFile,
                    onImportFromText: _importLinesFromJsonText,
                    onImportFromFile: _importLinesFromJsonFile,
                    onCopyPrompt: _copyJsonPromptTemplate,
                    onClearError: () => setState(() => _jsonImportError = null),
                  ),
                  const SizedBox(height: 12),
                  _buildReceiptOpenAiExtractPanel(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final currency = NumberFormat.simpleCurrency(name: '');
    final issueDate = _issueDate == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).format(_issueDate!);
    final activeLines = _lines.where((line) => line.hasAnyValue).toList();

    Widget row(
        {required String label, required String value, bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: t.bodyMedium.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: (strong ? t.bodyLarge : t.bodyMedium)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.receiptSummaryTitle,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            row(
                label: l.invoiceBillToLabel,
                value: _selectedClient?.name ?? '-'),
            row(label: l.receiptIssueDateLabel, value: issueDate),
            row(label: l.receiptLinesTitle, value: '${activeLines.length}'),
            const Divider(height: 20),
            row(
              label: l.receiptSubtotalLabel,
              value: currency.format(_subtotal),
            ),
            row(
              label: l.receiptTotalLabel,
              value: currency.format(_subtotal),
              strong: true,
            ),
            if (_notesCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l.invoiceNotesLabel,
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(_notesCtrl.text.trim(), style: t.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptOpenAiExtractPanel(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    Widget numField(
      String label,
      String value,
      ValueChanged<String> onChanged,
    ) {
      return SizedBox(
        width: 110,
        child: TextField(
          controller: TextEditingController(text: value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.invoiceLinesPhotoTitle} (OpenAI)',
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _extractingLines ? null : _pickExtractFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_extractFileName?.trim().isNotEmpty == true
                    ? _extractFileName!
                    : l.addPhoto),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _extractingLines ? null : _extractLinesWithOpenAi,
                icon: _extractingLines
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_extractingLines
                    ? l.invoiceLinesPhotoExtracting
                    : l.invoiceLinesModePhoto),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    _extractedDraftLines.isEmpty ? null : _clearExtractedLines,
                icon: const Icon(Icons.clear_all),
                label: Text(l.invoiceLinesPhotoClear),
              ),
            ],
          ),
          if ((_extractError ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _extractError!,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          ],
          if ((_extractMethodUsed ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'methodUsed: ${_extractMethodUsed!.trim()}',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_extractDiagnostics.isNotEmpty) ...[
            const SizedBox(height: 4),
            ..._extractDiagnostics.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('- $d', style: t.bodySmall),
                )),
          ],
          if (_extractedDraftLines.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  l.invoiceLinesPhotoExtractedCount(
                    '${_extractedDraftLines.length}',
                  ),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addExtractedLine,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                itemCount: _extractedDraftLines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final row = _extractedDraftLines[i];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: TextEditingController(
                            text: (row['description'] ?? '').toString(),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) =>
                              _updateExtractedLineField(i, 'description', v),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            numField(
                              'Qty',
                              (row['quantity'] ?? 1).toString(),
                              (v) => _updateExtractedLineField(i, 'quantity', v),
                            ),
                            const SizedBox(width: 6),
                            numField(
                              'Unit',
                              (row['unitPrice'] ?? 0).toString(),
                              (v) => _updateExtractedLineField(i, 'unitPrice', v),
                            ),
                            const SizedBox(width: 6),
                            numField(
                              'Tax %',
                              (row['taxRate'] ?? 21).toString(),
                              (v) => _updateExtractedLineField(i, 'taxRate', v),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _removeExtractedLine(i),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _jsonImporting
                  ? null
                  : () => _importExtractedLines(
                        overwrite: false,
                        defaultTaxRate: 21,
                      ),
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              label: Text(l.invoiceLinesJsonImportApply),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final canRenderPreview =
        (_draftReceipt?.id.trim().isNotEmpty ?? false) && !_loadingPreview;
    final previewNumber =
        (_draftReceipt?.receiptNumber?.trim().isNotEmpty ?? false)
            ? _draftReceipt!.receiptNumber!.trim()
            : l.receiptDraftNumberPlaceholder;

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              previewNumber,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (_loadingPreview)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if ((_previewError ?? '').trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: cs.errorContainer.withValues(alpha: 0.35),
                ),
                child: Text(
                  _previewError!,
                  style: t.bodySmall.copyWith(color: cs.onErrorContainer),
                ),
              )
            else if (_previewPdfBytes != null)
              PdfInlinePreview(
                bytes: _previewPdfBytes!,
                height: 420,
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: canRenderPreview
                  ? () => _loadDraftPreview(receiptId: _draftReceipt!.id)
                  : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.preview),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _savingDraft ? null : _saveDraft,
              icon: _savingDraft
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(l.saveDraft),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _issuing ? null : _finishFlow,
              icon: _issuing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(l.receiptIssueCta),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody(BuildContext context) {
    if (_step == 0) return _buildClientStep(context);
    if (_step == 1) return _buildDetailsStep(context);
    if (_step == 2) return _buildSummaryStep(context);
    return _buildPreviewStep(context);
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        _buildStepIndicator(context),
        const SizedBox(height: 14),
        _buildStepBody(context),
      ],
    );
  }

}



