part of '../group_invoices_screen.dart';

class _GroupInvoicesView extends StatelessWidget {
  const _GroupInvoicesView({required this.state});

  final _GroupInvoicesScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 980;

    Widget body;
    if (state._loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state._error != null) {
      body = ErrorView(message: state._error!, onRetry: state._loadAll);
    } else {
      final visibleInvoices = state._selectedClient == null
          ? state._invoices
          : state._invoices
              .where((inv) => inv.clientId == state._selectedClient!.id)
              .toList();
      final draftInvoices = state._selectedClient == null
          ? state._drafts
          : state._drafts
              .where((inv) => inv.clientId == state._selectedClient!.id)
              .toList();
      body = RefreshIndicator(
        onRefresh: state._loadAll,
        child: Row(
          children: [
            GroupInvoicesSideMenu(
              group: state.widget.group,
              billingProfile: state._billingProfile,
              busyProfile: state._busyProfile,
              businessExpanded: state._businessExpanded,
              facturacionExpanded: state._facturacionExpanded,
              gastosExpanded: state._gastosExpanded,
              impuestosExpanded: state._impuestosExpanded,
              informesExpanded: state._informesExpanded,
              issuedCount: state._invoices.length,
              draftsCount: state._drafts.length,
              receiptsCount:
                  state._receipts.length + state._receiptDrafts.length,
              onCreateInvoice: state._openCreateInvoice,
              onCreateReceipt: state._openCreateReceipt,
              onEditBillingProfile: state._openBillingProfile,
              onToggleBusinessExpanded: state._toggleBusinessExpanded,
              onToggleFacturacionExpanded: () => state.setState(() {
                final next = !state._facturacionExpanded;
                if (!isWide && next) {
                  state._gastosExpanded = false;
                  state._impuestosExpanded = false;
                  state._informesExpanded = false;
                }
                state._facturacionExpanded = next;
              }),
              onToggleGastosExpanded: () => state.setState(() {
                final next = !state._gastosExpanded;
                if (!isWide && next) {
                  state._facturacionExpanded = false;
                  state._impuestosExpanded = false;
                  state._informesExpanded = false;
                }
                state._gastosExpanded = next;
              }),
              onToggleImpuestosExpanded: () => state.setState(() {
                final next = !state._impuestosExpanded;
                if (!isWide && next) {
                  state._facturacionExpanded = false;
                  state._gastosExpanded = false;
                  state._informesExpanded = false;
                }
                state._impuestosExpanded = next;
              }),
              onToggleInformesExpanded: () => state.setState(() {
                final next = !state._informesExpanded;
                if (!isWide && next) {
                  state._facturacionExpanded = false;
                  state._gastosExpanded = false;
                  state._impuestosExpanded = false;
                }
                state._informesExpanded = next;
              }),
              selectedMenu: state._selectedMenu,
              onMenuChanged: (m) =>
                  state.setState(() => state._selectedMenu = m),
              collapsed: state._menuCollapsed,
              onToggleCollapse: () =>
                  state.setState(() => state._menuCollapsed = !state._menuCollapsed),
            ),
            Expanded(
              child: state._selectedMenu == 'invoice_editor'
                  ? InvoiceEditorScreen(
                      group: state.widget.group,
                      clients: state._clients,
                      initialClientId: state._invoiceEditorClientId,
                      embedded: true,
                      onDataChanged: state._loadAll,
                      onClose: (changed) =>
                          state._closeInlineInvoiceEditor(changed: changed),
                    )
                  : state._selectedMenu == 'clients' ||
                          state._selectedMenu == 'clients_flow'
                      ? GroupInvoicesClientsView(
                          groupId: state.widget.group.id,
                          clients: state._clients,
                          selectedClient: state._selectedClient,
                          issuedInvoices: visibleInvoices,
                          draftInvoices: draftInvoices,
                          onSelectClient: (c) =>
                              state.setState(() => state._selectedClient = c),
                          onCreateInvoice: state._openCreateInvoice,
                          onCreateReceipt: state._openCreateReceipt,
                          onEditSelectedClient: () {
                            if (state._selectedClient != null) {
                              state._openEditClient(state._selectedClient!);
                            }
                          },
                          onOpenInvoiceDetail: state._openInvoiceDetail,
                          onDeleteInvoice: state._deleteInvoice,
                          onUpdateClientClassification:
                              state._updateClientClassification,
                        )
                      : state._selectedMenu == 'receipts'
                          ? GroupReceiptsView(
                              drafts: state._receiptDrafts,
                              receipts: state._receipts,
                              clients: state._clients,
                              billingProfile: state._billingProfile,
                              selectedReceipt: state._selectedReceipt,
                              onSelectReceipt: (r) => state.setState(
                                  () => state._selectedReceipt = r),
                              onCreateReceipt: state._openCreateReceipt,
                              onEditReceipt: state._openEditReceipt,
                              onIssueReceipt: state._issueReceipt,
                              onDeleteReceipt: state._deleteReceipt,
                              onPreviewPdf: state._previewReceiptPdf,
                              onDownloadPdf: state._downloadReceiptPdf,
                            )
                          : state._selectedMenu == 'expenses_upload'
                              ? ExpenseUploadScreen(
                                  embedded: true,
                                  onUploaded: state._loadAll,
                                  initialTabIndex: 1,
                                  groupId: state.widget.group.id,
                                  groupName: state.widget.group.name,
                                )
                              : state._selectedMenu == 'expenses_list'
                                  ? ExpenseUploadScreen(
                                      embedded: true,
                                      onUploaded: state._loadAll,
                                      initialTabIndex: 0,
                                      groupId: state.widget.group.id,
                                      groupName: state.widget.group.name,
                                    )
                                  : state._selectedMenu == 'providers'
                                      ? ExpenseUploadScreen(
                                          embedded: true,
                                          providersOnly: true,
                                          groupId: state.widget.group.id,
                                          groupName: state.widget.group.name,
                                        )
                                      : state._selectedMenu == 'vat'
                                          ? VatSummaryView(
                                              api: state._vatApi,
                                              groupId: state.widget.group.id,
                                            )
                                          : state._selectedMenu == 'recurring'
                                              ? RecurringInvoicesScreen(
                                                  group: state.widget.group,
                                                  embedded: true,
                                                  initialSeriesId:
                                                      state._recurringSeriesToOpen,
                                                  onSeriesOpened: () => state
                                                      .setState(() =>
                                                          state._recurringSeriesToOpen =
                                                              null),
                                                )
                                              : state._selectedMenu ==
                                                      'client_classifications'
                                                  ? ClientClassificationsView(
                                                      groupId: state
                                                          .widget.group.id,
                                                      clients: state._clients,
                                                    )
                                                  : state._selectedMenu ==
                                                          'invoices_drafts'
                                                      ? GroupInvoicesInvoicesView(
                                                          drafts: state._drafts,
                                                          invoices:
                                                              state._invoices,
                                                          clients:
                                                              state._clients,
                                                          billingProfile:
                                                              state._billingProfile,
                                                          group:
                                                              state.widget.group,
                                                          selectedInvoice:
                                                              state._selectedInvoice,
                                                          onSelectInvoice: (inv) =>
                                                              state.setState(() =>
                                                                  state._selectedInvoice =
                                                                      inv),
                                                          onDeleteInvoice:
                                                              state._deleteInvoice,
                                                          onCreateInvoice:
                                                              state._openCreateInvoice,
                                                          onRefresh:
                                                              state._loadAll,
                                                          numberSort: state
                                                              ._effectiveInvoiceNumberSort,
                                                          onNumberSortChanged:
                                                              state
                                                                  ._handleInvoiceSortChanged,
                                                          sortLoading: state
                                                              ._effectiveSortingInvoices,
                                                          initialTabIndex: 0,
                                                          onOpenRecurringSeries:
                                                              (seriesId) =>
                                                                  state.setState(
                                                                      () {
                                                            state._recurringSeriesToOpen =
                                                                seriesId;
                                                            state._selectedMenu =
                                                                'recurring';
                                                          }),
                                                        )
                                                      : state._selectedMenu ==
                                                              'emails'
                                                          ? GroupInvoicesEmailsView(
                                                              group:
                                                                  state.widget.group,
                                                              selectedInvoice:
                                                                  state._selectedInvoice,
                                                              clients:
                                                                  state._clients,
                                                            )
                                                          : state._selectedMenu ==
                                                                  'invoices_issued'
                                                              ? GroupInvoicesInvoicesView(
                                                                  drafts:
                                                                      state._drafts,
                                                                  invoices:
                                                                      state._invoices,
                                                                  clients:
                                                                      state._clients,
                                                                  billingProfile:
                                                                      state._billingProfile,
                                                                  group: state
                                                                      .widget.group,
                                                                  selectedInvoice:
                                                                      state._selectedInvoice,
                                                                  onSelectInvoice: (inv) =>
                                                                      state.setState(() =>
                                                                          state._selectedInvoice =
                                                                              inv),
                                                                  onDeleteInvoice:
                                                                      state._deleteInvoice,
                                                                  onCreateInvoice:
                                                                      state._openCreateInvoice,
                                                                  onRefresh:
                                                                      state._loadAll,
                                                                  numberSort:
                                                                      state._effectiveInvoiceNumberSort,
                                                                  onNumberSortChanged:
                                                                      state._handleInvoiceSortChanged,
                                                                  sortLoading:
                                                                      state._effectiveSortingInvoices,
                                                                  initialTabIndex:
                                                                      1,
                                                                  onOpenRecurringSeries:
                                                                      (seriesId) =>
                                                                          state.setState(
                                                                              () {
                                                                    state._recurringSeriesToOpen =
                                                                        seriesId;
                                                                    state._selectedMenu =
                                                                        'recurring';
                                                                  }),
                                                                )
                                                              : GroupInvoicesInvoicesView(
                                                                  drafts:
                                                                      state._drafts,
                                                                  invoices:
                                                                      state._invoices,
                                                                  clients:
                                                                      state._clients,
                                                                  billingProfile:
                                                                      state._billingProfile,
                                                                  group: state
                                                                      .widget.group,
                                                                  selectedInvoice:
                                                                      state._selectedInvoice,
                                                                  onSelectInvoice: (inv) =>
                                                                      state.setState(() =>
                                                                          state._selectedInvoice =
                                                                              inv),
                                                                  onDeleteInvoice:
                                                                      state._deleteInvoice,
                                                                  onCreateInvoice:
                                                                      state._openCreateInvoice,
                                                                  onRefresh:
                                                                      state._loadAll,
                                                                  numberSort:
                                                                      state._effectiveInvoiceNumberSort,
                                                                  onNumberSortChanged:
                                                                      state._handleInvoiceSortChanged,
                                                                  sortLoading:
                                                                      state._effectiveSortingInvoices,
                                                                  onOpenRecurringSeries:
                                                                      (seriesId) =>
                                                                          state.setState(
                                                                              () {
                                                                    state._recurringSeriesToOpen =
                                                                        seriesId;
                                                                    state._selectedMenu =
                                                                        'recurring';
                                                                  }),
                                                                ),
            ),
          ],
        ),
      );
    }

    final fabIsReceipts = state._selectedMenu == 'receipts';
    final hideFab = state._selectedMenu == 'invoices' ||
        state._selectedMenu == 'invoices_drafts' ||
        state._selectedMenu == 'invoices_issued' ||
        state._selectedMenu == 'invoice_editor' ||
        state._selectedMenu == 'clients' ||
        state._selectedMenu == 'clients_flow' ||
        state._selectedMenu == 'receipts' ||
        state._selectedMenu == 'emails' ||
        state._selectedMenu == 'client_classifications' ||
        state._selectedMenu == 'expenses' ||
        state._selectedMenu == 'expenses_upload' ||
        state._selectedMenu == 'expenses_list' ||
        state._selectedMenu == 'providers' ||
        state._selectedMenu == 'vat' ||
        state._selectedMenu == 'recurring';

    if (state.widget.embedded && kIsWeb) {
      return Stack(
        children: [
          Positioned.fill(child: body),
          if (!hideFab)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: fabIsReceipts
                    ? state._openCreateReceipt
                    : state._openCreateInvoice,
                icon: const Icon(Icons.add),
                label: Text(
                  fabIsReceipts ? l.createReceiptCta : l.createInvoiceCta,
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.invoicesTitle(state.widget.group.name),
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: body,
      floatingActionButton: hideFab
          ? null
          : FloatingActionButton.extended(
              onPressed: fabIsReceipts
                  ? state._openCreateReceipt
                  : state._openCreateInvoice,
              icon: const Icon(Icons.add),
              label:
                  Text(fabIsReceipts ? l.createReceiptCta : l.createInvoiceCta),
            ),
    );
  }
}
