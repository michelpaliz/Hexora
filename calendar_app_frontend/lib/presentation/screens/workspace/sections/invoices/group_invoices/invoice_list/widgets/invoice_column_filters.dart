part of '../../widgets/group_invoices_invoices_view.dart';

extension _InvoiceColumnFilters on _InvoicesTabListState {
  _InvoiceColumnSort _sortFor(CompactDocumentColumn column) => switch (column) {
        CompactDocumentColumn.identity => _InvoiceColumnSort.number,
        CompactDocumentColumn.client => _InvoiceColumnSort.client,
        CompactDocumentColumn.status => _InvoiceColumnSort.status,
        CompactDocumentColumn.delivery => _InvoiceColumnSort.delivery,
        CompactDocumentColumn.payment => _InvoiceColumnSort.payment,
        CompactDocumentColumn.date => _InvoiceColumnSort.date,
        CompactDocumentColumn.taxableBase => _InvoiceColumnSort.taxableBase,
        CompactDocumentColumn.vat => _InvoiceColumnSort.vat,
        CompactDocumentColumn.total => _InvoiceColumnSort.total,
      };

  bool _filterActiveFor(CompactDocumentColumn column) => switch (column) {
        CompactDocumentColumn.identity => _invoiceNumberQuery.isNotEmpty,
        CompactDocumentColumn.client => _selectedClientNames.isNotEmpty,
        CompactDocumentColumn.status => _selectedLifecycleStatuses.isNotEmpty,
        CompactDocumentColumn.delivery => _selectedDeliveryStatuses.isNotEmpty,
        CompactDocumentColumn.payment => _selectedPaymentStatuses.isNotEmpty,
        CompactDocumentColumn.date => _fromDate != null || _toDate != null,
        CompactDocumentColumn.taxableBase => _baseRange.active,
        CompactDocumentColumn.vat => _vatRange.active,
        CompactDocumentColumn.total => _totalRange.active,
      };

  HexoraHeaderSortDirection? _sortDirectionFor(CompactDocumentColumn column) {
    if (_columnSort != _sortFor(column)) return null;
    return _columnSortDir == InvoiceSortDir.asc
        ? HexoraHeaderSortDirection.ascending
        : HexoraHeaderSortDirection.descending;
  }

  Widget _buildInvoiceColumnHeader(
    BuildContext context, {
    required CompactDocumentColumn column,
    required String label,
    required double width,
    required bool numeric,
    required List<Invoice> invoices,
  }) {
    return HexoraFilterableHeaderCell(
      label: label,
      width: width,
      numeric: numeric,
      centered: column == CompactDocumentColumn.status ||
          column == CompactDocumentColumn.delivery ||
          column == CompactDocumentColumn.payment,
      filterActive: _filterActiveFor(column),
      sortDirection: _sortDirectionFor(column),
      menuBuilder: (menuContext) => _columnMenu(
        menuContext,
        column: column,
        label: label,
        invoices: invoices,
      ),
    );
  }

  Widget _columnMenu(
    BuildContext context, {
    required CompactDocumentColumn column,
    required String label,
    required List<Invoice> invoices,
  }) {
    final cs = Theme.of(context).colorScheme;
    final sort = _sortFor(column);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<InvoiceSortDir>(
            segments: const [
              ButtonSegment(
                  value: InvoiceSortDir.asc,
                  icon: Icon(Icons.arrow_upward_rounded, size: 15),
                  label: Text('Ascendente')),
              ButtonSegment(
                  value: InvoiceSortDir.desc,
                  icon: Icon(Icons.arrow_downward_rounded, size: 15),
                  label: Text('Descendente')),
            ],
            selected: _columnSort == sort ? {_columnSortDir} : const {},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (value) {
              if (value.isNotEmpty) _applyColumnSort(sort, value.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStatePropertyAll(
                Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (column == CompactDocumentColumn.identity)
            TextFormField(
              initialValue: _invoiceNumberQuery,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Número de factura',
                hintText: 'Búsqueda exacta o parcial',
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded, size: 18),
              ),
              onChanged: _setInvoiceNumberQueryDebounced,
            ),
          if (column == CompactDocumentColumn.client)
            HexoraMultiSelectFilter(
              values: {
                for (final invoice in invoices)
                  _normalizedClientName(invoice, AppLocalizations.of(context)!)
              }.where((value) => value.isNotEmpty).toList()
                ..sort(),
              selected: _selectedClientNames,
              labelFor: (value) {
                for (final invoice in invoices) {
                  if (_normalizedClientName(
                          invoice, AppLocalizations.of(context)!) ==
                      value) {
                    return _invoiceFallbackClientName(
                        invoice, AppLocalizations.of(context)!);
                  }
                }
                return value;
              },
              onChanged: (value) =>
                  _updateInvoiceListState(() => _selectedClientNames = value),
              searchable: true,
              searchHint: 'Buscar cliente...',
              emptyLabel: 'No se encontraron clientes',
              selectionSingularLabel: 'cliente seleccionado',
              selectionPluralLabel: 'clientes seleccionados',
            ),
          if (column == CompactDocumentColumn.status)
            _selectionList(
              context,
              values: {
                for (final invoice in invoices)
                  _normalizedLifecycleStatus(invoice)
              }.toList(),
              selected: _selectedLifecycleStatuses,
              labelFor: _lifecycleLabel,
              onChanged: (value) => _updateInvoiceListState(
                  () => _selectedLifecycleStatuses = value),
            ),
          if (column == CompactDocumentColumn.delivery)
            _selectionList(
              context,
              values: {
                for (final invoice in invoices)
                  normalizeDeliveryStatus(invoice.deliveryStatus)
              }.toList(),
              selected: _selectedDeliveryStatuses,
              labelFor: (value) => invoiceDeliveryViewData(value).labelEs,
              onChanged: (value) => _updateInvoiceListState(
                  () => _selectedDeliveryStatuses = value),
            ),
          if (column == CompactDocumentColumn.payment)
            _selectionList(
              context,
              values: {
                for (final invoice in invoices)
                  _normalizedPaymentStatus(invoice)
              }.toList(),
              selected: _selectedPaymentStatuses,
              labelFor: _paymentLabel,
              onChanged: (value) => _updateInvoiceListState(
                  () => _selectedPaymentStatuses = value),
            ),
          if (column == CompactDocumentColumn.date) _dateFilter(context),
          if (column == CompactDocumentColumn.taxableBase)
            _amountFilter(
              context,
              value: _baseRange,
              onChanged: (value) =>
                  _updateInvoiceListState(() => _baseRange = value),
            ),
          if (column == CompactDocumentColumn.vat)
            _amountFilter(
              context,
              value: _vatRange,
              onChanged: (value) =>
                  _updateInvoiceListState(() => _vatRange = value),
            ),
          if (column == CompactDocumentColumn.total)
            _amountFilter(
              context,
              value: _totalRange,
              onChanged: (value) =>
                  _updateInvoiceListState(() => _totalRange = value),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: !_filterActiveFor(column)
                  ? null
                  : () {
                      _clearFilterFor(column);
                      closeHexoraColumnFilterMenu(context);
                    },
              icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
              label: const Text('Limpiar'),
              style: TextButton.styleFrom(foregroundColor: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionList(
    BuildContext context, {
    required List<String> values,
    required Set<String> selected,
    required String Function(String) labelFor,
    required ValueChanged<Set<String>> onChanged,
  }) {
    var localSelected = Set<String>.of(selected);
    return StatefulBuilder(builder: (context, setMenuState) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final value in values)
              CheckboxListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(labelFor(value),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                value: localSelected.contains(value),
                onChanged: (checked) {
                  final next = Set<String>.of(localSelected);
                  checked == true ? next.add(value) : next.remove(value);
                  localSelected = next;
                  onChanged(next);
                  setMenuState(() {});
                },
              ),
          ],
        ),
      );
    });
  }

  Widget _amountFilter(
    BuildContext context, {
    required _InvoiceAmountRange value,
    required ValueChanged<_InvoiceAmountRange> onChanged,
  }) {
    num? parse(String raw) =>
        num.tryParse(raw.trim().replaceAll('.', '').replaceAll(',', '.'));
    var min = value.min;
    var max = value.max;
    return Row(children: [
      Expanded(
        child: TextFormField(
          initialValue: value.min?.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Mínimo', isDense: true),
          onChanged: (raw) {
            min = parse(raw);
            onChanged(_InvoiceAmountRange(min: min, max: max));
          },
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextFormField(
          initialValue: value.max?.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Máximo', isDense: true),
          onChanged: (raw) {
            max = parse(raw);
            onChanged(_InvoiceAmountRange(min: min, max: max));
          },
        ),
      ),
    ]);
  }

  Widget _dateFilter(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ActionChip(
              label: const Text('Mes'), onPressed: () => _setRangeDays(30)),
          ActionChip(
              label: const Text('Trimestre'),
              onPressed: () => _setRangeMonths(3)),
          ActionChip(label: const Text('Año'), onPressed: _setRangeYear),
          ActionChip(
              avatar: const Icon(Icons.date_range_outlined, size: 15),
              label: const Text('Rango'),
              onPressed: _pickCustomDateRange),
          if (_fromDate != null || _toDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${HexoraFinancialFormat.date(_fromDate)} – ${HexoraFinancialFormat.date(_toDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );

  void _clearFilterFor(CompactDocumentColumn column) {
    _updateInvoiceListState(() {
      switch (column) {
        case CompactDocumentColumn.identity:
          _invoiceSearchDebounce?.cancel();
          _invoiceNumberQuery = '';
        case CompactDocumentColumn.client:
          _selectedClientNames = {};
        case CompactDocumentColumn.status:
          _selectedLifecycleStatuses = {};
        case CompactDocumentColumn.delivery:
          _selectedDeliveryStatuses = {};
        case CompactDocumentColumn.payment:
          _selectedPaymentStatuses = {};
        case CompactDocumentColumn.date:
          _fromDate = null;
          _toDate = null;
          _quickRange = DateQuickRange.none;
        case CompactDocumentColumn.taxableBase:
          _baseRange = const _InvoiceAmountRange();
        case CompactDocumentColumn.vat:
          _vatRange = const _InvoiceAmountRange();
        case CompactDocumentColumn.total:
          _totalRange = const _InvoiceAmountRange();
      }
    });
    if (column == CompactDocumentColumn.date) {
      _notifyDateFilterChanged();
      _refreshFilteredData();
    }
  }

  String _lifecycleLabel(String status) => switch (status) {
        'draft' => 'Borrador',
        'cancelled' => 'Anulada',
        'rectified' => 'Rectificativa',
        _ => 'Emitida',
      };

  String _paymentLabel(String status) => switch (status) {
        'paid' => 'Pagada',
        'partial' => 'Parcial',
        'unpaid' => 'No pagada',
        'overdue' => 'Vencida',
        _ => 'Sin información',
      };
}
