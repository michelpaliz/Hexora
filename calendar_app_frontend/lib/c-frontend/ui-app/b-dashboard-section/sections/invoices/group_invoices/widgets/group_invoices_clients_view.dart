import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_detail_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/clients_list_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/client_classification_store.dart';

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
  final ValueChanged<Invoice> onDeleteInvoice;
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
    required this.onDeleteInvoice,
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
      _reloadOptions();
    }
  }

  Future<void> _reloadOptions() async {
    try {
      final loaded = await ClientClassificationStore.getOptions(widget.groupId);
      if (!mounted) return;
      setState(() {
        _savedEntityTypes = loaded.entityTypes;
        _savedPropertyKinds = loaded.propertyKinds;
      });
    } catch (_) {
      if (!mounted) return;
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

    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      final haystack = <String>[
        c.name,
        c.email ?? '',
        c.phone ?? '',
        c.billing?.legalName ?? '',
      ].join(' ').toLowerCase();
      if (!haystack.contains(q)) return false;
    }

    final entityOk =
        _entityFilter == null || (c.entityType ?? '').trim() == _entityFilter!;
    final propertyOk = _propertyFilter == null ||
        (c.propertyKind ?? '').trim() == _propertyFilter!;
    return entityOk && propertyOk;
  }

  void _clearFilters() {
    setState(() {
      _entityFilter = null;
      _propertyFilter = null;
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

    final filteredClients = widget.clients.where(_matchesFilters).toList();
    final selectedHiddenByFilters = widget.selectedClient != null &&
        widget.clients.any((c) => c.id == widget.selectedClient!.id) &&
        !filteredClients.any((c) => c.id == widget.selectedClient!.id);

    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ClientsListPanel(
                    allClients: widget.clients,
                    filteredClients: filteredClients,
                    selectedClient: widget.selectedClient,
                    selectedHiddenByFilters: selectedHiddenByFilters,
                    hideInactive: _hideInactive,
                    onToggleHideInactive: () =>
                        setState(() => _hideInactive = !_hideInactive),
                    searchController: _search,
                    onSearchChanged: () => setState(() {}),
                    entityFilter: _entityFilter,
                    propertyFilter: _propertyFilter,
                    entityOptions: entityOptions,
                    propertyOptions: propertyOptions,
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ClientDetailPanel(
                    clients: widget.clients,
                    selectedClient: widget.selectedClient,
                    issuedInvoices: widget.issuedInvoices,
                    draftInvoices: widget.draftInvoices,
                    entityOptions: entityOptions,
                    propertyOptions: propertyOptions,
                    assignBusy: _assignBusy,
                    onEditSelectedClient: widget.onEditSelectedClient,
                    onCreateInvoice: widget.onCreateInvoice,
                    onCreateReceipt: widget.onCreateReceipt,
                    onOpenInvoiceDetail: widget.onOpenInvoiceDetail,
                    onDeleteInvoice: widget.onDeleteInvoice,
                    onApplyClassification: ({
                      String? entityType,
                      String? propertyKind,
                    }) =>
                        _applyToSelected(
                      entityType: entityType,
                      propertyKind: propertyKind,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
