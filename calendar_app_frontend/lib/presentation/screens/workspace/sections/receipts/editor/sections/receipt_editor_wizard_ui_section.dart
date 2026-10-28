part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardUiSection on _ReceiptEditorWizardScreenState {
  Widget _buildWizardToolbarContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final title = Text(
      l.createReceiptCta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 2),
              _buildStepIndicator(context),
            ],
          );
        }
        return Row(
          children: [
            Flexible(flex: 2, child: title),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: _buildStepIndicator(context)),
          ],
        );
      },
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return HexoraDocumentStepper(
      steps: [
        HexoraDocumentStep(
          label: l.invoiceBillToLabel,
          icon: Icons.person_outline_rounded,
        ),
        HexoraDocumentStep(
          label: l.receiptLinesTitle,
          icon: Icons.format_list_bulleted_rounded,
        ),
        HexoraDocumentStep(
          label: l.preview,
          icon: Icons.picture_as_pdf_outlined,
        ),
      ],
      currentStep: _step,
      onStepTapped: _tryGoToStep,
      itemKeyBuilder: (index, _) => ValueKey('receipt-editor-step-$index'),
    );
  }

  Widget _buildClientStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final client = _selectedClient;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    Widget? selectedDetails;
    if (client != null) {
      selectedDetails = Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      client.name.trim().isEmpty
                          ? '?'
                          : client.name.trim()[0].toUpperCase(),
                      style: t.bodyLarge.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            if ((client.email ?? '').trim().isNotEmpty)
                              _WizardClientChip(
                                icon: Icons.email_outlined,
                                label: client.email!.trim(),
                              ),
                            if ((client.phone ?? '').trim().isNotEmpty)
                              _WizardClientChip(
                                icon: Icons.phone_outlined,
                                label: client.phone!.trim(),
                              ),
                            if ((client.entityType ?? '').trim().isNotEmpty)
                              _WizardClientChip(
                                icon: Icons.business_outlined,
                                label: client.entityType!.trim(),
                              ),
                            if ((client.propertyKind ?? '').trim().isNotEmpty)
                              _WizardClientChip(
                                icon: Icons.home_work_outlined,
                                label: client.propertyKind!.trim(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 204,
              child: _ClientReceiptStatsBox(
                issuedCount: _clientIssuedCount,
                draftCount: _clientDraftCount,
                loading: _loadingReceiptStats,
                pastReceipts: _clientPastReceipts,
                onPreview: _previewHistoricalReceipt,
              ),
            ),
          ],
        ),
      );
    }

    return DocumentClientStep(
      clients: widget.clients,
      selectedClientId: _clientId,
      onClientChanged: (value) {
        setState(() {
          _clientId = value;
          _markDraftDirty();
        });
        _loadClientReceiptStats(value);
      },
      mode: _useManualClient
          ? DocumentClientMode.manual
          : DocumentClientMode.existing,
      onModeChanged: (mode) {
        setState(() {
          _useManualClient = mode == DocumentClientMode.manual;
          _markDraftDirty();
        });
      },
      selectedDetails: selectedDetails,
      manual: DocumentManualClientConfig(
        nameController: _clientNameCtrl,
        addressController: _clientAddressCtrl,
        cityController: _clientCityCtrl,
        postalCodeController: _clientPostalCodeCtrl,
        nameLabel: isEs ? 'Nombre del cliente' : 'Client name',
        addressLabel: isEs ? 'Dirección' : 'Address',
        cityLabel: isEs ? 'Ciudad' : 'City',
        postalCodeLabel: isEs ? 'CP' : 'Postal code',
        helperText: isEs
            ? 'La dirección, ciudad y CP son opcionales y solo se usan en este recibo.'
            : 'Address, city, and postal code are optional and only used for this receipt.',
        onChanged: () => setState(_markDraftDirty),
      ),
      existingLabel: isEs ? 'Cliente existente' : 'Existing client',
      manualLabel: isEs ? 'Cliente manual' : 'Manual client',
      selectClientLabel: l.receiptSelectClientLabel,
      emptySelectionLabel: isEs
          ? 'Selecciona un cliente para continuar'
          : 'Select a client to continue',
      clientSearchController: _clientSearchCtrl,
    );
  }

  Widget _buildDetailsStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final dateLabel = _issueDate == null
        ? '-'
        : DateFormat.yMMMd(l.localeName).format(_issueDate!);
    final activeLineCount = _lines.where((line) => line.hasAnyValue).length;
    final linesTotal = _lines.fold<num>(0, (sum, line) => sum + line.total);
    final currency = NumberFormat.simpleCurrency(name: '');

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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: cs.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.receiptLinesTitle,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _ReceiptMetaChip(
                              icon: Icons.event_outlined,
                              label: l.receiptIssueDateLabel,
                              value: dateLabel,
                              onTap: _pickIssueDate,
                            ),
                            _ReceiptMetaChip(
                              icon: Icons.format_list_bulleted_rounded,
                              label: 'Lineas',
                              value: '$activeLineCount',
                            ),
                            _ReceiptMetaChip(
                              icon: Icons.payments_outlined,
                              label: 'Total',
                              value: currency.format(linesTotal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: !_isManualLinesMode
                        ? null
                        : () => setState(() {
                              _lines.add(ReceiptLineDraft.empty());
                              _markDraftDirty();
                            }),
                    icon: const Icon(Icons.add),
                    label: Text(l.addLine),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                    _markDraftDirty();
                  });
                },
                onChanged: () => setState(_markDraftDirty),
                onAddLine: () => setState(() {
                  _lines.add(ReceiptLineDraft.empty());
                  _markDraftDirty();
                }),
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
                    showDefaultTaxRate: false,
                    formatHint:
                        'Formato: {"items": [{"quantity": 1, "description": "...", "unitPrice": 21.70}]}',
                  ),
                  const SizedBox(height: 12),
                  _buildReceiptOpenAiExtractPanel(context),
                ],
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.save_outlined,
                    color: cs.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.localeName.startsWith('es')
                          ? 'Guarda el borrador antes de generar la vista previa.'
                          : 'Save the draft before generating the preview.',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _savingDraft ? null : _saveDraft,
                    icon: _savingDraft
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l.saveDraft),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _savingDraft ? null : () => _tryGoToStep(2),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l.preview),
                  ),
                ],
              ),
            ),
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
                              (v) =>
                                  _updateExtractedLineField(i, 'quantity', v),
                            ),
                            const SizedBox(width: 6),
                            numField(
                              'Unit',
                              (row['unitPrice'] ?? 0).toString(),
                              (v) =>
                                  _updateExtractedLineField(i, 'unitPrice', v),
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
        child: LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;
          return Flex(
            direction: narrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: summary + actions ───────────────────────────────────
              Flexible(
                fit: narrow ? FlexFit.loose : FlexFit.tight,
                flex: narrow ? 0 : 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      previewNumber,
                      style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 16),
                    if ((_previewError ?? '').trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: cs.errorContainer.withValues(alpha: 0.35),
                        ),
                        child: Text(
                          _previewError!,
                          style:
                              t.bodySmall.copyWith(color: cs.onErrorContainer),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: canRenderPreview
                          ? () =>
                              _loadDraftPreview(receiptId: _draftReceipt!.id)
                          : null,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l.preview),
                    ),
                  ],
                ),
              ),
              SizedBox(width: narrow ? 0 : 16, height: narrow ? 16 : 0),
              // ── Right: PDF preview ────────────────────────────────────────
              Flexible(
                fit: narrow ? FlexFit.loose : FlexFit.tight,
                flex: narrow ? 0 : 6,
                child: _loadingPreview
                    ? const SizedBox(
                        height: 520,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _previewPdfBytes != null
                        ? PdfInlinePreview(
                            bytes: _previewPdfBytes!,
                            height: 520,
                          )
                        : const SizedBox(height: 520),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepBody(BuildContext context) {
    if (_step == 0) return _buildClientStep(context);
    if (_step == 1) return _buildDetailsStep(context);
    return _buildPreviewStep(context);
  }

  Widget _buildExistingDraftBanner(BuildContext context) {
    final id = _existingUnnumberedReceiptId;
    final receipt = _existingUnnumberedReceipt;
    if ((id == null || id.trim().isEmpty) && receipt == null) {
      return const SizedBox.shrink();
    }
    if (_draftReceipt?.id == id || _draftReceipt?.id == receipt?.id) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_outlined, color: cs.tertiary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEs
                  ? 'Tienes un borrador de recibo pendiente'
                  : 'There is a pending unnumbered receipt draft.',
              style: t.bodyMedium.copyWith(
                color: cs.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: _checkingUnnumberedDraft
                ? null
                : () => _openExistingUnnumberedDraft(
                      receiptId: id,
                      receipt: receipt,
                    ),
            icon: _checkingUnnumberedDraft
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.open_in_new_outlined, size: 16),
            label: Text(isEs ? 'Abrir' : 'Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final statusText = _draftSaveFailed
        ? (l.localeName.startsWith('es')
            ? 'No se pudo guardar el borrador'
            : 'Draft could not be saved')
        : _draftDirty
            ? (l.localeName.startsWith('es')
                ? 'Cambios sin guardar'
                : 'Unsaved changes')
            : (l.localeName.startsWith('es')
                ? 'Borrador actualizado'
                : 'Draft up to date');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded != true) _buildStepIndicator(context),
        const SizedBox(height: 6),
        Expanded(
          child: _step == 0
              ? _buildClientStep(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStepBody(context),
                ),
        ),
        HexoraDocumentFooter(
          status: Text(statusText, style: const TextStyle(fontSize: 12)),
          back: OutlinedButton.icon(
            onPressed:
                _step == 0 ? _requestClose : () => _tryGoToStep(_step - 1),
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: Text(_step == 0 ? l.close : l.back),
          ),
          primary: FilledButton.icon(
            onPressed: _savingDraft
                ? null
                : _step < 2
                    ? () => _tryGoToStep(_step + 1)
                    : _saveDraft,
            icon: _savingDraft
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _step < 2
                        ? Icons.arrow_forward_rounded
                        : Icons.save_outlined,
                    size: 17,
                  ),
            label: Text(
              _step < 2
                  ? (l.localeName.startsWith('es') ? 'Continuar' : 'Continue')
                  : l.saveDraft,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

String _wizardMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
}

class _ReceiptMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ReceiptMetaChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final clickable = onTap != null;

    return Material(
      color: clickable
          ? cs.primaryContainer.withValues(alpha: 0.42)
          : cs.surface.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: clickable
                  ? cs.primary.withValues(alpha: 0.18)
                  : cs.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: clickable ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '$label: ',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: t.bodySmall.copyWith(
                  color: clickable ? cs.primary : cs.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientReceiptStatsBox extends StatefulWidget {
  final int issuedCount;
  final int draftCount;
  final bool loading;
  final List<Receipt> pastReceipts;
  final Future<void> Function(Receipt)? onPreview;

  const _ClientReceiptStatsBox({
    required this.issuedCount,
    required this.draftCount,
    required this.loading,
    required this.pastReceipts,
    this.onPreview,
  });

  @override
  State<_ClientReceiptStatsBox> createState() => _ClientReceiptStatsBoxState();
}

class _ClientReceiptStatsBoxState extends State<_ClientReceiptStatsBox>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Receipt? _previewingReceipt;

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
                      if (widget.pastReceipts.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${widget.pastReceipts.length}',
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
                isEs ? 'Recibos este mes' : 'Receipts this month',
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
                  child: _StatCell(
                    label: isEs ? 'Emitidos' : 'Issued',
                    count: widget.issuedCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCell(
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
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.pastReceipts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isEs ? 'Sin recibos anteriores' : 'No previous receipts',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Build grouped list (month headers + receipt items)
    final items = <Object>[];
    String? lastKey;
    for (final r in widget.pastReceipts) {
      final date = r.issueDate ?? r.registeredAt;
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        items.add(date == null ? '—' : _wizardMonthLabel(date, locale));
        lastKey = key;
      }
      items.add(r);
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
        final r = item as Receipt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _HistoryReceiptItem(
            receipt: r,
            isPreviewing: _previewingReceipt?.id == r.id,
            onPreview: widget.onPreview == null
                ? null
                : () async {
                    setState(() => _previewingReceipt = r);
                    await widget.onPreview!(r);
                    if (mounted) setState(() => _previewingReceipt = null);
                  },
          ),
        );
      },
    );
  }
}

class _HistoryReceiptItem extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onPreview;
  final bool isPreviewing;

  const _HistoryReceiptItem({
    required this.receipt,
    this.onPreview,
    this.isPreviewing = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    final date = receipt.issueDate ?? receipt.registeredAt;
    final dateLabel = date != null
        ? DateFormat.yMMMd(l.localeName).format(date.toLocal())
        : '—';
    final number = (receipt.receiptNumber?.trim().isNotEmpty == true)
        ? receipt.receiptNumber!.trim()
        : (isEs ? 'Borrador' : 'Draft');
    final isIssued = receipt.status == 'issued';

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
          if (isIssued && onPreview != null)
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

class _StatCell extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCell({
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

class _WizardClientChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WizardClientChip({required this.icon, required this.label});

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
