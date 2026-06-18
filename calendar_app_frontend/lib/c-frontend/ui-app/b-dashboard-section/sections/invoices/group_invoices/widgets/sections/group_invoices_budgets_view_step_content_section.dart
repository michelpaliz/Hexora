part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewStepContentSection
    on _GroupInvoicesBudgetsViewState {
  Widget _buildIssuedEditReasonPanel(
    ColorScheme cs, {
    required bool reviewMode,
  }) {
    final hasReason = _issuedEditReasonCtrl.text.trim().isNotEmpty;
    final title = _isSpanishLocale ? 'Motivo del cambio' : 'Change reason';
    final subtitle = reviewMode
        ? (_isSpanishLocale
            ? 'Revisa o actualiza el motivo antes de guardar la nueva version.'
            : 'Review or update the reason before saving the new version.')
        : (_isSpanishLocale
            ? 'Indica por que se modifica este presupuesto emitido para poder continuar.'
            : 'Add why this issued presupuesto is changing before continuing.');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.18),
            cs.surfaceContainerHighest.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasReason
              ? cs.primary.withValues(alpha: 0.32)
              : cs.secondary.withValues(alpha: 0.48),
          width: hasReason ? 1 : 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 19,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: hasReason
                      ? cs.primary.withValues(alpha: 0.14)
                      : cs.secondary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasReason
                      ? (_isSpanishLocale ? 'Listo' : 'Ready')
                      : (_isSpanishLocale ? 'Obligatorio' : 'Required'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: hasReason ? cs.primary : cs.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _issuedEditReasonCtrl,
            minLines: reviewMode ? 2 : 3,
            maxLines: 5,
            onChanged: (_) => setState(() {
              _markDraftDirty();
              _error = null;
            }),
            decoration: InputDecoration(
              hintText: _isSpanishLocale
                  ? 'Ej. Se aplica descuento por acuerdo con el cliente...'
                  : 'E.g. Discount applied after client agreement...',
              prefixIcon: Icon(
                Icons.short_text_rounded,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              alignLabelWithHint: true,
              filled: true,
              fillColor: cs.surface.withValues(alpha: 0.45),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide(color: cs.primary, width: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ColorScheme cs, AppLocalizations l) {
    if (_visibleStep == 0) {
      final isExisting = _clientSource == _ClientSource.existing;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Info banner ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.budgetClientInfoPrompt,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Type selector ──────────────────────────────────────────────
          Row(
            children: [
              _clientTypeOption(
                cs: cs,
                icon: Icons.group_outlined,
                label: 'Cliente existente',
                sublabel: 'De tu base de datos',
                selected: isExisting,
                onTap: !_isDraftEditable
                    ? () {}
                    : () => setState(() {
                          _clientSource = _ClientSource.existing;
                          _selectedClientId = null;
                          _clientNameCtrl.clear();
                          _clientAddressCtrl.clear();
                          _clientCityCtrl.clear();
                          _clientPostalCodeCtrl.clear();
                          _markDraftDirty();
                          _error = null;
                        }),
              ),
              const SizedBox(width: 10),
              _clientTypeOption(
                cs: cs,
                icon: Icons.edit_outlined,
                label: 'Cliente manual',
                sublabel: 'Solo nombre, sin ID',
                selected: !isExisting,
                onTap: !_isDraftEditable
                    ? () {}
                    : () => setState(() {
                          _clientSource = _ClientSource.manual;
                          _selectedClientId = null;
                          _clientNameCtrl.clear();
                          _clientAddressCtrl.clear();
                          _clientCityCtrl.clear();
                          _clientPostalCodeCtrl.clear();
                          _markDraftDirty();
                          _error = null;
                        }),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Content area ───────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: isExisting
                ? IgnorePointer(
                    ignoring: !_isDraftEditable,
                    child: Opacity(
                      opacity: _isDraftEditable ? 1 : 0.7,
                      child: _buildExistingClientLayout(cs),
                    ),
                  )
                : Column(
                    key: const ValueKey('manual'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Input card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: cs.secondary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.person_add_outlined,
                                      size: 14, color: cs.secondary),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Nombre del cliente',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _clientNameCtrl,
                              enabled: _isDraftEditable,
                              autofocus: true,
                              style: const TextStyle(fontSize: 13),
                              onChanged: (_) => setState(() {
                                _markDraftDirty();
                                _error = null;
                              }),
                              decoration: InputDecoration(
                                labelText: l.budgetClientNameLabel,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.business_outlined,
                                  size: 16,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 0),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 11),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.4)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: BorderSide(
                                      color:
                                          cs.secondary.withValues(alpha: 0.7),
                                      width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _clientAddressCtrl,
                                    enabled: _isDraftEditable,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => setState(() {
                                      _markDraftDirty();
                                      _error = null;
                                    }),
                                    decoration: _manualClientInputDecoration(
                                      context: context,
                                      label: 'Dirección',
                                      icon: Icons.location_on_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _clientCityCtrl,
                                    enabled: _isDraftEditable,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => setState(() {
                                      _markDraftDirty();
                                      _error = null;
                                    }),
                                    decoration: _manualClientInputDecoration(
                                      context: context,
                                      label: 'Ciudad',
                                      icon: Icons.location_city_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: _clientPostalCodeCtrl,
                                    enabled: _isDraftEditable,
                                    style: const TextStyle(fontSize: 13),
                                    onChanged: (_) => setState(() {
                                      _markDraftDirty();
                                      _error = null;
                                    }),
                                    decoration: _manualClientInputDecoration(
                                      context: context,
                                      label: 'CP',
                                      icon: Icons.markunread_mailbox_outlined,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tip row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color:
                              cs.surfaceContainerHighest.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined,
                                size: 13,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.55)),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'El PDF mostrará el nombre manual y, si los completas, la dirección y ciudad.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }

    if (_visibleStep == 1) {
      // ── Step 1: Detalles (date, currency, notes) ─────────────────────────
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 15, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isSpanishLocale
                        ? 'Ajusta la fecha de emisión, la moneda y añade notas internas opcionales.'
                        : 'Set the issue date, currency, and add optional internal notes.',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSpanishLocale ? 'Datos generales' : 'General details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // ── Date picker chip ──────────────────────────────────
                    Expanded(
                      child: _DatePickerChip(
                        date: _budgetIssueDate,
                        locale: l.localeName,
                        enabled: _isDraftEditable || _isIssuedEditable,
                        labelEs: 'Fecha de emisión',
                        labelEn: 'Issue date',
                        onPicked: (picked) => setState(() {
                          _budgetIssueDate = picked;
                          _markDraftDirty();
                          _error = null;
                        }),
                        cs: cs,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ── Currency ──────────────────────────────────────────
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _budgetCurrencyCtrl,
                        enabled: _isDraftEditable,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z]')),
                          LengthLimitingTextInputFormatter(3),
                        ],
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        onChanged: (_) => setState(() {
                          _markDraftDirty();
                          _error = null;
                        }),
                        decoration: InputDecoration(
                          labelText: _isSpanishLocale ? 'Moneda' : 'Currency',
                          labelStyle: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                          prefixIcon: Icon(Icons.currency_exchange_rounded,
                              size: 14,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 36),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                                color: cs.secondary.withValues(alpha: 0.7),
                                width: 1.5),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.15)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ── Notes ────────────────────────────────────────────────
                TextField(
                  controller: _budgetNotesCtrl,
                  enabled: _isDraftEditable || _isIssuedEditable,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setState(() {
                    _markDraftDirty();
                    _error = null;
                  }),
                  decoration: InputDecoration(
                    labelText: _isSpanishLocale ? 'Notas' : 'Notes',
                    labelStyle:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    alignLabelWithHint: true,
                    hintText: _isSpanishLocale
                        ? 'Observaciones internas del presupuesto…'
                        : 'Internal notes for this budget…',
                    hintStyle: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    prefixIcon: Padding(
                      padding:
                          const EdgeInsets.only(left: 10, right: 6, top: 10),
                      child: Icon(Icons.notes_rounded,
                          size: 15,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                          color: cs.secondary.withValues(alpha: 0.7),
                          width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
                if (_isIssuedEditable) ...[
                  const SizedBox(height: 10),
                  _buildIssuedEditReasonPanel(cs, reviewMode: false),
                ] else if (!_isDraftEditable) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 5),
                      Text(
                        _isSpanishLocale
                            ? 'Este presupuesto no se puede editar.'
                            : 'This presupuesto cannot be edited.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (_visibleStep == 2) {
      final total = _budgetTotalAfterDiscount;
      final editorHeight = (MediaQuery.sizeOf(context).height - 150)
          .clamp(640.0, 920.0)
          .toDouble();
      return IgnorePointer(
        ignoring: !(_isDraftEditable || _isIssuedEditable),
        child: Opacity(
          opacity: (_isDraftEditable || _isIssuedEditable) ? 1 : 0.7,
          child: SizedBox(
            height: editorHeight,
            child: InvoiceContentSection(
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
              discountConfig: InvoiceContentDiscountConfig(
                readOnly: !_isDraftEditable,
                usePercent: _useBudgetDiscountPercent,
                amountCtrl: _budgetDiscountAmountCtrl,
                percentCtrl: _budgetDiscountPercentCtrl,
                effectiveDiscountAmount: _budgetEffectiveDiscountAmount,
                total: _budgetTotalAfterDiscount,
                onModePercentChanged: _setBudgetDiscountModePercent,
                onAmountChanged: _setBudgetDiscountAmountText,
                onPercentChanged: _setBudgetDiscountPercentText,
              ),
              jsonImportLoading: _jsonImportLoading,
              jsonPromptLoading: _jsonPromptLoading,
              jsonImportFileName: _jsonImportFileName,
              jsonImportErrorText: _jsonImportError,
              onPickJsonImportFile: _pickBudgetJsonFile,
              onClearJsonImportFile: _clearBudgetJsonFile,
              onClearJsonImportError: () =>
                  setState(() => _jsonImportError = null),
              onImportJsonFromText: (rawText,
                      {required bool overwrite,
                      required double defaultTaxRate}) =>
                  _importBudgetJsonFromText(
                rawText,
                overwrite: overwrite,
                defaultTaxRate: defaultTaxRate,
              ),
              onImportJsonFromFile: (
                      {required bool overwrite,
                      required double defaultTaxRate}) =>
                  _importBudgetJsonFromFile(
                overwrite: overwrite,
                defaultTaxRate: defaultTaxRate,
              ),
              onCopyJsonPrompt: _copyBudgetPromptTemplate,
              jsonTextValidator: _validateBudgetJsonShape,
              onPickImageForLineExtraction: _pickBudgetExtractFile,
              onApplyExtractedLines: _extractedBlocks.isEmpty
                  ? null
                  : () => _importExtractedBudgetBlocks(
                        overwrite: false,
                        defaultTaxRate: 21,
                      ),
              onClearExtractedLines: _clearBudgetExtractedBlocks,
              showSaveDraftButton: false,
            ),
          ),
        ),
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
      final clientDisplay = resolvedClient.isEmpty ? '-' : resolvedClient;
      final numberDisplay =
          _issuedPresupuestoNumber ?? l.budgetNumberPendingIssue;
      final draftDisplay = _draftId ?? '-';
      final linesDisplay = _billableItemsCount.toString();

      // Summary rows data
      final summaryRows = [
        (Icons.person_outline_rounded, 'Cliente', clientDisplay),
        (Icons.tag_rounded, 'Número', numberDisplay),
        (Icons.article_outlined, 'ID borrador', draftDisplay),
        (Icons.format_list_numbered_rounded, 'Líneas', linesDisplay),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Info banner ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 15, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.budgetInfoBanner,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary card ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // Card header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt_long_outlined,
                            size: 14, color: cs.secondary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Resumen del presupuesto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                // Rows
                ...summaryRows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Icon(row.$1,
                                size: 14,
                                color:
                                    cs.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            Text(
                              row.$2,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              row.$3,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < summaryRows.length - 1)
                        Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: cs.outlineVariant.withValues(alpha: 0.12)),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Confirmation toggle ──────────────────────────────────────────
          if (_isIssuedEditable) ...[
            _buildIssuedEditReasonPanel(cs, reviewMode: true),
            const SizedBox(height: 16),
          ],

          GestureDetector(
            onTap: () => setState(() {
              _confirmPreview = !_confirmPreview;
              _error = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _confirmPreview
                    ? cs.secondary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _confirmPreview
                      ? cs.secondary.withValues(alpha: 0.45)
                      : cs.outlineVariant.withValues(alpha: 0.3),
                  width: _confirmPreview ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                          _confirmPreview ? cs.secondary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _confirmPreview
                            ? cs.secondary
                            : cs.outlineVariant.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: _confirmPreview
                        ? Icon(Icons.check_rounded,
                            size: 14, color: cs.onSecondary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.budgetPreviewAcceptLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _confirmPreview ? FontWeight.w600 : FontWeight.w400,
                        color: _confirmPreview ? cs.secondary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final previewId = (_draftId ?? '').trim();
    final previewLabel = (_issuedPresupuestoNumber ?? '').trim().isNotEmpty
        ? _issuedPresupuestoNumber!.trim()
        : (previewId.isEmpty ? '-' : previewId);
    return _buildPreviewStepV2(cs, l, previewId, previewLabel);
    // ignore: dead_code
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: title + actions ─────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.budgetPreviewAutoTitle(previewLabel),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 14),
              if (_previewError != null && _previewError!.isNotEmpty) ...[
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
                ),
                const SizedBox(height: 12),
              ],
              if (_previewPdfBytes == null && !_loadingPreview)
                OutlinedButton.icon(
                  onPressed:
                      _issuing ? null : () => _createDraftAndPreparePreview(),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l.budgetPreviewOpenCta),
                ),
              if (_previewPdfBytes != null) ...[
                OutlinedButton.icon(
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
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        // ── Right: PDF preview ────────────────────────────────────────────
        Expanded(
          flex: 6,
          child: _loadingPreview
              ? const SizedBox(
                  height: 520,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _previewPdfBytes != null
                  ? PdfInlinePreview(
                      bytes: Uint8List.fromList(_previewPdfBytes!),
                      height: 520,
                    )
                  : _budgetPreviewWidget(l),
        ),
      ],
    );
  }

  Widget _buildPreviewStepV2(
    ColorScheme cs,
    AppLocalizations l,
    String previewId,
    String previewLabel,
  ) {
    final rows = _previewRows();
    final total = _previewTotal();
    final money = NumberFormat.currency(locale: l.localeName, symbol: '€');

    Widget metricCard({
      required IconData icon,
      required String label,
      required String value,
      Color? accent,
    }) {
      final color = accent ?? cs.primary;
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.24)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.16),
                cs.secondary.withValues(alpha: 0.08),
                cs.surfaceContainerHighest.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: cs.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSpanishLocale ? 'Revisión final' : 'Final review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSpanishLocale
                          ? 'Comprueba el PDF y guarda esta versión cuando todo esté correcto.'
                          : 'Check the PDF and save this version when everything looks right.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
                ),
                child: Text(
                  previewLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      metricCard(
                        icon: Icons.format_list_bulleted_rounded,
                        label: _isSpanishLocale ? 'Líneas' : 'Lines',
                        value: '${rows.length}',
                      ),
                      const SizedBox(width: 10),
                      metricCard(
                        icon: Icons.payments_outlined,
                        label: 'Total',
                        value: money.format(total),
                        accent: cs.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 17, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              _isSpanishLocale
                                  ? 'Resumen del contenido'
                                  : 'Content summary',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (rows.isEmpty)
                          Text(
                            _isSpanishLocale
                                ? 'Sin líneas para previsualizar.'
                                : 'No lines to preview.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          )
                        else
                          ...rows.take(6).map((row) {
                            final label = row['label']?.toString() ?? '-';
                            final qty = row['qty'];
                            final unitPrice = row['unitPrice'];
                            final discountRate =
                                (row['discountRate'] as num?) ?? 0;
                            final lineTotal = row['total'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$qty x ${money.format(unitPrice)}'
                                          '${discountRate > 0 ? ' · Dto. $discountRate%' : ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    money.format(lineTotal),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        if (rows.length > 6)
                          Text(
                            '+${rows.length - 6}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_previewError != null && _previewError!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: cs.error.withValues(alpha: 0.32)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 18, color: cs.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _previewError!,
                              style: TextStyle(color: cs.error),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _loadPreviewPdf(force: true),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(l.tryAgain),
                          ),
                        ],
                      ),
                    ),
                  if (_previewError == null || _previewError!.isEmpty)
                    FilledButton.icon(
                      onPressed: _loadingPreview || _issuing
                          ? null
                          : _previewPdfBytes == null
                              ? () => _createDraftAndPreparePreview()
                              : () async {
                                  final fileName = previewId.isEmpty
                                      ? 'presupuesto-preview.pdf'
                                      : 'presupuesto-$previewId-preview.pdf';
                                  await pdf_launcher.launchPdfPreview(
                                    Uint8List.fromList(_previewPdfBytes!),
                                    fileName: fileName,
                                  );
                                },
                      icon: Icon(_previewPdfBytes == null
                          ? Icons.visibility_outlined
                          : Icons.open_in_new_outlined),
                      label: Text(l.budgetPreviewOpenCta),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                child: _loadingPreview
                    ? const SizedBox(
                        height: 620,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _previewPdfBytes != null
                        ? PdfInlinePreview(
                            bytes: Uint8List.fromList(_previewPdfBytes!),
                            height: 620,
                          )
                        : _budgetPreviewWidget(l),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _clientTypeOption({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? cs.secondary.withValues(alpha: 0.08)
                : cs.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? cs.secondary.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.25),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected
                      ? cs.secondary.withValues(alpha: 0.14)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: selected ? cs.secondary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.secondary : cs.onSurface,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant
                            .withValues(alpha: selected ? 0.8 : 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: cs.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 11, color: cs.onSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _manualClientInputDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      ),
      prefixIcon: Icon(
        icon,
        size: 16,
        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: cs.secondary.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildExistingClientLayout(ColorScheme cs) {
    final t = AppTypography.of(context);
    final isEs = _isSpanishLocale;
    final selectedClient = _selectedClientId == null
        ? null
        : widget.clients.cast<GroupClient?>().firstWhere(
              (c) => c?.id == _selectedClientId,
              orElse: () => null,
            );

    Widget listCard({required double maxListHeight}) {
      return Container(
        key: const ValueKey('existing'),
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
                    isEs ? 'Selecciona cliente' : 'Select client',
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
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
                  selectedClientId: _selectedClientId,
                  onClientChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                      _markDraftDirty();
                      _error = null;
                    });
                    _loadClientBudgetStats(value);
                  },
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
                        child: Icon(Icons.person_search_outlined,
                            size: 26,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
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
                          _BudgetClientChip(
                              icon: Icons.email_outlined,
                              label: selectedClient.email!.trim()),
                        if ((selectedClient.phone ?? '').trim().isNotEmpty)
                          _BudgetClientChip(
                              icon: Icons.phone_outlined,
                              label: selectedClient.phone!.trim()),
                        if ((selectedClient.entityType ?? '').trim().isNotEmpty)
                          _BudgetClientChip(
                              icon: Icons.business_outlined,
                              label: selectedClient.entityType!.trim()),
                        if ((selectedClient.propertyKind ?? '')
                            .trim()
                            .isNotEmpty)
                          _BudgetClientChip(
                              icon: Icons.home_work_outlined,
                              label: selectedClient.propertyKind!.trim()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _BudgetClientStatsBox(
                        issuedCount: _clientBudgetIssuedCount,
                        draftCount: _clientBudgetDraftCount,
                        loading: _loadingClientBudgetStats,
                        pastBudgets: _clientPastBudgets,
                        onPreview: _previewHistoricalBudget,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        if (_validateCurrentStep()) _setVisibleStep(1);
                      }),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        isEs ? 'Continuar → Detalles' : 'Continue → Details',
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 430,
                child: listCard(maxListHeight: 340),
              ),
              if (selectedClient != null) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => setState(() {
                    if (_validateCurrentStep()) _setVisibleStep(1);
                  }),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                      isEs ? 'Continuar → Detalles' : 'Continue → Details'),
                ),
              ],
            ],
          );
        }
        return SizedBox(
          height: 460,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  flex: 3, child: listCard(maxListHeight: double.infinity)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: previewCard()),
            ],
          ),
        );
      },
    );
  }
}

// ─── Date picker chip ─────────────────────────────────────────────────────────

class _DatePickerChip extends StatefulWidget {
  const _DatePickerChip({
    required this.date,
    required this.locale,
    required this.enabled,
    required this.labelEs,
    required this.labelEn,
    required this.onPicked,
    required this.cs,
  });

  final DateTime? date;
  final String locale;
  final bool enabled;
  final String labelEs;
  final String labelEn;
  final ValueChanged<DateTime> onPicked;
  final ColorScheme cs;

  @override
  State<_DatePickerChip> createState() => _DatePickerChipState();
}

class _DatePickerChipState extends State<_DatePickerChip> {
  bool _hovered = false;

  bool get _isEs => Localizations.localeOf(context)
      .languageCode
      .toLowerCase()
      .startsWith('es');

  Future<void> _pick() async {
    if (!widget.enabled) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    widget.onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final hasDate = widget.date != null;
    final label = _isEs ? widget.labelEs : widget.labelEn;
    final dateText = hasDate
        ? DateFormat.yMMMd(widget.locale).format(widget.date!.toLocal())
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? _pick : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: hasDate
                ? cs.secondary.withValues(alpha: _hovered ? 0.12 : 0.07)
                : (_hovered && widget.enabled
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.25)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: hasDate
                  ? cs.secondary.withValues(alpha: _hovered ? 0.6 : 0.4)
                  : cs.outlineVariant
                      .withValues(alpha: widget.enabled ? 0.35 : 0.2),
              width: hasDate ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Calendar icon box
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasDate
                      ? cs.secondary.withValues(alpha: 0.12)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: hasDate
                      ? cs.secondary
                      : cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              // Label + value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasDate
                            ? cs.secondary.withValues(alpha: 0.8)
                            : cs.onSurfaceVariant.withValues(alpha: 0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateText ?? (_isEs ? 'Seleccionar fecha' : 'Select date'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: hasDate ? FontWeight.w700 : FontWeight.w400,
                        color: hasDate
                            ? cs.secondary
                            : cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              // Edit indicator
              if (widget.enabled)
                Icon(
                  Icons.edit_calendar_outlined,
                  size: 14,
                  color: hasDate
                      ? cs.secondary.withValues(alpha: 0.6)
                      : cs.onSurfaceVariant.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Budget client panel helpers ──────────────────────────────────────────────

String _budgetMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
}

class _BudgetClientChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BudgetClientChip({required this.icon, required this.label});

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

class _BudgetClientStatsBox extends StatefulWidget {
  final int issuedCount;
  final int draftCount;
  final bool loading;
  final List<Map<String, dynamic>> pastBudgets;
  final Future<void> Function(Map<String, dynamic>)? onPreview;

  const _BudgetClientStatsBox({
    required this.issuedCount,
    required this.draftCount,
    required this.loading,
    required this.pastBudgets,
    this.onPreview,
  });

  @override
  State<_BudgetClientStatsBox> createState() => _BudgetClientStatsBoxState();
}

class _BudgetClientStatsBoxState extends State<_BudgetClientStatsBox>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Map<String, dynamic>? _previewingBudget;

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
              overlayColor:
                  WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.06)),
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
                      if (widget.pastBudgets.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${widget.pastBudgets.length}',
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
                _buildThisMonthTab(isEs, t, cs),
                _buildHistoryTab(context, isEs, t, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisMonthTab(bool isEs, AppTypography t, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEs ? 'Presupuestos este mes' : 'Budgets this month',
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
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _BudgetStatCell(
                    label: isEs ? 'Emitidos' : 'Issued',
                    count: widget.issuedCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BudgetStatCell(
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

    if (widget.pastBudgets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            isEs ? 'Sin presupuestos anteriores' : 'No previous budgets',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    DateTime? budgetDate(Map<String, dynamic> b) {
      final v = b['registeredAt'] ?? b['issueDate'] ?? b['createdAt'];
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    final items = <Object>[];
    String? lastKey;
    for (final b in widget.pastBudgets) {
      final date = budgetDate(b);
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (key != lastKey) {
        items.add(date == null ? '—' : _budgetMonthLabel(date, locale));
        lastKey = key;
      }
      items.add(b);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) {
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 10, bottom: 4),
            child: Text(item,
                style: t.bodySmall.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                )),
          );
        }
        final b = item as Map<String, dynamic>;
        final id = (b['_id'] ?? b['id'] ?? '').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _BudgetHistoryItem(
            budget: b,
            isPreviewing:
                (_previewingBudget?['_id'] ?? _previewingBudget?['id']) == id,
            onPreview: widget.onPreview == null
                ? null
                : () async {
                    setState(() => _previewingBudget = b);
                    try {
                      await widget.onPreview!(b);
                    } finally {
                      if (mounted) setState(() => _previewingBudget = null);
                    }
                  },
          ),
        );
      },
    );
  }
}

class _BudgetStatCell extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _BudgetStatCell({
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
              Text(label,
                  style: t.bodySmall.copyWith(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  )),
              Text('$count',
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetHistoryItem extends StatelessWidget {
  final Map<String, dynamic> budget;
  final VoidCallback? onPreview;
  final bool isPreviewing;

  const _BudgetHistoryItem({
    required this.budget,
    this.onPreview,
    this.isPreviewing = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');

    final status = (budget['status'] ?? '').toString();
    final isIssued = status.contains('issue') || status == 'accepted';

    final rawDate =
        budget['registeredAt'] ?? budget['issueDate'] ?? budget['createdAt'];
    DateTime? date;
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate);
    }
    final dateLabel = date != null
        ? DateFormat.yMMMd(l.localeName).format(date.toLocal())
        : '—';

    final number = (budget['presupuestoNumber'] ?? budget['budgetNumber'] ?? '')
        .toString()
        .trim();
    final displayNumber =
        number.isNotEmpty ? number : (isEs ? 'Borrador' : 'Draft');

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
            isIssued ? Icons.description_outlined : Icons.edit_note_rounded,
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
                  displayNumber,
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
                  style: t.bodySmall
                      .copyWith(fontSize: 10, color: cs.onSurfaceVariant),
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
                        strokeWidth: 2, color: cs.primary),
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
