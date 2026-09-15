import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/invoicing/recurring_invoices_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_details_sheet/invoice_detail_sheet.dart';
import 'invoice_row_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

part '../invoice_list/sections/invoice_list_layout.dart';
part '../invoice_list/sections/invoice_list_dialogs.dart';
part '../invoice_list/models/invoice_list_state.dart';
part '../invoice_list/controller/invoice_list_controller.dart';
part '../invoice_list/utils/invoice_client_helpers.dart';
part '../invoice_list/widgets/month_divider.dart';
part '../invoice_list/widgets/summary_totals_bar.dart';
part '../invoice_list/widgets/payment_notices.dart';

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
  final ValueChanged<List<Invoice>>? onIssueAllDrafts;
  final VoidCallback onCreateInvoice;
  final VoidCallback onRefresh;
  final InvoiceSortState sortState;
  final ValueChanged<InvoiceSortBy> onSortBySelected;
  final bool sortLoading;
  final bool? issueAllDraftsLoading;
  final int initialTabIndex;
  final ValueChanged<String>? onOpenRecurringSeries;
  final ValueChanged<InvoiceDateFilterState>? onIssuedDateFilterChanged;
  final Future<void> Function(List<Invoice>)? onDownloadFiltered;
  final bool canEditIssued;

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
    this.onIssueAllDrafts,
    required this.onCreateInvoice,
    required this.onRefresh,
    required this.sortState,
    required this.onSortBySelected,
    this.sortLoading = false,
    this.issueAllDraftsLoading = false,
    this.initialTabIndex = 0,
    this.onOpenRecurringSeries,
    this.onIssuedDateFilterChanged,
    this.onDownloadFiltered,
    this.canEditIssued = false,
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
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.18),
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: TabBar(
                          dividerColor: Colors.transparent,
                          splashFactory: NoSplash.splashFactory,
                          overlayColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: cs.onPrimary,
                          unselectedLabelColor: cs.onSurfaceVariant,
                          labelStyle:
                              t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                          unselectedLabelStyle:
                              t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                          indicatorPadding: EdgeInsets.zero,
                          padding: EdgeInsets.zero,
                          tabs: [
                            Tab(
                              text: l.groupInvoicesTabDrafts(
                                widget.drafts.length,
                              ),
                            ),
                            Tab(
                              text: l.groupInvoicesTabInvoices(
                                widget.invoices.length,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            onIssueAll: widget.onIssueAllDrafts,
                            sortState: widget.sortState,
                            onSortBySelected: widget.onSortBySelected,
                            sortLoading: widget.sortLoading,
                            issueAllLoading: widget.issueAllDraftsLoading,
                            selectedInvoiceId: widget.selectedInvoice?.id,
                            showSummaryTotals: false,
                            groupId: widget.group.id,
                            onOpenRecurringSeries: widget.onOpenRecurringSeries,
                            onDateFilterChanged: null,
                            allowClientNameSort: true,
                          ),
                          _InvoicesTabList(
                            emptyTitle: l.noInvoicesYet,
                            emptySubtitle: l.noInvoicesYetSubtitle,
                            icon: Icons.receipt_long_outlined,
                            invoices: widget.invoices,
                            clients: widget.clients,
                            onTap: widget.onSelectInvoice,
                            onDelete: null,
                            onEdit: widget.canEditIssued
                                ? widget.onEditDraft
                                : null,
                            onIssue: null,
                            onIssueAll: null,
                            sortState: widget.sortState,
                            onSortBySelected: widget.onSortBySelected,
                            sortLoading: widget.sortLoading,
                            issueAllLoading: false,
                            selectedInvoiceId: widget.selectedInvoice?.id,
                            showSummaryTotals: true,
                            groupId: widget.group.id,
                            onOpenRecurringSeries: widget.onOpenRecurringSeries,
                            onDateFilterChanged:
                                widget.onIssuedDateFilterChanged,
                            onDownloadFiltered: widget.onDownloadFiltered,
                            allowClientNameSort: false,
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
                      client: _resolveInvoiceClient(
                        widget.selectedInvoice!,
                        widget.clients,
                        l,
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
