import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'invoice_row_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum InvoiceSortBy { date, number }

enum InvoiceSortDir { asc, desc }

class InvoiceSortState {
  final InvoiceSortBy by;
  final InvoiceSortDir dir;

  const InvoiceSortState({
    required this.by,
    required this.dir,
  });

  InvoiceSortState copyWith({
    InvoiceSortBy? by,
    InvoiceSortDir? dir,
  }) {
    return InvoiceSortState(
      by: by ?? this.by,
      dir: dir ?? this.dir,
    );
  }
}

InvoiceSortState nextInvoiceSortState(
  InvoiceSortState current,
  InvoiceSortBy selectedBy,
) {
  if (current.by == selectedBy) {
    return current.copyWith(
      dir: current.dir == InvoiceSortDir.desc
          ? InvoiceSortDir.asc
          : InvoiceSortDir.desc,
    );
  }
  return InvoiceSortState(by: selectedBy, dir: InvoiceSortDir.desc);
}

class GroupInvoicesInvoicesView extends StatefulWidget {
  final List<Invoice> drafts;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final BillingProfile? billingProfile;
  final Group group;
  final Invoice? selectedInvoice;
  final ValueChanged<Invoice> onSelectInvoice;
  final ValueChanged<Invoice> onDeleteInvoice;
  final ValueChanged<Invoice> onEditDraft;
  final ValueChanged<Invoice> onIssueDraft;
  final VoidCallback onCreateInvoice;
  final VoidCallback onRefresh;
  final InvoiceSortState sortState;
  final ValueChanged<InvoiceSortBy> onSortBySelected;
  final bool sortLoading;
  final int initialTabIndex;
  final ValueChanged<String>? onOpenRecurringSeries;

  const GroupInvoicesInvoicesView({
    super.key,
    required this.drafts,
    required this.invoices,
    required this.clients,
    required this.billingProfile,
    required this.group,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    required this.onDeleteInvoice,
    required this.onEditDraft,
    required this.onIssueDraft,
    required this.onCreateInvoice,
    required this.onRefresh,
    required this.sortState,
    required this.onSortBySelected,
    this.sortLoading = false,
    this.initialTabIndex = 0,
    this.onOpenRecurringSeries,
  });

  @override
  State<GroupInvoicesInvoicesView> createState() =>
      _GroupInvoicesInvoicesViewState();
}

class _GroupInvoicesInvoicesViewState extends State<GroupInvoicesInvoicesView> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DefaultTabController(
              length: 2,
              initialIndex: widget.initialTabIndex.clamp(0, 1),
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStatePropertyAll(
                          cs.primary.withValues(alpha: 0.08),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        labelColor: cs.onPrimaryContainer,
                        unselectedLabelColor: cs.onSurfaceVariant,
                        labelStyle:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                        unselectedLabelStyle:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                        indicatorPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                        tabs: [
                          Tab(
                            text: l.groupInvoicesTabDrafts(
                              widget.drafts.length,
                            ),
                          ),
                          Tab(
                              text: l.groupInvoicesTabInvoices(
                                  widget.invoices.length)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _InvoicesTabList(
                            emptyTitle: l.groupInvoicesDraftInvoicesTitle,
                            emptySubtitle: l.noInvoicesYetSubtitle,
                            icon: Icons.drafts_outlined,
                            invoices: widget.drafts,
                            clients: widget.clients,
                            onTap: widget.onSelectInvoice,
                            onDelete: widget.onDeleteInvoice,
                            onEdit: widget.onEditDraft,
                            onIssue: widget.onIssueDraft,
                            sortState: widget.sortState,
                            onSortBySelected: widget.onSortBySelected,
                            sortLoading: widget.sortLoading,
                            selectedInvoiceId: widget.selectedInvoice?.id,
                          ),
                          _InvoicesTabList(
                            emptyTitle: l.noInvoicesYet,
                            emptySubtitle: l.noInvoicesYetSubtitle,
                            icon: Icons.receipt_long_outlined,
                            invoices: widget.invoices,
                            clients: widget.clients,
                            onTap: widget.onSelectInvoice,
                            onDelete: null,
                            onEdit: null,
                            onIssue: null,
                            sortState: widget.sortState,
                            onSortBySelected: widget.onSortBySelected,
                            sortLoading: widget.sortLoading,
                            selectedInvoiceId: widget.selectedInvoice?.id,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Card(
              clipBehavior: Clip.antiAlias,
              color: Colors.transparent,
              elevation: 0,
              child: widget.selectedInvoice == null
                  ? Center(
                      child: Text(
                        l.groupInvoicesSelectInvoiceHint,
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : InvoiceDetailSheet(
                      key: ValueKey(widget.selectedInvoice!.id),
                      invoice: widget.selectedInvoice!,
                      client: widget.clients.firstWhere(
                        (c) => c.id == widget.selectedInvoice!.clientId,
                        orElse: () => GroupClient(
                          id: widget.selectedInvoice!.clientId,
                          name: l.unknownClient,
                          isActive: true,
                        ),
                      ),
                      billingProfile: widget.billingProfile,
                      group: widget.group,
                      onOpenRecurringSeries: widget.onOpenRecurringSeries,
                      onInvoiceChanged: widget.onRefresh,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthDivider extends StatelessWidget {
  const _MonthDivider({required this.label, this.first = false});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesTabList extends StatefulWidget {
  final String emptyTitle;
  final String emptySubtitle;
  final IconData icon;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final ValueChanged<Invoice> onTap;
  final ValueChanged<Invoice>? onDelete;
  final ValueChanged<Invoice>? onEdit;
  final ValueChanged<Invoice>? onIssue;
  final InvoiceSortState sortState;
  final ValueChanged<InvoiceSortBy> onSortBySelected;
  final bool sortLoading;
  final String? selectedInvoiceId;

  const _InvoicesTabList({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.invoices,
    required this.clients,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onIssue,
    required this.sortState,
    required this.onSortBySelected,
    required this.sortLoading,
    required this.selectedInvoiceId,
  });

  @override
  State<_InvoicesTabList> createState() => _InvoicesTabListState();
}

class _InvoicesTabListState extends State<_InvoicesTabList> {
  DateQuickRange _quickRange = DateQuickRange.none;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _filtersExpanded = false;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  DateTime? _invoiceDate(Invoice inv) =>
      inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;

  String _invoiceMonthLabel(DateTime dt, bool isSpanish) {
    const es = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${(isSpanish ? es : en)[dt.month - 1]} ${dt.year}';
  }

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
    final visible = filtered;

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

              Widget sortButton({
                required InvoiceSortBy value,
                required String label,
                required String tooltip,
              }) {
                final active = currentSort.by == value;
                final isAsc = currentSort.dir == InvoiceSortDir.asc;
                return Tooltip(
                  message: tooltip,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: widget.sortLoading
                        ? null
                        : () => widget.onSortBySelected(value),
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

              return DateRangeFilterCard(
                quickRange: _quickRange,
                expanded: _filtersExpanded,
                fromDate: _fromDate,
                toDate: _toDate,
                showLabel: true,
                labelActions: [
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
              );
            },
          ),
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
                    final byDate =
                        widget.sortState.by == InvoiceSortBy.date;

                    // Flat list: String = month header, Invoice = row.
                    // Only inject headers when sorted by date.
                    final items = <Object>[];
                    if (byDate) {
                      String? lastKey;
                      for (final inv in visible) {
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
                    } else {
                      items.addAll(visible);
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
                        final client = widget.clients.firstWhere(
                          (c) => c.id == inv.clientId,
                          orElse: () => GroupClient(
                            id: inv.clientId,
                            name: l.unknownClient,
                            isActive: true,
                          ),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InvoiceListItem(
                            invoice: inv,
                            client: client,
                            selected: selected,
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







