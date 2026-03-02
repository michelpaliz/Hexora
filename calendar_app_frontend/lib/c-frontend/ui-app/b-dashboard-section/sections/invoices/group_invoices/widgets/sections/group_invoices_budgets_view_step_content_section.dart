part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewStepContentSection
    on _GroupInvoicesBudgetsViewState {
  Widget _buildStepContent(ColorScheme cs, AppLocalizations l) {
    if (_visibleStep == 0) {
      final isExisting = _clientSource == _ClientSource.existing;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.budgetClientInfoPrompt,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de cliente',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<_ClientSource>(
                  segments: const [
                    ButtonSegment(
                      value: _ClientSource.existing,
                      label: Text('Cliente existente'),
                      icon: Icon(Icons.group_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: _ClientSource.manual,
                      label: Text('Cliente manual'),
                      icon: Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                  selected: {_clientSource},
                  onSelectionChanged: (Set<_ClientSource> selection) {
                    setState(() {
                      _clientSource = selection.first;
                      _selectedClientId = null;
                      _clientNameCtrl.clear();
                      _markDraftDirty();
                      _error = null;
                    });
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isExisting) ...[
            Text(
              'Selecciona un cliente registrado. Se enviará el ID completo.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClientSearchSelect(
              clients: widget.clients,
              selectedClientId: _selectedClientId,
              onClientChanged: (value) => setState(() {
                _selectedClientId = value;
                _markDraftDirty();
                _error = null;
              }),
              useDefaultPropertyKind: false,
              maxListHeight: 220,
            ),
          ] else ...[
            Text(
              'Introduce el nombre del cliente manualmente. Solo se guardará el nombre.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _clientNameCtrl,
              onChanged: (_) => setState(() {
                _markDraftDirty();
                _error = null;
              }),
              decoration: InputDecoration(
                labelText: l.budgetClientNameLabel,
                border: const OutlineInputBorder(),
                isDense: true,
                helperText:
                    'El PDF mostrará solo el nombre sin dirección ni datos adicionales',
                helperMaxLines: 2,
              ),
            ),
          ],
        ],
      );
    }

    if (_visibleStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.budgetNumberAutoOnIssue,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            l.budgetConfirmNumberValue(_issuedPresupuestoNumber ?? '-'),
          ),
        ],
      );
    }
    if (_visibleStep == 2) {
      final total = _useBlocks
          ? InvoiceEditorFormatters.totalBlocks(_budgetBlocks)
          : InvoiceEditorFormatters.total(_budgetLines);
      final statusDraft = (_issuedPresupuestoNumber ?? '').trim().isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!statusDraft) ...[
            Text(
              'Este presupuesto ya fue emitido. Al importar se creara un nuevo borrador editable.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: DefaultTabController(
              length: 3,
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
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                unselectedLabelStyle:
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                tabs: [
                  Tab(text: l.invoiceLinesModeManual),
                  Tab(text: l.invoiceLinesModePhoto),
                  Tab(text: l.invoiceLinesModeJson),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_isJsonLinesMode)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinesJsonImportPanel(
                  loading: _jsonImportLoading,
                  loadingPrompt: _jsonPromptLoading,
                  disabled: false,
                  fileName: _jsonImportFileName,
                  errorText: _jsonImportError,
                  onPickFile: _pickBudgetJsonFile,
                  onClearFile: _clearBudgetJsonFile,
                  onImportFromText: _importBudgetJsonFromText,
                  onImportFromFile: _importBudgetJsonFromFile,
                  onCopyPrompt: _copyBudgetPromptTemplate,
                  onClearError: () => setState(() => _jsonImportError = null),
                  textValidator: _validateBudgetJsonShape,
                ),
              ],
            )
          else if (_isPhotoLinesMode)
            _buildBudgetOpenAiExtractPanel(context)
          else
            InvoiceContentSection(
              useBlocks: _useBlocks,
              onModeChanged: (value) => setState(() {
                _useBlocks = value;
                _markDraftDirty();
                _error = null;
              }),
              blocks: _budgetBlocks,
              lines: _budgetLines,
              onChanged: () => setState(() {
                _markDraftDirty();
                _error = null;
              }),
              total: total,
            ),
        ],
      );
    }

    if (_visibleStep == 3) {
      final selectedClient = widget.clients
          .where((c) => c.id == _selectedClientId)
          .cast<GroupClient?>()
          .firstWhere((_) => true, orElse: () => null);
      final resolvedClient = selectedClient?.name.trim().isNotEmpty == true
          ? selectedClient!.name
          : _clientNameCtrl.text.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              l.budgetInfoBanner,
            ),
          ),
          const SizedBox(height: 12),
          Text(l.budgetConfirmClientValue(
              resolvedClient.isEmpty ? '-' : resolvedClient)),
          const SizedBox(height: 6),
          Text(l.budgetConfirmNumberValue(
              _issuedPresupuestoNumber ?? l.budgetNumberPendingIssue)),
          const SizedBox(height: 6),
          Text(l.budgetConfirmDraftIdValue(_draftId ?? '-')),
          const SizedBox(height: 6),
          Text(l.budgetConfirmLinesValue(_billableItemsCount.toString())),
          const SizedBox(height: 10),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _confirmPreview,
            onChanged: (v) => setState(() {
              _confirmPreview = v == true;
              _error = null;
            }),
            title: Text(l.budgetPreviewAcceptLabel),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      );
    }

    final previewId = (_draftId ?? '').trim();
    final previewLabel = (_issuedPresupuestoNumber ?? '').trim().isNotEmpty
        ? _issuedPresupuestoNumber!.trim()
        : (previewId.isEmpty ? '-' : previewId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.budgetPreviewAutoTitle(previewLabel),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (_loadingPreview)
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_previewError != null && _previewError!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.error.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _previewError!,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _loadPreviewPdf(force: true),
                  icon: const Icon(Icons.refresh),
                  label: Text(l.tryAgain),
                ),
              ],
            ),
          )
        else if (_previewPdfBytes != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PdfInlinePreview(
                bytes: Uint8List.fromList(_previewPdfBytes!),
                height: 480,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final fileName = previewId.isEmpty
                        ? 'presupuesto-preview.pdf'
                        : 'presupuesto-$previewId-preview.pdf';
                    await pdf_launcher.launchPdfPreview(
                      Uint8List.fromList(_previewPdfBytes!),
                      fileName: fileName,
                    );
                  },
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: Text(l.budgetPreviewOpenCta),
                ),
              ),
            ],
          )
        else
          _budgetPreviewWidget(l),
        if ((_previewPdfBytes == null) && !_loadingPreview) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed:
                  _issuing ? null : () => _issueBudgetAndPreparePreview(),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l.budgetPreviewOpenCta),
            ),
          ),
        ],
      ],
    );
  }
}
