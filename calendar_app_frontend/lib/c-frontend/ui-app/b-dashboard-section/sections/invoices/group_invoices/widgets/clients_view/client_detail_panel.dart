import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_list_item.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/billing_verification_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/quick_assignment_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientDetailPanel extends StatefulWidget {
  final List<GroupClient> clients;
  final GroupClient? selectedClient;
  final List<Invoice> issuedInvoices;
  final List<Invoice> draftInvoices;

  final List<String> entityOptions;
  final List<String> propertyOptions;
  final bool assignBusy;

  final VoidCallback onEditSelectedClient;
  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateReceipt;
  final ValueChanged<Invoice> onOpenInvoiceDetail;
  final ValueChanged<Invoice> onDeleteInvoice;

  final Future<void> Function({String? entityType, String? propertyKind})
      onApplyClassification;

  const ClientDetailPanel({
    super.key,
    required this.clients,
    required this.selectedClient,
    required this.issuedInvoices,
    required this.draftInvoices,
    required this.entityOptions,
    required this.propertyOptions,
    required this.assignBusy,
    required this.onEditSelectedClient,
    required this.onCreateInvoice,
    required this.onCreateReceipt,
    required this.onOpenInvoiceDetail,
    required this.onDeleteInvoice,
    required this.onApplyClassification,
  });

  @override
  State<ClientDetailPanel> createState() => _ClientDetailPanelState();
}

class _ClientDetailPanelState extends State<ClientDetailPanel> {
  bool _headerExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
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
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _Header(
                        clientName: widget.selectedClient!.name,
                        entityType:
                            (widget.selectedClient!.entityType ?? '').trim(),
                        propertyKind:
                            (widget.selectedClient!.propertyKind ?? '').trim(),
                        expanded: _headerExpanded,
                        onToggleExpanded: () =>
                            setState(() => _headerExpanded = !_headerExpanded),
                        onEdit: widget.onEditSelectedClient,
                        onCreateInvoice: widget.onCreateInvoice,
                        onCreateReceipt: widget.onCreateReceipt,
                      ),
                    ),
                  ),
                  if (_headerExpanded) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: _QuickAssignAndBilling(
                          clients: widget.clients,
                          selectedClient: widget.selectedClient!,
                          entityOptions: widget.entityOptions,
                          propertyOptions: widget.propertyOptions,
                          assignBusy: widget.assignBusy,
                          onApplyClassification: widget.onApplyClassification,
                          onEditClient: widget.onEditSelectedClient,
                        ),
                      ),
                    ),
                  ],
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarHeaderDelegate(
                      child: _ClientTabs(
                        invoicesCount: widget.issuedInvoices.length,
                        draftsCount: widget.draftInvoices.length,
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
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
                    ),
                    _InvoiceList(
                      emptyTitle: l.groupInvoicesDraftInvoicesTitle,
                      emptySubtitle: l.noInvoicesYetSubtitle,
                      icon: Icons.drafts_outlined,
                      invoices: widget.draftInvoices,
                      clients: widget.clients,
                      fallbackClient: widget.selectedClient!,
                      onTap: widget.onOpenInvoiceDetail,
                      onDelete: widget.onDeleteInvoice,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final String clientName;
  final String entityType;
  final String propertyKind;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEdit;
  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateReceipt;

  const _Header({
    required this.clientName,
    required this.entityType,
    required this.propertyKind,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onEdit,
    required this.onCreateInvoice,
    required this.onCreateReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final chips = <Widget>[];
    if (entityType.isNotEmpty) {
      chips.add(_MiniChip(label: entityType));
    }
    if (propertyKind.isNotEmpty) {
      chips.add(_MiniChip(label: propertyKind));
    }

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggleExpanded,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      clientName.trim().isEmpty
                          ? '?'
                          : clientName.trim().substring(0, 1).toUpperCase(),
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: ThemeColors.textPrimary(context),
                          ),
                        ),
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 6, children: chips),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: expanded
                        ? l.clientDetailsCollapseTooltip
                        : l.clientDetailsExpandTooltip,
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;

                  final editBtn = OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l.edit),
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  );

                  final invoiceBtn = FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l.createInvoiceCta),
                    onPressed: onCreateInvoice,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  );

                  final receiptBtn = FilledButton.tonalIcon(
                    icon: const Icon(Icons.description_outlined),
                    label: Text(l.createReceiptCta),
                    onPressed: onCreateReceipt,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  );

                  if (!compact) {
                    return Row(
                      children: [
                        Expanded(child: editBtn),
                        const SizedBox(width: 10),
                        Expanded(child: invoiceBtn),
                        const SizedBox(width: 10),
                        Expanded(child: receiptBtn),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: editBtn),
                          const SizedBox(width: 10),
                          Expanded(child: invoiceBtn),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: receiptBtn),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ClientTabs extends StatelessWidget {
  final int invoicesCount;
  final int draftsCount;

  const _ClientTabs({
    required this.invoicesCount,
    required this.draftsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return TabBar(
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
      labelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
      unselectedLabelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      labelPadding: EdgeInsets.zero,
      tabs: [
        Tab(text: l.groupInvoicesTabInvoices(invoicesCount)),
        Tab(text: l.groupInvoicesTabDrafts(draftsCount)),
      ],
    );
  }
}

class _QuickAssignAndBilling extends StatelessWidget {
  final List<GroupClient> clients;
  final GroupClient selectedClient;
  final List<String> entityOptions;
  final List<String> propertyOptions;
  final bool assignBusy;
  final Future<void> Function({String? entityType, String? propertyKind})
      onApplyClassification;
  final VoidCallback onEditClient;

  const _QuickAssignAndBilling({
    required this.clients,
    required this.selectedClient,
    required this.entityOptions,
    required this.propertyOptions,
    required this.assignBusy,
    required this.onApplyClassification,
    required this.onEditClient,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuickAssignmentCard(
          client: selectedClient,
          entityOptions: entityOptions,
          propertyOptions: propertyOptions,
          busy: assignBusy,
          onApplyClassification: onApplyClassification,
        ),
        if (entityOptions.isNotEmpty || propertyOptions.isNotEmpty)
          const SizedBox(height: 12),
        BillingVerificationCard(
          client: selectedClient,
          onEdit: onEditClient,
        ),
        const SizedBox(height: 2),
        Text(
          AppLocalizations.of(context)!.billingDetailsSubtitle,
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
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

  const _InvoiceList({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.invoices,
    required this.clients,
    required this.fallbackClient,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<_InvoiceList> {
  DateTime? _fromDate;
  DateTime? _toDate;
  DateQuickRange _quickRange = DateQuickRange.none;
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
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
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
            showLabel: false,
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
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final inv = filtered[i];
                      final client = widget.clients.firstWhere(
                        (c) => c.id == inv.clientId,
                        orElse: () => widget.fallbackClient,
                      );

                      return InvoiceListItem(
                        invoice: inv,
                        client: client,
                        onTap: () => widget.onTap(inv),
                        onDelete: widget.onDelete == null
                            ? null
                            : () => widget.onDelete!(inv),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabBarHeaderDelegate({required this.child});

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}
