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
    final activeMenu = state._selectedMenu;
    final menu = state._selectedMenu == 'invoice_editor'
        ? state._menuBeforeInvoiceEditor
        : state._selectedMenu == 'receipt_editor'
            ? state._menuBeforeReceiptEditor
            : state._selectedMenu;
    final compactPrimaryButtonStyle = FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(44, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
    );
    final compactIconButtonStyle = IconButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(40, 40),
      padding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      foregroundColor: cs.onSurfaceVariant,
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
    );

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
          : switch (activeMenu) {
              'invoice_editor' => l.invoiceEditorTitle,
              'billing_profile' => l.billingProfileTitle,
              'invoices_drafts' => l.groupInvoicesDraftInvoicesTitle,
              'invoices_issued' => l.invoicesListTitle,
              'budgets_list' => l.budgetsMenuList,
              'budgets_new' => l.budgetsMenuNew,
              'budgets_convert' => 'Convertir presupuesto',
              'clients' => 'Clientes',
              'client_invoice_stats' => 'Análisis de ingresos',
              'clients_flow' => l.groupInvoicesClientsFlowCta,
              'receipts' => 'Recibos',
              'emails' => 'Correo electrónico',
              'expenses_upload' => 'Gastos',
              'expenses_list' => 'Gastos',
              'providers' => 'Proveedores',
              'vat' => 'Impuestos',
              'invoices_suspects' => Localizations.localeOf(context)
                      .languageCode
                      .toLowerCase()
                      .startsWith('es')
                  ? 'Auditoría IVA ingresos'
                  : 'Income VAT audit',
              'invoices_accountant_compare' => Localizations.localeOf(context)
                      .languageCode
                      .toLowerCase()
                      .startsWith('es')
                  ? 'Comparar Excel de asesoría'
                  : 'Compare accountant Excel',
              'expenses_suspects' => Localizations.localeOf(context)
                      .languageCode
                      .toLowerCase()
                      .startsWith('es')
                  ? 'Auditoría IVA gastos'
                  : 'Expense VAT audit',
              'recurring' => 'Recurrentes',
              'recurring_receipts' => 'Recibos recurrentes',
              'client_classifications' => l.clientClassificationTitle,
              _ => l.invoicesTitle(state.widget.group.name),
            };
      final showInvoiceActions = activeMenu == 'invoices' ||
          activeMenu == 'invoices_issued' ||
          activeMenu == 'invoices_drafts';
      final showInvoiceConceptExport =
          activeMenu == 'invoices' || activeMenu == 'invoices_issued';
      final invoiceActionButtonStyle = OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.18)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: cs.primary,
        backgroundColor: cs.primary.withValues(alpha: 0.04),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );
      final invoiceActions = showInvoiceActions
          ? <Widget>[
              FilledButton.icon(
                onPressed: state._openCreateInvoice,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: const Color(0xFF397DDA),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(l.invoiceToolbarNew),
              ),
              _InvoiceExportMenuButton(
                state: state,
                showExcel: showInvoiceConceptExport,
                style: invoiceActionButtonStyle,
              ),
              OutlinedButton.icon(
                onPressed: state._showStoredInvoiceZipDownloads,
                style: invoiceActionButtonStyle,
                icon: state._loadingInvoiceZipDownloads
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.history_rounded, size: 22),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.invoiceToolbarHistory),
                    if (state._invoiceZipDownloads.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Badge(
                        backgroundColor: cs.error,
                        textColor: cs.onError,
                        label: Text('${state._invoiceZipDownloads.length}'),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: l.refreshAction,
                onPressed: state._refreshInvoiceListsOnly,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.65)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  foregroundColor: cs.onSurfaceVariant,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 24),
              ),
            ]
          : null;
      final recurringActions =
          activeMenu == 'recurring' && state._recurringActions != null
              ? <Widget>[
                  Tooltip(
                    message: l.recurringInvoicesRefreshCta,
                    child: IconButton(
                      onPressed: state._recurringActions!.onRefresh,
                      style: compactIconButtonStyle,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ),
                  Tooltip(
                    message: l.recurringInvoicesCreateCta,
                    child: FilledButton(
                      onPressed: state._recurringActions!.canManage
                          ? state._recurringActions!.onCreate
                          : null,
                      style: compactPrimaryButtonStyle,
                      child: const Icon(Icons.add_rounded, size: 18),
                    ),
                  ),
                ]
              : null;
      final recurringReceiptsActions = activeMenu == 'recurring_receipts' &&
              state._recurringReceiptsActions != null
          ? <Widget>[
              Tooltip(
                message: l.recurringInvoicesRefreshCta,
                child: IconButton(
                  onPressed: state._recurringReceiptsActions!.onRefresh,
                  style: compactIconButtonStyle,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
              Tooltip(
                message: 'Crear recurrencia de recibo',
                child: FilledButton(
                  onPressed: state._recurringReceiptsActions!.canManage
                      ? state._recurringReceiptsActions!.onCreate
                      : null,
                  style: compactPrimaryButtonStyle,
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ]
          : null;
      final expenseListActions = activeMenu == 'expenses_list'
          ? <Widget>[
              Tooltip(
                message: l.refreshAction,
                child: IconButton(
                  onPressed: state._refreshExpensesListOnly,
                  style: compactIconButtonStyle,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
            ]
          : null;
      final receiptActions = activeMenu == 'receipts'
          ? <Widget>[
              Tooltip(
                message: l.refreshAction,
                child: IconButton(
                  onPressed: state._refreshInvoiceListsOnly,
                  style: compactIconButtonStyle,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
            ]
          : null;
      final clientsActions = activeMenu == 'clients' ||
              activeMenu == 'clients_flow' ||
              activeMenu == 'client_invoice_stats'
          ? <Widget>[
              Tooltip(
                message: l.refreshAction,
                child: IconButton(
                  onPressed: state._refreshingClientsSection == true
                      ? null
                      : state._refreshClientsSection,
                  style: compactIconButtonStyle,
                  icon: state._refreshingClientsSection == true
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
              if (activeMenu != 'client_invoice_stats')
                Tooltip(
                  message: l.addClient,
                  child: FilledButton(
                    onPressed: state._openCreateClient,
                    style: compactPrimaryButtonStyle,
                    child: const Icon(Icons.person_add_outlined, size: 18),
                  ),
                ),
            ]
          : null;
      final classificationActions = activeMenu == 'client_classifications'
          ? <Widget>[
              Tooltip(
                message: l.clientClassificationAddTitle,
                child: FilledButton(
                  onPressed: state._openClientClassificationManager,
                  style: compactPrimaryButtonStyle,
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ]
          : null;
      final folderActions = classificationActions ??
          expenseListActions ??
          receiptActions ??
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
                  clientsExpanded: state._clientsExpanded,
                  issuedCount: state._invoices.length,
                  draftsCount: state._drafts.length,
                  receiptsCount:
                      state._receipts.length + state._receiptDrafts.length,
                  onCreateInvoice: state._openCreateInvoice,
                  onCreateReceipt: state._openCreateReceipt,
                  onEditBillingProfile: state._openBillingProfile,
                  onToggleBusinessExpanded: state._toggleBusinessExpanded,
                  onToggleFacturacionExpanded: () => state._updateView(() {
                    final next = !state._facturacionExpanded;
                    if (!isWide && next) {
                      state._businessExpanded = false;
                      state._clientsExpanded = false;
                      state._gastosExpanded = false;
                      state._impuestosExpanded = false;
                      state._informesExpanded = false;
                    }
                    state._facturacionExpanded = next;
                  }),
                  onToggleGastosExpanded: () => state._updateView(() {
                    final next = !state._gastosExpanded;
                    if (!isWide && next) {
                      state._facturacionExpanded = false;
                      state._impuestosExpanded = false;
                      state._informesExpanded = false;
                    }
                    state._gastosExpanded = next;
                  }),
                  onToggleImpuestosExpanded: () => state._updateView(() {
                    final next = !state._impuestosExpanded;
                    if (!isWide && next) {
                      state._facturacionExpanded = false;
                      state._gastosExpanded = false;
                      state._informesExpanded = false;
                    }
                    state._impuestosExpanded = next;
                  }),
                  onToggleInformesExpanded: () => state._updateView(() {
                    final next = !state._informesExpanded;
                    if (!isWide && next) {
                      state._facturacionExpanded = false;
                      state._businessExpanded = false;
                      state._gastosExpanded = false;
                      state._impuestosExpanded = false;
                      state._clientsExpanded = false;
                    }
                    state._informesExpanded = next;
                  }),
                  onToggleClientsExpanded: () => state._updateView(() {
                    final next = !state._clientsExpanded;
                    if (!isWide && next) {
                      state._facturacionExpanded = false;
                      state._businessExpanded = false;
                      state._gastosExpanded = false;
                      state._impuestosExpanded = false;
                      state._informesExpanded = false;
                    }
                    state._clientsExpanded = next;
                  }),
                  selectedMenu: state._selectedMenu,
                  onMenuChanged: (m) async {
                    final canLeave = await state._confirmLeaveActiveEditor();
                    if (!canLeave || !state.mounted) return;
                    state._changeInvoicesMenu(m);
                  },
                  collapsed: state._invoiceSideMenuCollapsed,
                  compactMode: false,
                  onToggleCollapse: state._toggleInvoiceSideMenuCollapsed,
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
    final hideFab = activeMenu == 'invoices' ||
        activeMenu == 'invoices_drafts' ||
        activeMenu == 'invoices_issued' ||
        state._selectedMenu == 'invoice_editor' ||
        state._selectedMenu == 'receipt_editor' ||
        state._selectedMenu == 'billing_profile' ||
        activeMenu == 'clients' ||
        activeMenu == 'client_invoice_stats' ||
        activeMenu == 'clients_flow' ||
        activeMenu == 'receipts' ||
        activeMenu == 'emails' ||
        activeMenu == 'client_classifications' ||
        activeMenu == 'expenses' ||
        activeMenu == 'expenses_upload' ||
        activeMenu == 'expenses_list' ||
        activeMenu == 'providers' ||
        activeMenu == 'vat' ||
        activeMenu == 'budgets_list' ||
        activeMenu == 'budgets_new' ||
        activeMenu == 'budgets_convert' ||
        activeMenu == 'recurring_receipts' ||
        activeMenu == 'recurring' ||
        activeMenu == 'invoices_suspects' ||
        activeMenu == 'invoices_accountant_compare' ||
        activeMenu == 'expenses_suspects';

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

class _InvoiceExportMenuButton extends StatelessWidget {
  const _InvoiceExportMenuButton({
    required this.state,
    required this.showExcel,
    required this.style,
  });

  final _GroupInvoicesScreenState state;
  final bool showExcel;
  final ButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final busy = state._downloadingAllPdfs || state._exportingInvoiceConcepts;
    return MenuAnchor(
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed:
              state._downloadingAllPdfs ? null : state._showBulkDownloadDialog,
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined,
              color: Color(0xFFC62828)),
          child: Text(l.invoiceToolbarPdf),
        ),
        if (showExcel)
          MenuItemButton(
            onPressed: state._exportingInvoiceConcepts
                ? null
                : state._exportInvoiceConceptsExcel,
            leadingIcon:
                const Icon(Icons.table_view_outlined, color: Color(0xFF21834A)),
            child: Text(l.invoiceToolbarExcel),
          ),
      ],
      builder: (context, controller, child) => OutlinedButton.icon(
        style: style,
        onPressed: busy
            ? null
            : () {
                controller.isOpen ? controller.close() : controller.open();
              },
        icon: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.description_outlined, size: 22),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.invoiceToolbarExport),
            const SizedBox(width: 12),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InvoiceZipDownloadsDialog extends StatefulWidget {
  const _InvoiceZipDownloadsDialog({required this.state});

  final _GroupInvoicesScreenState state;

  @override
  State<_InvoiceZipDownloadsDialog> createState() =>
      _InvoiceZipDownloadsDialogState();
}

class _InvoiceZipDownloadsDialogState
    extends State<_InvoiceZipDownloadsDialog> {
  late List<InvoiceZipDownload> _downloads;
  late bool _loading;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _downloads = widget.state._invoiceZipDownloads;
    _loading = widget.state._loadingInvoiceZipDownloads;
    _syncPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await widget.state._refreshInvoiceZipDownloads(showErrors: true);
    if (!mounted) return;
    setState(() {
      _downloads = widget.state._invoiceZipDownloads;
      _loading = false;
    });
    _syncPolling();
  }

  void _syncPolling() {
    final hasActive = _downloads.any((item) {
      final status = (item.status ?? '').trim().toLowerCase();
      return status == 'queued' || status == 'processing';
    });
    if (!hasActive) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (!_loading) unawaited(_refresh());
      },
    );
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '-';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString().padLeft(4, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  String _statusLabel(AppLocalizations l, String status) => switch (status) {
        'completed' => l.invoiceZipStatusCompleted,
        'ready' => l.invoiceZipStatusReady,
        'queued' => l.invoiceZipStatusQueued,
        'processing' => l.invoiceZipStatusProcessing,
        'failed' => l.invoiceZipStatusFailed,
        _ => l.invoiceZipStatusUnknown,
      };

  ({Color foreground, Color background, IconData icon}) _statusStyle(
    ColorScheme cs,
    String status,
  ) =>
      switch (status) {
        'completed' || 'ready' => (
            foreground: const Color(0xFF19713A),
            background: const Color(0xFFE6F5EA),
            icon: Icons.check_circle_outline_rounded,
          ),
        'failed' => (
            foreground: cs.error,
            background: cs.errorContainer.withValues(alpha: 0.6),
            icon: Icons.error_outline_rounded,
          ),
        'queued' => (
            foreground: cs.onSurfaceVariant,
            background: cs.surfaceContainerHighest,
            icon: Icons.schedule_rounded,
          ),
        _ => (
            foreground: cs.primary,
            background: cs.primaryContainer.withValues(alpha: 0.55),
            icon: Icons.sync_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 32,
        vertical: compact ? 20 : 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: size.height * (compact ? 0.92 : 0.84),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.folder_zip_outlined,
                        size: 22, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.invoiceZipDialogTitle,
                            style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          l.invoiceZipDialogSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.invoiceZipCloseAction,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Container(
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              child: Row(
                children: [
                  Text(
                    l.invoiceZipCountLabel(_downloads.length),
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _loading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(l.invoiceZipRefreshAction),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            Flexible(
              child: _loading && _downloads.isEmpty
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _downloads.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 52,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_off_outlined,
                                  size: 38, color: cs.onSurfaceVariant),
                              const SizedBox(height: 12),
                              Text(
                                l.invoiceZipEmptyTitle,
                                textAlign: TextAlign.center,
                                style: t.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                l.invoiceZipEmptyMessage,
                                textAlign: TextAlign.center,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: _downloads.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            final item = _downloads[index];
                            final fileName = item.fileName.trim().isEmpty
                                ? l.invoiceZipFileFallback
                                : item.fileName.trim();
                            final status =
                                (item.status ?? '').trim().toLowerCase();
                            final canDownload = item.fileUrl != null ||
                                status == 'completed' ||
                                status == 'ready';
                            final errorMessage =
                                item.errorMessage?.trim() ?? '';
                            final statusStyle = _statusStyle(cs, status);

                            return Material(
                              color: cs.surfaceContainerLowest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.55),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                onTap: canDownload
                                    ? () =>
                                        widget.state._openStoredInvoiceZip(item)
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer
                                        .withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.folder_zip_outlined,
                                      size: 20, color: cs.primary),
                                ),
                                title: Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 7,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(_formatDate(item.createdAt)),
                                          Text('•',
                                              style: TextStyle(
                                                  color: cs.outlineVariant)),
                                          Text(_formatSize(item.sizeBytes)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusStyle.background,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(statusStyle.icon,
                                                    size: 12,
                                                    color:
                                                        statusStyle.foreground),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _statusLabel(l, status),
                                                  style: t.bodySmall.copyWith(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        statusStyle.foreground,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (status == 'failed' &&
                                          errorMessage.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          errorMessage,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.bodySmall.copyWith(
                                            color: cs.error,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                trailing: IconButton.filledTonal(
                                  tooltip: l.invoiceZipDownloadAction(fileName),
                                  onPressed: canDownload
                                      ? () => widget.state
                                          ._openStoredInvoiceZip(item)
                                      : null,
                                  icon: const Icon(Icons.download_rounded,
                                      size: 20),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.invoiceZipCloseAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
