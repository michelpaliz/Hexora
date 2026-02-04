import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum InvoiceNumberSort { recent, numberAsc, numberDesc }

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
  final VoidCallback onCreateInvoice;
  final VoidCallback onRefresh;
  final InvoiceNumberSort numberSort;
  final ValueChanged<InvoiceNumberSort> onNumberSortChanged;
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
    required this.onCreateInvoice,
    required this.onRefresh,
    required this.numberSort,
    required this.onNumberSortChanged,
    this.sortLoading = false,
    this.initialTabIndex = 0,
    this.onOpenRecurringSeries,
  });

  @override
  State<GroupInvoicesInvoicesView> createState() =>
      _GroupInvoicesInvoicesViewState();
}

class _GroupInvoicesInvoicesViewState extends State<GroupInvoicesInvoicesView> {
  final _invoicesApi = InvoicesApi();
  bool _downloadingAll = false;

  Future<void> _downloadAllPdfs() async {
    if (_downloadingAll) return;
    if (widget.invoices.isEmpty && widget.drafts.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noInvoicesYet)),
      );
      return;
    }
    setState(() => _downloadingAll = true);
    try {
      final response = await _invoicesApi.downloadAllPdfsZip(widget.group.id);
      final fileName = 'invoices-${widget.group.id}.zip';
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType: 'application/zip',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DefaultTabController(
              length: 2,
              initialIndex: widget.initialTabIndex.clamp(0, 1),
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.invoicesListTitle,
                              style: t.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: widget.onCreateInvoice,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l.createInvoiceCta),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed:
                                _downloadingAll ? null : _downloadAllPdfs,
                            icon: _downloadingAll
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download_outlined),
                            label: Text('${l.download} PDFs'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              textStyle: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: l.refreshAction,
                            onPressed: widget.onRefresh,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: TabBar(
                        dividerColor: Colors.transparent,
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
                            numberSort: widget.numberSort,
                            onNumberSortChanged: widget.onNumberSortChanged,
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
                            numberSort: widget.numberSort,
                            onNumberSortChanged: widget.onNumberSortChanged,
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
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Card(
              clipBehavior: Clip.antiAlias,
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
                    ),
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
  final InvoiceNumberSort numberSort;
  final ValueChanged<InvoiceNumberSort> onNumberSortChanged;
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
    required this.numberSort,
    required this.onNumberSortChanged,
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
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeFilterCard(
            quickRange: _quickRange,
            expanded: _filtersExpanded,
            fromDate: _fromDate,
            toDate: _toDate,
            showLabel: true,
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _SortDropdown<_NumberSort>(
                label: l.invoiceSortByNumberLabel,
                value: _toNumberSort(widget.numberSort),
                items: {
                  _NumberSort.none: l.invoiceSortByNumberRecent,
                  _NumberSort.asc: l.invoiceSortByNumberAsc,
                  _NumberSort.desc: l.invoiceSortByNumberDesc,
                },
                enabled: !widget.sortLoading,
                onChanged: (v) => widget.onNumberSortChanged(
                  _fromNumberSort(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: EmptyView(
                      icon: widget.icon,
                      title: widget.emptyTitle,
                      subtitle: widget.emptySubtitle,
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final inv = visible[i];
                      final selected = widget.selectedInvoiceId == inv.id;
                      final client = widget.clients.firstWhere(
                        (c) => c.id == inv.clientId,
                        orElse: () => GroupClient(
                          id: inv.clientId,
                          name: l.unknownClient,
                          isActive: true,
                        ),
                      );
                      return InvoiceListItem(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

enum _NumberSort { none, asc, desc }

class _SortDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final bool enabled;

  const _SortDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        isDense: true,
        onChanged: enabled
            ? (v) {
                if (v != null) onChanged(v);
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          suffixIcon: enabled
              ? null
              : const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        ),
        items: items.entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value, style: t.bodySmall),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

_NumberSort _toNumberSort(InvoiceNumberSort sort) {
  return switch (sort) {
    InvoiceNumberSort.recent => _NumberSort.none,
    InvoiceNumberSort.numberAsc => _NumberSort.asc,
    InvoiceNumberSort.numberDesc => _NumberSort.desc,
  };
}

InvoiceNumberSort _fromNumberSort(_NumberSort sort) {
  return switch (sort) {
    _NumberSort.none => InvoiceNumberSort.recent,
    _NumberSort.asc => InvoiceNumberSort.numberAsc,
    _NumberSort.desc => InvoiceNumberSort.numberDesc,
  };
}
