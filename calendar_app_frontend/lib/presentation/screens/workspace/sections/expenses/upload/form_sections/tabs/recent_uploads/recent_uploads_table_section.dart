part of '../recent_uploads_tab.dart';

extension _ExpenseRecentUploadsTableSection on _ExpenseRecentUploadsTabState {
  static const double _supplierWidth = 260;
  static const double _invoiceWidth = 132;
  static const double _dateWidth = 112;
  static const double _baseWidth = 118;
  static const double _vatWidth = 96;
  static const double _totalWidth = 124;
  static const double _totalStatusGap = 14;
  static const double _vatStateWidth = 142;
  static const double _actionsWidth = 112;

  double get _expenseTableWidth =>
      _supplierWidth +
      _invoiceWidth +
      (_visibleFinancialColumns.contains(HexoraFinancialColumn.date)
          ? _dateWidth
          : 0) +
      (_visibleFinancialColumns.contains(HexoraFinancialColumn.taxableBase)
          ? _baseWidth
          : 0) +
      (_visibleFinancialColumns.contains(HexoraFinancialColumn.vat)
          ? _vatWidth
          : 0) +
      (_visibleFinancialColumns.contains(HexoraFinancialColumn.total)
          ? _totalWidth + _totalStatusGap
          : 0) +
      _vatStateWidth +
      _actionsWidth +
      32;

  void _applyExpenseColumnFilter(
    VoidCallback change, {
    bool refreshImmediately = false,
  }) {
    final feedbackVersion = ++_columnFilterFeedbackVersion;
    _columnFilterBusy.value = true;
    _updateExpenseColumnFilters(change);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      refreshImmediately ? Duration.zero : const Duration(milliseconds: 300),
      () async {
        final feedbackTimer = Stopwatch()..start();
        await _reloadActiveSummary();
        final remainingFeedback =
            const Duration(milliseconds: 250) - feedbackTimer.elapsed;
        if (remainingFeedback > Duration.zero) {
          await Future<void>.delayed(remainingFeedback);
        }
        if (!mounted || feedbackVersion != _columnFilterFeedbackVersion) {
          return;
        }
        _columnFilterBusy.value = false;
      },
    );
  }

  HexoraHeaderSortDirection? _expenseSortDirection(
    Set<_ExpenseListSortOption> ascending,
    Set<_ExpenseListSortOption> descending,
  ) {
    if (ascending.contains(_selectedSort)) {
      return HexoraHeaderSortDirection.ascending;
    }
    if (descending.contains(_selectedSort)) {
      return HexoraHeaderSortDirection.descending;
    }
    return null;
  }

  Widget _buildExpenseTable(
    List<Map<String, String>> items,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final width =
          _expenseTableWidth.clamp(constraints.maxWidth, double.infinity);
      return Scrollbar(
        thumbVisibility: width > constraints.maxWidth,
        notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Column(
              children: [
                _buildExpenseTableHeader(cs, isSpanish),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outlineVariant.withValues(alpha: .28),
                    ),
                    itemBuilder: (context, index) => _buildExpenseTableRow(
                      context,
                      items[index],
                      l,
                      t,
                      cs,
                      isSpanish,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildExpenseTableHeader(ColorScheme cs, bool isSpanish) {
    final vendorValues = widget.recentUploads
        .map((item) => (item['vendor'] ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return Container(
      key: const ValueKey('expense-table-header'),
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: cs.surfaceContainerHighest.withValues(alpha: .24),
      child: Row(children: [
        HexoraFilterableHeaderCell(
          label: isSpanish ? 'Proveedor' : 'Supplier',
          width: _supplierWidth,
          filterActive: _vendorColumnFilters.isNotEmpty,
          sortDirection: _expenseSortDirection(
            {_ExpenseListSortOption.vendorAz},
            {_ExpenseListSortOption.vendorZa},
          ),
          menuBuilder: (_) => HexoraColumnFilterMenu(
            label: isSpanish ? 'Proveedor' : 'Supplier',
            sortDirection: _expenseSortDirection(
              {_ExpenseListSortOption.vendorAz},
              {_ExpenseListSortOption.vendorZa},
            ),
            onSortAscending: () =>
                _setSortOption(_ExpenseListSortOption.vendorAz),
            onSortDescending: () =>
                _setSortOption(_ExpenseListSortOption.vendorZa),
            filterActive: _vendorColumnFilters.isNotEmpty,
            onClear: () => _applyExpenseColumnFilter(
              () => _vendorColumnFilters = <String>{},
              refreshImmediately: true,
            ),
            child: HexoraMultiSelectFilter(
              values: vendorValues,
              selected: _vendorColumnFilters,
              labelFor: (value) => value,
              onChanged: (values) => _applyExpenseColumnFilter(
                () => _vendorColumnFilters = values,
                refreshImmediately: true,
              ),
              searchable: true,
              searchHint:
                  isSpanish ? 'Buscar proveedor...' : 'Search supplier...',
              emptyLabel: isSpanish
                  ? 'No se encontraron proveedores'
                  : 'No suppliers found',
              selectionSingularLabel:
                  isSpanish ? 'proveedor seleccionado' : 'selected supplier',
              selectionPluralLabel: isSpanish
                  ? 'proveedores seleccionados'
                  : 'selected suppliers',
            ),
          ),
        ),
        HexoraFilterableHeaderCell(
          label: isSpanish ? 'Nº factura' : 'Invoice no.',
          width: _invoiceWidth,
          filterActive: _invoiceColumnQuery.trim().isNotEmpty,
          sortDirection: _expenseSortDirection(
            {_ExpenseListSortOption.invoiceAz},
            {_ExpenseListSortOption.invoiceZa},
          ),
          menuBuilder: (_) => _textColumnFilterMenu(
            label: isSpanish ? 'Nº factura' : 'Invoice no.',
            value: _invoiceColumnQuery,
            hint: isSpanish ? 'Buscar referencia' : 'Search reference',
            onChanged: (value) =>
                _applyExpenseColumnFilter(() => _invoiceColumnQuery = value),
            ascending: _ExpenseListSortOption.invoiceAz,
            descending: _ExpenseListSortOption.invoiceZa,
          ),
        ),
        if (_visibleFinancialColumns.contains(HexoraFinancialColumn.date))
          HexoraFilterableHeaderCell(
            label: isSpanish ? 'Fecha' : 'Date',
            width: _dateWidth,
            filterActive: _dateColumnRange != null,
            sortDirection: _expenseSortDirection(
              {_ExpenseListSortOption.oldest},
              {_ExpenseListSortOption.newest},
            ),
            menuBuilder: _dateColumnFilterMenu,
          ),
        if (_visibleFinancialColumns
            .contains(HexoraFinancialColumn.taxableBase))
          _amountHeader(
            isSpanish ? 'Base imponible' : 'Taxable base',
            _baseWidth,
            _baseColumnMin,
            _baseColumnMax,
            _ExpenseListSortOption.baseLowToHigh,
            _ExpenseListSortOption.baseHighToLow,
            (min, max) => _applyExpenseColumnFilter(() {
              _baseColumnMin = min?.toDouble();
              _baseColumnMax = max?.toDouble();
            }),
          ),
        if (_visibleFinancialColumns.contains(HexoraFinancialColumn.vat))
          _amountHeader(
            'IVA',
            _vatWidth,
            _vatColumnMin,
            _vatColumnMax,
            _ExpenseListSortOption.vatLowToHigh,
            _ExpenseListSortOption.vatHighToLow,
            (min, max) => _applyExpenseColumnFilter(() {
              _vatColumnMin = min?.toDouble();
              _vatColumnMax = max?.toDouble();
            }),
          ),
        if (_visibleFinancialColumns.contains(HexoraFinancialColumn.total)) ...[
          _amountHeader(
            'Total',
            _totalWidth,
            _totalColumnMin,
            _totalColumnMax,
            _ExpenseListSortOption.amountLowToHigh,
            _ExpenseListSortOption.amountHighToLow,
            (min, max) => _applyExpenseColumnFilter(() {
              _totalColumnMin = min?.toDouble();
              _totalColumnMax = max?.toDouble();
            }),
          ),
          const SizedBox(width: _totalStatusGap),
        ],
        HexoraFilterableHeaderCell(
          label: isSpanish ? 'Estado IVA' : 'VAT status',
          width: _vatStateWidth,
          filterActive: _vatColumnStates.isNotEmpty,
          menuBuilder: (_) => _vatStateFilterMenu(isSpanish),
        ),
        SizedBox(
          width: _actionsWidth,
          child: Text(
            isSpanish ? 'Acciones' : 'Actions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11.5,
                ),
          ),
        ),
      ]),
    );
  }

  Widget _textColumnFilterMenu({
    required String label,
    required String value,
    required String hint,
    required ValueChanged<String> onChanged,
    required _ExpenseListSortOption ascending,
    required _ExpenseListSortOption descending,
  }) {
    return HexoraColumnFilterMenu(
      label: label,
      sortDirection: _expenseSortDirection({ascending}, {descending}),
      onSortAscending: () => _setSortOption(ascending),
      onSortDescending: () => _setSortOption(descending),
      filterActive: value.trim().isNotEmpty,
      onClear: () => onChanged(''),
      child: TextFormField(
        initialValue: value,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _amountHeader(
    String label,
    double width,
    double? min,
    double? max,
    _ExpenseListSortOption ascending,
    _ExpenseListSortOption descending,
    void Function(num? min, num? max) onChanged,
  ) {
    return HexoraFilterableHeaderCell(
      label: label,
      width: width,
      numeric: true,
      filterActive: min != null || max != null,
      sortDirection: _expenseSortDirection({ascending}, {descending}),
      menuBuilder: (_) => HexoraColumnFilterMenu(
        label: label,
        sortDirection: _expenseSortDirection({ascending}, {descending}),
        onSortAscending: () => _setSortOption(ascending),
        onSortDescending: () => _setSortOption(descending),
        filterActive: min != null || max != null,
        onClear: () => onChanged(null, null),
        child: HexoraAmountRangeInput(
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateColumnFilterMenu(BuildContext dialogContext) {
    final isSpanish =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    final now = DateTime.now();
    void setRange(DateTime start, DateTime end) {
      _applyExpenseColumnFilter(
        () => _dateColumnRange = DateTimeRange(start: start, end: end),
      );
      closeHexoraColumnFilterMenu(dialogContext);
    }

    return HexoraColumnFilterMenu(
      label: isSpanish ? 'Fecha' : 'Date',
      sortDirection: _expenseSortDirection(
        {_ExpenseListSortOption.oldest},
        {_ExpenseListSortOption.newest},
      ),
      onSortAscending: () => _setSortOption(_ExpenseListSortOption.oldest),
      onSortDescending: () => _setSortOption(_ExpenseListSortOption.newest),
      filterActive: _dateColumnRange != null,
      onClear: () => _applyExpenseColumnFilter(() => _dateColumnRange = null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextButton(
          onPressed: () => setRange(
            DateTime(now.year, now.month),
            DateTime(now.year, now.month + 1, 0),
          ),
          child: Text(isSpanish ? 'Este mes' : 'This month'),
        ),
        TextButton(
          onPressed: () {
            final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
            setRange(
              DateTime(now.year, startMonth),
              DateTime(now.year, startMonth + 3, 0),
            );
          },
          child: Text(isSpanish ? 'Este trimestre' : 'This quarter'),
        ),
        TextButton(
          onPressed: () =>
              setRange(DateTime(now.year), DateTime(now.year, 12, 31)),
          child: Text(isSpanish ? 'Este año' : 'This year'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              initialDateRange: _dateColumnRange,
              builder: hexoraCompactDateRangePickerBuilder,
            );
            if (picked != null) {
              _applyExpenseColumnFilter(() => _dateColumnRange = picked);
              if (dialogContext.mounted) {
                closeHexoraColumnFilterMenu(dialogContext);
              }
            }
          },
          icon: const Icon(Icons.date_range_outlined, size: 16),
          label: Text(isSpanish ? 'Elegir fechas' : 'Choose dates'),
        ),
      ]),
    );
  }

  Widget _vatStateFilterMenu(bool isSpanish) {
    const states = [
      'verified',
      'zero',
      'review',
      'processing',
      'error',
      'missingDocument',
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish ? 'Estado IVA' : 'VAT status',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _columnFilterBusy,
                builder: (context, busy, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: busy
                      ? Row(
                          key: const ValueKey('vat-filter-loading'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox.square(
                              dimension: 13,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSpanish ? 'Actualizando…' : 'Updating…',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('vat-filter-idle'),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HexoraMultiSelectFilter(
            values: states,
            selected: _vatColumnStates,
            labelFor: (value) => _vatStateLabel(value, isSpanish),
            onChanged: (values) => _applyExpenseColumnFilter(
              () => _vatColumnStates = values,
              refreshImmediately: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _vatColumnStates.isEmpty
                  ? null
                  : () => _applyExpenseColumnFilter(
                        () => _vatColumnStates = <String>{},
                        refreshImmediately: true,
                      ),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
              label: Text(isSpanish ? 'Limpiar' : 'Clear'),
            ),
          ),
        ],
      ),
    );
  }

  String _vatStateLabel(String state, bool isSpanish) => switch (state) {
        'verified' => isSpanish ? 'Verificado' : 'Verified',
        'zero' => isSpanish ? 'IVA 0' : 'VAT 0',
        'review' => isSpanish ? 'Pendiente de revisión' : 'Pending review',
        'processing' => isSpanish ? 'Procesando' : 'Processing',
        'error' => 'Error',
        'missingDocument' => isSpanish ? 'Sin documento' : 'No document',
        _ => state,
      };

  Widget _buildExpenseTableRow(
    BuildContext rowContext,
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    final id = (item['id'] ?? '').trim();
    final vendor = (item['vendor'] ?? '').trim();
    final invoice = (item['invoice'] ?? '').trim();
    final file = (item['file'] ?? '').trim();
    final selected = widget.selectedExpense?['id'] == item['id'];
    final reprocessing = _reprocessingExpenseIds.contains(id);
    final state = _expenseVatState(item);
    final stateColor = switch (state) {
      'verified' => const Color(0xFF16803A),
      'processing' => cs.primary,
      'error' => cs.error,
      'zero' || 'review' || 'missingDocument' => const Color(0xFFD97706),
      _ => cs.onSurfaceVariant,
    };
    final stateIcon = switch (state) {
      'verified' => Icons.verified_outlined,
      'processing' => Icons.sync_rounded,
      'error' => Icons.error_outline_rounded,
      'zero' => Icons.percent_rounded,
      'review' => Icons.warning_amber_rounded,
      'missingDocument' => Icons.attach_file_rounded,
      _ => Icons.info_outline_rounded,
    };

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: .32)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _selectExpense(item),
        hoverColor: cs.primary.withValues(alpha: .05),
        child: Container(
          key: ValueKey('expense-row-$id'),
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(children: [
            SizedBox(
              width: _supplierWidth,
              child: Tooltip(
                message: vendor,
                child: Row(children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: cs.primaryContainer.withValues(alpha: .55),
                    child: Text(
                      vendor.isEmpty ? '?' : vendor[0].toUpperCase(),
                      style: t.bodySmall.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vendor.isEmpty
                          ? (isSpanish ? 'Sin proveedor' : 'No supplier')
                          : vendor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ]),
              ),
            ),
            SizedBox(
              width: _invoiceWidth,
              child: Text(
                invoice.isEmpty ? '—' : invoice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(fontSize: 12),
              ),
            ),
            if (_visibleFinancialColumns.contains(HexoraFinancialColumn.date))
              HexoraDateCell(value: _expenseDate(item), width: _dateWidth),
            if (_visibleFinancialColumns
                .contains(HexoraFinancialColumn.taxableBase))
              HexoraFinancialCell(
                value: _expenseBase(item),
                width: _baseWidth,
              ),
            if (_visibleFinancialColumns.contains(HexoraFinancialColumn.vat))
              HexoraFinancialCell(value: _expenseVat(item), width: _vatWidth),
            if (_visibleFinancialColumns
                .contains(HexoraFinancialColumn.total)) ...[
              HexoraFinancialCell(
                value: _expenseAmount(item),
                total: true,
                width: _totalWidth,
              ),
              const SizedBox(width: _totalStatusGap),
            ],
            SizedBox(
              width: _vatStateWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Tooltip(
                  message: _vatStateLabel(state, isSpanish),
                  child: _StatusPill(
                    label: _compactVatStateLabel(state, isSpanish),
                    cs: cs,
                    color: stateColor,
                    icon: stateIcon,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: _actionsWidth,
              child: Center(
                child: _ExpenseActionGroup(
                  showPreview: true,
                  isSpanish: isSpanish,
                  previewEnabled: file.isNotEmpty ||
                      (item['fileUrl'] ?? '').trim().isNotEmpty,
                  onPreview: () {
                    widget.onSelectExpense(item);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (rowContext.mounted) {
                        DocumentWorkspaceScope.maybeOf(rowContext)
                            ?.openPreviewDrawer();
                      }
                    });
                  },
                  reprocessing: reprocessing,
                  onOcr: id.isEmpty || reprocessing
                      ? null
                      : () => _reprocessExpense(item),
                  onEdit: () => _openExpenseEditor(item),
                  deleting: _deletingExpenseIds.contains(id),
                  onDelete: id.isEmpty || !widget.canDeleteExpenses
                      ? null
                      : () => _confirmDeleteExpense(item),
                  onOpenOriginal: _originalDocumentAction(item),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  VoidCallback? _originalDocumentAction(Map<String, String> item) {
    final uri = Uri.tryParse((item['fileUrl'] ?? '').trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return null;
    }
    return () => unawaited(launchUrl(uri));
  }

  Widget _buildExpenseSplitRow(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    bool isSpanish,
  ) {
    final id = (item['id'] ?? '').trim();
    final vendor = (item['vendor'] ?? '').trim();
    final invoice = (item['invoice'] ?? '').trim();
    final date = _shortDate(item['date'] ?? '');
    final currency = (item['currency'] ?? '').trim();
    final selected = widget.selectedExpense?['id'] == item['id'];
    final reprocessing = _reprocessingExpenseIds.contains(id);
    final state = _expenseVatState(item);
    final stateColor = switch (state) {
      'verified' => const Color(0xFF16803A),
      'processing' => cs.primary,
      'error' => cs.error,
      'zero' || 'review' || 'missingDocument' => const Color(0xFFD97706),
      _ => cs.onSurfaceVariant,
    };
    final stateIcon = switch (state) {
      'verified' => Icons.verified_outlined,
      'processing' => Icons.sync_rounded,
      'error' => Icons.error_outline_rounded,
      'zero' => Icons.percent_rounded,
      'review' => Icons.warning_amber_rounded,
      'missingDocument' => Icons.attach_file_rounded,
      _ => Icons.info_outline_rounded,
    };

    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: .32)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _selectExpense(item),
        hoverColor: cs.primary.withValues(alpha: .05),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 6, 4),
          decoration: selected
              ? BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: cs.primary, width: 3),
                  ),
                )
              : null,
          child: Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: cs.primaryContainer.withValues(alpha: .55),
              child: Text(
                vendor.isEmpty ? '?' : vendor[0].toUpperCase(),
                style: t.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: vendor,
                    child: Text(
                      vendor.isEmpty
                          ? (isSpanish ? 'Sin proveedor' : 'No supplier')
                          : vendor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (invoice.isNotEmpty) '#$invoice',
                      if (date.isNotEmpty) date
                    ].join(' · '),
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
            const SizedBox(width: 8),
            Tooltip(
              message: _vatStateLabel(state, isSpanish),
              child: _StatusPill(
                label: _compactVatStateLabel(state, isSpanish),
                cs: cs,
                color: stateColor,
                icon: stateIcon,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 94,
              child: Text(
                [
                  _formatMoney(_expenseAmount(item)),
                  if (currency.isNotEmpty) currency,
                ].join(' '),
                maxLines: 1,
                overflow: TextOverflow.fade,
                textAlign: TextAlign.end,
                style: t.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 16),
            _ExpenseActionGroup(
              showPreview: false,
              isSpanish: isSpanish,
              previewEnabled: false,
              onPreview: null,
              reprocessing: reprocessing,
              onOcr: id.isEmpty || reprocessing
                  ? null
                  : () => _reprocessExpense(item),
              onEdit: () => _openExpenseEditor(item),
              deleting: _deletingExpenseIds.contains(id),
              onDelete: id.isEmpty || !widget.canDeleteExpenses
                  ? null
                  : () => _confirmDeleteExpense(item),
              onOpenOriginal: _originalDocumentAction(item),
            ),
          ]),
        ),
      ),
    );
  }

  String _compactVatStateLabel(String state, bool isSpanish) => switch (state) {
        'zero' => 'IVA 0',
        'missingDocument' => isSpanish ? 'Sin doc.' : 'No doc.',
        _ => _vatStateLabel(state, isSpanish),
      };
}

class _ExpenseActionGroup extends StatelessWidget {
  const _ExpenseActionGroup({
    required this.showPreview,
    required this.isSpanish,
    required this.previewEnabled,
    required this.onPreview,
    required this.reprocessing,
    required this.onOcr,
    required this.onEdit,
    required this.deleting,
    required this.onDelete,
    required this.onOpenOriginal,
  });

  final bool showPreview;
  final bool isSpanish;
  final bool previewEnabled;
  final VoidCallback? onPreview;
  final bool reprocessing;
  final VoidCallback? onOcr;
  final VoidCallback? onEdit;
  final bool deleting;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final hasOcrAction = onOcr != null || reprocessing;
    final hasDeleteAction = onDelete != null || deleting;
    final hasMoreActions =
        hasOcrAction || hasDeleteAction || onOpenOriginal != null;
    final actions = <Widget>[
      if (showPreview)
        HexoraButton.iconOnly(
          icon: Icons.visibility_outlined,
          tooltip: isSpanish ? 'Vista previa' : 'Preview',
          size: HexoraButtonSize.compact,
          variant: HexoraButtonVariant.ghost,
          onPressed: previewEnabled ? onPreview : null,
        ),
      HexoraButton.iconOnly(
        icon: Icons.edit_outlined,
        tooltip: isSpanish ? 'Editar gasto' : 'Edit expense',
        size: HexoraButtonSize.compact,
        variant: HexoraButtonVariant.ghost,
        onPressed: onEdit,
      ),
      PopupMenuButton<String>(
        enabled: hasMoreActions,
        padding: EdgeInsets.zero,
        onSelected: (value) {
          switch (value) {
            case 'ocr':
              onOcr?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
            case 'open-original':
              onOpenOriginal?.call();
              break;
          }
        },
        itemBuilder: (_) => [
          if (hasOcrAction)
            PopupMenuItem(
              value: 'ocr',
              enabled: onOcr != null && !reprocessing,
              child: Row(children: [
                reprocessing
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner_outlined, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    reprocessing
                        ? (isSpanish
                            ? 'Releyendo documento…'
                            : 'Reviewing document…')
                        : (isSpanish
                            ? 'OCR / Revisar documento'
                            : 'OCR / Review document'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          if (onOpenOriginal != null)
            PopupMenuItem(
              value: 'open-original',
              child: Row(children: [
                const Icon(Icons.open_in_new_rounded, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isSpanish ? 'Abrir documento original' : 'Open original',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          if (hasDeleteAction)
            PopupMenuItem(
              value: 'delete',
              enabled: onDelete != null && !deleting,
              child: Row(children: [
                deleting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(isSpanish ? 'Eliminar gasto' : 'Delete expense'),
                ),
              ]),
            ),
        ],
        child: IgnorePointer(
          child: HexoraButton.iconOnly(
            icon: Icons.more_horiz_rounded,
            tooltip: isSpanish ? 'Más acciones' : 'More actions',
            size: HexoraButtonSize.compact,
            variant: HexoraButtonVariant.ghost,
            onPressed: hasMoreActions ? () {} : null,
          ),
        ),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          actions[index],
        ],
      ],
    );
  }
}
