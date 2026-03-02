part of '../group_invoices_screen.dart';

class _GroupInvoicesView extends StatelessWidget {
  const _GroupInvoicesView({required this.state});

  final _GroupInvoicesScreenState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    if (isMobile) return _InvoicesMobileView(state: state);
    final isWide = MediaQuery.of(context).size.width >= 980;
    final showInlineEditor = state._selectedMenu == 'invoice_editor' &&
        state.widget.embedded &&
        kIsWeb;
    final showInlineReceiptEditor = state._selectedMenu == 'receipt_editor' &&
        state.widget.embedded &&
        kIsWeb;
    final menu = state._selectedMenu == 'invoice_editor'
        ? state._menuBeforeInvoiceEditor
        : state._selectedMenu == 'receipt_editor'
            ? state._menuBeforeReceiptEditor
            : state._selectedMenu;

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
      final folderTitle = showInlineReceiptEditor
          ? l.receiptEditorTitle(l.receiptDraftNumberPlaceholder)
          : switch (menu) {
              'invoice_editor' => l.invoiceEditorTitle,
              'billing_profile' => l.billingProfileTitle,
              'invoices_drafts' => l.groupInvoicesDraftInvoicesTitle,
              'invoices_issued' => l.invoicesListTitle,
              'budgets_list' => l.budgetsMenuList,
              'budgets_new' => l.budgetsMenuNew,
              'clients' => 'Clientes',
              'clients_flow' => l.groupInvoicesClientsFlowCta,
              'receipts' => 'Recibos',
              'emails' => 'Correo electrónico',
              'expenses_upload' => 'Gastos',
              'expenses_list' => 'Gastos',
              'providers' => 'Proveedores',
              'vat' => 'Impuestos',
              'recurring' => 'Recurrentes',
              'recurring_receipts' => 'Recibos recurrentes',
              'client_classifications' => l.clientClassificationTitle,
              _ => l.invoicesTitle(state.widget.group.name),
            };
      final showInvoiceActions = menu == 'invoices' ||
          menu == 'invoices_issued' ||
          menu == 'invoices_drafts';
      final invoiceActions = showInvoiceActions
          ? <Widget>[
              Tooltip(
                message: l.createInvoiceCta,
                child: FilledButton(
                  onPressed: state._openCreateInvoice,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
              Tooltip(
                message: '${l.download} PDFs',
                child: OutlinedButton(
                  onPressed: state._downloadingAllPdfs
                      ? null
                      : state._downloadAllInvoicesPdfs,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: state._downloadingAllPdfs
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined, size: 18),
                ),
              ),
              Tooltip(
                message: l.refreshAction,
                child: OutlinedButton(
                  onPressed: state._refreshInvoiceListsOnly,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ),
            ]
          : null;
      final recurringActions =
          menu == 'recurring' && state._recurringActions != null
              ? <Widget>[
                  Tooltip(
                    message: l.recurringInvoicesRefreshCta,
                    child: OutlinedButton(
                      onPressed: state._recurringActions!.onRefresh,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 36),
                      ),
                      child: const Icon(Icons.refresh, size: 18),
                    ),
                  ),
                  Tooltip(
                    message: l.recurringInvoicesCreateCta,
                    child: FilledButton(
                      onPressed: state._recurringActions!.canManage
                          ? state._recurringActions!.onCreate
                          : null,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 36),
                      ),
                      child: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ),
                ]
              : null;
      final recurringReceiptsActions = menu == 'recurring_receipts' &&
              state._recurringReceiptsActions != null
          ? <Widget>[
              Tooltip(
                message: l.recurringInvoicesRefreshCta,
                child: OutlinedButton(
                  onPressed: state._recurringReceiptsActions!.onRefresh,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ),
              Tooltip(
                message: 'Crear recurrencia de recibo',
                child: FilledButton(
                  onPressed: state._recurringReceiptsActions!.canManage
                      ? state._recurringReceiptsActions!.onCreate
                      : null,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ]
          : null;
      final expenseListActions = menu == 'expenses_list'
          ? <Widget>[
              Tooltip(
                message: l.refreshAction,
                child: OutlinedButton(
                  onPressed: state._refreshExpensesListOnly,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.refresh, size: 18),
                ),
              ),
            ]
          : null;
      final clientsActions = menu == 'clients' || menu == 'clients_flow'
          ? <Widget>[
              Tooltip(
                message: l.addClient,
                child: FilledButton(
                  onPressed: state._openCreateClient,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.person_add_outlined, size: 18),
                ),
              ),
            ]
          : null;
      final classificationActions = menu == 'client_classifications'
          ? <Widget>[
              Tooltip(
                message: l.clientClassificationAddTitle,
                child: FilledButton(
                  onPressed: state._openClientClassificationManager,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 36),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ]
          : null;
      final folderActions = classificationActions ??
          expenseListActions ??
          clientsActions ??
          recurringReceiptsActions ??
          recurringActions ??
          invoiceActions;

      final content = _GroupInvoicesContent(
        state: state,
        menu: menu,
        showInlineEditor: showInlineEditor,
        visibleInvoices: visibleInvoices,
        draftInvoices: draftInvoices,
      );
      body = LayoutBuilder(
        builder: (context, constraints) {
          final viewport = MediaQuery.sizeOf(context);
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : viewport.width;
          final height = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : viewport.height;
          return SizedBox(
            width: width,
            height: height,
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
                  collapsed: false,
                  compactMode: false,
                  onToggleCollapse: () {},
                ),
                Expanded(
                  child: (kIsWeb && state._selectedMenu != 'receipt_editor')
                      ? FolderPanel(
                          title: folderTitle,
                          showTab: true,
                          actions: folderActions,
                          child: content,
                        )
                      : content,
                ),
              ],
            ),
          );
        },
      );
    }

    final fabIsReceipts = state._selectedMenu == 'receipts';
    final hideFab = menu == 'invoices' ||
        menu == 'invoices_drafts' ||
        menu == 'invoices_issued' ||
        state._selectedMenu == 'invoice_editor' ||
        state._selectedMenu == 'receipt_editor' ||
        state._selectedMenu == 'billing_profile' ||
        menu == 'clients' ||
        menu == 'clients_flow' ||
        menu == 'receipts' ||
        menu == 'emails' ||
        menu == 'client_classifications' ||
        menu == 'expenses' ||
        menu == 'expenses_upload' ||
        menu == 'expenses_list' ||
        menu == 'providers' ||
        menu == 'vat' ||
        menu == 'budgets_list' ||
        menu == 'budgets_new' ||
        menu == 'recurring_receipts' ||
        menu == 'recurring';

    if (state.widget.embedded && kIsWeb) {
      if (hideFab) {
        return SizedBox.expand(child: body);
      }
      return SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(child: body),
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
        ),
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
      body: SizedBox.expand(child: body),
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
