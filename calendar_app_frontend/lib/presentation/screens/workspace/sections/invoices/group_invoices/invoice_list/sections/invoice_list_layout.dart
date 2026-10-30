part of '../../widgets/group_invoices_invoices_view.dart';

extension _InvoiceListLayout on _InvoicesTabListState {
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasFilter = _fromDate != null || _toDate != null;
    final sourceInvoices = _unlinkedOnly
        ? (_unlinkedInvoices ?? const <Invoice>[])
        : widget.invoices;
    final searchQuery = _searchText.trim().toLowerCase();
    final invoiceQuery = _invoiceNumberQuery.trim().toLowerCase();
    // ignore: unused_local_variable
    final hasColumnFilters = searchQuery.isNotEmpty ||
        invoiceQuery.isNotEmpty ||
        _selectedClientNames.isNotEmpty ||
        _selectedLifecycleStatuses.isNotEmpty ||
        _selectedDeliveryStatuses.isNotEmpty ||
        _selectedPaymentStatuses.isNotEmpty ||
        _baseRange.active ||
        _vatRange.active ||
        _totalRange.active ||
        hasFilter;
    final filtered = sourceInvoices.where((inv) {
      if (invoiceQuery.isNotEmpty &&
          !inv.invoiceNumber.toLowerCase().contains(invoiceQuery)) {
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
        final clientName = _invoiceFallbackClientName(inv, l).toLowerCase();
        final amount = inv.total?.toString() ?? '';
        final searchable = [
          inv.invoiceNumber,
          clientName,
          inv.billingName ?? '',
          inv.clientName ?? '',
          inv.totalFormatted ?? '',
          amount,
          amount.replaceAll('.', ','),
        ].join(' ').toLowerCase();
        if (!searchable.contains(searchQuery)) return false;
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
    Invoice? firstMismatch;
    for (final invoice in visible) {
      final subtotal = invoice.subtotal;
      final tax = invoice.taxTotal;
      final total = invoice.total;
      if (subtotal != null &&
          tax != null &&
          total != null &&
          (subtotal + tax - total).abs() > 0.02) {
        firstMismatch = invoice;
        break;
      }
    }
    // [sourceInvoices] is the complete module dataset, so this uses the same
    // normalized criteria as the rows and never falls back to page totals.
    final usesLocalSummary = _unlinkedOnly ||
        searchQuery.isNotEmpty ||
        invoiceQuery.isNotEmpty ||
        _selectedClientNames.isNotEmpty ||
        _selectedLifecycleStatuses.isNotEmpty ||
        _selectedDeliveryStatuses.isNotEmpty ||
        _selectedPaymentStatuses.isNotEmpty ||
        _baseRange.active ||
        _vatRange.active ||
        _totalRange.active;
    final summaryTotals =
        usesLocalSummary ? _summaryFromInvoices(visible) : _summaryTotals;

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
                  totalCount: sourceInvoices.length,
                  summary: summaryTotals,
                  loading: _unlinkedOnly
                      ? _unlinkedLoading
                      : usesLocalSummary
                          ? false
                          : _summaryLoading,
                  error: _unlinkedOnly
                      ? _unlinkedError
                      : usesLocalSummary
                          ? null
                          : _summaryError,
                  visibleColumns: _visibleFinancialColumns,
                  onColumnsChanged: _setVisibleFinancialColumns,
                  unlinkedOnly: _unlinkedOnly,
                  paymentSuggestionsLoading: _paymentSuggestionsLoading,
                  searchQuery: _searchText,
                  onSearchChanged: _setGlobalSearchDebounced,
                  onHeaderAction: (action) {
                    switch (action) {
                      case _InvoiceHeaderAction.toggleUnlinked:
                        _toggleUnlinkedOnly();
                      case _InvoiceHeaderAction.resolveLinks:
                        _openPaymentSuggestionsDialog();
                    }
                  },
                  leading: widget.toolbarLeading,
                  toolbarOptions: widget.toolbarOptions,
                  onMismatchTap: firstMismatch == null
                      ? null
                      : () => widget.onTap(firstMismatch!),
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
                        ? 'Buscar facturas, clientes o importes...'
                        : 'Search invoices, clients or amounts...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              );
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
          if (widget.showSummaryTotals && _unlinkedOnly) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _UnlinkedInvoicesNotice(
                loading: _unlinkedLoading,
                error: _unlinkedError,
                onRetry: _loadUnlinkedInvoices,
              ),
            ),
          ],
          const SizedBox(height: 6),
          CompactDocumentTableHeader(
            identityLabel: 'Factura',
            visibleFinancialColumns: _visibleFinancialColumns,
            showDeliveryColumn: true,
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
                                onTap: () => widget.onTap(inv),
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
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
