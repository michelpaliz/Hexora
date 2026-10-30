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
      minimumSize: const Size(32, HexoraDimensions.buttonCompact),
      padding:
          const EdgeInsets.symmetric(horizontal: HexoraTableTokens.cellPadding),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius)),
      elevation: 0,
    );
    final compactIconButtonStyle = IconButton.styleFrom(
      minimumSize: const Size.square(HexoraDimensions.buttonCompact),
      fixedSize: const Size.square(HexoraDimensions.buttonCompact),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HexoraDimensions.radius)),
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
              'expenses_import_history' => 'Historial de lotes',
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
      final invoiceToolbarOptions = showInvoiceActions
          ? InvoiceToolbarOptions(
              onOpenRecentExports: state._showStoredInvoiceZipDownloads,
              recentExportsCount: state._invoiceZipDownloads.length,
              onRefresh: state._refreshInvoiceListsOnly,
            )
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
              Tooltip(
                message: l.createReceiptCta,
                child: FilledButton(
                  onPressed: state._openCreateReceipt,
                  style: compactPrimaryButtonStyle,
                  child: const Icon(Icons.add_rounded, size: 18),
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
      final List<Widget>? classificationActions =
          activeMenu == 'client_classifications'
              ? [
                  FilledButton.icon(
                    onPressed: state._openClientClassificationManager,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                        Localizations.localeOf(context).languageCode == 'es'
                            ? 'Nueva clasificación'
                            : 'New classification'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  )
                ]
              : activeMenu == 'client_invoice_stats'
                  ? const []
                  : null;
      final folderActions = classificationActions ??
          expenseListActions ??
          receiptActions ??
          clientsActions ??
          recurringReceiptsActions ??
          recurringActions;
      final invoiceToolbarTabs = showInvoiceActions
          ? _InvoiceToolbarTabs(
              draftsCount: state._drafts.length,
              invoicesCount: state._invoices.length,
              draftsSelected: activeMenu != 'invoices_issued',
              onDrafts: () => state._changeInvoicesMenu('invoices_drafts'),
              onInvoices: () => state._changeInvoicesMenu('invoices_issued'),
            )
          : null;
      final receiptToolbarTabs = activeMenu == 'receipts'
          ? HexoraDocumentStatusTabs(
              tabs: [
                HexoraDocumentStatusTab(
                  label: Localizations.localeOf(context).languageCode == 'es'
                      ? 'Borradores'
                      : 'Drafts',
                  count: state._receiptDrafts.length,
                  icon: Icons.drafts_outlined,
                ),
                HexoraDocumentStatusTab(
                  label: Localizations.localeOf(context).languageCode == 'es'
                      ? 'Recibos'
                      : 'Receipts',
                  count: state._receipts.length,
                  icon: Icons.receipt_long_outlined,
                ),
              ],
              selectedIndex: state._receiptListTabIndex,
              onSelected: (index) => state._updateView(
                () => state._receiptListTabIndex = index,
              ),
            )
          : null;
      final documentToolbarTabs = invoiceToolbarTabs ?? receiptToolbarTabs;
      final invoiceToolbarLeading = !showInvoiceActions
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(builder: (context) {
                  final moduleLabel =
                      HexoraNavContext.maybeOf(context)?.moduleLabel ??
                          (Localizations.localeOf(context).languageCode == 'es'
                              ? 'Ingresos'
                              : 'Income');
                  return Text(
                    moduleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }),
                const SizedBox(width: 10),
                invoiceToolbarTabs!,
              ],
            );

      final content = HexoraMenuContentTransition(
        transitionKey: activeMenu,
        child: _GroupInvoicesContent(
          state: state,
          menu: menu,
          showInlineEditor: showInlineEditor,
          visibleInvoices: visibleInvoices,
          draftInvoices: draftInvoices,
          invoiceToolbarLeading: invoiceToolbarLeading,
          invoiceToolbarOptions: invoiceToolbarOptions,
        ),
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
                          showTab: activeMenu != 'clients',
                          tabContent:
                              showInvoiceActions || documentToolbarTabs == null
                                  ? null
                                  : Row(
                                      children: [
                                        HexoraBreadcrumb(title: folderTitle),
                                        const SizedBox(width: 16),
                                        Expanded(child: documentToolbarTabs),
                                      ],
                                    ),
                          actions: folderActions,
                          actionsSpacing: 6,
                          showToolbarDivider: !showInvoiceActions &&
                              activeMenu != 'recurring' &&
                              activeMenu != 'recurring_receipts',
                          contentTopPadding: activeMenu == 'clients'
                              ? 0
                              : showInvoiceActions
                                  ? HexoraDimensions.button +
                                      HexoraTableTokens.gap
                                  : 30,
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
        activeMenu == 'expenses_import_history' ||
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

class _InvoiceToolbarTabs extends StatelessWidget {
  const _InvoiceToolbarTabs({
    required this.draftsCount,
    required this.invoicesCount,
    required this.draftsSelected,
    required this.onDrafts,
    required this.onInvoices,
  });

  final int draftsCount;
  final int invoicesCount;
  final bool draftsSelected;
  final VoidCallback onDrafts;
  final VoidCallback onInvoices;

  @override
  Widget build(BuildContext context) {
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return HexoraDocumentStatusTabs(
      tabs: [
        HexoraDocumentStatusTab(
          icon: Icons.drafts_outlined,
          label: isEs ? 'Borradores' : 'Drafts',
          count: draftsCount,
        ),
        HexoraDocumentStatusTab(
          icon: Icons.receipt_long_outlined,
          label: isEs ? 'Facturas' : 'Invoices',
          count: invoicesCount,
        ),
      ],
      selectedIndex: draftsSelected ? 0 : 1,
      onSelected: (index) => index == 0 ? onDrafts() : onInvoices(),
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
  String? _error;
  final Set<String> _openingDownloads = {};

  @override
  void initState() {
    super.initState();
    _downloads = List.of(widget.state._invoiceZipDownloads);
    _loading = false;
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final downloads = await widget.state._invoicesApi
          .listInvoiceZipDownloads(widget.state.widget.group.id);
      downloads.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      if (!mounted) return;
      setState(() => _downloads = downloads);
      if (widget.state.mounted) {
        widget.state
            .setState(() => widget.state._invoiceZipDownloads = downloads);
      }
    } catch (_) {
      if (!mounted) return;
      final isEs = Localizations.localeOf(context).languageCode == 'es';
      setState(() => _error = isEs
          ? 'No se pudieron cargar las exportaciones. Inténtalo de nuevo.'
          : 'Could not load exports. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _syncPolling();
      }
    }
  }

  Future<void> _download(InvoiceZipDownload item) async {
    final key = item.id.isNotEmpty ? item.id : item.fileName;
    if (_openingDownloads.contains(key)) return;
    setState(() => _openingDownloads.add(key));
    try {
      await widget.state._openStoredInvoiceZip(item);
    } finally {
      if (mounted) setState(() => _openingDownloads.remove(key));
    }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final hasActive = _downloads
        .any((item) => item.status == 'queued' || item.status == 'processing');

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      title: Row(
        children: [
          Icon(Icons.history_rounded, color: cs.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(isEs ? 'Exportaciones recientes' : 'Recent exports',
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: isEs ? 'Actualizar' : 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
          IconButton(
            tooltip: isEs ? 'Cerrar' : 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: (MediaQuery.sizeOf(context).height * 0.6).clamp(180.0, 460.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasActive
                  ? (isEs
                      ? 'Tus archivos se están preparando. La lista se actualiza automáticamente.'
                      : 'Your files are being prepared. This list updates automatically.')
                  : (isEs
                      ? 'Descarga tus archivos de facturas desde aquí.'
                      : 'Download your invoice files here.'),
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else
              Divider(
                  height: 2, color: cs.outlineVariant.withValues(alpha: 0.4)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Icon(Icons.error_outline, color: cs.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_error!,
                          style: t.bodySmall.copyWith(color: cs.error))),
                  TextButton(
                      onPressed: _loading ? null : _refresh,
                      child: Text(isEs ? 'Reintentar' : 'Retry')),
                ]),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _downloads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_zip_outlined,
                              size: 40, color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                              _loading
                                  ? (isEs
                                      ? 'Cargando exportaciones…'
                                      : 'Loading exports…')
                                  : (isEs
                                      ? 'Aún no hay exportaciones'
                                      : 'No exports yet'),
                              style: t.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700)),
                          if (!_loading && _error == null) ...[
                            const SizedBox(height: 6),
                            Text(
                                isEs
                                    ? 'Usa «Exportar PDF (ZIP)» en el menú ••• de la lista de facturas.'
                                    : 'Use “Export PDF (ZIP)” in the invoice list’s ••• menu.',
                                textAlign: TextAlign.center,
                                style: t.bodySmall
                                    .copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _downloads.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _downloads[index];
                        final status = (item.status ?? '').trim().toLowerCase();
                        final failed = status == 'failed';
                        final working =
                            status == 'queued' || status == 'processing';
                        final canDownload = !failed &&
                            !working &&
                            ((item.fileUrl?.trim().isNotEmpty ?? false) ||
                                status == 'completed' ||
                                status == 'ready');
                        final label = switch (status) {
                          'queued' => isEs ? 'En cola' : 'Queued',
                          'processing' => isEs ? 'Preparando' : 'Preparing',
                          'failed' => isEs ? 'Error' : 'Failed',
                          'completed' ||
                          'ready' =>
                            isEs ? 'Disponible' : 'Ready',
                          _ => canDownload
                              ? (isEs ? 'Disponible' : 'Ready')
                              : (isEs ? 'No disponible' : 'Unavailable'),
                        };
                        final color = failed
                            ? cs.error
                            : canDownload
                                ? cs.primary
                                : cs.onSurfaceVariant;
                        final fileName = item.fileName.trim().isEmpty
                            ? 'facturas.zip'
                            : item.fileName.trim();
                        final opening = _openingDownloads.contains(
                            item.id.isNotEmpty ? item.id : item.fileName);
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [
                                Icon(
                                    failed
                                        ? Icons.error_outline
                                        : Icons.folder_zip_outlined,
                                    size: 20,
                                    color: color),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(fileName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodySmall.copyWith(
                                            fontWeight: FontWeight.w700))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: color)),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                    child: Text(
                                  [
                                    _formatDate(item.createdAt?.toLocal()),
                                    if ((item.sizeBytes ?? 0) > 0)
                                      _formatSize(item.sizeBytes)
                                  ].join(' · '),
                                  style: t.bodySmall
                                      .copyWith(color: cs.onSurfaceVariant),
                                )),
                                if (canDownload)
                                  TextButton.icon(
                                    onPressed:
                                        opening ? null : () => _download(item),
                                    icon: Icon(
                                        opening
                                            ? Icons.hourglass_empty_rounded
                                            : Icons.download_outlined,
                                        size: 16),
                                    label:
                                        Text(isEs ? 'Descargar' : 'Download'),
                                  ),
                              ]),
                              if (working) ...[
                                const SizedBox(height: 6),
                                const LinearProgressIndicator(minHeight: 2),
                              ],
                              if (failed) ...[
                                const SizedBox(height: 4),
                                Text(
                                    isEs
                                        ? 'No se pudo generar el archivo. Vuelve a exportarlo desde la lista de facturas.'
                                        : 'The file could not be generated. Export it again from the invoice list.',
                                    style:
                                        t.bodySmall.copyWith(color: cs.error)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
