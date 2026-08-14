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
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.24)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: cs.primary,
        backgroundColor: cs.primary.withValues(alpha: 0.045),
      );
      final invoiceActions = showInvoiceActions
          ? <Widget>[
              Tooltip(
                message: l.createInvoiceCta,
                child: FilledButton(
                  onPressed: state._openCreateInvoice,
                  style: compactPrimaryButtonStyle,
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
              Tooltip(
                message: '${l.download} PDFs',
                child: _InvoiceExportMenuButton(
                  state: state,
                ),
              ),
              if (showInvoiceConceptExport)
                Tooltip(
                  message: Localizations.localeOf(context).languageCode == 'es'
                      ? 'Exporta las facturas con una categoría calculada según los conceptos de sus líneas.'
                      : 'Export invoices with a calculated category based on line concepts.',
                  child: OutlinedButton.icon(
                    onPressed: state._exportingInvoiceConcepts
                        ? null
                        : state._exportInvoiceConceptsExcel,
                    style: invoiceActionButtonStyle,
                    icon: state._exportingInvoiceConcepts
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_view_outlined, size: 16),
                    label: const Text('Excel'),
                  ),
                ),
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
                  onToggleFacturacionExpanded: () => state.setState(() {
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
                      state._businessExpanded = false;
                      state._gastosExpanded = false;
                      state._impuestosExpanded = false;
                      state._clientsExpanded = false;
                    }
                    state._informesExpanded = next;
                  }),
                  onToggleClientsExpanded: () => state.setState(() {
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
  const _InvoiceExportMenuButton({required this.state});

  final _GroupInvoicesScreenState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final hasExports = state._invoiceZipDownloads.isNotEmpty;
    final label = isSpanish ? 'Exportar' : 'Export';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SegmentedButton<_InvoiceExportAction>(
        showSelectedIcon: false,
        emptySelectionAllowed: true,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: cs.primary.withValues(alpha: 0.24)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          foregroundColor: WidgetStatePropertyAll(cs.primary),
          backgroundColor: WidgetStatePropertyAll(
            cs.primary.withValues(alpha: 0.045),
          ),
        ),
        segments: [
          ButtonSegment(
            value: _InvoiceExportAction.queuePdf,
            icon: state._downloadingAllPdfs
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: Text(label),
          ),
          ButtonSegment(
            value: _InvoiceExportAction.recent,
            icon: state._loadingInvoiceZipDownloads
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: hasExports,
                    label: Text('${state._invoiceZipDownloads.length}'),
                    child: const Icon(Icons.history_rounded, size: 16),
                  ),
            label: Text(isSpanish ? 'Recientes' : 'Recent'),
          ),
        ],
        selected: const <_InvoiceExportAction>{},
        onSelectionChanged: state._downloadingAllPdfs
            ? null
            : (selection) {
                final action = selection.isEmpty ? null : selection.first;
                switch (action) {
                  case _InvoiceExportAction.queuePdf:
                    state._showBulkDownloadDialog();
                  case _InvoiceExportAction.recent:
                    state._showStoredInvoiceZipDownloads();
                  case null:
                    break;
                }
              },
      ),
    );
  }
}

enum _InvoiceExportAction { queuePdf, recent }

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_zip_outlined, size: 20),
          const SizedBox(width: 8),
          Text(isSpanish ? 'ZIPs exportados' : 'Exported ZIPs'),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((widget.state._lastExportFileId ?? '').isNotEmpty ||
                (widget.state._lastExportFileUrl ?? '').isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  [
                    if ((widget.state._lastExportFileId ?? '').isNotEmpty)
                      'ID: ${widget.state._lastExportFileId}',
                    if ((widget.state._lastExportFileUrl ?? '').isNotEmpty)
                      'URL: ${widget.state._lastExportFileUrl}',
                  ].join('\n'),
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Flexible(
              child: _loading && _downloads.isEmpty
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _downloads.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text(
                            isSpanish
                                ? 'Todavia no hay ZIPs de facturas guardados.'
                                : 'No stored invoice ZIP exports yet.',
                            style: t.bodyMedium.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 420),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _downloads.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _downloads[index];
                              final fileName = item.fileName.trim().isEmpty
                                  ? 'invoices.zip'
                                  : item.fileName.trim();
                              final status =
                                  (item.status ?? '').trim().toLowerCase();
                              final canDownload = item.fileUrl != null ||
                                  status == 'completed' ||
                                  status == 'ready';
                              final errorMessage =
                                  item.errorMessage?.trim() ?? '';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.folder_zip_outlined,
                                  color: status == 'failed'
                                      ? cs.error
                                      : cs.primary,
                                ),
                                title: Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  [
                                    _formatDate(item.createdAt),
                                    _formatSize(item.sizeBytes),
                                    item.status ?? '-',
                                    if (status == 'failed' &&
                                        errorMessage.isNotEmpty)
                                      errorMessage,
                                  ].join(' · '),
                                ),
                                trailing: IconButton(
                                  tooltip: isSpanish ? 'Descargar' : 'Download',
                                  onPressed: canDownload
                                      ? () => widget.state
                                          ._openStoredInvoiceZip(item)
                                      : null,
                                  icon: const Icon(Icons.download_rounded),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : _refresh,
          child: Text(isSpanish ? 'Actualizar' : 'Refresh'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isSpanish ? 'Cerrar' : 'Close'),
        ),
      ],
    );
  }
}
