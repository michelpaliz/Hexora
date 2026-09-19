part of '../../widgets/group_invoices_invoices_view.dart';

extension _InvoiceListLayout on _InvoicesTabListState {
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasFilter = _fromDate != null || _toDate != null;
    final sourceInvoices = _unlinkedOnly
        ? (_unlinkedInvoices ?? const <Invoice>[])
        : widget.invoices;
    final filtered = sourceInvoices.where((inv) {
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
    if (widget.allowClientNameSort && _clientNameSortEnabled) {
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
    final summaryTotals =
        _unlinkedOnly ? _summaryFromInvoices(visible) : _summaryTotals;

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

              Widget compactSortButton({
                required IconData icon,
                required String label,
                required bool active,
                required bool ascending,
                required VoidCallback onTap,
              }) {
                final foreground =
                    active ? cs.onPrimaryContainer : cs.onSurfaceVariant;
                return Tooltip(
                  message:
                      '$label · ${isSpanish ? (ascending ? 'ascendente' : 'descendente') : (ascending ? 'ascending' : 'descending')}',
                  child: InkWell(
                    onTap: widget.sortLoading ? null : onTap,
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            active ? cs.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? cs.primaryContainer
                              : cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(icon, size: 15, color: foreground),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Icon(
                              ascending
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 9,
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final labelActions = <Widget>[
                if (issueAllButton != null) issueAllButton,
                sortButton(
                  value: InvoiceSortBy.date,
                  label: l.date,
                  tooltip: l.date,
                ),
                sortButton(
                  value: InvoiceSortBy.number,
                  label: l.invoiceSortByNumberLabel,
                  tooltip: l.invoiceSortByNumberLabel,
                ),
                if (widget.allowClientNameSort) clientNameSortButton(),
              ];

              if (widget.showSummaryTotals) {
                final sortActions = <Widget>[
                  compactSortButton(
                    icon: Icons.calendar_month_outlined,
                    label: l.date,
                    active: !_clientNameSortEnabled &&
                        currentSort.by == InvoiceSortBy.date,
                    ascending: currentSort.dir == InvoiceSortDir.asc,
                    onTap: () {
                      if (_clientNameSortEnabled) {
                        _updateInvoiceListState(
                            () => _clientNameSortEnabled = false);
                      }
                      widget.onSortBySelected(InvoiceSortBy.date);
                    },
                  ),
                  compactSortButton(
                    icon: Icons.format_list_numbered_rounded,
                    label: l.invoiceSortByNumberLabel,
                    active: !_clientNameSortEnabled &&
                        currentSort.by == InvoiceSortBy.number,
                    ascending: currentSort.dir == InvoiceSortDir.asc,
                    onTap: () {
                      if (_clientNameSortEnabled) {
                        _updateInvoiceListState(
                            () => _clientNameSortEnabled = false);
                      }
                      widget.onSortBySelected(InvoiceSortBy.number);
                    },
                  ),
                  if (widget.allowClientNameSort)
                    compactSortButton(
                      icon: Icons.sort_by_alpha_rounded,
                      label: isSpanish ? 'Cliente' : 'Client',
                      active: _clientNameSortEnabled,
                      ascending: _clientNameSortDir == InvoiceSortDir.asc,
                      onTap: () {
                        _updateInvoiceListState(() {
                          if (_clientNameSortEnabled) {
                            _clientNameSortDir =
                                _clientNameSortDir == InvoiceSortDir.asc
                                    ? InvoiceSortDir.desc
                                    : InvoiceSortDir.asc;
                          } else {
                            _clientNameSortEnabled = true;
                            _clientNameSortDir = InvoiceSortDir.asc;
                          }
                        });
                      },
                    ),
                ];

                return _InvoiceSummaryTotalsBar(
                  count: visible.length,
                  summary: summaryTotals,
                  loading: _unlinkedOnly ? _unlinkedLoading : _summaryLoading,
                  error: _unlinkedOnly ? _unlinkedError : _summaryError,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  quickRange: _quickRange,
                  sortActions: sortActions,
                  unlinkedOnly: _unlinkedOnly,
                  paymentSuggestionsLoading: _paymentSuggestionsLoading,
                  onDateRangeSelected: (value) {
                    if (value == DateQuickRange.month) {
                      _setRangeDays(30);
                    } else if (value == DateQuickRange.quarter) {
                      _setRangeMonths(3);
                    } else if (value == DateQuickRange.custom) {
                      _pickCustomDateRange();
                    } else {
                      _updateInvoiceListState(() {
                        _fromDate = null;
                        _toDate = null;
                        _quickRange = DateQuickRange.none;
                      });
                      _notifyDateFilterChanged();
                      _refreshFilteredData();
                    }
                  },
                  onHeaderAction: (action) {
                    switch (action) {
                      case _InvoiceHeaderAction.toggleUnlinked:
                        _toggleUnlinkedOnly();
                      case _InvoiceHeaderAction.resolveLinks:
                        _openPaymentSuggestionsDialog();
                    }
                  },
                  downloadingFiltered: _downloadingFiltered,
                  onDownloadFiltered: widget.onDownloadFiltered == null
                      ? null
                      : () async {
                          if (_downloadingFiltered) return;
                          _updateInvoiceListState(
                              () => _downloadingFiltered = true);
                          try {
                            await widget.onDownloadFiltered!(visible);
                          } finally {
                            if (mounted) {
                              _updateInvoiceListState(
                                  () => _downloadingFiltered = false);
                            }
                          }
                        },
                );
              }

              return DateRangeFilterCard(
                quickRange: _quickRange,
                expanded: _filtersExpanded,
                fromDate: _fromDate,
                toDate: _toDate,
                showLabel: true,
                labelActions: labelActions,
                onToggleExpanded: () => _updateInvoiceListState(
                    () => _filtersExpanded = !_filtersExpanded),
                onClear: () {
                  _updateInvoiceListState(() {
                    _fromDate = null;
                    _toDate = null;
                    _quickRange = DateQuickRange.none;
                  });
                  _notifyDateFilterChanged();
                  _refreshFilteredData();
                },
                onPickFrom: _pickFromDate,
                onPickTo: _pickToDate,
                onSelectQuickRange: (value) {
                  if (value == DateQuickRange.month) {
                    _setRangeDays(30);
                  } else if (value == DateQuickRange.quarter) {
                    _setRangeMonths(3);
                  } else {
                    _updateInvoiceListState(() {
                      _quickRange = DateQuickRange.custom;
                      _filtersExpanded = true;
                    });
                  }
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
                        return Padding(
                          key: ValueKey(inv.id),
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InvoiceListItem(
                                invoice: inv,
                                client: client,
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
