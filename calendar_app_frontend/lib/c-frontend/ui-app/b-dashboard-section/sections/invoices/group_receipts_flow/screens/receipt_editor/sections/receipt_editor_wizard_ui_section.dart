part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardUiSection on _ReceiptEditorWizardScreenState {
  Widget _buildStepIndicator(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedClientName = _resolvedClientName;
    final labels = [
      l.invoiceBillToLabel,
      l.receiptLinesTitle,
      l.receiptSummaryTitle,
      l.preview,
    ];
    final icons = [
      Icons.person_outline,
      Icons.format_list_bulleted_outlined,
      Icons.summarize_outlined,
      Icons.picture_as_pdf_outlined,
    ];
    final totalSteps = labels.length;

    return Row(
      children: [
        // ── Connected stepper ──────────────────────────────────────────────
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: List.generate(totalSteps * 2 - 1, (i) {
                // Odd indices → connector lines between steps
                if (i.isOdd) {
                  final stepIndex = i ~/ 2;
                  final filled = stepIndex < _step;
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: filled
                            ? cs.primary.withValues(alpha: 0.5)
                            : cs.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }

                // Even indices → step node
                final index = i ~/ 2;
                final active = index == _step;
                final complete = index < _step;
                final canTap = index <= _step || index == _step + 1;

                return GestureDetector(
                  onTap: canTap ? () => _tryGoToStep(index) : null,
                  child: MouseRegion(
                    cursor: canTap
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Step circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: complete
                                  ? cs.primary
                                  : active
                                      ? cs.primary
                                      : cs.surfaceContainerHighest
                                          .withValues(alpha: 0.8),
                              border: Border.all(
                                color: active || complete
                                    ? cs.primary
                                    : cs.outlineVariant.withValues(alpha: 0.4),
                                width: active ? 2 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: complete
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: cs.onPrimary,
                                    )
                                  : active
                                      ? Icon(
                                          icons[index],
                                          size: 13,
                                          color: cs.onPrimary,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                            ),
                          ),
                          // Label (only for active / complete)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: active
                                ? Padding(
                                    padding: const EdgeInsets.only(left: 7),
                                    child: Text(
                                      labels[index],
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // ── Client badge ───────────────────────────────────────────────────
        if (selectedClientName.isNotEmpty) ...[
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      selectedClientName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: cs.tertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    selectedClientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.tertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientStep(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final client = _selectedClient;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    Widget sourceSelector() {
      return SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<bool>(
            value: false,
            icon: const Icon(Icons.people_alt_outlined, size: 16),
            label: Text(isEs ? 'Cliente existente' : 'Existing client'),
          ),
          ButtonSegment<bool>(
            value: true,
            icon: const Icon(Icons.edit_note_outlined, size: 16),
            label: Text(isEs ? 'Cliente manual' : 'Manual client'),
          ),
        ],
        selected: {_useManualClient},
        onSelectionChanged: (values) {
          final manual = values.first;
          setState(() {
            _useManualClient = manual;
            if (manual) {
              _clientId = null;
              _clientIssuedCount = 0;
              _clientDraftCount = 0;
              _clientPastReceipts = [];
            } else {
              _clientNameCtrl.clear();
            }
            _markDraftDirty();
          });
        },
      );
    }

    // ── Left: search + list card ───────────────────────────────────────────
    Widget listCard({required double listHeight}) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card header
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
                      '${widget.clients.length}',
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
                  clients: widget.clients,
                  selectedClientId: _clientId,
                  onClientChanged: (value) {
                    setState(() {
                      _useManualClient = false;
                      _clientId = value;
                      _clientNameCtrl.clear();
                      _markDraftDirty();
                    });
                    _loadClientReceiptStats(value);
                  },
                  useDefaultPropertyKind: false,
                  showAdvancedFilters: false,
                  maxListHeight: listHeight,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget manualCard() {
      return Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEs ? 'Cliente manual' : 'Manual client',
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              isEs
                  ? 'Crea un recibo sin guardar el cliente en la base de datos.'
                  : 'Create a receipt without saving a client record.',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientNameCtrl,
              decoration: InputDecoration(
                labelText: isEs ? 'Nombre del cliente' : 'Client name',
                hintText: isEs
                    ? 'Nombre que aparecerá en el recibo'
                    : 'Name shown on the receipt',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (_) {
                setState(() => _markDraftDirty());
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _clientNameCtrl.text.trim().isEmpty
                  ? null
                  : () => _tryGoToStep(1),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                isEs
                    ? 'Continuar → Líneas de recibo'
                    : 'Continue → Receipt lines',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      );
    }

    // ── Right: preview panel ───────────────────────────────────────────────
    Widget previewCard() {
      final manualName = _clientNameCtrl.text.trim();
      final hasManualClient = _useManualClient && manualName.isNotEmpty;
      final hasDisplayClient = client != null || hasManualClient;
      final displayName = hasManualClient ? manualName : client?.name ?? '';
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: hasDisplayClient
              ? cs.primary.withValues(alpha: 0.04)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDisplayClient
                ? cs.primary.withValues(alpha: 0.28)
                : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: !hasDisplayClient
            // ── Empty state
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
            // ── Selected client
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar + name
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
                                displayName.trim().isEmpty
                                    ? '?'
                                    : displayName.trim()[0].toUpperCase(),
                                style: t.titleLarge.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
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

                    // Meta chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (client != null &&
                            (client.email ?? '').trim().isNotEmpty)
                          _WizardClientChip(
                            icon: Icons.email_outlined,
                            label: client.email!.trim(),
                          ),
                        if (client != null &&
                            (client.phone ?? '').trim().isNotEmpty)
                          _WizardClientChip(
                            icon: Icons.phone_outlined,
                            label: client.phone!.trim(),
                          ),
                        if (client != null &&
                            (client.entityType ?? '').trim().isNotEmpty)
                          _WizardClientChip(
                            icon: Icons.business_outlined,
                            label: client.entityType!.trim(),
                          ),
                        if (client != null &&
                            (client.propertyKind ?? '').trim().isNotEmpty)
                          _WizardClientChip(
                            icon: Icons.home_work_outlined,
                            label: client.propertyKind!.trim(),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Client receipt stats this month ──────────────────
                    if (client != null)
                      Expanded(
                        child: _ClientReceiptStatsBox(
                          issuedCount: _clientIssuedCount,
                          draftCount: _clientDraftCount,
                          loading: _loadingReceiptStats,
                          pastReceipts: _clientPastReceipts,
                          onPreview: _previewHistoricalReceipt,
                        ),
                      )
                    else
                      const Spacer(),

                    const SizedBox(height: 12),

                    // CTA
                    FilledButton.icon(
                      onPressed: () => _tryGoToStep(1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        isEs
                            ? 'Continuar → Líneas de recibo'
                            : 'Continue → Receipt lines',
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

    // ── Responsive layout ──────────────────────────────────────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        const panelHeight = 560.0;

        if (!wide) {
          // Narrow: single column, list + inline CTA
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sourceSelector(),
              const SizedBox(height: 10),
              SizedBox(
                height: panelHeight,
                child:
                    _useManualClient ? manualCard() : listCard(listHeight: 430),
              ),
              if (_hasClient) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _tryGoToStep(1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    isEs
                        ? 'Continuar → Líneas de recibo'
                        : 'Continue → Receipt lines',
                  ),
                ),
              ],
            ],
          );
        }

        // Wide: 2-column
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: sourceSelector(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: panelHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _useManualClient
                        ? manualCard()
                        : listCard(listHeight: 430),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: previewCard(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
                      : () => setState(() {
                            _lines.add(ReceiptLineDraft.empty());
                            _markDraftDirty();
                          }),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptSummaryTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      _savingDraft ? null : _syncDraftForPreviewFromSummary,
                  icon: _savingDraft
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_outlined),
                  label: Text(
                    l.localeName.startsWith('es')
                        ? 'Guardar para vista previa'
                        : 'Save for preview',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            row(
              label: l.invoiceBillToLabel,
              value: _resolvedClientName.isEmpty ? '-' : _resolvedClientName,
            ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: summary + actions ───────────────────────────────────
            Expanded(
              flex: 4,
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
                        style: t.bodySmall.copyWith(color: cs.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: canRenderPreview
                        ? () => _loadDraftPreview(receiptId: _draftReceipt!.id)
                        : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.preview),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
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
                ],
              ),
            ),
            const SizedBox(width: 16),
            // ── Right: PDF preview ────────────────────────────────────────
            Expanded(
              flex: 6,
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

// ── Helper widgets ─────────────────────────────────────────────────────────────

String _wizardMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
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
