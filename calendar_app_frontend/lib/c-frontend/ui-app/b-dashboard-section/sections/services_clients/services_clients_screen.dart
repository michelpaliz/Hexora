import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'sheets/add_client_sheet/add_client_sheet.dart';
import 'sheets/add_service_sheet.dart';
import 'tabs/clients/clients_tab.dart';
import 'tabs/services/services_tab.dart';

class ServicesClientsScreen extends StatefulWidget {
  final Group group;
  const ServicesClientsScreen({super.key, required this.group});

  @override
  State<ServicesClientsScreen> createState() => _ServicesClientsScreenState();
}

class _ServicesClientsScreenState extends State<ServicesClientsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _clientsApi = ClientsApi();
  final _servicesApi = ServiceApi();

  List<GroupClient> _clients = [];
  List<Service> _services = [];
  bool _loadingClients = true, _loadingServices = true;
  String? _errClients, _errServices;
  bool _showInactiveClients = false;
  GroupClient? _editingClient;
  bool _creatingClient = false;
  Service? _editingService;
  bool _creatingService = false;
  String? _propertyKindFilter;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadClients();
    _loadServices();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _loadingClients = true;
      _errClients = null;
    });
    try {
      final data =
          await _clientsApi.list(groupId: widget.group.id, active: null);
      setState(() => _clients = data);
    } catch (e) {
      setState(() => _errClients = e.toString());
    } finally {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() {
      _loadingServices = true;
      _errServices = null;
    });
    try {
      final data = await _servicesApi.list(groupId: widget.group.id);
      setState(() => _services = data);
    } catch (e) {
      setState(() => _errServices = e.toString());
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  // ---------- Create flows ----------
  bool _useSidePanel(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  void _startAddClient() {
    setState(() {
      _creatingClient = true;
      _editingClient = null;
    });
  }

  void _startEditClient(GroupClient client) {
    setState(() {
      _creatingClient = false;
      _editingClient = client;
    });
  }

  void _startAddService() {
    setState(() {
      _creatingService = true;
      _editingService = null;
    });
  }

  void _startEditService(Service service) {
    setState(() {
      _creatingService = false;
      _editingService = service;
    });
  }

  Future<void> _openAddClientSheet() async {
    final created = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          AddClientSheet(groupId: widget.group.id, api: _clientsApi),
    );
    if (created != null && mounted) {
      setState(() => _clients.insert(0, created));
      final l = AppLocalizations.of(context)!;
      final t = AppTypography.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.clientCreatedWithName(created.name),
                style: t.bodySmall)),
      );
    }
  }

  Future<void> _openAddServiceSheet() async {
    final created = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          AddServiceSheet(groupId: widget.group.id, api: _servicesApi),
    );
    if (created != null && mounted) {
      setState(() => _services.insert(0, created));
      final l = AppLocalizations.of(context)!;
      final t = AppTypography.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.serviceCreatedWithName(created.name),
                style: t.bodySmall)),
      );
    }
  }

  // ---------- Edit flows ----------
  Future<void> _openEditClientSheet(GroupClient c) async {
    final updated = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddClientSheet(
        groupId: widget.group.id, // harmless on edit
        api: _clientsApi,
        client: c,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        final i = _clients.indexWhere((x) => x.id == updated.id);
        if (i != -1) _clients[i] = updated;
      });
      final l = AppLocalizations.of(context)!;
      final t = AppTypography.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.clientUpdatedWithName(updated.name),
                style: t.bodySmall)),
      );
    }
  }

  Future<void> _openEditServiceSheet(Service s) async {
    final updated = await showModalBottomSheet<Service>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddServiceSheet(
        groupId: widget.group.id,
        api: _servicesApi,
        service: s,
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        final i = _services.indexWhere((x) => x.id == updated.id);
        if (i != -1) _services[i] = updated;
      });
      final l = AppLocalizations.of(context)!;
      final t = AppTypography.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.serviceUpdatedWithName(updated.name),
                style: t.bodySmall)),
      );
    }
  }

  void _handleClientSaved(GroupClient saved) {
    final idx = _clients.indexWhere((c) => c.id == saved.id);
    final isEdit = idx != -1;
    setState(() {
      if (isEdit) {
        _clients[idx] = saved;
      } else {
        _clients.insert(0, saved);
      }
      _creatingClient = false;
      _editingClient = null;
    });
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              isEdit
                  ? l.clientUpdatedWithName(saved.name)
                  : l.clientCreatedWithName(saved.name),
              style: t.bodySmall)),
    );
  }

  void _handleServiceSaved(Service saved) {
    final idx = _services.indexWhere((s) => s.id == saved.id);
    final isEdit = idx != -1;
    setState(() {
      if (isEdit) {
        _services[idx] = saved;
      } else {
        _services.insert(0, saved);
      }
      _creatingService = false;
      _editingService = null;
    });
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              isEdit
                  ? l.serviceUpdatedWithName(saved.name)
                  : l.serviceCreatedWithName(saved.name),
              style: t.bodySmall)),
    );
  }

  Future<void> _confirmDeleteClient(GroupClient client) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.remove),
        content: Text(l.removeClientConfirm(client.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final deleted = await _clientsApi.delete(client.id);
      if (!mounted) return;
      if (deleted) {
        setState(() => _clients.removeWhere((c) => c.id == client.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.clientRemovedSnack(client.name))),
        );
      } else {
        final updated = await _clientsApi.setActive(client.id, false);
        if (!mounted) return;
        setState(() {
          final i = _clients.indexWhere((c) => c.id == updated.id);
          if (i != -1) _clients[i] = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.clientDeactivatedSnack(client.name))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.removeFailedWithReason(e.toString()))),
      );
    }
  }

  Future<void> _confirmDeleteService(Service service) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.remove),
        content: Text(l.removeServiceConfirm(service.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final deleted = await _servicesApi.delete(service.id);
      if (!mounted) return;
      if (deleted) {
        setState(() => _services.removeWhere((s) => s.id == service.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.serviceRemovedSnack(service.name))),
        );
      } else {
        final updated = await _servicesApi.setActive(service.id, false);
        if (!mounted) return;
        setState(() {
          final i = _services.indexWhere((s) => s.id == updated.id);
          if (i != -1) _services[i] = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.serviceDeactivatedSnack(service.name))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.removeFailedWithReason(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final useSidePanel = _useSidePanel(context);

    final Color primary = cs.primary;
    final Color selectedText = ThemeColors.contrastOn(primary);
    final Color unselectedText =
        ThemeColors.textPrimary(context).withOpacity(0.7);
    final Color trackBg = ThemeColors.cardBg(context);

    // Optional: show counts in tab labels for quick context
    final clientsTabLabel = '${l.tabClients} · ${_clients.length}';
    final servicesTabLabel = '${l.tabServices} · ${_services.length}';
    final propertyKindOptions = _clients
        .map((c) => (c.propertyKind ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(
          l.screenServicesClientsTitle,
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: ThemeColors.textPrimary(context)),
        backgroundColor: cs.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: trackBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.06)),
              ),
              child: TabBar(
                controller: _tab,
                tabs: [
                  Tab(text: clientsTabLabel),
                  Tab(text: servicesTabLabel),
                ],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: selectedText,
                unselectedLabelColor: unselectedText,
                labelStyle: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: .2,
                ),
                unselectedLabelStyle: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                splashBorderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final left = TabBarView(
            controller: _tab,
            children: [
              ClientsTab(
                items: _clients,
                loading: _loadingClients,
                error: _errClients,
                onRefresh: _loadClients,
                showInlineCTA: true,
                onAddTap: () =>
                    useSidePanel ? _startAddClient() : _openAddClientSheet(),
                showInactive: _showInactiveClients,
                onToggleInactive: (v) =>
                    setState(() => _showInactiveClients = v),
                propertyKindFilter: _propertyKindFilter,
                propertyKindOptions: propertyKindOptions,
                onPropertyKindChanged: (v) =>
                    setState(() => _propertyKindFilter = v),
                onDelete: _confirmDeleteClient,
                onEdit: (client) => useSidePanel
                    ? _startEditClient(client)
                    : _openEditClientSheet(client),
              ),
              ServicesTab(
                items: _services,
                loading: _loadingServices,
                error: _errServices,
                onRefresh: _loadServices,
                showInlineCTA: true,
                onDelete: _confirmDeleteService,
                onAddTap: () =>
                    useSidePanel ? _startAddService() : _openAddServiceSheet(),
                onEdit: (service) => useSidePanel
                    ? _startEditService(service)
                    : _openEditServiceSheet(service),
              ),
            ],
          );

          if (!useSidePanel) {
            return left;
          }

          final right = AnimatedBuilder(
            animation: _tab,
            builder: (context, _) {
              final isClients = _tab.index == 0;
              final showClientEditor =
                  isClients && (_creatingClient || _editingClient != null);
              final showServiceEditor =
                  !isClients && (_creatingService || _editingService != null);

              if (showClientEditor) {
                return AddClientSheet(
                  key: ValueKey<String>(_editingClient == null
                      ? 'client-new'
                      : _editingClient!.id),
                  groupId: widget.group.id,
                  api: _clientsApi,
                  client: _editingClient,
                  closeOnSave: false,
                  onSaved: _handleClientSaved,
                );
              }

              if (showServiceEditor) {
                return AddServiceSheet(
                  key: ValueKey<String>(_editingService == null
                      ? 'service-new'
                      : _editingService!.id),
                  groupId: widget.group.id,
                  api: _servicesApi,
                  service: _editingService,
                  closeOnSave: false,
                  onSaved: _handleServiceSaved,
                );
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    isClients ? l.selectClientFirst : l.createServicesSubtitle,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          );

          final panelWidth =
              constraints.maxWidth.clamp(360.0, 480.0).toDouble();

          return Row(
            children: [
              Expanded(child: left),
              Container(
                width: panelWidth,
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    left: BorderSide(
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                ),
                child: right,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: AnimatedBuilder(
              animation: _tab,
              builder: (_, __) => Text(
                _tab.index == 0 ? l.addClient : l.addService,
                style: t.bodySmall.copyWith(
                  color: ThemeColors.contrastOn(cs.primary),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onPressed: () => _tab.index == 0
                ? (useSidePanel ? _startAddClient() : _openAddClientSheet())
                : (useSidePanel ? _startAddService() : _openAddServiceSheet()),
          ),
        ),
      ),
    );
  }
}
