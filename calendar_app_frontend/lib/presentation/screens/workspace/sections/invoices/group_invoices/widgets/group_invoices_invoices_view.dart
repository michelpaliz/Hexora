import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_compact_financial_summary.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
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
part '../invoice_list/widgets/invoice_filters_menu.dart';
part '../invoice_list/widgets/invoice_download_menu.dart';
part '../invoice_list/widgets/payment_notices.dart';

class GroupInvoicesInvoicesView extends StatefulWidget {
  final List<Invoice> drafts;
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final BillingProfile? billingProfile;
  final Group group;
  final Invoice? selectedInvoice;
  final ValueChanged<Invoice> onSelectInvoice;
  final VoidCallback? onClearSelection;
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
  final Future<void> Function(List<Invoice>)? onDownloadExcelFiltered;
  final bool canEditIssued;
  final bool showHeaderTabs;

  const GroupInvoicesInvoicesView({
    super.key,
    required this.drafts,
    required this.invoices,
    required this.clients,
    required this.billingProfile,
    required this.group,
    required this.selectedInvoice,
    required this.onSelectInvoice,
    this.onClearSelection,
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
    this.onDownloadExcelFiltered,
    this.canEditIssued = false,
    this.showHeaderTabs = true,
  });

  @override
  State<GroupInvoicesInvoicesView> createState() =>
      _GroupInvoicesInvoicesViewState();
}

class _GroupInvoicesInvoicesViewState extends State<GroupInvoicesInvoicesView> {
  final _splitModeNotifier = ValueNotifier<DocumentViewMode?>(null);

  @override
  void dispose() {
    _splitModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final activeInvoices =
        widget.initialTabIndex == 0 ? widget.drafts : widget.invoices;
    final selectedIndex = widget.selectedInvoice == null
        ? -1
        : activeInvoices.indexWhere(
            (invoice) => invoice.id == widget.selectedInvoice!.id,
          );

    return Padding(
      padding: const EdgeInsets.all(5),
      child: ValueListenableBuilder<DocumentViewMode?>(
        valueListenable: _splitModeNotifier,
        builder: (context, mode, child) => DocumentSplitView(
          storageKey: 'invoices',
          modeNotifier: _splitModeNotifier,
          selectionKey: widget.selectedInvoice?.id,
          list: DefaultTabController(
            key: ValueKey(
              'invoice-tabs-${widget.initialTabIndex}-${widget.showHeaderTabs}',
            ),
            length: 2,
            initialIndex: widget.initialTabIndex.clamp(0, 1),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              child: Column(
                children: [
                  if (widget.showHeaderTabs) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: HexoraSectionTabs(
                        compact: true,
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
                    const SizedBox(height: 4),
                  ],
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
                          onDownloadFiltered: widget.onDownloadFiltered,
                          onDownloadExcelFiltered:
                              widget.onDownloadExcelFiltered,
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
                          onEdit:
                              widget.canEditIssued ? widget.onEditDraft : null,
                          onIssue: null,
                          onIssueAll: null,
                          sortState: widget.sortState,
                          onSortBySelected: widget.onSortBySelected,
                          sortLoading: widget.sortLoading,
                          issueAllLoading: false,
                          selectedInvoiceId: widget.selectedInvoice?.id,
                          showSummaryTotals: true,
                          groupId: widget.group.id,
                          onDownloadFiltered: widget.onDownloadFiltered,
                          onDownloadExcelFiltered:
                              widget.onDownloadExcelFiltered,
                          onOpenRecurringSeries: widget.onOpenRecurringSeries,
                          onDateFilterChanged: widget.onIssuedDateFilterChanged,
                          allowClientNameSort: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          preview: Card(
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
                    onClose: widget.onClearSelection,
                    onPrevious: selectedIndex > 0
                        ? () => widget.onSelectInvoice(
                              activeInvoices[selectedIndex - 1],
                            )
                        : null,
                    onNext: selectedIndex >= 0 &&
                            selectedIndex + 1 < activeInvoices.length
                        ? () => widget.onSelectInvoice(
                              activeInvoices[selectedIndex + 1],
                            )
                        : null,
                    onExpand: null,
                    isExpanded: false,
                  ),
          ),
        ),
      ),
    );
  }
}
