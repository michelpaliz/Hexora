import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/services/clients/client_contracts_api.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:intl/intl.dart';
import '../invoice_row_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'client_invoice_stats_card.dart';
import 'client_contracts_tab.dart';
import '../../../../receipts/views/client_receipts_tab.dart';

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
  final VoidCallback? onAddClient;

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
    this.onAddClient,
    required this.onApplyClassification,
  });

  @override
  State<ClientDetailPanel> createState() => _ClientDetailPanelState();
}

class _ClientDetailPanelState extends State<ClientDetailPanel> {
  final ClientContractsApi _contractsApi = ClientContractsApi();
  final ReceiptsApi _receiptsApi = ReceiptsApi();
  int _contractsCount = 0;
  int _receiptsCount = 0;
  String? _contractsCountClientId;
  String? _receiptsCountRequestKey;

  @override
  void initState() {
    super.initState();
    _loadContractsCount();
    _loadReceiptsCount();
  }

  @override
  void didUpdateWidget(covariant ClientDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedClient?.id != widget.selectedClient?.id ||
        oldWidget.groupId != widget.groupId) {
      setState(() {
        _contractsCount = 0;
        _receiptsCount = 0;
      });
      _loadContractsCount();
      _loadReceiptsCount();
    }
  }

  Future<void> _loadContractsCount() async {
    final clientId = widget.selectedClient?.id.trim();
    if (clientId == null || clientId.isEmpty) return;
    _contractsCountClientId = clientId;
    try {
      final contracts = await _contractsApi.list(clientId);
      if (!mounted || _contractsCountClientId != clientId) return;
      setState(() => _contractsCount = contracts.length);
    } catch (_) {
      // Keep the tab usable; it will show the full error if the user opens it.
    }
  }

  Future<void> _loadReceiptsCount() async {
    final clientId = widget.selectedClient?.id.trim();
    final groupId = widget.groupId.trim();
    if (clientId == null || clientId.isEmpty || groupId.isEmpty) return;

    final requestKey = '$groupId:$clientId';
    _receiptsCountRequestKey = requestKey;
    try {
      final results = await Future.wait([
        _receiptsApi.list(groupId: groupId, status: 'issued'),
        _receiptsApi.list(groupId: groupId, status: 'draft'),
      ]);
      if (!mounted || _receiptsCountRequestKey != requestKey) return;
      final count = results
          .expand((receipts) => receipts)
          .where((receipt) => receipt.clientId == clientId)
          .length;
      setState(() => _receiptsCount = count);
    } catch (_) {
      // The receipts tab keeps its own detailed loading error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: widget.selectedClient == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 36, color: cs.primary),
                    const SizedBox(height: 10),
                    Text(
                      widget.clients.isEmpty
                          ? l.noClientsYet
                          : l.selectClientFirst,
                      textAlign: TextAlign.center,
                      style: t.bodyLarge.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.clients.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.noClientsYet,
                        textAlign: TextAlign.center,
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (widget.onAddClient != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('client-detail-add-client'),
                          onPressed: widget.onAddClient,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: Text(l.addClient),
                        ),
                      ],
                    ],
                  ],
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
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      ClientPropertyImage(client: widget.selectedClient!),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Text(widget.selectedClient!.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyLarge)),
                      IconButton(
                          onPressed: widget.onEditSelectedClient,
                          tooltip: l.editClient,
                          icon: const Icon(Icons.edit_outlined)),
                    ]),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
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

    // Label + neutral count pill; the active tab is marked by the underline.
    Tab tab({
      required IconData icon,
      required String label,
      int? count,
    }) {
      return Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: HexoraDocumentTokens.icon),
            const SizedBox(width: 6),
            Text(label),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: HexoraTypography.caption,
                    fontFeatures: HexoraTypography.numericFeatures,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return HexoraSectionTabs(
      compact: true,
      tabs: [
        tab(
          icon: Icons.receipt_long_outlined,
          label: l.invoicesListTitle,
          count: invoicesCount,
        ),
        tab(
          icon: Icons.description_outlined,
          label: l.receiptsTitle,
          count: receiptsCount,
        ),
        tab(
          icon: Icons.folder_outlined,
          label: l.contractsTitle,
          count: contractsCount,
        ),
        tab(
          icon: Icons.insights_outlined,
          label: isSpanish ? 'Gráfico' : 'Chart',
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeFilterCard(
            quickRange: _quickRange,
            expanded: _filtersExpanded,
            fromDate: _fromDate,
            toDate: _toDate,
            showLabel: true,
            trailingActions: [
              Tooltip(
                message: filtered.isEmpty
                    ? l.noInvoicesYet
                    : isSpanish
                        ? 'Descargar las facturas visibles (${filtered.length})'
                        : 'Download visible invoices (${filtered.length})',
                child: TextButton.icon(
                  onPressed: filtered.isEmpty || _downloadingVisible
                      ? null
                      : () => _downloadVisible(filtered),
                  style: TextButton.styleFrom(
                      minimumSize: Size(
                          0, MediaQuery.sizeOf(context).width < 650 ? 48 : 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: cs.onSurfaceVariant),
                  icon: _downloadingVisible
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.folder_zip_outlined, size: 14),
                  label: Text('ZIP (${filtered.length})', style: t.bodySmall),
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
            padding: EdgeInsets.zero,
            child: _MonthSeparator(label: item.label),
          );
        }
        final inv = item as Invoice;
        final client = widget.clients.firstWhere(
          (c) => c.id == inv.clientId,
          orElse: () => widget.fallbackClient,
        );

        return Padding(
          padding: EdgeInsets.zero,
          child: InvoiceListItem(
            invoice: inv,
            client: client,
            showClient: false,
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
    return HexoraMonthSeparator(label: label);
  }
}
