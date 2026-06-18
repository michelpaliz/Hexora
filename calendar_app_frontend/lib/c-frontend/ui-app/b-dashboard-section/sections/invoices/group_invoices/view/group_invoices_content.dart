part of '../../group_invoices_screen.dart';

class _GroupInvoicesContent extends StatelessWidget {
  const _GroupInvoicesContent({
    required this.state,
    required this.menu,
    required this.showInlineEditor,
    required this.visibleInvoices,
    required this.draftInvoices,
  });

  final _GroupInvoicesScreenState state;
  final String menu;
  final bool showInlineEditor;
  final List<Invoice> visibleInvoices;
  final List<Invoice> draftInvoices;

  @override
  Widget build(BuildContext context) {
    if (!showInlineEditor) {
      return _buildContent(context);
    }
    return InvoiceEditorScreen(
      key: ValueKey(
        'inline-invoice-editor-${state._invoiceEditorSession}-${state._invoiceEditorInvoice?.id ?? 'new'}-${state._invoiceEditorClientId ?? 'none'}',
      ),
      group: state.widget.group,
      clients: state._clients,
      initialClientId: state._invoiceEditorClientId,
      initialInvoice: state._invoiceEditorInvoice,
      embedded: true,
      onDataChanged: null,
      onUnsavedStateChanged: (dirty) =>
          state._inlineInvoiceEditorUnsaved = dirty,
      onClose: (changed) => state._closeInlineInvoiceEditor(changed: changed),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (menu == 'client_invoice_stats') {
      return ClientInvoiceComparisonView(
        key: const ValueKey('group-invoices-client-invoice-stats'),
        clients: state._clients,
        selectedClient: state._selectedClient,
        onSelectClient: (client) =>
            state.setState(() => state._selectedClient = client),
      );
    }

    if (menu == 'clients' || menu == 'clients_flow') {
      return GroupInvoicesClientsView(
        key: ValueKey('group-invoices-clients-$menu'),
        groupId: state.widget.group.id,
        clients: state._clients,
        selectedClient: state._selectedClient,
        issuedInvoices: visibleInvoices,
        draftInvoices: draftInvoices,
        onSelectClient: (c) => state.setState(() => state._selectedClient = c),
        onCreateInvoice: state._openCreateInvoice,
        onCreateReceipt: state._openCreateReceipt,
        onEditSelectedClient: () {
          if (state._selectedClient != null) {
            state._openEditClient(state._selectedClient!);
          }
        },
        onOpenInvoiceDetail: state._openInvoiceDetail,
        onDeleteInvoice: state._deleteInvoice,
        onDownloadVisibleInvoices: state._downloadVisibleInvoicesPdfs,
        onUpdateClientClassification: state._updateClientClassification,
      );
    }

    if (state._selectedMenu == 'billing_profile') {
      return BillingProfileInlineEditor(
        initial: state._billingProfile,
        groupId: state.widget.group.id,
        api: state._billingApi,
        onSaved: (updated) {
          if (!state.mounted) return;
          state.setState(() => state._billingProfile = updated);
          final l = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l.billingProfileSaved)));
        },
        showFolder: false,
      );
    }

    if (state._selectedMenu == 'receipts') {
      return GroupReceiptsView(
        drafts: state._receiptDrafts,
        receipts: state._receipts,
        clients: state._clients,
        billingProfile: state._billingProfile,
        selectedReceipt: state._selectedReceipt,
        onSelectReceipt: (r) =>
            state.setState(() => state._selectedReceipt = r),
        onCreateReceipt: state._openCreateReceipt,
        onEditReceipt: state._openEditReceipt,
        onIssueReceipt: state._issueReceipt,
        onDeleteReceipt: state._deleteReceipt,
        onPreviewPdf: state._previewReceiptPdf,
        onDownloadPdf: state._downloadReceiptPdf,
        onImportJson: state._openReceiptJsonImportDialog,
        onLoadInlinePdf: state._loadReceiptInlinePdfBytes,
        disableDetailPreviewInteraction:
            state._disableReceiptPreviewInteraction,
      );
    }

    if (state._selectedMenu == 'receipt_editor') {
      return ReceiptEditorWizardScreen(
        key: ValueKey(
          'inline-receipt-editor-${state._receiptEditorSession}-${state._receiptEditorReceipt?.id ?? 'new'}-${state._receiptEditorClientId ?? 'none'}',
        ),
        group: state.widget.group,
        clients: state._clients,
        initialClientId: state._receiptEditorClientId,
        initialReceipt: state._receiptEditorReceipt,
        embedded: true,
        onUnsavedStateChanged: (dirty) =>
            state._inlineReceiptEditorUnsaved = dirty,
        onClose: (changed) => state._closeInlineReceiptEditor(changed: changed),
      );
    }

    if (state._selectedMenu == 'expenses_upload') {
      return ExpenseUploadScreen(
        key: const ValueKey('expenses_upload'),
        embedded: true,
        onUploaded: state._loadAll,
        initialTabIndex: 1,
        uploadOnly: true,
        groupId: state.widget.group.id,
        groupName: state.widget.group.name,
      );
    }

    if (state._selectedMenu == 'expenses_list') {
      return ExpenseUploadScreen(
        key: state._safeExpensesListKey,
        embedded: true,
        onUploaded: state._loadAll,
        initialTabIndex: 0,
        listOnly: true,
        groupId: state.widget.group.id,
        groupName: state.widget.group.name,
      );
    }

    if (state._selectedMenu == 'providers') {
      return ExpenseUploadScreen(
        key: const ValueKey('expenses_providers'),
        embedded: true,
        providersOnly: true,
        groupId: state.widget.group.id,
        groupName: state.widget.group.name,
      );
    }

    if (state._selectedMenu == 'provider_new') {
      return ExpenseUploadScreen(
        key: const ValueKey('provider_new'),
        embedded: true,
        providerFormOnly: true,
        groupId: state.widget.group.id,
        groupName: state.widget.group.name,
      );
    }

    if (state._selectedMenu == 'vat') {
      return VatSummaryView(
        api: state._vatApi,
        groupId: state.widget.group.id,
      );
    }

    if (state._selectedMenu == 'expenses_suspects') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: ExpenseVatAuditView(
          key: const ValueKey('expenses_suspects'),
          groupId: state.widget.group.id,
          onEditExpense: (expenseId) async =>
              state._openExpenseForEdit(expenseId),
        ),
      );
    }

    if (state._selectedMenu == 'invoices_suspects') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: InvoiceVatAuditView(
          key: const ValueKey('invoices_suspects'),
          groupId: state.widget.group.id,
          clients: state._clients,
          onEditInvoice: state._openInvoiceFromBudgetConversion,
        ),
      );
    }

    if (state._selectedMenu == 'invoices_accountant_compare') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: InvoiceAccountantCompareView(
          key: const ValueKey('invoices_accountant_compare'),
          groupId: state.widget.group.id,
          clients: state._clients,
          onEditInvoice: state._openInvoiceFromBudgetConversion,
        ),
      );
    }

    if (state._selectedMenu == 'budgets_list') {
      return GroupInvoicesBudgetsView(
        key: ValueKey('group-invoices-budgets-list-${state.widget.group.id}'),
        groupId: state.widget.group.id,
        clients: state._clients,
        mode: GroupInvoicesBudgetsMode.list,
        initialSelectedBudgetId: state.widget.initialBudgetId,
        onOpenInvoiceId: state._openInvoiceFromBudgetConversion,
        onEditDraftBudget: state._openDraftBudgetEditor,
      );
    }

    if (state._selectedMenu == 'budgets_new') {
      final editorBudgetId =
          state._budgetEditorBudgetId ?? state.widget.initialBudgetId;
      return GroupInvoicesBudgetsView(
        key: ValueKey(
          'group-invoices-budgets-create-${state.widget.group.id}-${editorBudgetId ?? 'new'}',
        ),
        groupId: state.widget.group.id,
        clients: state._clients,
        mode: GroupInvoicesBudgetsMode.create,
        initialSelectedBudgetId: editorBudgetId,
        onUnsavedStateChanged: (dirty) => state._budgetEditorUnsaved = dirty,
        onExitEditor:
            editorBudgetId == null ? null : state._closeBudgetEditorToList,
      );
    }

    if (state._selectedMenu == 'budgets_convert') {
      return PresupuestoInvoiceConversionView(
        key: ValueKey(
          'presupuesto-conversion-${state.widget.group.id}-${state.widget.initialBudgetId ?? ''}',
        ),
        groupId: state.widget.group.id,
        clients: state._clients,
        initialSelectedBudgetId: state.widget.initialBudgetId,
        onOpenInvoiceId: state._openInvoiceFromBudgetConversion,
      );
    }

    if (state._selectedMenu == 'recurring') {
      return RecurringInvoicesScreen(
        group: state.widget.group,
        embedded: true,
        initialSeriesId: state._recurringSeriesToOpen,
        onActionsReady: (actions) {
          final prev = state._recurringActions;
          final same = (prev == null && actions == null) ||
              (prev != null &&
                  actions != null &&
                  prev.canManage == actions.canManage);
          if (same || !state.mounted) return;
          state.setState(() => state._recurringActions = actions);
        },
        onSeriesOpened: () =>
            state.setState(() => state._recurringSeriesToOpen = null),
      );
    }

    if (state._selectedMenu == 'recurring_receipts') {
      return RecurringReceiptsScreen(
        group: state.widget.group,
        embedded: true,
        initialSeriesId: state._recurringSeriesToOpen,
        onActionsReady: (actions) {
          final prev = state._recurringReceiptsActions;
          final same = (prev == null && actions == null) ||
              (prev != null &&
                  actions != null &&
                  prev.canManage == actions.canManage);
          if (same || !state.mounted) return;
          state.setState(() => state._recurringReceiptsActions = actions);
        },
        onSeriesOpened: () =>
            state.setState(() => state._recurringSeriesToOpen = null),
      );
    }

    if (state._selectedMenu == 'client_classifications') {
      return ClientClassificationsView(
        key: ValueKey(
          'client_classifications_${state._classificationViewRefreshTick}',
        ),
        groupId: state.widget.group.id,
        clients: state._clients,
      );
    }

    if (menu == 'invoices_drafts') {
      return GroupInvoicesInvoicesView(
        drafts: state._drafts,
        invoices: state._invoices,
        clients: state._clients,
        billingProfile: state._billingProfile,
        group: state.widget.group,
        selectedInvoice: state._selectedInvoice,
        onSelectInvoice: (inv) =>
            state.setState(() => state._selectedInvoice = inv),
        onDeleteInvoice: state._deleteInvoice,
        onEditDraft: state._openEditDraft,
        onIssueDraft: state._issueInvoice,
        onIssueAllDrafts: state._issueAllDraftInvoices,
        onCreateInvoice: state._openCreateInvoice,
        onRefresh: state._refreshInvoiceListsOnly,
        sortState: state._effectiveInvoiceSortState,
        onSortBySelected: state._handleInvoiceSortBySelected,
        sortLoading: state._effectiveSortingInvoices,
        issueAllDraftsLoading: state._issuingAllDrafts == true,
        initialTabIndex: 0,
        onOpenRecurringSeries: (seriesId) => state.setState(() {
          state._recurringSeriesToOpen = seriesId;
          state._selectedMenu = 'recurring';
        }),
        onIssuedDateFilterChanged: state._updateIssuedInvoiceDateFilter,
      );
    }

    if (menu == 'emails') {
      return GroupInvoicesEmailsView(
        group: state.widget.group,
        selectedInvoice: state._selectedInvoice,
        clients: state._clients,
      );
    }

    if (menu == 'invoices_issued') {
      return GroupInvoicesInvoicesView(
        drafts: state._drafts,
        invoices: state._invoices,
        clients: state._clients,
        billingProfile: state._billingProfile,
        group: state.widget.group,
        selectedInvoice: state._selectedInvoice,
        onSelectInvoice: (inv) =>
            state.setState(() => state._selectedInvoice = inv),
        onDeleteInvoice: state._deleteInvoice,
        onEditDraft: state._openEditDraft,
        onIssueDraft: state._issueInvoice,
        onIssueAllDrafts: state._issueAllDraftInvoices,
        onCreateInvoice: state._openCreateInvoice,
        onRefresh: state._refreshInvoiceListsOnly,
        sortState: state._effectiveInvoiceSortState,
        onSortBySelected: state._handleInvoiceSortBySelected,
        sortLoading: state._effectiveSortingInvoices,
        issueAllDraftsLoading: state._issuingAllDrafts == true,
        initialTabIndex: 1,
        onOpenRecurringSeries: (seriesId) => state.setState(() {
          state._recurringSeriesToOpen = seriesId;
          state._selectedMenu = 'recurring';
        }),
        onIssuedDateFilterChanged: state._updateIssuedInvoiceDateFilter,
        onDownloadFiltered: state._downloadFilteredInvoices,
      );
    }

    return GroupInvoicesInvoicesView(
      drafts: state._drafts,
      invoices: state._invoices,
      clients: state._clients,
      billingProfile: state._billingProfile,
      group: state.widget.group,
      selectedInvoice: state._selectedInvoice,
      onSelectInvoice: (inv) =>
          state.setState(() => state._selectedInvoice = inv),
      onDeleteInvoice: state._deleteInvoice,
      onEditDraft: state._openEditDraft,
      onIssueDraft: state._issueInvoice,
      onIssueAllDrafts: state._issueAllDraftInvoices,
      onCreateInvoice: state._openCreateInvoice,
      onRefresh: state._refreshInvoiceListsOnly,
      sortState: state._effectiveInvoiceSortState,
      onSortBySelected: state._handleInvoiceSortBySelected,
      sortLoading: state._effectiveSortingInvoices,
      issueAllDraftsLoading: state._issuingAllDrafts == true,
      onOpenRecurringSeries: (seriesId) => state.setState(() {
        state._recurringSeriesToOpen = seriesId;
        state._selectedMenu = 'recurring';
      }),
      onIssuedDateFilterChanged: state._updateIssuedInvoiceDateFilter,
      onDownloadFiltered: state._downloadFilteredInvoices,
    );
  }
}
