import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/hexora_resizable_split.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/client_detail_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/clients_view/clients_list_panel.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/client_classification_store.dart';

class GroupInvoicesClientsView extends StatefulWidget {
  final String groupId;
  final List<GroupClient> clients;
  final GroupClient? selectedClient;
  final List<Invoice> issuedInvoices;
  final List<Invoice> draftInvoices;
  final ValueChanged<GroupClient> onSelectClient;
  final VoidCallback onCreateInvoice;
  final VoidCallback onCreateReceipt;
  final VoidCallback onEditSelectedClient;
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
  final int initialDetailTabIndex;
  final VoidCallback? onAddClient;
  final ValueChanged<GroupClient>? onEditClient;
  final VoidCallback? onRefresh;
  final bool refreshing;

  /// Replaces the client detail panel, e.g. with the inline client form.
  final Widget? detailOverride;
  final Future<void> Function(
    GroupClient client, {
    String? entityType,
    String? propertyKind,
  }) onUpdateClientClassification;

  const GroupInvoicesClientsView({
    super.key,
    required this.groupId,
    required this.clients,
    required this.selectedClient,
    required this.issuedInvoices,
    required this.draftInvoices,
    required this.onSelectClient,
    required this.onCreateInvoice,
    required this.onCreateReceipt,
    required this.onEditSelectedClient,
    required this.onOpenInvoiceDetail,
    this.onEditInvoice,
    required this.onEditReceipt,
    required this.invoicePreviewBuilder,
    required this.receiptPreviewBuilder,
    required this.onDeleteInvoice,
    required this.onDownloadVisibleInvoices,
    this.initialDetailTabIndex = 0,
    this.detailOverride,
    this.onAddClient,
    this.onEditClient,
    this.onRefresh,
    this.refreshing = false,
    required this.onUpdateClientClassification,
  });

  @override
  State<GroupInvoicesClientsView> createState() =>
      _GroupInvoicesClientsViewState();
}

class _GroupInvoicesClientsViewState extends State<GroupInvoicesClientsView> {
  String? _entityFilter;
  String? _propertyFilter;
  bool _assignBusy = false;
  bool _hideInactive = true;
  bool _missingCurrentMonthInvoiceOnly = false;
  bool _clientsPanelCollapsed = false;
  final TextEditingController _search = TextEditingController();

  List<String> _savedEntityTypes = const [];
  List<String> _savedPropertyKinds = const [];

  @override
  void initState() {
    super.initState();
    _reloadOptions();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroupInvoicesClientsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _entityFilter = null;
      _propertyFilter = null;
      _missingCurrentMonthInvoiceOnly = false;
      _hideInactive = true;
      _search.clear();
      _reloadOptions();
    }
  }

  Future<void> _reloadOptions() async {
    final groupId = widget.groupId;
    try {
      final loaded = await ClientClassificationStore.getOptions(groupId);
      if (!mounted || widget.groupId != groupId) return;
      setState(() {
        _savedEntityTypes = loaded.entityTypes;
        _savedPropertyKinds = loaded.propertyKinds;
      });
    } catch (_) {
      if (!mounted || widget.groupId != groupId) return;
      setState(() {
        _savedEntityTypes = const [];
        _savedPropertyKinds = const [];
      });
    }
  }

  List<String> _mergedOptions({
    required List<String> saved,
    required Iterable<String?> fromClients,
  }) {
    final values = <String>{
      ...saved.map((e) => e.trim()).where((e) => e.isNotEmpty),
      ...fromClients.map((e) => (e ?? '').trim()).where((e) => e.isNotEmpty),
    };
    final list = values.toList()..sort();
    return list;
  }

  bool _matchesFilters(GroupClient c) {
    if (_hideInactive && !c.isActive) return false;
    if (_missingCurrentMonthInvoiceOnly &&
        c.missingCurrentMonthInvoice != true) {
      return false;
    }

    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final haystack = <String>[
        c.name,
        c.email ?? '',
        c.phone ?? '',
        c.billing?.legalName ?? '',
        c.effectiveCustomerType ?? '',
        c.effectivePropertyType ?? '',
      ].join(' ').toLowerCase();
      if (!haystack.contains(q)) return false;
    }

    final entityOk = _entityFilter == null ||
        (c.effectiveCustomerType ?? '').trim() == _entityFilter!;
    final propertyOk = _propertyFilter == null ||
        (c.effectivePropertyType ?? '').trim() == _propertyFilter!;
    return entityOk && propertyOk;
  }

  void _clearFilters() {
    setState(() {
      _entityFilter = null;
      _propertyFilter = null;
      _missingCurrentMonthInvoiceOnly = false;
    });
  }

  Future<void> _applyToSelected({
    String? entityType,
    String? propertyKind,
  }) async {
    final selected = widget.selectedClient;
    if (selected == null) return;
    setState(() => _assignBusy = true);
    try {
      await widget.onUpdateClientClassification(
        selected,
        entityType: entityType,
        propertyKind: propertyKind,
      );
    } finally {
      if (mounted) setState(() => _assignBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entityOptions = _mergedOptions(
      saved: _savedEntityTypes,
      fromClients: widget.clients.map((c) => c.entityType),
    );
    final propertyOptions = _mergedOptions(
      saved: _savedPropertyKinds,
      fromClients: widget.clients.map((c) => c.propertyKind),
    );
    final customerTypeOptions = widget.clients
        .map((client) => client.effectiveCustomerType)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    final propertyTypeOptions = widget.clients
        .map((client) => client.effectivePropertyType)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    final filteredClients = widget.clients.where(_matchesFilters).toList();
    final selectedHiddenByFilters = widget.selectedClient != null &&
        widget.clients.any((c) => c.id == widget.selectedClient!.id) &&
        !filteredClients.any((c) => c.id == widget.selectedClient!.id);

    final detail = widget.detailOverride ??
        ClientDetailPanel(
          groupId: widget.groupId,
          clients: widget.clients,
          selectedClient: widget.selectedClient,
          issuedInvoices: widget.issuedInvoices,
          draftInvoices: widget.draftInvoices,
          entityOptions: entityOptions,
          propertyOptions: propertyOptions,
          assignBusy: _assignBusy,
          initialTabIndex: widget.initialDetailTabIndex,
          onEditSelectedClient: widget.onEditSelectedClient,
          onCreateInvoice: widget.onCreateInvoice,
          onCreateReceipt: widget.onCreateReceipt,
          onOpenInvoiceDetail: widget.onOpenInvoiceDetail,
          onEditInvoice: widget.onEditInvoice,
          onEditReceipt: widget.onEditReceipt,
          invoicePreviewBuilder: widget.invoicePreviewBuilder,
          receiptPreviewBuilder: widget.receiptPreviewBuilder,
          onDeleteInvoice: widget.onDeleteInvoice,
          onDownloadVisibleInvoices: widget.onDownloadVisibleInvoices,
          onAddClient: widget.onAddClient,
          onApplyClassification: ({String? entityType, String? propertyKind}) =>
              _applyToSelected(
            entityType: entityType,
            propertyKind: propertyKind,
          ),
        );

    return Column(
      children: [
        const SizedBox(height: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _clientsPanelCollapsed
                ? Row(children: [
                    Tooltip(
                      message:
                          Localizations.localeOf(context).languageCode == 'es'
                              ? 'Mostrar clientes'
                              : 'Show clients',
                      child: IconButton(
                        onPressed: () =>
                            setState(() => _clientsPanelCollapsed = false),
                        icon: const Icon(
                            Icons.keyboard_double_arrow_right_rounded),
                      ),
                    ),
                    Expanded(child: detail),
                  ])
                : HexoraResizableSplit(
                    // Keep the client table as the primary workspace while
                    // retaining enough room for the selected client's detail.
                    preferenceKey: 'invoices_clients_split_fraction_v5',
                    initialFraction: 0.40,
                    minStartWidth: 360,
                    maxStartWidth: 560,
                    minEndWidth: 460,
                    start: ClientsListPanel(
                      allClients: widget.clients,
                      filteredClients: filteredClients,
                      selectedClient: widget.selectedClient,
                      selectedHiddenByFilters: selectedHiddenByFilters,
                      hideInactive: _hideInactive,
                      onToggleHideInactive: () =>
                          setState(() => _hideInactive = !_hideInactive),
                      missingCurrentMonthInvoiceOnly:
                          _missingCurrentMonthInvoiceOnly,
                      onToggleMissingCurrentMonthInvoiceOnly: (value) =>
                          setState(() {
                        _missingCurrentMonthInvoiceOnly = value;
                      }),
                      searchController: _search,
                      onSearchChanged: () => setState(() {}),
                      entityFilter: _entityFilter,
                      propertyFilter: _propertyFilter,
                      entityOptions: customerTypeOptions,
                      propertyOptions: propertyTypeOptions,
                      onClearFilters: _clearFilters,
                      onToggleEntityFilter: (v) => setState(() {
                        _entityFilter = _entityFilter == v ? null : v;
                      }),
                      onTogglePropertyFilter: (v) => setState(() {
                        _propertyFilter = _propertyFilter == v ? null : v;
                      }),
                      onClearEntityFilter: () =>
                          setState(() => _entityFilter = null),
                      onClearPropertyFilter: () =>
                          setState(() => _propertyFilter = null),
                      onSelectClient: widget.onSelectClient,
                      onAddClient: widget.onAddClient,
                      onRefresh: widget.onRefresh,
                      refreshing: widget.refreshing,
                      onEditClient: widget.onEditClient,
                      onCollapse: () => setState(
                        () => _clientsPanelCollapsed = true,
                      ),
                    ),
                    end: detail,
                  ),
          ),
        ),
      ],
    );
  }
}
