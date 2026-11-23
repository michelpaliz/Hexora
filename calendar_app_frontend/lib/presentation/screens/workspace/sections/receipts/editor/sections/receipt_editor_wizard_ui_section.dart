part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardUiSection on _ReceiptEditorWizardScreenState {
  Widget _buildStepIndicator(BuildContext context, {bool vertical = false}) {
    final l = AppLocalizations.of(context)!;
    final selectedClientName = _useManualClient
        ? _clientNameCtrl.text.trim()
        : (_selectedClient?.name.trim() ?? '');
    return HexoraDocumentStepper(
      steps: [
        HexoraDocumentStep(
          label: l.localeName.toLowerCase().startsWith('es')
              ? 'Recibo para'
              : 'Receipt for',
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
      compactConnectors: true,
      vertical: vertical,
      afterStepBuilder: vertical && _step > 0 && selectedClientName.isNotEmpty
          ? (index) => index == 0
              ? HexoraDocumentClientContext(
                  key: const ValueKey('receipt-selected-client-context'),
                  clientName: selectedClientName,
                  onTap: () => _tryGoToStep(0),
                )
              : null
          : null,
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
    Widget? searchDrivenDetails;
    if (client != null) {
      final billing = client.billing;
      final billingName = (billing?.legalName ?? '').trim();
      final taxId = (billing?.taxId ?? '').trim();
      final billingEmail = (billing?.email ?? '').trim();
      final email =
          billingEmail.isNotEmpty ? billingEmail : (client.email ?? '').trim();
      final address = <String>[
        (billing?.addressStreet ?? '').trim(),
        (billing?.addressPostalCode ?? '').trim(),
        (billing?.addressCity ?? '').trim(),
        (billing?.addressProvince ?? '').trim(),
      ].where((value) => value.isNotEmpty).join(', ');
      final classification = <String>[
        (client.entityType ?? '').trim(),
        (client.propertyKind ?? '').trim(),
      ].where((value) => value.isNotEmpty).join(' · ');

      Widget metadataLine(IconData icon, String value) => Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Icon(icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          );

      searchDrivenDetails = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: Text(
                    client.name.trim().isEmpty
                        ? '?'
                        : client.name.trim()[0].toUpperCase(),
                    style: t.bodyMedium.copyWith(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (billingName.isNotEmpty) ...[
              const SizedBox(height: 8),
              metadataLine(Icons.business_outlined, billingName),
            ],
            if (taxId.isNotEmpty) metadataLine(Icons.badge_outlined, taxId),
            if (classification.isNotEmpty)
              metadataLine(Icons.category_outlined, classification),
            if (address.isNotEmpty)
              metadataLine(Icons.location_on_outlined, address),
          ],
        ),
      );

      selectedDetails = Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
        child: _ClientReceiptStatsBox(
          issuedCount: _clientIssuedCount,
          draftCount: _clientDraftCount,
          loading: _loadingReceiptStats,
          pastReceipts: _clientPastReceipts,
          onPreview: _previewHistoricalReceipt,
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: DocumentClientStep(
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
          searchDrivenDetails: searchDrivenDetails,
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
                ? 'La dirección y el CP son obligatorios y solo se usan en este recibo.'
                : 'Address and postal code are required and only used for this receipt.',
            onChanged: () => setState(_markDraftDirty),
          ),
          existingLabel: isEs ? 'Existente' : 'Existing',
          manualLabel: isEs ? 'Manual' : 'Manual',
          selectClientLabel: l.receiptSelectClientLabel,
          emptySelectionLabel: isEs
              ? 'Selecciona un cliente para continuar'
              : 'Select a client to continue',
          clientSearchController: _clientSearchCtrl,
          twoColumnBreakpoint: 900,
          desktopListWidth: null,
          showSelectionHeading: false,
          modeSelectorAlignment: AlignmentDirectional.centerStart,
          modeSelectorTrailing: const _ReceiptPeriodTabs(),
          adaptivePreview: false,
          compactSelectionMaxWidth: 620,
          // Keep the count beside the search field in the compact client toolbar
          // instead of rendering a separate line above it.
          showClientCount: false,
          flat: true,
          searchDriven: true,
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
    final activeLineCount = _lines.where((line) => line.hasAnyValue).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l.receiptLinesTitle,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeLineCount',
                        style: t.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickIssueDate,
                      icon: const Icon(Icons.event_outlined, size: 15),
                      label: Text(dateLabel),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HexoraButton(
                onPressed: !_isManualLinesMode
                    ? null
                    : () => setState(() {
                          _lines.add(ReceiptLineDraft.empty());
                          _markDraftDirty();
                        }),
                icon: Icons.add_rounded,
                label: l.addLine,
                variant: HexoraButtonVariant.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<int>(
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  label: Text(l.invoiceLinesModeManual),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text(l.invoiceLinesModeJson),
                ),
              ],
              selected: {_linesInputTabIndex},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() {
                  _linesInputTabIndex = selection.first;
                  _jsonImportError = null;
                });
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        ],
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

  Widget _buildContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
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
    final receiptTotal = _lines.fold<num>(0, (sum, line) => sum + line.total);
    final totalLabel = NumberFormat.currency(
      locale: l.localeName,
      symbol: '€',
      decimalDigits: 2,
    ).format(receiptTotal);
    return LayoutBuilder(builder: (context, constraints) {
      final desktopRail = constraints.maxWidth >= 820;
      final stepContent = Expanded(
        child: HexoraStepTransition(
          step: _step,
          child: _step == 0
              ? _buildClientStep(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStepBody(context),
                ),
        ),
      );
      final footer = HexoraDocumentFooter(
        compact: true,
        showStatusWhenNarrow: true,
        status: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _draftSaveFailed
                  ? Icons.error_outline_rounded
                  : _draftDirty
                      ? Icons.edit_outlined
                      : Icons.cloud_done_outlined,
              size: 15,
              color: _draftSaveFailed
                  ? cs.error
                  : _draftDirty
                      ? cs.onSurfaceVariant
                      : cs.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                statusText,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(fontSize: 12),
              ),
            ),
            if (_step == 1) ...[
              const SizedBox(width: 16),
              Text('Total',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(width: 6),
              Text(totalLabel,
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
          ],
        ),
        back: HexoraButton(
          onPressed: _step == 0 ? _requestClose : () => _tryGoToStep(_step - 1),
          icon: Icons.arrow_back_rounded,
          label: _step == 0 ? l.close : l.back,
          variant: HexoraButtonVariant.secondary,
        ),
        primary: HexoraButton(
          onPressed: _savingDraft
              ? null
              : _step < 2
                  ? () => _tryGoToStep(_step + 1)
                  : _saveDraftAndFinish,
          loading: _savingDraft,
          icon: _step < 2 ? Icons.arrow_forward_rounded : Icons.save_outlined,
          label: _step < 2
              ? (l.localeName.startsWith('es') ? 'Continuar' : 'Continue')
              : l.saveDraft,
        ),
      );

      if (desktopRail) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 174,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 10),
                      child: _buildStepIndicator(context, vertical: true),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 12),
                  stepContent,
                ],
              ),
            ),
            footer,
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.embedded != true)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildStepIndicator(context, vertical: true),
            ),
          stepContent,
          footer,
        ],
      );
    });
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

String _wizardMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
}

class _ReceiptPeriodTabs extends StatelessWidget {
  const _ReceiptPeriodTabs();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 300,
      height: 42,
      child: TabBar(
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
        labelStyle:
            t.bodySmall.copyWith(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle:
            t.bodySmall.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        tabs: [
          Tab(
              text: l.localeName.toLowerCase().startsWith('es')
                  ? 'Este mes'
                  : 'This month'),
          Tab(
              text: l.localeName.toLowerCase().startsWith('es')
                  ? 'Historial'
                  : 'History'),
        ],
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

class _ClientReceiptStatsBoxState extends State<_ClientReceiptStatsBox> {
  Receipt? _previewingReceipt;
  final Set<String> _collapsedReceiptMonths = <String>{};
  bool _historyNewestFirst = true;

  @override
  void didUpdateWidget(covariant _ClientReceiptStatsBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pastReceipts, widget.pastReceipts)) {
      _collapsedReceiptMonths.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final tabs = DefaultTabController.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _buildThisMonthTab(context, isEs, t, cs),
              _buildHistoryTab(context, isEs, t, cs),
            ],
          ),
        ),
      ],
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

    final sortedReceipts = List<Receipt>.of(widget.pastReceipts)
      ..sort((a, b) {
        final da = a.issueDate ?? a.registeredAt;
        final db = b.issueDate ?? b.registeredAt;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return _historyNewestFirst ? db.compareTo(da) : da.compareTo(db);
      });
    final groups = <_ReceiptMonthGroup>[];
    for (final r in sortedReceipts) {
      final date = r.issueDate ?? r.registeredAt;
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (groups.isEmpty || groups.last.key != key) {
        groups.add(_ReceiptMonthGroup(
          key: key,
          label: date == null ? '—' : _wizardMonthLabel(date, locale),
        ));
      }
      groups.last.receipts.add(r);
    }
    final items = <Object>[];
    for (final group in groups) {
      items.add(group);
      if (!_collapsedReceiptMonths.contains(group.key)) {
        items.addAll(group.receipts);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: isEs ? 'Historial de recibos ' : 'Receipt history ',
                    children: [
                      TextSpan(
                        text: '(${widget.pastReceipts.length})',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(
                  () => _historyNewestFirst = !_historyNewestFirst,
                ),
                icon: const Icon(Icons.sort_rounded, size: 15),
                label: Text(
                  _historyNewestFirst
                      ? (isEs ? 'Más recientes' : 'Most recent')
                      : (isEs ? 'Más antiguos' : 'Oldest'),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item is _ReceiptMonthGroup) {
                final count = item.receipts.length;
                final collapsible = count > 1;
                final collapsed = _collapsedReceiptMonths.contains(item.key);
                return InkWell(
                  onTap: collapsible
                      ? () => setState(() {
                            if (collapsed) {
                              _collapsedReceiptMonths.remove(item.key);
                            } else {
                              _collapsedReceiptMonths.add(item.key);
                            }
                          })
                      : null,
                  child: Container(
                    height: 30,
                    margin: EdgeInsets.only(top: i == 0 ? 0 : 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: .45),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          item.label,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $count ${isEs ? (count == 1 ? 'recibo' : 'recibos') : (count == 1 ? 'receipt' : 'receipts')}',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        if (collapsible)
                          Icon(
                            collapsed
                                ? Icons.keyboard_arrow_right_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 17,
                            color: cs.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                );
              }
              final r = item as Receipt;
              return _HistoryReceiptItem(
                receipt: r,
                onAudit: () => _showReceiptAuditHistory(r),
                isPreviewing: _previewingReceipt?.id == r.id,
                onPreview: widget.onPreview == null
                    ? null
                    : () async {
                        setState(() => _previewingReceipt = r);
                        try {
                          await widget.onPreview!(r);
                        } finally {
                          if (mounted) {
                            setState(() => _previewingReceipt = null);
                          }
                        }
                      },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showReceiptAuditHistory(Receipt receipt) async {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Historial del recibo' : 'Receipt history'),
        content: FutureBuilder<Map<String, dynamic>>(
          future: ReceiptsApi().getHistory(receipt.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                width: 320,
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                width: 320,
                child: Text(isEs
                    ? 'No se pudo cargar el historial.'
                    : 'Could not load the history.'),
              );
            }
            final raw = snapshot.data?['history'];
            final entries = raw is List
                ? raw
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];
            if (entries.isEmpty) {
              return SizedBox(
                width: 320,
                child: Text(isEs
                    ? 'Aún no hay cambios registrados.'
                    : 'No changes recorded yet.'),
              );
            }
            final dateFormat =
                DateFormat.yMMMd(Localizations.localeOf(context).toString())
                    .add_Hm();
            return SizedBox(
              width: 420,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (_, index) {
                  final entry = entries[index];
                  final changedAt =
                      DateTime.tryParse('${entry['changedAt'] ?? ''}')
                          ?.toLocal();
                  final actor = (entry['userName'] ?? '').toString().trim();
                  final field = (entry['field'] ?? '').toString();
                  final reason = (entry['reason'] ?? '').toString().trim();
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_note_rounded),
                    title: Text(
                        field.isEmpty ? (isEs ? 'Cambio' : 'Change') : field),
                    subtitle: Text([
                      if (changedAt != null) dateFormat.format(changedAt),
                      if (actor.isNotEmpty) '${isEs ? 'por' : 'by'} $actor',
                      if (reason.isNotEmpty) reason,
                    ].join(' · ')),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isEs ? 'Cerrar' : 'Close'),
          ),
        ],
      ),
    );
  }
}

class _ReceiptMonthGroup {
  _ReceiptMonthGroup({required this.key, required this.label});

  final String key;
  final String label;
  final List<Receipt> receipts = <Receipt>[];
}

class _HistoryReceiptItem extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onPreview;
  final VoidCallback? onAudit;
  final bool isPreviewing;

  const _HistoryReceiptItem({
    required this.receipt,
    this.onPreview,
    this.onAudit,
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
    final concepts = receipt.lines
        .map((line) => line.description.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final concept = concepts.isEmpty
        ? (isEs ? 'Sin concepto' : 'No concept')
        : concepts.first;
    final extraConcepts = concepts.length - 1;
    final amount = receipt.total == null
        ? '—'
        : NumberFormat.currency(
            locale: l.localeName,
            symbol: '€',
            decimalDigits: 2,
          ).format(receipt.total);
    final amountWidth = MediaQuery.sizeOf(context).width < 360 ? 74.0 : 94.0;
    final effectivePreview = isIssued ? onPreview : null;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: .24),
            ),
          ),
        ),
        child: InkWell(
          onTap: effectivePreview,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                number,
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                dateLabel,
                                style: t.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Tooltip(
                          message:
                              concepts.isEmpty ? concept : concepts.join('\n'),
                          child: Text(
                            extraConcepts > 0
                                ? '$concept +$extraConcepts ${isEs ? 'conceptos' : 'concepts'}'
                                : concept,
                            style: t.bodySmall.copyWith(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: amountWidth,
                    child: Text(
                      amount,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (effectivePreview != null)
                    isPreviewing
                        ? SizedBox.square(
                            dimension: 40,
                            child: Center(
                              child: SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: effectivePreview,
                            icon: const Icon(Icons.visibility_outlined),
                            iconSize: 16,
                            tooltip: isEs ? 'Vista previa' : 'Preview',
                            color: cs.primary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 40,
                              height: 40,
                            ),
                          ),
                  if (onAudit != null)
                    IconButton(
                      onPressed: onAudit,
                      icon: const Icon(Icons.history_rounded),
                      iconSize: 16,
                      tooltip: isEs ? 'Ver cambios' : 'View changes',
                      color: cs.onSurfaceVariant,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
