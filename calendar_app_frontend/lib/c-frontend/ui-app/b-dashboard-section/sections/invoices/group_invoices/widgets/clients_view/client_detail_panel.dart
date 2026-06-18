import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:intl/intl.dart';
import '../invoice_row_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'client_invoice_stats_card.dart';
import 'client_contracts_tab.dart';
import 'client_receipts_tab.dart';

class ClientDetailPanel extends StatefulWidget {
  final String groupId;
  final List<GroupClient> clients;
  final GroupClient? selectedClient;
  final List<Invoice> issuedInvoices;
  final List<Invoice> draftInvoices;

  final List<String> entityOptions;
  final List<String> propertyOptions;
  final bool assignBusy;
  final int initialTabIndex;

  final VoidCallback onEditSelectedClient;
  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateReceipt;
  final ValueChanged<Invoice> onOpenInvoiceDetail;
  final ValueChanged<Invoice> onDeleteInvoice;
  final Future<void> Function(List<Invoice> invoices) onDownloadVisibleInvoices;

  final Future<void> Function({String? entityType, String? propertyKind})
      onApplyClassification;

  const ClientDetailPanel({
    super.key,
    required this.groupId,
    required this.clients,
    required this.selectedClient,
    required this.issuedInvoices,
    required this.draftInvoices,
    required this.entityOptions,
    required this.propertyOptions,
    required this.assignBusy,
    this.initialTabIndex = 0,
    required this.onEditSelectedClient,
    required this.onCreateInvoice,
    required this.onCreateReceipt,
    required this.onOpenInvoiceDetail,
    required this.onDeleteInvoice,
    required this.onDownloadVisibleInvoices,
    required this.onApplyClassification,
  });

  @override
  State<ClientDetailPanel> createState() => _ClientDetailPanelState();
}

class _ClientDetailPanelState extends State<ClientDetailPanel> {
  int _contractsCount = 0;
  int _receiptsCount = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: widget.selectedClient == null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  l.selectClientFirst,
                  style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          : DefaultTabController(
              key: ValueKey(
                'client-detail-${widget.selectedClient!.id}-${widget.initialTabIndex}',
              ),
              length: 4,
              initialIndex: widget.initialTabIndex.clamp(0, 3),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: _ClientTabs(
                      invoicesCount: widget.issuedInvoices.length,
                      contractsCount: _contractsCount,
                      receiptsCount: _receiptsCount,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _InvoiceList(
                          emptyTitle: l.noInvoicesYet,
                          emptySubtitle: l.noInvoicesYetSubtitle,
                          icon: Icons.receipt_long_outlined,
                          invoices: widget.issuedInvoices,
                          clients: widget.clients,
                          fallbackClient: widget.selectedClient!,
                          onTap: widget.onOpenInvoiceDetail,
                          onDelete: null,
                          onDownloadVisibleInvoices:
                              widget.onDownloadVisibleInvoices,
                        ),
                        ClientReceiptsTab(
                          key:
                              ValueKey('receipts-${widget.selectedClient!.id}'),
                          groupId: widget.groupId,
                          client: widget.selectedClient!,
                          onCountChanged: (count) =>
                              setState(() => _receiptsCount = count),
                        ),
                        ClientContractsTab(
                          key: ValueKey(
                              'contracts-${widget.selectedClient!.id}'),
                          client: widget.selectedClient!,
                          onCountChanged: (count) =>
                              setState(() => _contractsCount = count),
                        ),
                        ClientInvoiceStatsCard(
                          key: ValueKey(
                              'invoice-stats-${widget.selectedClient!.id}'),
                          client: widget.selectedClient!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ClientTabs extends StatelessWidget {
  final int invoicesCount;
  final int receiptsCount;
  final int contractsCount;

  const _ClientTabs({
    required this.invoicesCount,
    required this.receiptsCount,
    required this.contractsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    Widget tab({
      required IconData icon,
      required String label,
      int? count,
    }) {
      return Tab(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15),
              const SizedBox(width: 6),
              Text(label),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: cs.onPrimaryContainer,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
        indicatorPadding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        tabs: [
          tab(
            icon: Icons.receipt_long_outlined,
            label: l.groupInvoicesTabInvoices(invoicesCount),
          ),
          tab(
            icon: Icons.description_outlined,
            label: '${l.receiptsTitle} ($receiptsCount)',
          ),
          tab(
            icon: Icons.folder_outlined,
            label: '${l.contractsTitle} ($contractsCount)',
          ),
          tab(
            icon: Icons.insights_outlined,
            label: isSpanish ? 'Grafico' : 'Graph',
          ),
        ],
      ),
    );
  }
}

class _InvoiceList extends StatefulWidget {
  final String emptyTitle;
  final String emptySubtitle;
  final IconData icon;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final GroupClient fallbackClient;
  final ValueChanged<Invoice> onTap;
  final ValueChanged<Invoice>? onDelete;
  final Future<void> Function(List<Invoice> invoices) onDownloadVisibleInvoices;

  const _InvoiceList({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.invoices,
    required this.clients,
    required this.fallbackClient,
    required this.onTap,
    required this.onDelete,
    required this.onDownloadVisibleInvoices,
  });

  @override
  State<_InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<_InvoiceList> {
  DateTime? _fromDate;
  DateTime? _toDate;
  DateQuickRange _quickRange = DateQuickRange.none;
  bool _filtersExpanded = false;
  bool _downloadingVisible = false;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  DateTime? _invoiceDate(Invoice inv) =>
      inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;

  void _setRangeDays(int days) {
    final now = DateTime.now();
    setState(() {
      _toDate = now;
      _fromDate = now.subtract(Duration(days: days - 1));
      _quickRange = DateQuickRange.month;
    });
  }

  void _setRangeMonths(int months) {
    final now = DateTime.now();
    setState(() {
      _toDate = now;
      _fromDate = DateTime(now.year, now.month - (months - 1), now.day);
      _quickRange = DateQuickRange.quarter;
    });
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? _toDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = _fromDate;
      }
      _quickRange = DateQuickRange.none;
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
        _fromDate = _toDate;
      }
      _quickRange = DateQuickRange.none;
    });
  }

  Future<void> _downloadVisible(List<Invoice> invoices) async {
    if (_downloadingVisible || invoices.isEmpty) return;
    setState(() => _downloadingVisible = true);
    try {
      await widget.onDownloadVisibleInvoices(invoices);
    } finally {
      if (mounted) setState(() => _downloadingVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final hasFilter = _fromDate != null || _toDate != null;
    final filtered = widget.invoices.where((inv) {
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeFilterCard(
            quickRange: _quickRange,
            expanded: _filtersExpanded,
            fromDate: _fromDate,
            toDate: _toDate,
            showLabel: true,
            labelActions: [
              Tooltip(
                message: filtered.isEmpty
                    ? l.noInvoicesYet
                    : isSpanish
                        ? 'Descargar las facturas visibles (${filtered.length})'
                        : 'Download visible invoices (${filtered.length})',
                child: InkWell(
                  onTap: filtered.isEmpty || _downloadingVisible
                      ? null
                      : () => _downloadVisible(filtered),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_downloadingVisible)
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onSurfaceVariant,
                            ),
                          )
                        else
                          Icon(
                            Icons.folder_zip_outlined,
                            size: 14,
                            color: filtered.isEmpty
                                ? cs.onSurfaceVariant.withValues(alpha: 0.35)
                                : cs.onSurfaceVariant,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          isSpanish
                              ? 'ZIP visibles (${filtered.length})'
                              : 'Visible ZIP (${filtered.length})',
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: filtered.isEmpty
                                ? cs.onSurfaceVariant.withValues(alpha: 0.35)
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            onToggleExpanded: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            onClear: () => setState(() {
              _fromDate = null;
              _toDate = null;
              _quickRange = DateQuickRange.none;
            }),
            onPickFrom: _pickFromDate,
            onPickTo: _pickToDate,
            onSelectQuickRange: (value) {
              if (value == DateQuickRange.month) {
                _setRangeDays(30);
              } else if (value == DateQuickRange.quarter) {
                _setRangeMonths(3);
              } else {
                setState(() {
                  _quickRange = DateQuickRange.custom;
                  _filtersExpanded = true;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: EmptyView(
                      icon: widget.icon,
                      title: widget.emptyTitle,
                      subtitle: widget.emptySubtitle,
                    ),
                  )
                : _buildGroupedList(context, filtered),
          ),
        ],
      ),
    );
  }

  /// Builds a flat list of month-header + invoice items, injecting a
  /// [_MonthSeparator] whenever the month/year changes between invoices.
  Widget _buildGroupedList(BuildContext context, List<Invoice> invoices) {
    final l = AppLocalizations.of(context)!;

    // Build flat items: alternating _MonthKey (headers) and Invoice
    final items = <Object>[];
    String? lastKey;

    for (final inv in invoices) {
      final date = _invoiceDate(inv);
      final key = date == null
          ? null
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (key != null && key != lastKey) {
        items.add(_MonthKey(date!, l.localeName));
        lastKey = key;
      }
      items.add(inv);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is _MonthKey) {
          return Padding(
            padding: EdgeInsets.only(
              top: i == 0 ? 0 : 12,
              bottom: 6,
            ),
            child: _MonthSeparator(label: item.label),
          );
        }
        final inv = item as Invoice;
        final client = widget.clients.firstWhere(
          (c) => c.id == inv.clientId,
          orElse: () => widget.fallbackClient,
        );
        final isLast = i == items.length - 1 || items[i + 1] is _MonthKey;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: InvoiceListItem(
            invoice: inv,
            client: client,
            onTap: () => widget.onTap(inv),
            onDelete:
                widget.onDelete == null ? null : () => widget.onDelete!(inv),
          ),
        );
      },
    );
  }
}

/// Lightweight data holder for a month-group header.
class _MonthKey {
  final String label;
  _MonthKey(DateTime date, String locale) : label = _formatMonth(date, locale);

  static String _formatMonth(DateTime date, String locale) {
    final formatter = DateFormat.yMMMM(locale);
    final raw = formatter.format(date);
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

/// A centered month/year divider: ── January 2026 ──
class _MonthSeparator extends StatelessWidget {
  const _MonthSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            height: 1,
          ),
        ),
      ],
    );
  }
}
