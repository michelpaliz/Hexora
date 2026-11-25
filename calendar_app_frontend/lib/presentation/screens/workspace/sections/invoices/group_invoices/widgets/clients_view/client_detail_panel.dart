import 'package:hexora/presentation/shared/widgets/client_initial_avatar.dart';
import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';
import 'package:hexora/presentation/shared/widgets/documents/compact_document_row.dart';
import 'package:hexora/presentation/shared/widgets/financial/hexora_financial_table.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hexora/presentation/shared/widgets/client_property_image.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_split_view.dart';
import 'package:hexora/services/clients/client_contracts_api.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/widgets/presupuesto_pdf_preview_dialog.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:intl/intl.dart';
import '../invoice_row_item.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/date_range_filter_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'client_invoice_stats_card.dart';
import 'client_contracts_tab.dart';
import '../../../../receipts/views/client_receipts_tab.dart';

class ClientDetailPanel extends StatefulWidget {
  final String groupId;
  final List<GroupClient> clients;
  final GroupClient? selectedClient;
  final List<Invoice> issuedInvoices;
  final List<Invoice> draftInvoices;

  final List<String> entityOptions;
  final List<String> propertyOptions;
  final bool assignBusy;
  final int initialTabIndex;

  final VoidCallback onEditSelectedClient;
  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateReceipt;
  final ValueChanged<Invoice> onOpenInvoiceDetail;
  final ValueChanged<Invoice>? onEditInvoice;
  final ValueChanged<Receipt> onEditReceipt;
  final Widget Function(
    BuildContext context,
    Invoice invoice,
    VoidCallback onClose,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  ) invoicePreviewBuilder;
  final Widget Function(
    BuildContext context,
    Receipt receipt,
    VoidCallback onClose,
    VoidCallback? onPrevious,
    VoidCallback? onNext,
  ) receiptPreviewBuilder;
  final ValueChanged<Invoice> onDeleteInvoice;
  final Future<void> Function(List<Invoice> invoices) onDownloadVisibleInvoices;
  final VoidCallback? onAddClient;

  final Future<void> Function({String? entityType, String? propertyKind})
      onApplyClassification;

  const ClientDetailPanel({
    super.key,
    required this.groupId,
    required this.clients,
    required this.selectedClient,
    required this.issuedInvoices,
    required this.draftInvoices,
    required this.entityOptions,
    required this.propertyOptions,
    required this.assignBusy,
    this.initialTabIndex = 0,
    required this.onEditSelectedClient,
    required this.onCreateInvoice,
    required this.onCreateReceipt,
    required this.onOpenInvoiceDetail,
    this.onEditInvoice,
    required this.onEditReceipt,
    required this.invoicePreviewBuilder,
    required this.receiptPreviewBuilder,
    required this.onDeleteInvoice,
    required this.onDownloadVisibleInvoices,
    this.onAddClient,
    required this.onApplyClassification,
  });

  @override
  State<ClientDetailPanel> createState() => _ClientDetailPanelState();
}

class _ClientDetailPanelState extends State<ClientDetailPanel> {
  final ClientContractsApi _contractsApi = ClientContractsApi();
  final ReceiptsApi _receiptsApi = ReceiptsApi();
  final _ClientInvoiceFilterController _invoiceFilters =
      _ClientInvoiceFilterController();
  int _contractsCount = 0;
  int _receiptsCount = 0;
  String? _contractsCountClientId;
  String? _receiptsCountRequestKey;
  Invoice? _selectedInvoice;

  /// Active document tab, kept when another client is selected so switching
  /// clients from the list doesn't bounce the user back to Facturas.
  late int _tabIndex = widget.initialTabIndex.clamp(0, 4);

  String _classificationLabel(String value) =>
      {
        'particular': 'Particular',
        'community': 'Comunidad de propietarios',
        'company': 'Empresa',
        'chalet': 'Chalet',
        'apartment': 'Apartamento',
        'building': 'Edificio / Urbanización',
        'hotel': 'Hotel',
        'commercial_premises': 'Local comercial',
        'owner': 'Propietario',
        'administrator': 'Administrador',
        'tenant': 'Inquilino',
        'other': 'Otro',
      }[value.toLowerCase()] ??
      value;

  String _clientMetadata(GroupClient client) {
    final parts = <String>[
      if ((client.pdfAlias ?? '').trim().isNotEmpty) client.pdfAlias!.trim(),
      if ((client.effectiveCustomerType ?? '').trim().isNotEmpty)
        _classificationLabel(client.effectiveCustomerType!.trim()),
      if ((client.effectivePropertyType ?? '').trim().isNotEmpty)
        _classificationLabel(client.effectivePropertyType!.trim()),
      if ((client.effectivePropertyRelationship ?? '').trim().isNotEmpty)
        _classificationLabel(client.effectivePropertyRelationship!.trim()),
    ];
    // Drop repeats (e.g. "Chalet" as both client and property type) and the
    // client name itself, which is already the heading.
    final seen = <String>{client.name.trim().toLowerCase()};
    return parts.where((part) => seen.add(part.toLowerCase())).join(' · ');
  }

  @override
  void initState() {
    super.initState();
    _loadContractsCount();
    _loadReceiptsCount();
  }

  @override
  void dispose() {
    _invoiceFilters.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClientDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _tabIndex = widget.initialTabIndex.clamp(0, 4);
    }
    if (oldWidget.selectedClient?.id != widget.selectedClient?.id) {
      _selectedInvoice = null;
    } else if (_selectedInvoice != null &&
        !widget.issuedInvoices.any((item) => item.id == _selectedInvoice!.id)) {
      _selectedInvoice = null;
    }
    if (oldWidget.selectedClient?.id != widget.selectedClient?.id ||
        oldWidget.groupId != widget.groupId) {
      setState(() {
        _contractsCount = 0;
        _receiptsCount = 0;
      });
      _loadContractsCount();
      _loadReceiptsCount();
    }
  }

  Future<void> _loadContractsCount() async {
    final clientId = widget.selectedClient?.id.trim();
    if (clientId == null || clientId.isEmpty) return;
    _contractsCountClientId = clientId;
    try {
      final contracts = await _contractsApi.list(clientId);
      if (!mounted || _contractsCountClientId != clientId) return;
      setState(() => _contractsCount = contracts.length);
    } catch (_) {
      // Keep the tab usable; it will show the full error if the user opens it.
    }
  }

  Future<void> _loadReceiptsCount() async {
    final clientId = widget.selectedClient?.id.trim();
    final groupId = widget.groupId.trim();
    if (clientId == null || clientId.isEmpty || groupId.isEmpty) return;

    final requestKey = '$groupId:$clientId';
    _receiptsCountRequestKey = requestKey;
    try {
      final results = await Future.wait([
        _receiptsApi.list(groupId: groupId, status: 'issued'),
        _receiptsApi.list(groupId: groupId, status: 'draft'),
      ]);
      if (!mounted || _receiptsCountRequestKey != requestKey) return;
      final count = results
          .expand((receipts) => receipts)
          .where((receipt) => receipt.clientId == clientId)
          .length;
      setState(() => _receiptsCount = count);
    } catch (_) {
      // The receipts tab keeps its own detailed loading error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedClientMetadata = widget.selectedClient == null
        ? ''
        : _clientMetadata(widget.selectedClient!);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      child: widget.selectedClient == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.users, size: 36, color: cs.primary),
                    const SizedBox(height: 10),
                    Text(
                      widget.clients.isEmpty
                          ? l.noClientsYet
                          : l.selectClientFirst,
                      textAlign: TextAlign.center,
                      style: t.bodyLarge.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.clients.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l.noClientsYet,
                        textAlign: TextAlign.center,
                        style: t.bodyMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (widget.onAddClient != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('client-detail-add-client'),
                          onPressed: widget.onAddClient,
                          icon: const Icon(LucideIcons.userPlus),
                          label: Text(l.addClient),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            )
          : DefaultTabController(
              // Keyed per client so each client's tabs start fresh (no stale
              // documents from the previous client), opening on the same tab.
              key: ValueKey(
                'client-detail-${widget.selectedClient!.id}-${widget.initialTabIndex}',
              ),
              length: 5,
              initialIndex: _tabIndex,
              animationDuration: HexoraMotion.duration(
                context,
                HexoraMotion.tabIndicator,
              ),
              child: Column(
                children: [
                  Padding(
                    key: const ValueKey('client-detail-compact-header'),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final compact = constraints.maxWidth < 560;
                      return Row(children: [
                        // Same initial avatar and blue accent as the selected
                        // row in the client list; a saved photo still wins.
                        if (widget.selectedClient!.imageVersion != null)
                          ClientPropertyImage(
                            client: widget.selectedClient!,
                            width: 32,
                            height: 32,
                          )
                        else
                          ClientInitialAvatar(
                            key: const ValueKey('client-detail-avatar'),
                            name: widget.selectedClient!.name,
                            size: 32,
                            emphasized: true,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Tooltip(
                                message: widget.selectedClient!.name,
                                waitDuration: const Duration(milliseconds: 500),
                                child: Text(
                                  widget.selectedClient!.name,
                                  key: const ValueKey('client-detail-name'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              if (selectedClientMetadata.isNotEmpty)
                                Tooltip(
                                  message: selectedClientMetadata,
                                  child: Text(
                                    selectedClientMetadata,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ClientInvoiceToolbar(
                          compact: compact,
                          controller: _invoiceFilters,
                          invoices: widget.issuedInvoices,
                          onDownloadVisibleInvoices:
                              widget.onDownloadVisibleInvoices,
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                            onPressed: widget.onEditSelectedClient,
                            tooltip: l.editClient,
                            icon: const Icon(LucideIcons.pencil, size: 18),
                            style: IconButton.styleFrom(
                              foregroundColor: cs.onSurfaceVariant,
                              hoverColor: cs.primary.withValues(alpha: 0.08),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            )),
                      ]);
                    }),
                  ),
                  Container(
                    key: const ValueKey('client-detail-tabs-row'),
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: Builder(
                      builder: (tabContext) {
                        final controller = DefaultTabController.of(tabContext);
                        return AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) {
                            _tabIndex = controller.index;
                            return _ClientTabs(
                              invoicesCount: widget.issuedInvoices.length,
                              contractsCount: _contractsCount,
                              receiptsCount: _receiptsCount,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        DocumentSplitView(
                          storageKey: 'client-invoices',
                          initialListFraction: 0.68,
                          minListWidth: 360,
                          minPreviewWidth: 320,
                          selectionKey: _selectedInvoice?.id,
                          list: _InvoiceList(
                            emptyTitle: l.noInvoicesYet,
                            emptySubtitle: l.noInvoicesYetSubtitle,
                            icon: LucideIcons.receiptText,
                            invoices: widget.issuedInvoices,
                            clients: widget.clients,
                            fallbackClient: widget.selectedClient!,
                            selectedInvoiceId: _selectedInvoice?.id,
                            onTap: (invoice) =>
                                setState(() => _selectedInvoice = invoice),
                            onDelete: null,
                            onEdit: widget.onEditInvoice,
                            filterController: _invoiceFilters,
                          ),
                          preview: _selectedInvoice == null
                              ? const SizedBox.shrink()
                              : widget.invoicePreviewBuilder(
                                  context,
                                  _selectedInvoice!,
                                  () => setState(() => _selectedInvoice = null),
                                  _adjacentInvoice(-1),
                                  _adjacentInvoice(1),
                                ),
                        ),
                        ClientReceiptsTab(
                          key:
                              ValueKey('receipts-${widget.selectedClient!.id}'),
                          groupId: widget.groupId,
                          client: widget.selectedClient!,
                          previewBuilder: widget.receiptPreviewBuilder,
                          onEditReceipt: widget.onEditReceipt,
                          onCountChanged: (count) =>
                              setState(() => _receiptsCount = count),
                        ),
                        ClientContractsTab(
                          key: ValueKey(
                              'contracts-${widget.selectedClient!.id}'),
                          client: widget.selectedClient!,
                          compact: true,
                          onCountChanged: (count) =>
                              setState(() => _contractsCount = count),
                        ),
                        _ClientPresupuestosTab(
                          groupId: widget.groupId,
                          clientId: widget.selectedClient!.id,
                        ),
                        ClientInvoiceStatsCard(
                          key: ValueKey(
                              'invoice-stats-${widget.selectedClient!.id}'),
                          client: widget.selectedClient!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  VoidCallback? _adjacentInvoice(int offset) {
    final selected = _selectedInvoice;
    if (selected == null) return null;
    final index = widget.issuedInvoices.indexWhere((i) => i.id == selected.id);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= widget.issuedInvoices.length) {
      return null;
    }
    return () =>
        setState(() => _selectedInvoice = widget.issuedInvoices[target]);
  }
}

class _ClientInvoiceFilterController extends ChangeNotifier {
  bool _disposed = false;
  DateTime? fromDate;
  DateTime? toDate;
  DateQuickRange quickRange = DateQuickRange.none;
  bool customRangeExpanded = false;
  bool downloading = false;

  bool get hasFilter => fromDate != null || toDate != null;

  List<Invoice> apply(List<Invoice> invoices) => invoices.where((invoice) {
        if (!hasFilter) return true;
        final date =
            invoice.issueDate ?? invoice.registeredAt ?? invoice.occurrenceDate;
        if (date == null) return false;
        if (fromDate != null) {
          final start =
              DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
          if (date.isBefore(start)) return false;
        }
        if (toDate != null) {
          final end = DateTime(
            toDate!.year,
            toDate!.month,
            toDate!.day,
            23,
            59,
            59,
            999,
          );
          if (date.isAfter(end)) return false;
        }
        return true;
      }).toList(growable: false);

  void clear() {
    fromDate = null;
    toDate = null;
    quickRange = DateQuickRange.none;
    customRangeExpanded = false;
    notifyListeners();
  }

  void selectRecentDays(int days) {
    final now = DateTime.now();
    toDate = now;
    fromDate = now.subtract(Duration(days: days - 1));
    quickRange = DateQuickRange.month;
    customRangeExpanded = false;
    notifyListeners();
  }

  void selectRecentMonths(int months) {
    final now = DateTime.now();
    toDate = now;
    fromDate = DateTime(now.year, now.month - (months - 1), now.day);
    quickRange = DateQuickRange.quarter;
    customRangeExpanded = false;
    notifyListeners();
  }

  void showCustomRange() {
    quickRange = DateQuickRange.custom;
    customRangeExpanded = true;
    notifyListeners();
  }

  void updateFrom(DateTime value) {
    fromDate = value;
    if (toDate != null && toDate!.isBefore(value)) toDate = value;
    quickRange = DateQuickRange.custom;
    notifyListeners();
  }

  void updateTo(DateTime value) {
    toDate = value;
    if (fromDate != null && value.isBefore(fromDate!)) fromDate = value;
    quickRange = DateQuickRange.custom;
    notifyListeners();
  }

  void setDownloading(bool value) {
    if (_disposed || downloading == value) return;
    downloading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _ClientInvoiceToolbar extends StatelessWidget {
  const _ClientInvoiceToolbar({
    this.compact = false,
    required this.controller,
    required this.invoices,
    required this.onDownloadVisibleInvoices,
  });

  final _ClientInvoiceFilterController controller;
  final bool compact;
  final List<Invoice> invoices;
  final Future<void> Function(List<Invoice>) onDownloadVisibleInvoices;

  List<Invoice> _filteredInvoices() => controller.apply(invoices);

  Future<void> _downloadVisible() async {
    final filtered = _filteredInvoices();
    if (controller.downloading || filtered.isEmpty) return;
    controller.setDownloading(true);
    try {
      await onDownloadVisibleInvoices(filtered);
    } finally {
      controller.setDownloading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final filtered = _filteredInvoices();
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ClientPeriodMenu(
                compact: compact,
                selected: controller.quickRange,
                hasFilter: controller.hasFilter,
                isSpanish: isSpanish,
                onSelected: (value) {
                  if (value == null) {
                    controller.clear();
                  } else if (value == DateQuickRange.month) {
                    controller.selectRecentDays(30);
                  } else if (value == DateQuickRange.quarter) {
                    controller.selectRecentMonths(3);
                  } else {
                    controller.showCustomRange();
                  }
                },
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: filtered.isEmpty
                    ? l.noInvoicesYet
                    : isSpanish
                        ? 'Descargar las facturas visibles (${filtered.length})'
                        : 'Download visible invoices (${filtered.length})',
                child: compact
                    ? IconButton(
                        key: const ValueKey('client-invoice-zip-download'),
                        onPressed: filtered.isEmpty || controller.downloading
                            ? null
                            : _downloadVisible,
                        icon: controller.downloading
                            ? const SizedBox.square(
                                dimension: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(LucideIcons.folderArchive, size: 16),
                        style: IconButton.styleFrom(
                          fixedSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                      )
                    : TextButton.icon(
                        key: const ValueKey('client-invoice-zip-download'),
                        onPressed: filtered.isEmpty || controller.downloading
                            ? null
                            : _downloadVisible,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                        icon: controller.downloading
                            ? const SizedBox.square(
                                dimension: 13,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.folderArchive, size: 14),
                        label: Text('ZIP (${filtered.length})',
                            style: t.bodySmall),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientTabs extends StatelessWidget {
  final int invoicesCount;
  final int receiptsCount;
  final int contractsCount;

  const _ClientTabs({
    required this.invoicesCount,
    required this.receiptsCount,
    required this.contractsCount,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    // Label + neutral count pill; the active tab is marked by the underline.
    Tab tab({
      required IconData icon,
      required String label,
      int? count,
    }) {
      return Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: HexoraDocumentTokens.icon),
            const SizedBox(width: 6),
            Text(label),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: HexoraTypography.caption,
                    fontFeatures: HexoraTypography.numericFeatures,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return HexoraSectionTabs(
      compact: true,
      tabs: [
        tab(
          icon: LucideIcons.receiptText,
          label: l.invoicesListTitle,
          count: invoicesCount,
        ),
        tab(
          icon: LucideIcons.fileText,
          label: l.receiptsTitle,
          count: receiptsCount,
        ),
        tab(
          icon: LucideIcons.folder,
          label: l.contractsTitle,
          count: contractsCount,
        ),
        tab(
          icon: LucideIcons.fileText,
          label: isSpanish ? 'Presupuestos' : 'Proposals',
        ),
        tab(
          icon: LucideIcons.chartNoAxesCombined,
          label: isSpanish ? 'Gráfico' : 'Chart',
        ),
      ],
    );
  }
}

class _ClientPresupuestosTab extends StatefulWidget {
  const _ClientPresupuestosTab({required this.groupId, required this.clientId});

  final String groupId;
  final String clientId;

  @override
  State<_ClientPresupuestosTab> createState() => _ClientPresupuestosTabState();
}

class _ClientPresupuestosTabState extends State<_ClientPresupuestosTab> {
  late Future<List<Map<String, dynamic>>> _future;
  final _api = PresupuestosApi();
  String? _previewingId;

  @override
  void initState() {
    super.initState();
    _future = PresupuestosApi().listByGroup(
      groupId: widget.groupId,
      clientId: widget.clientId,
      limit: 100,
    );
  }

  Future<void> _preview(Map<String, dynamic> row) async {
    final id = (row['id'] ?? row['presupuestoId'] ?? row['_id'] ?? '')
        .toString()
        .trim();
    if (id.isEmpty || _previewingId != null) return;
    setState(() => _previewingId = id);
    try {
      final response = await _api.previewPdf(id);
      if (!mounted) return;
      final number = (row['presupuestoNumber'] ??
              row['budgetNumber'] ??
              row['number'] ??
              id)
          .toString()
          .replaceAll('/', '-');
      await PresupuestoPdfPreviewDialog.show(
        context,
        bytes: response.bodyBytes,
        onDownload: () => launchFileDownload(
          response.bodyBytes,
          fileName: 'presupuesto-$number.pdf',
          mimeType: 'application/pdf',
        ),
      );
    } catch (error) {
      if (mounted) {
        showErrorSnack(
            context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _previewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
                isEs
                    ? 'No se pudieron cargar los presupuestos.'
                    : 'Proposals could not be loaded.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return Center(
            child: Text(
                isEs
                    ? 'No hay presupuestos para este cliente.'
                    : 'No proposals for this client.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final row = rows[index];
            final number = (row['presupuestoNumber'] ??
                    row['budgetNumber'] ??
                    row['number'] ??
                    'Presupuesto')
                .toString();
            final status =
                (row['statusLabel'] ?? row['status'] ?? '').toString();
            final id = (row['id'] ?? row['presupuestoId'] ?? row['_id'] ?? '')
                .toString();
            return ListTile(
              onTap: id.trim().isEmpty ? null : () => _preview(row),
              dense: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              tileColor: cs.surfaceContainerLow,
              leading: _previewingId == id
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(LucideIcons.fileText, color: cs.primary, size: 19),
              title: Text(number,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: status.isEmpty ? null : Text(status),
            );
          },
        );
      },
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
  final ValueChanged<Invoice>? onEdit;
  final String? selectedInvoiceId;
  final _ClientInvoiceFilterController filterController;

  const _InvoiceList({
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.icon,
    required this.invoices,
    required this.clients,
    required this.fallbackClient,
    required this.onTap,
    required this.onDelete,
    this.onEdit,
    this.selectedInvoiceId,
    required this.filterController,
  });

  @override
  State<_InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<_InvoiceList> {
  DateTime? _invoiceDate(Invoice inv) =>
      inv.issueDate ?? inv.registeredAt ?? inv.occurrenceDate;

  @override
  void initState() {
    super.initState();
    widget.filterController.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _InvoiceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterController != widget.filterController) {
      oldWidget.filterController.removeListener(_refresh);
      widget.filterController.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.filterController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.filterController;
    final filtered = filters.apply(widget.invoices);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (filters.customRangeExpanded) ...[
            _ClientCustomDateRange(controller: filters),
            const SizedBox(height: 2),
          ],
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: EmptyView(
                      icon: widget.icon,
                      title: widget.emptyTitle,
                      subtitle: widget.emptySubtitle,
                    ),
                  )
                : _buildGroupedList(context, filtered),
          ),
        ],
      ),
    );
  }

  /// Builds a flat list of month-header + invoice items, injecting a
  /// [_MonthSeparator] whenever the month/year changes between invoices.
  Widget _buildGroupedList(BuildContext context, List<Invoice> invoices) {
    final l = AppLocalizations.of(context)!;

    // Build flat items: alternating _MonthKey (headers) and Invoice
    final items = <Object>[];
    String? lastKey;

    for (final inv in invoices) {
      final date = _invoiceDate(inv);
      final key = date == null
          ? null
          : '${date.year}-${date.month.toString().padLeft(2, '0')}';

      if (key != null && key != lastKey) {
        items.add(_MonthKey(date!, l.localeName));
        lastKey = key;
      }
      items.add(inv);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is _MonthKey) {
          return Padding(
            padding: EdgeInsets.zero,
            child: _MonthSeparator(label: item.label),
          );
        }
        final inv = item as Invoice;
        final client = widget.clients.firstWhere(
          (c) => c.id == inv.clientId,
          orElse: () => widget.fallbackClient,
        );

        return Padding(
          padding: EdgeInsets.zero,
          child: InvoiceListItem(
            invoice: inv,
            client: client,
            showClient: false,
            visibleFinancialColumns: const {
              HexoraFinancialColumn.date,
              HexoraFinancialColumn.total,
            },
            onTap: () => widget.onTap(inv),
            onPreview: () => widget.onTap(inv),
            selected: widget.selectedInvoiceId == inv.id,
            onDelete:
                widget.onDelete == null ? null : () => widget.onDelete!(inv),
            onEdit: widget.onEdit == null ? null : () => widget.onEdit!(inv),
          ),
        );
      },
    );
  }
}

class _ClientCustomDateRange extends StatelessWidget {
  const _ClientCustomDateRange({required this.controller});

  final _ClientInvoiceFilterController controller;

  Future<void> _pick(BuildContext context, {required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: from
          ? controller.fromDate ?? controller.toDate ?? now
          : controller.toDate ?? controller.fromDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    if (from) {
      controller.updateFrom(picked);
    } else {
      controller.updateTo(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    String label(DateTime? value, String fallback) =>
        value == null ? fallback : DateFormat.yMMMd(l.localeName).format(value);

    return Container(
      key: const ValueKey('client-custom-date-range'),
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
      color: cs.surfaceContainerLow.withValues(alpha: .45),
      child: Row(
        children: [
          Icon(LucideIcons.calendarRange, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: TextButton(
              onPressed: () => _pick(context, from: true),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                label(controller.fromDate, l.eventStartDateHint),
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall,
              ),
            ),
          ),
          Text('–', style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
          Flexible(
            child: TextButton(
              onPressed: () => _pick(context, from: false),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                label(controller.toDate, l.eventEndDateHint),
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall,
              ),
            ),
          ),
          IconButton(
            tooltip: l.clearSelection,
            onPressed: controller.clear,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            icon: const Icon(LucideIcons.x, size: 16),
          ),
        ],
      ),
    );
  }
}

class _ClientPeriodMenu extends StatelessWidget {
  const _ClientPeriodMenu({
    this.compact = false,
    required this.selected,
    required this.hasFilter,
    required this.isSpanish,
    required this.onSelected,
  });

  final DateQuickRange selected;
  final bool compact;
  final bool hasFilter;
  final bool isSpanish;
  final ValueChanged<DateQuickRange?> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final narrow = compact || MediaQuery.sizeOf(context).width < 500;
    final label = switch (selected) {
      DateQuickRange.month => isSpanish ? '30 días' : '30 days',
      DateQuickRange.quarter => isSpanish ? '3 meses' : '3 months',
      DateQuickRange.custom => isSpanish ? 'Personalizado' : 'Custom',
      DateQuickRange.none => isSpanish ? 'Periodo' : 'Period',
    };

    return PopupMenuButton<String>(
      key: const ValueKey('client-document-period-menu'),
      tooltip: '${isSpanish ? 'Seleccionar periodo' : 'Select period'}: $label',
      onSelected: (value) => onSelected(switch (value) {
        'month' => DateQuickRange.month,
        'quarter' => DateQuickRange.quarter,
        'custom' => DateQuickRange.custom,
        _ => null,
      }),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'all',
          child: Text(isSpanish ? 'Todo el periodo' : 'All time'),
        ),
        PopupMenuItem(
          value: 'month',
          child: Text(isSpanish ? '30 días' : '30 days'),
        ),
        PopupMenuItem(
          value: 'quarter',
          child: Text(isSpanish ? '3 meses' : '3 months'),
        ),
        PopupMenuItem(
          value: 'custom',
          child: Text(isSpanish ? 'Personalizado' : 'Custom'),
        ),
      ],
      child: Container(
        height: 32,
        width: narrow ? 32 : null,
        padding: EdgeInsets.symmetric(horizontal: narrow ? 7 : 10),
        decoration: BoxDecoration(
          color: hasFilter
              ? cs.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.calendarRange,
                size: 15, color: hasFilter ? cs.primary : cs.onSurfaceVariant),
            if (!narrow) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  color: hasFilter ? cs.primary : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown,
                  size: 15,
                  color: hasFilter ? cs.primary : cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lightweight data holder for a month-group header.
class _MonthKey {
  final String label;
  _MonthKey(DateTime date, String locale) : label = _formatMonth(date, locale);

  static String _formatMonth(DateTime date, String locale) {
    final formatter = DateFormat.yMMMM(locale);
    final raw = formatter.format(date);
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

/// A centered month/year divider: ── January 2026 ──
class _MonthSeparator extends StatelessWidget {
  const _MonthSeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return HexoraMonthSeparator(label: label, flat: true);
  }
}
