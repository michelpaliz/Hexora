import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_detail_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/widgets/receipt_list_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _receiptMonthLabel(DateTime dt, String locale) {
  final formatter = DateFormat.yMMMM(locale);
  final raw = formatter.format(dt.toLocal());
  return raw[0].toUpperCase() + raw.substring(1);
}

String _receiptClientDisplayName(Receipt receipt, String fallback) {
  final snapshotName = receipt.clientSnapshot?.legalName?.trim();
  if (snapshotName != null && snapshotName.isNotEmpty) return snapshotName;
  final manualName = receipt.clientName?.trim();
  if (manualName != null && manualName.isNotEmpty) return manualName;
  return fallback;
}

GroupClient _receiptClientFor(
  Receipt receipt,
  List<GroupClient> clients,
  String unknownClientLabel,
) {
  GroupClient? existing;
  for (final client in clients) {
    if (client.id == receipt.clientId) {
      existing = client;
      break;
    }
  }
  final fallback = existing?.name ?? unknownClientLabel;
  final displayName = _receiptClientDisplayName(receipt, fallback);
  return existing == null
      ? GroupClient(
          id: receipt.clientId,
          name: displayName,
          isActive: true,
        )
      : existing.copyWith(name: displayName);
}

class _MonthDivider extends StatelessWidget {
  const _MonthDivider({required this.label, this.first = false});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) => HexoraMonthSeparator(label: label);
}

enum _ReceiptSortColumn { number, client, status, date, base, total }

class _ReceiptRange {
  const _ReceiptRange({this.min, this.max});
  final num? min;
  final num? max;
  bool get active => min != null || max != null;
  bool includes(num value) =>
      (min == null || value >= min!) && (max == null || value <= max!);
}

class _GroupedReceiptList extends StatefulWidget {
  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final String unknownClientLabel;
  final EdgeInsetsGeometry padding;
  final Widget Function(
    Receipt,
    GroupClient,
    Set<HexoraFinancialColumn>,
  ) itemBuilder;

  const _GroupedReceiptList({
    required this.receipts,
    required this.clients,
    required this.unknownClientLabel,
    required this.padding,
    required this.itemBuilder,
  });

  @override
  State<_GroupedReceiptList> createState() => _GroupedReceiptListState();
}

class _GroupedReceiptListState extends State<_GroupedReceiptList> {
  static const _available = {
    HexoraFinancialColumn.date,
    HexoraFinancialColumn.taxableBase,
    HexoraFinancialColumn.total,
  };
  Set<HexoraFinancialColumn> _visible = Set.of(_available);
  String _numberQuery = '';
  Set<String> _clients = {};
  Set<String> _statuses = {};
  Set<String> _deliveryStatuses = {};
  DateTime? _fromDate;
  DateTime? _toDate;
  _ReceiptRange _baseRange = const _ReceiptRange();
  _ReceiptRange _totalRange = const _ReceiptRange();
  _ReceiptSortColumn? _sort;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    HexoraColumnVisibilityStore.load('recibos', _available).then((value) {
      if (mounted) setState(() => _visible = value);
    });
  }

  DateTime? _date(Receipt r) => r.issueDate ?? r.registeredAt;

  num _total(Receipt receipt) =>
      receipt.total ??
      receipt.lines.fold<num>(
        0,
        (sum, line) => sum + (line.total ?? (line.quantity * line.unitPrice)),
      );

  String _clientName(Receipt receipt) => _receiptClientFor(
        receipt,
        widget.clients,
        widget.unknownClientLabel,
      ).name.trim().toLowerCase();

  String _status(Receipt receipt) {
    final raw = (receipt.status ?? '').trim().toLowerCase();
    if (raw.contains('void') || raw.contains('cancel')) return 'void';
    if (raw.contains('issue')) return 'issued';
    return 'draft';
  }

  String _statusLabel(String value) => switch (value) {
        'draft' => 'Borrador',
        'void' => 'Anulado',
        _ => 'Emitido',
      };

  String _deliveryLabel(String value) => switch (value) {
        'sent' => 'Enviado',
        'failed' => 'Error de envío',
        _ => 'No enviado',
      };

  bool get _hasFilters =>
      _numberQuery.isNotEmpty ||
      _clients.isNotEmpty ||
      _statuses.isNotEmpty ||
      _deliveryStatuses.isNotEmpty ||
      _fromDate != null ||
      _toDate != null ||
      _baseRange.active ||
      _totalRange.active;

  void _setSort(_ReceiptSortColumn column, bool ascending) => setState(() {
        _sort = column;
        _ascending = ascending;
      });

  void _clearAll() => setState(() {
        _numberQuery = '';
        _clients = {};
        _statuses = {};
        _deliveryStatuses = {};
        _fromDate = null;
        _toDate = null;
        _baseRange = const _ReceiptRange();
        _totalRange = const _ReceiptRange();
      });

  void _setDateMonths(int months) {
    final now = DateTime.now();
    setState(() {
      _toDate = now;
      _fromDate = DateTime(now.year, now.month - months, now.day + 1);
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final value = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _fromDate == null || _toDate == null
          ? null
          : DateTimeRange(start: _fromDate!, end: _toDate!),
      builder: hexoraCompactDateRangePickerBuilder,
    );
    if (value != null) {
      setState(() {
        _fromDate = value.start;
        _toDate = value.end;
      });
    }
  }

  bool _filterActive(CompactDocumentColumn column) => switch (column) {
        CompactDocumentColumn.identity => _numberQuery.isNotEmpty,
        CompactDocumentColumn.client => _clients.isNotEmpty,
        CompactDocumentColumn.status =>
          _statuses.isNotEmpty || _deliveryStatuses.isNotEmpty,
        CompactDocumentColumn.date => _fromDate != null || _toDate != null,
        CompactDocumentColumn.taxableBase => _baseRange.active,
        CompactDocumentColumn.total => _totalRange.active,
        _ => false,
      };

  _ReceiptSortColumn _sortColumn(CompactDocumentColumn column) =>
      switch (column) {
        CompactDocumentColumn.identity => _ReceiptSortColumn.number,
        CompactDocumentColumn.client => _ReceiptSortColumn.client,
        CompactDocumentColumn.status => _ReceiptSortColumn.status,
        CompactDocumentColumn.date => _ReceiptSortColumn.date,
        CompactDocumentColumn.taxableBase => _ReceiptSortColumn.base,
        _ => _ReceiptSortColumn.total,
      };

  void _clearColumn(CompactDocumentColumn column) => setState(() {
        switch (column) {
          case CompactDocumentColumn.identity:
            _numberQuery = '';
          case CompactDocumentColumn.client:
            _clients = {};
          case CompactDocumentColumn.status:
            _statuses = {};
            _deliveryStatuses = {};
          case CompactDocumentColumn.delivery:
            _deliveryStatuses = {};
          case CompactDocumentColumn.date:
            _fromDate = null;
            _toDate = null;
          case CompactDocumentColumn.taxableBase:
            _baseRange = const _ReceiptRange();
          case CompactDocumentColumn.total:
            _totalRange = const _ReceiptRange();
          case CompactDocumentColumn.payment:
          case CompactDocumentColumn.vat:
            break;
        }
      });

  Widget _header(
    BuildContext context,
    CompactDocumentColumn column,
    String label,
    double width,
    bool numeric,
  ) {
    final sortColumn = _sortColumn(column);
    final active = _filterActive(column);
    final direction = _sort == sortColumn
        ? (_ascending
            ? HexoraHeaderSortDirection.ascending
            : HexoraHeaderSortDirection.descending)
        : null;
    final clientValues = widget.receipts
        .map(_clientName)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final statusValues = widget.receipts.map(_status).toSet().toList();
    final deliveryValues = widget.receipts
        .map((r) => normalizedDeliveryStatus(r.deliveryStatus))
        .toSet()
        .toList();

    Widget filter = const SizedBox.shrink();
    if (column == CompactDocumentColumn.identity) {
      filter = TextFormField(
        initialValue: _numberQuery,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Número de recibo',
          hintText: 'Búsqueda exacta o parcial',
          prefixIcon: Icon(Icons.search_rounded, size: 18),
          isDense: true,
        ),
        onChanged: (value) => setState(() => _numberQuery = value.trim()),
      );
    } else if (column == CompactDocumentColumn.client) {
      filter = HexoraMultiSelectFilter(
        values: clientValues,
        selected: _clients,
        labelFor: (value) => value,
        onChanged: (value) => setState(() => _clients = value),
        searchable: true,
        searchHint: 'Buscar cliente...',
        emptyLabel: 'No se encontraron clientes',
        selectionSingularLabel: 'cliente seleccionado',
        selectionPluralLabel: 'clientes seleccionados',
      );
    } else if (column == CompactDocumentColumn.status) {
      filter = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Documento', style: Theme.of(context).textTheme.labelSmall),
          HexoraMultiSelectFilter(
            values: statusValues,
            selected: _statuses,
            labelFor: _statusLabel,
            onChanged: (value) => setState(() => _statuses = value),
          ),
          const SizedBox(height: 6),
          Text('Entrega', style: Theme.of(context).textTheme.labelSmall),
          HexoraMultiSelectFilter(
            values: deliveryValues,
            selected: _deliveryStatuses,
            labelFor: _deliveryLabel,
            onChanged: (value) => setState(() => _deliveryStatuses = value),
          ),
        ],
      );
    } else if (column == CompactDocumentColumn.date) {
      filter = Wrap(spacing: 6, runSpacing: 6, children: [
        ActionChip(
            label: const Text('Mes'), onPressed: () => _setDateMonths(1)),
        ActionChip(
            label: const Text('Trimestre'), onPressed: () => _setDateMonths(3)),
        ActionChip(
            label: const Text('Año'), onPressed: () => _setDateMonths(12)),
        ActionChip(
            avatar: const Icon(Icons.date_range_outlined, size: 15),
            label: const Text('Rango'),
            onPressed: _pickDateRange),
      ]);
    } else if (column == CompactDocumentColumn.taxableBase) {
      filter = HexoraAmountRangeInput(
        min: _baseRange.min,
        max: _baseRange.max,
        onChanged: (min, max) =>
            setState(() => _baseRange = _ReceiptRange(min: min, max: max)),
      );
    } else if (column == CompactDocumentColumn.total) {
      filter = HexoraAmountRangeInput(
        min: _totalRange.min,
        max: _totalRange.max,
        onChanged: (min, max) =>
            setState(() => _totalRange = _ReceiptRange(min: min, max: max)),
      );
    }

    return HexoraFilterableHeaderCell(
      label: label,
      width: width,
      numeric: numeric,
      centered: column == CompactDocumentColumn.status,
      filterActive: active,
      sortDirection: direction,
      menuBuilder: (_) => HexoraColumnFilterMenu(
        label: label,
        sortDirection: direction,
        onSortAscending: () => _setSort(sortColumn, true),
        onSortDescending: () => _setSort(sortColumn, false),
        filterActive: active,
        onClear: () => _clearColumn(column),
        child: filter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final start = _fromDate == null
        ? null
        : DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final end = _toDate == null
        ? null
        : DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
    final filtered = widget.receipts.where((receipt) {
      final number = (receipt.receiptNumber ?? '').toLowerCase();
      if (_numberQuery.isNotEmpty &&
          !number.contains(_numberQuery.toLowerCase())) {
        return false;
      }
      if (_clients.isNotEmpty && !_clients.contains(_clientName(receipt))) {
        return false;
      }
      if (_statuses.isNotEmpty && !_statuses.contains(_status(receipt))) {
        return false;
      }
      if (_deliveryStatuses.isNotEmpty &&
          !_deliveryStatuses
              .contains(normalizedDeliveryStatus(receipt.deliveryStatus))) {
        return false;
      }
      final date = _date(receipt);
      if (start != null && (date == null || date.isBefore(start))) {
        return false;
      }
      if (end != null && (date == null || date.isAfter(end))) {
        return false;
      }
      if (_baseRange.active && !_baseRange.includes(receipt.subtotal ?? 0)) {
        return false;
      }
      if (_totalRange.active && !_totalRange.includes(_total(receipt))) {
        return false;
      }
      return true;
    }).toList();
    int compare(Receipt a, Receipt b) => switch (_sort) {
          _ReceiptSortColumn.number => (a.receiptNumber ?? '')
              .toLowerCase()
              .compareTo((b.receiptNumber ?? '').toLowerCase()),
          _ReceiptSortColumn.client => _clientName(a).compareTo(_clientName(b)),
          _ReceiptSortColumn.status => _status(a).compareTo(_status(b)),
          _ReceiptSortColumn.date =>
            (_date(a) ?? DateTime(9999)).compareTo(_date(b) ?? DateTime(9999)),
          _ReceiptSortColumn.base =>
            (a.subtotal ?? 0).compareTo(b.subtotal ?? 0),
          _ReceiptSortColumn.total => _total(a).compareTo(_total(b)),
          null => (_date(b) ?? DateTime(0)).compareTo(_date(a) ?? DateTime(0)),
        };
    final items = <Object>[];
    final groups = <String, List<Receipt>>{};
    final groupDates = <String, DateTime?>{};
    for (final r in filtered) {
      final date = _date(r);
      final key = date == null
          ? '__none__'
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(r);
      groupDates[key] ??= date;
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        final aDate = groupDates[a] ?? DateTime(0);
        final bDate = groupDates[b] ?? DateTime(0);
        final value = aDate.compareTo(bDate);
        return _sort == _ReceiptSortColumn.date && _ascending ? value : -value;
      });
    for (final key in groupKeys) {
      final rows = groups[key]!
        ..sort((a, b) {
          final value = compare(a, b);
          return _sort == null || _ascending ? value : -value;
        });
      final date = groupDates[key];
      items.add(date == null ? '—' : _receiptMonthLabel(date, locale));
      items.addAll(rows);
    }

    return ListView.builder(
      padding: widget.padding,
      itemCount: items.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const DocumentLayoutSelector(
                    key: ValueKey('receipt-layout-selector'),
                  ),
                  const SizedBox(width: 8),
                  Text('${filtered.length} recibos'),
                  const Spacer(),
                  if (_hasFilters)
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                      label: const Text('Limpiar filtros'),
                    ),
                  HexoraColumnVisibilityMenu(
                    moduleKey: 'recibos',
                    availableColumns: _available,
                    visibleColumns: _visible,
                    onChanged: (value) => setState(() => _visible = value),
                  ),
                ]),
              ),
              CompactDocumentTableHeader(
                identityLabel: 'Recibo',
                visibleFinancialColumns: _visible,
                actionsWidth: 128,
                headerBuilder: _header,
              ),
            ],
          );
        }
        final item = items[i - 1];
        if (item is String) return _MonthDivider(label: item, first: i == 0);
        final r = item as Receipt;
        final client = _receiptClientFor(
          r,
          widget.clients,
          widget.unknownClientLabel,
        );
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).width < 650 ? 8 : 0),
          child: widget.itemBuilder(r, client, _visible),
        );
      },
    );
  }
}

class _IssuedReceiptsTab extends StatefulWidget {
  const _IssuedReceiptsTab({
    required this.receipts,
    required this.clients,
    required this.unknownClientLabel,
    required this.selectedId,
    required this.onSelect,
    required this.onPreview,
    required this.onDownload,
    required this.onMarkSent,
    required this.onMarkUnsent,
  });

  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final String unknownClientLabel;
  final String? selectedId;
  final ValueChanged<Receipt> onSelect;
  final Future<void> Function(Receipt) onPreview;
  final ValueChanged<Receipt> onDownload;
  final ValueChanged<Receipt> onMarkSent;
  final ValueChanged<Receipt> onMarkUnsent;

  @override
  State<_IssuedReceiptsTab> createState() => _IssuedReceiptsTabState();
}

class _IssuedReceiptsTabState extends State<_IssuedReceiptsTab> {
  @override
  Widget build(BuildContext context) {
    return _GroupedReceiptList(
      receipts: widget.receipts,
      clients: widget.clients,
      unknownClientLabel: widget.unknownClientLabel,
      padding: const EdgeInsets.all(10),
      itemBuilder: (receipt, client, visibleColumns) => ReceiptListItem(
        receipt: receipt,
        client: client,
        selected: receipt.id == widget.selectedId,
        visibleFinancialColumns: visibleColumns,
        onTap: () => widget.onSelect(receipt),
        onPreview: () => widget.onPreview(receipt),
        onDownload: () => widget.onDownload(receipt),
        onMarkSent: () => widget.onMarkSent(receipt),
        onMarkUnsent: () => widget.onMarkUnsent(receipt),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class GroupReceiptsView extends StatelessWidget {
  final List<Receipt> drafts;
  final List<Receipt> receipts;
  final List<GroupClient> clients;
  final BillingProfile? billingProfile;

  final Receipt? selectedReceipt;
  final ValueChanged<Receipt> onSelectReceipt;

  final VoidCallback onCreateReceipt;
  final ValueChanged<Receipt> onEditReceipt;
  final ValueChanged<Receipt> onIssueReceipt;
  final ValueChanged<Receipt> onMarkReceiptSent;
  final ValueChanged<Receipt> onMarkReceiptUnsent;
  final ValueChanged<Receipt> onDeleteReceipt;
  final Future<void> Function(Receipt) onPreviewPdf;
  final ValueChanged<Receipt> onDownloadPdf;
  final ValueChanged<Receipt> onImportJson;
  final Future<Uint8List?> Function(Receipt) onLoadInlinePdf;
  final bool disableDetailPreviewInteraction;
  final int initialTabIndex;
  final bool showHeaderTabs;
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onClearSelection;
  final ValueNotifier<DocumentViewMode?> modeNotifier;

  const GroupReceiptsView({
    super.key,
    required this.drafts,
    required this.receipts,
    required this.clients,
    required this.billingProfile,
    required this.selectedReceipt,
    required this.onSelectReceipt,
    required this.onCreateReceipt,
    required this.onEditReceipt,
    required this.onIssueReceipt,
    required this.onMarkReceiptSent,
    required this.onMarkReceiptUnsent,
    required this.onDeleteReceipt,
    required this.onPreviewPdf,
    required this.onDownloadPdf,
    required this.onImportJson,
    required this.onLoadInlinePdf,
    this.disableDetailPreviewInteraction = false,
    this.initialTabIndex = 1,
    this.showHeaderTabs = true,
    this.onTabChanged,
    this.onClearSelection,
    required this.modeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final totalCount = drafts.length + receipts.length;
    final activeReceipts = initialTabIndex == 0 ? drafts : receipts;
    final selectedIndex = selectedReceipt == null
        ? -1
        : activeReceipts.indexWhere((item) => item.id == selectedReceipt!.id);

    return Padding(
      padding: const EdgeInsets.all(5),
      child: DocumentSplitView(
        storageKey: 'receipts',
        modeNotifier: modeNotifier,
        selectionKey: selectedReceipt?.id,
        list: DefaultTabController(
          key: ValueKey('receipt-tabs-$initialTabIndex-$showHeaderTabs'),
          length: 2,
          initialIndex: initialTabIndex.clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surface.withValues(alpha: 0.20)
                  : cs.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(
                  alpha: isDark ? 0.20 : 0.25,
                ),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (showHeaderTabs) ...[
                  // Header row
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.30)
                          : cs.surfaceContainerLow.withValues(alpha: 0.60),
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(
                            alpha: isDark ? 0.20 : 0.25,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cs.primary.withValues(alpha: 0.22),
                                cs.primary.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 15,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEs ? 'Documentos' : 'Documents',
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (totalCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$totalCount',
                              style: t.bodySmall.copyWith(
                                color: cs.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        Tooltip(
                          message: isEs ? 'Nuevo documento' : 'New document',
                          child: IconButton(
                            onPressed: onCreateReceipt,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            style: IconButton.styleFrom(
                              foregroundColor: cs.primary,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              padding: const EdgeInsets.all(6),
                              minimumSize: const Size(32, 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: HexoraSectionTabs(
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_note_rounded, size: 14),
                              const SizedBox(width: 5),
                              Text(l.groupReceiptsTabDrafts(drafts.length)),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.task_alt_rounded, size: 14),
                              const SizedBox(width: 5),
                              Text(l.groupReceiptsTabReceipts(receipts.length)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(
                      alpha: isDark ? 0.20 : 0.25,
                    ),
                  ),
                ],
                Expanded(
                  child: TabBarView(
                    children: [
                      _GroupedReceiptList(
                        receipts: drafts,
                        clients: clients,
                        unknownClientLabel: l.unknownClient,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (r, client, visibleColumns) =>
                            ReceiptListItem(
                          receipt: r,
                          client: client,
                          selected: r.id == selectedReceipt?.id,
                          visibleFinancialColumns: visibleColumns,
                          onTap: () => onSelectReceipt(r),
                          onPreview: () => onPreviewPdf(r),
                          onEdit: () => onEditReceipt(r),
                          onDownload: () => onDownloadPdf(r),
                          onIssue: () => onIssueReceipt(r),
                          onDelete: () => onDeleteReceipt(r),
                        ),
                      ),
                      _IssuedReceiptsTab(
                        receipts: receipts,
                        clients: clients,
                        unknownClientLabel: l.unknownClient,
                        selectedId: selectedReceipt?.id,
                        onSelect: onSelectReceipt,
                        onPreview: onPreviewPdf,
                        onDownload: onDownloadPdf,
                        onMarkSent: onMarkReceiptSent,
                        onMarkUnsent: onMarkReceiptUnsent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        preview: Container(
          decoration: BoxDecoration(
            color: isDark
                ? cs.surface.withValues(alpha: 0.20)
                : cs.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withValues(
                alpha: isDark ? 0.20 : 0.25,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: selectedReceipt == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cs.primary.withValues(alpha: 0.16),
                                cs.primary.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 26,
                            color: cs.primary.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEs
                              ? 'Sin documento seleccionado'
                              : 'No document selected',
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.groupReceiptsSelectReceiptHint,
                          textAlign: TextAlign.center,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.tonalIcon(
                          onPressed: onCreateReceipt,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(
                            isEs ? 'Nuevo documento' : 'New document',
                          ),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.comfortable,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ValueListenableBuilder<DocumentViewMode?>(
                  valueListenable: modeNotifier,
                  builder: (context, mode, _) => ReceiptDetailCard(
                    key: ValueKey(selectedReceipt!.id),
                    receipt: selectedReceipt!,
                    client: _receiptClientFor(
                      selectedReceipt!,
                      clients,
                      l.unknownClient,
                    ),
                    billingProfile: billingProfile,
                    onEdit: () => onEditReceipt(selectedReceipt!),
                    onPreviewPdf: () => onPreviewPdf(selectedReceipt!),
                    onDownloadPdf: () => onDownloadPdf(selectedReceipt!),
                    onIssue: () => onIssueReceipt(selectedReceipt!),
                    onMarkSent: () => onMarkReceiptSent(selectedReceipt!),
                    onMarkUnsent: () => onMarkReceiptUnsent(selectedReceipt!),
                    onDeleteDraft: () => onDeleteReceipt(selectedReceipt!),
                    onImportJson: () => onImportJson(selectedReceipt!),
                    onLoadInlinePdf: () => onLoadInlinePdf(selectedReceipt!),
                    previewInteractive: !disableDetailPreviewInteraction,
                    onPrevious: selectedIndex > 0
                        ? () =>
                            onSelectReceipt(activeReceipts[selectedIndex - 1])
                        : null,
                    onNext: selectedIndex >= 0 &&
                            selectedIndex + 1 < activeReceipts.length
                        ? () =>
                            onSelectReceipt(activeReceipts[selectedIndex + 1])
                        : null,
                    onClose: onClearSelection,
                    onExpand: null,
                    isExpanded: false,
                  ),
                ),
        ),
      ),
    );
  }
}
