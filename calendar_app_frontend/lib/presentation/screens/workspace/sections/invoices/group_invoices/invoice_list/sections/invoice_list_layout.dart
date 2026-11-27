part of '../../widgets/group_invoices_invoices_view.dart';

extension _InvoiceListLayout on _InvoicesTabListState {
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasFilter = _fromDate != null || _toDate != null;
    final sourceInvoices = _unpaidOnly
        ? (_unpaidInvoices ?? const <Invoice>[])
        : _unlinkedOnly
            ? (_unlinkedInvoices ?? const <Invoice>[])
            : widget.invoices;
    final searchQuery = _searchText.trim().toLowerCase();
    final invoiceQuery = _invoiceNumberQuery.trim();
    final hasColumnFilters = _duplicateFilter != 'all' ||
        invoiceQuery.isNotEmpty ||
        _selectedClientNames.isNotEmpty ||
        _selectedLifecycleStatuses.isNotEmpty ||
        _selectedDeliveryStatuses.isNotEmpty ||
        _selectedPaymentStatuses.isNotEmpty ||
        _baseRange.active ||
        _vatRange.active ||
        _totalRange.active ||
        _mismatchOnly ||
        hasFilter;
    final filteredByTable = sourceInvoices.where((inv) {
      if (_duplicateFilter == 'duplicates' && !inv.isDuplicate) return false;
      if (_duplicateFilter == 'without_duplicates' && inv.isDuplicate) {
        return false;
      }
      if (invoiceQuery.isNotEmpty &&
          !invoiceNumberMatchesSearch(inv.invoiceNumber, invoiceQuery)) {
        return false;
      }
      if (_selectedClientNames.isNotEmpty &&
          !_selectedClientNames.contains(_normalizedClientName(inv, l))) {
        return false;
      }
      if (_selectedLifecycleStatuses.isNotEmpty &&
          !_selectedLifecycleStatuses
              .contains(_normalizedLifecycleStatus(inv))) {
        return false;
      }
      if (_selectedDeliveryStatuses.isNotEmpty &&
          !_selectedDeliveryStatuses
              .contains(normalizeDeliveryStatus(inv.deliveryStatus))) {
        return false;
      }
      if (_selectedPaymentStatuses.isNotEmpty &&
          !_selectedPaymentStatuses.contains(_normalizedPaymentStatus(inv))) {
        return false;
      }
      if (_baseRange.active && !_baseRange.includes(inv.subtotal)) return false;
      if (_vatRange.active && !_vatRange.includes(inv.taxTotal)) return false;
      if (_totalRange.active && !_totalRange.includes(inv.total)) return false;
      if (searchQuery.isNotEmpty) {
        final clientName = _invoiceClientDisplayName(inv, l).toLowerCase();
        final amount = inv.total?.toString() ?? '';
        final searchable = [
          inv.invoiceNumber,
          clientName,
          inv.billingName ?? '',
          inv.clientName ?? '',
          inv.conceptSummaries.join(' '),
          ...inv.lines.map((line) => line.description),
          inv.totalFormatted ?? '',
          inv.notes ?? '',
          amount,
          amount.replaceAll('.', ','),
        ].join(' ').toLowerCase();
        if (!searchable.contains(searchQuery) &&
            !invoiceNumberMatchesSearch(inv.invoiceNumber, searchQuery)) {
          return false;
        }
      }
      final date = _invoiceDate(inv);
      if (!hasFilter) return true;
      if (date == null) return false;
      if (_fromDate != null && date.isBefore(_startOfDay(_fromDate!))) {
        return false;
      }
      if (_toDate != null && date.isAfter(_endOfDay(_toDate!))) {
        return false;
      }
      return true;
    }).toList();
    final mismatchInvoices =
        filteredByTable.where(_hasFinancialMismatch).toList(growable: false);
    final filtered = _mismatchOnly ? mismatchInvoices : filteredByTable;
    final visible = [...filtered];
    if (_columnSort != null) {
      int compareNullableNum(num? a, num? b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      }

      int compare(Invoice a, Invoice b) => switch (_columnSort!) {
            _InvoiceColumnSort.number => a.invoiceNumber
                .toLowerCase()
                .compareTo(b.invoiceNumber.toLowerCase()),
            _InvoiceColumnSort.client => _normalizedClientName(a, l)
                .compareTo(_normalizedClientName(b, l)),
            _InvoiceColumnSort.status => _normalizedLifecycleStatus(a)
                .compareTo(_normalizedLifecycleStatus(b)),
            _InvoiceColumnSort.delivery =>
              normalizeDeliveryStatus(a.deliveryStatus)
                  .compareTo(normalizeDeliveryStatus(b.deliveryStatus)),
            _InvoiceColumnSort.payment => _normalizedPaymentStatus(a)
                .compareTo(_normalizedPaymentStatus(b)),
            _InvoiceColumnSort.date => (_invoiceDate(a) ?? DateTime(9999))
                .compareTo(_invoiceDate(b) ?? DateTime(9999)),
            _InvoiceColumnSort.notes => (a.notes ?? '')
                .toLowerCase()
                .compareTo((b.notes ?? '').toLowerCase()),
            _InvoiceColumnSort.taxableBase =>
              compareNullableNum(a.subtotal, b.subtotal),
            _InvoiceColumnSort.vat =>
              compareNullableNum(a.taxTotal, b.taxTotal),
            _InvoiceColumnSort.total => compareNullableNum(a.total, b.total),
          };
      visible.sort((a, b) {
        final value = compare(a, b);
        return _columnSortDir == InvoiceSortDir.asc ? value : -value;
      });
    } else if (widget.allowClientNameSort && _clientNameSortEnabled) {
      visible.sort((a, b) {
        final compare = _invoiceClientSortName(a, l).compareTo(
          _invoiceClientSortName(b, l),
        );
        if (compare != 0) {
          return _clientNameSortDir == InvoiceSortDir.asc ? compare : -compare;
        }
        return _compareInvoiceFallback(a, b);
      });
    }
    // [sourceInvoices] is the complete module dataset, so whenever any filter
    // is active (including the date range) the footer sums the same visible
    // invoices as the rows instead of falling back to the server page totals.
    final usesLocalSummary = _unpaidOnly ||
        _unlinkedOnly ||
        hasColumnFilters ||
        searchQuery.isNotEmpty;
    final summaryTotals = usesLocalSummary
        ? _summaryFromInvoices(visible, outstandingOnly: _unpaidOnly)
        : _summaryTotals;

    Future<void> downloadFiltered({required bool excel}) async {
      final action =
          excel ? widget.onDownloadExcelFiltered : widget.onDownloadFiltered;
      if (_downloadingFiltered || visible.isEmpty || action == null) return;
      final selection = List<Invoice>.unmodifiable(visible);
      _updateInvoiceListState(() => _downloadingFiltered = true);
      try {
        await action(selection);
      } finally {
        if (mounted) {
          _updateInvoiceListState(() => _downloadingFiltered = false);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final t = AppTypography.of(context);
              final cs = Theme.of(context).colorScheme;
              final currentSort = widget.sortState;
              final isSpanish =
                  Localizations.localeOf(context).languageCode == 'es';
              final issueAllBackground =
                  cs.tertiaryContainer.withValues(alpha: 0.92);
              final issueAllForeground = cs.onTertiaryContainer;
              final issueAllBorder = cs.tertiary.withValues(alpha: 0.32);

              // ignore: unused_element
              Widget sortButton({
                required InvoiceSortBy value,
                required String label,
                required String tooltip,
              }) {
                final active =
                    !_clientNameSortEnabled && currentSort.by == value;
                final isAsc = currentSort.dir == InvoiceSortDir.asc;
                return Tooltip(
                  message: tooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: widget.sortLoading
                        ? null
                        : () {
                            if (_clientNameSortEnabled) {
                              _updateInvoiceListState(
                                  () => _clientNameSortEnabled = false);
                            }
                            widget.onSortBySelected(value);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primaryContainer
                            : cs.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? cs.primaryContainer
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 14,
                            color: active
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // ignore: unused_element
              Widget clientNameSortButton() {
                final active = _clientNameSortEnabled;
                final isAsc = _clientNameSortDir == InvoiceSortDir.asc;
                final label = isSpanish
                    ? (isAsc ? 'Cliente A-Z' : 'Cliente Z-A')
                    : (isAsc ? 'Client A-Z' : 'Client Z-A');
                return Tooltip(
                  message: label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      _updateInvoiceListState(() {
                        if (_clientNameSortEnabled) {
                          _clientNameSortDir =
                              isAsc ? InvoiceSortDir.desc : InvoiceSortDir.asc;
                        } else {
                          _clientNameSortEnabled = true;
                          _clientNameSortDir = InvoiceSortDir.asc;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? cs.primaryContainer
                            : cs.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? cs.primaryContainer
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort_by_alpha_rounded,
                            size: 14,
                            color: active
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final draftsToIssue = visible
                  .where((invoice) => invoice.isDraft)
                  .toList(growable: false);
              final canIssueAll =
                  widget.onIssueAll != null && draftsToIssue.isNotEmpty;
              final issueAllButton = canIssueAll
                  ? Tooltip(
                      message: isSpanish
                          ? 'Emitir todos los borradores (${draftsToIssue.length})'
                          : 'Issue all drafts (${draftsToIssue.length})',
                      child: FilledButton.tonalIcon(
                        onPressed: widget.issueAllLoading == true
                            ? null
                            : () => widget.onIssueAll!(draftsToIssue),
                        style: FilledButton.styleFrom(
                          backgroundColor: issueAllBackground,
                          foregroundColor: issueAllForeground,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          side: BorderSide(color: issueAllBorder),
                        ),
                        icon: widget.issueAllLoading == true
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    issueAllForeground,
                                  ),
                                ),
                              )
                            : const Icon(Icons.publish_outlined, size: 14),
                        label: Text(
                          isSpanish ? 'Emitir todos' : 'Issue all',
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: issueAllForeground,
                          ),
                        ),
                      ),
                    )
                  : null;

              if (widget.showSummaryTotals) {
                return _InvoiceSummaryTotalsBar(
                  count: visible.length,
                  visibleColumns: _visibleFinancialColumns,
                  onColumnsChanged: _setVisibleFinancialColumns,
                  unpaidOnly: _unpaidOnly,
                  unlinkedOnly: _unlinkedOnly,
                  paymentSuggestionsLoading: _paymentSuggestionsLoading,
                  searchQuery: _searchText,
                  onSearchChanged: _setGlobalSearchDebounced,
                  onHeaderAction: (action) {
                    switch (action) {
                      case _InvoiceHeaderAction.toggleUnpaid:
                        _toggleUnpaidOnly();
                      case _InvoiceHeaderAction.toggleUnlinked:
                        _toggleUnlinkedOnly();
                      case _InvoiceHeaderAction.resolveLinks:
                        _openPaymentSuggestionsDialog();
                    }
                  },
                  leading: widget.toolbarLeading,
                  toolbarOptions: widget.toolbarOptions,
                  downloadingFiltered: _downloadingFiltered,
                  onDownloadFiltered: widget.onDownloadFiltered == null
                      ? null
                      : () => downloadFiltered(excel: false),
                  onDownloadExcelFiltered:
                      widget.onDownloadExcelFiltered == null
                          ? null
                          : () => downloadFiltered(excel: true),
                );
              }

              final draftSearch = SizedBox(
                height: 34,
                child: TextFormField(
                  key: ValueKey('draft-invoice-search-$_searchText'),
                  initialValue: _searchText,
                  onChanged: _setGlobalSearchDebounced,
                  textInputAction: TextInputAction.search,
                  style: t.bodySmall.copyWith(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: isSpanish
                        ? 'Buscar factura, cliente o concepto...'
                        : 'Search invoice, client or concept...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip:
                                isSpanish ? 'Limpiar búsqueda' : 'Clear search',
                            onPressed: () => _setGlobalSearchDebounced(''),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              );
              Widget duplicateFilterButton() {
                final selection = switch (_duplicateFilter) {
                  'duplicates' =>
                    isSpanish ? 'Solo duplicados' : 'Duplicates only',
                  'without_duplicates' =>
                    isSpanish ? 'Sin duplicados' : 'Without duplicates',
                  _ => isSpanish ? 'Todos' : 'All',
                };
                return PopupMenuButton<String>(
                  tooltip:
                      isSpanish ? 'Filtrar duplicados' : 'Filter duplicates',
                  onSelected: (value) => _updateInvoiceListState(
                    () => _duplicateFilter = value,
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'all', child: Text(isSpanish ? 'Todos' : 'All')),
                    PopupMenuItem(
                        value: 'duplicates',
                        child: Text(
                            isSpanish ? 'Solo duplicados' : 'Duplicates only')),
                    PopupMenuItem(
                        value: 'without_duplicates',
                        child: Text(isSpanish
                            ? 'Sin duplicados'
                            : 'Without duplicates')),
                  ],
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_rounded,
                            size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                            '${isSpanish ? 'Duplicados' : 'Duplicates'}: $selection',
                            style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant)),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 18, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              }

              final options = InvoiceToolbarOptionsMenu(
                count: visible.length,
                downloading: _downloadingFiltered,
                availableColumns:
                    _InvoicesTabListState._availableFinancialColumns,
                visibleColumns: _visibleFinancialColumns,
                onColumnsChanged: _setVisibleFinancialColumns,
                unlinkedOnly: false,
                paymentSuggestionsLoading: false,
                toolbarOptions: widget.toolbarOptions,
                onPdf: widget.onDownloadFiltered == null
                    ? null
                    : () => downloadFiltered(excel: false),
                onExcel: widget.onDownloadExcelFiltered == null
                    ? null
                    : () => downloadFiltered(excel: true),
              );
              final orderedActions = <Widget>[
                if (issueAllButton != null) issueAllButton,
                duplicateFilterButton(),
                options,
              ];
              final actions = Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: orderedActions,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final fullyUnified = constraints.maxWidth >= 1100 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 18;
                  if (fullyUnified) {
                    return SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          if (widget.toolbarLeading != null) ...[
                            widget.toolbarLeading!,
                            const SizedBox(width: 10),
                          ],
                          const DocumentLayoutSelector(
                            key: ValueKey('invoice-layout-selector'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: draftSearch),
                          const SizedBox(width: 8),
                          actions,
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.toolbarLeading != null) ...[
                        SizedBox(
                          height: 36,
                          child: ClipRect(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: widget.toolbarLeading,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          const DocumentLayoutSelector(
                            key: ValueKey('invoice-layout-selector'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: draftSearch),
                          if (constraints.maxWidth >= 600) ...[
                            const SizedBox(width: 8),
                            actions,
                          ],
                        ],
                      ),
                      if (constraints.maxWidth < 600) ...[
                        const SizedBox(height: 4),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    ],
                  );
                },
              );
            },
          ),
          if (widget.showSummaryTotals && (_unpaidOnly || _unlinkedOnly)) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _UnlinkedInvoicesNotice(
                loading: _unpaidOnly ? _unpaidLoading : _unlinkedLoading,
                error: _unpaidOnly ? _unpaidError : _unlinkedError,
                unpaidOnly: _unpaidOnly,
                onRetry:
                    _unpaidOnly ? _loadUnpaidInvoices : _loadUnlinkedInvoices,
              ),
            ),
          ],
          if (hasColumnFilters || searchQuery.isNotEmpty) ...[
            const SizedBox(height: 4),
            _InvoiceActiveFiltersBar(
              searchActive: searchQuery.isNotEmpty,
              columnFilterActive: hasColumnFilters,
              clientNames: _selectedClientNames,
              clientLabelFor: (value) =>
                  _clientFilterLabel(value, sourceInvoices, l),
              lifecycleStatuses: _selectedLifecycleStatuses,
              paymentStatuses: _selectedPaymentStatuses,
              dateActive: hasFilter,
              amountActive:
                  _baseRange.active || _vatRange.active || _totalRange.active,
              onClearClient: () =>
                  _clearFilterFor(CompactDocumentColumn.client),
              onClearLifecycle: () =>
                  _clearFilterFor(CompactDocumentColumn.status),
              onClearPayment: () =>
                  _clearFilterFor(CompactDocumentColumn.payment),
              onClearDate: () => _clearFilterFor(CompactDocumentColumn.date),
              onClearAmount: () => _clearFilterFor(CompactDocumentColumn.total),
              onClearColumnFilters: _clearOnlyColumnFilters,
              onClearAll: _clearColumnFilters,
            ),
          ],
          const SizedBox(height: 6),
          CompactDocumentTableHeader(
            identityLabel:
                l.localeName.startsWith('es') ? 'Factura' : 'Invoice',
            visibleFinancialColumns: _visibleFinancialColumns,
            showDeliveryColumn: true,
            invoiceColumnOrder: true,
            preferWideClient: true,
            fullColumnsMinWidth: 1360,
            hideActionsInSplitView: true,
            // Preview and overflow use two compact 32px slots with a 4px gap.
            // Keep the header reservation identical to each row.
            actionsWidth: 68,
            headerBuilder: (context, column, label, width, numeric) =>
                _buildInvoiceColumnHeader(
              context,
              column: column,
              label: label,
              width: width,
              numeric: numeric,
              invoices: sourceInvoices,
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: EmptyView(
                      icon: widget.icon,
                      title: widget.emptyTitle,
                      subtitle: widget.emptySubtitle,
                    ),
                  )
                : Builder(builder: (context) {
                    final isSpanish =
                        Localizations.localeOf(context).languageCode == 'es';

                    final items = <Object>[];
                    String? lastKey;
                    for (final inv in visible) {
                      if (_clientNameSortEnabled) {
                        items.add(inv);
                        continue;
                      }
                      final date = _invoiceDate(inv);
                      final key = date == null
                          ? '__none__'
                          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
                      if (key != lastKey) {
                        items.add(date == null
                            ? (isSpanish ? 'Sin fecha' : 'No date')
                            : _invoiceMonthLabel(date.toLocal(), isSpanish));
                        lastKey = key;
                      }
                      items.add(inv);
                    }

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        if (item is String) {
                          return _MonthDivider(label: item, first: i == 0);
                        }
                        final inv = item as Invoice;
                        final selected = widget.selectedInvoiceId == inv.id;
                        final client = _resolveInvoiceClient(
                          inv,
                          widget.clients,
                          l,
                        );
                        final hasUnknownClientError =
                            _hasUnknownDraftClient(inv, client, l);
                        final hasMonthWarning = _hasInvoiceMonthWarning(inv);
                        final chronologyConflict =
                            invoiceChronologyConflict(inv, widget.invoices);
                        final financialMismatchTooltip =
                            _financialMismatchTooltip(inv, l);
                        return Padding(
                          key: ValueKey(inv.id),
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InvoiceListItem(
                                invoice: inv,
                                client: client,
                                visibleFinancialColumns:
                                    _visibleFinancialColumns,
                                selected: selected,
                                warning: hasUnknownClientError,
                                warningLabel: hasUnknownClientError
                                    ? 'Cliente desconocido'
                                    : null,
                                monthWarning: hasMonthWarning,
                                monthWarningLabel: hasMonthWarning
                                    ? _invoiceMonthWarningLabel(inv, l)
                                    : null,
                                monthWarningTooltip: hasMonthWarning
                                    ? _invoiceMonthWarningTooltip(inv, l)
                                    : null,
                                dateWarningTooltip: chronologyConflict == null
                                    ? null
                                    : invoiceChronologyConflictMessage(
                                        chronologyConflict,
                                        l,
                                      ),
                                financialMismatchTooltip:
                                    financialMismatchTooltip,
                                onInspectRecurrence: hasUnknownClientError &&
                                        (inv.recurringSeriesId
                                                ?.trim()
                                                .isNotEmpty ??
                                            false)
                                    ? () => _openRecurringDraftDebugDialog(
                                          context,
                                          inv,
                                        )
                                    : null,
                                onTap: () {
                                  widget.onTap(inv);
                                  DocumentWorkspaceScope.maybeOf(context)
                                      ?.openPreviewDrawer();
                                },
                                onPreview: () => widget.onTap(inv),
                                onDelete: widget.onDelete == null
                                    ? null
                                    : () => widget.onDelete!(inv),
                                onEdit: widget.onEdit == null
                                    ? null
                                    : () => widget.onEdit!(inv),
                                onIssue: widget.onIssue == null
                                    ? null
                                    : () => widget.onIssue!(inv),
                                onLinkInvoice: widget.onLinkInvoice == null ||
                                        inv.isDraft ||
                                        inv.isLinkedResolved
                                    ? null
                                    : () => widget.onLinkInvoice!(inv),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
          ),
          if (widget.showSummaryTotals) ...[
            const SizedBox(height: 4),
            _InvoiceFinancialSummaryBar(
              count: visible.length,
              totalCount: sourceInvoices.length,
              filtered: usesLocalSummary || hasFilter,
              visibleColumns: _visibleFinancialColumns,
              summary: summaryTotals,
              loading: _unpaidOnly
                  ? _unpaidLoading
                  : _unlinkedOnly
                      ? _unlinkedLoading
                      : usesLocalSummary
                          ? false
                          : _summaryLoading,
              error: _unpaidOnly
                  ? _unpaidError
                  : _unlinkedOnly
                      ? _unlinkedError
                      : usesLocalSummary
                          ? null
                          : _summaryError,
              mismatchCount: mismatchInvoices.length,
              mismatchFilterActive: _mismatchOnly,
              onMismatchTap: mismatchInvoices.isEmpty && !_mismatchOnly
                  ? null
                  : _toggleMismatchOnly,
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceActiveFiltersBar extends StatelessWidget {
  const _InvoiceActiveFiltersBar({
    required this.searchActive,
    required this.columnFilterActive,
    required this.clientNames,
    required this.clientLabelFor,
    required this.lifecycleStatuses,
    required this.paymentStatuses,
    required this.dateActive,
    required this.amountActive,
    required this.onClearClient,
    required this.onClearLifecycle,
    required this.onClearPayment,
    required this.onClearDate,
    required this.onClearAmount,
    required this.onClearColumnFilters,
    required this.onClearAll,
  });

  final bool searchActive;
  final bool columnFilterActive;
  final Set<String> clientNames;
  final String Function(String) clientLabelFor;
  final Set<String> lifecycleStatuses;
  final Set<String> paymentStatuses;
  final bool dateActive;
  final bool amountActive;
  final VoidCallback onClearClient;
  final VoidCallback onClearLifecycle;
  final VoidCallback onClearPayment;
  final VoidCallback onClearDate;
  final VoidCallback onClearAmount;
  final VoidCallback onClearColumnFilters;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final chips = <Widget>[];
    for (final client in clientNames) {
      final label = clientLabelFor(client);
      chips.add(_chip(
          '${isEs ? 'Cliente' : 'Client'}: ${label.isEmpty ? '-' : label}',
          cs,
          onClearClient));
    }
    for (final status in lifecycleStatuses) {
      chips.add(
          _chip('Estado: ${_statusLabel(status, isEs)}', cs, onClearLifecycle));
    }
    for (final status in paymentStatuses) {
      chips.add(
          _chip('Pago: ${_paymentLabel(status, isEs)}', cs, onClearPayment));
    }
    if (dateActive) {
      chips.add(_chip(isEs ? 'Fecha' : 'Date', cs, onClearDate));
    }
    if (amountActive) {
      chips.add(_chip(isEs ? 'Importe' : 'Amount', cs, onClearAmount));
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (searchActive)
          Text(
            isEs ? 'Búsqueda activa' : 'Search active',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ...chips,
        if (columnFilterActive)
          TextButton(
            onPressed: onClearColumnFilters,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(isEs ? 'Limpiar filtros' : 'Clear filters'),
          ),
        if (searchActive && columnFilterActive)
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(isEs ? 'Limpiar todo' : 'Clear all'),
          ),
      ],
    );
  }

  Widget _chip(String label, ColorScheme cs, VoidCallback onDeleted) =>
      InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close_rounded, size: 14),
        visualDensity: VisualDensity.compact,
        labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        backgroundColor: cs.primaryContainer.withValues(alpha: .5),
        side: BorderSide(color: cs.primary.withValues(alpha: .22)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );

  String _statusLabel(String value, bool isEs) => switch (value) {
        'draft' => isEs ? 'Borrador' : 'Draft',
        'cancelled' => isEs ? 'Anulada' : 'Cancelled',
        'rectified' => isEs ? 'Rectificativa' : 'Rectified',
        _ => isEs ? 'Emitida' : 'Issued',
      };

  String _paymentLabel(String value, bool isEs) => switch (value) {
        'paid' => isEs ? 'Pagada' : 'Paid',
        'partial' => isEs ? 'Parcial' : 'Partial',
        'unpaid' => isEs ? 'No pagada' : 'Unpaid',
        'overdue' => isEs ? 'Vencida' : 'Overdue',
        _ => isEs ? 'Sin información' : 'Unknown',
      };
}
