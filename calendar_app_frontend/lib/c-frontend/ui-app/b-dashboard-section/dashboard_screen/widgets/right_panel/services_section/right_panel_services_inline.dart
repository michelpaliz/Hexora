import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet/add_client_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_service_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/tabs/clients/clients_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/tabs/services/services_tab.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ServicesClientsInlinePanel extends StatefulWidget {
  final Group group;

  const ServicesClientsInlinePanel({
    super.key,
    required this.group,
  });

  @override
  State<ServicesClientsInlinePanel> createState() =>
      _ServicesClientsInlinePanelState();
}

class _ServicesClientsInlinePanelState extends State<ServicesClientsInlinePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _clientsApi = ClientsApi();
  final _servicesApi = ServiceApi();

  List<GroupClient> _clients = [];
  List<Service> _services = [];
  bool _showInactiveClients = false;
  bool _loadingClients = true, _loadingServices = true;
  String? _errClients, _errServices;
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
    if (!mounted) return;
    setState(() {
      _loadingClients = true;
      _errClients = null;
    });
    try {
      final data =
          await _clientsApi.list(groupId: widget.group.id, active: null);
      if (!mounted) return;
      setState(() => _clients = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errClients = e.toString());
    } finally {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  Future<void> _loadServices() async {
    if (!mounted) return;
    setState(() {
      _loadingServices = true;
      _errServices = null;
    });
    try {
      final data = await _servicesApi.list(groupId: widget.group.id);
      if (!mounted) return;
      setState(() => _services = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errServices = e.toString());
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  bool _useSidePanel(double width) => width >= 820;

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
          content:
              Text(l.clientCreatedWithName(created.name), style: t.bodySmall),
        ),
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
          content:
              Text(l.serviceCreatedWithName(created.name), style: t.bodySmall),
        ),
      );
    }
  }

  Future<void> _openEditClientSheet(GroupClient c) async {
    final updated = await showModalBottomSheet<GroupClient>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddClientSheet(
        groupId: widget.group.id,
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
          content:
              Text(l.clientUpdatedWithName(updated.name), style: t.bodySmall),
        ),
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
          content:
              Text(l.serviceUpdatedWithName(updated.name), style: t.bodySmall),
        ),
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
          style: t.bodySmall,
        ),
      ),
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
          style: t.bodySmall,
        ),
      ),
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

    final Color primary = cs.primary;
    final Color selectedText = ThemeColors.contrastOn(primary);
    final Color unselectedText =
        ThemeColors.textPrimary(context).withValues(alpha: 0.7);
    final Color trackBg = ThemeColors.cardBg(context);

    final clientsTabLabel = '${l.tabClients} · ${_clients.length}';
    final servicesTabLabel = '${l.tabServices} · ${_services.length}';
    final propertyKindOptions = _clients
        .map((c) => (c.propertyKind ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSidePanel = _useSidePanel(constraints.maxWidth);
        final left = Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: trackBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
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
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  ClientsTab(
                    items: _clients,
                    loading: _loadingClients,
                    error: _errClients,
                    onRefresh: _loadClients,
                    showInactive: _showInactiveClients,
                    onToggleInactive: (v) =>
                        setState(() => _showInactiveClients = v),
                    propertyKindFilter: _propertyKindFilter,
                    propertyKindOptions: propertyKindOptions,
                    onPropertyKindChanged: (v) =>
                        setState(() => _propertyKindFilter = v),
                    onDelete: _confirmDeleteClient,
                    showInlineCTA: true,
                    onAddTap: () => useSidePanel
                        ? _startAddClient()
                        : _openAddClientSheet(),
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
                    onAddTap: () => useSidePanel
                        ? _startAddService()
                        : _openAddServiceSheet(),
                    onEdit: (service) => useSidePanel
                        ? _startEditService(service)
                        : _openEditServiceSheet(service),
                  ),
                ],
              ),
            ),
          ],
        );

        if (!useSidePanel) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                left,
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: AnimatedBuilder(
                    animation: _tab,
                    builder: (_, __) {
                      final isClients = _tab.index == 0;
                      final label = isClients ? l.addClient : l.addService;
                      final onPressed = isClients
                          ? _openAddClientSheet
                          : _openAddServiceSheet;
                      return FloatingActionButton.extended(
                        icon: const Icon(Icons.add),
                        label: Text(label),
                        backgroundColor: primary,
                        foregroundColor: ThemeColors.contrastOn(primary),
                        onPressed: onPressed,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        final panelWidth =
            (constraints.maxWidth * 0.48).clamp(420.0, 620.0).toDouble();

        final right = AnimatedBuilder(
          animation: _tab,
          builder: (context, _) {
            final isClients = _tab.index == 0;
            final showClientEditor =
                isClients && (_creatingClient || _editingClient != null);
            final showServiceEditor =
                !isClients && (_creatingService || _editingService != null);
            final isEditing = showClientEditor || showServiceEditor;

            Widget content;
            if (showClientEditor) {
              content = AddClientSheet(
                key: ValueKey<String>(
                    _editingClient == null ? 'client-new' : _editingClient!.id),
                groupId: widget.group.id,
                api: _clientsApi,
                client: _editingClient,
                closeOnSave: false,
                onSaved: _handleClientSaved,
              );
            } else if (showServiceEditor) {
              content = AddServiceSheet(
                key: ValueKey<String>(_editingService == null
                    ? 'service-new'
                    : _editingService!.id),
                groupId: widget.group.id,
                api: _servicesApi,
                service: _editingService,
                closeOnSave: false,
                onSaved: _handleServiceSaved,
              );
            } else {
              final showClientsEmptyState = isClients && _clients.isEmpty;
              final showServicesEmptyState = !isClients && _services.isEmpty;
              if (showClientsEmptyState || showServicesEmptyState) {
                content = Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      margin: const EdgeInsets.all(18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showClientsEmptyState
                                ? Icons.people_outline_rounded
                                : Icons.design_services_outlined,
                            size: 30,
                            color: cs.primary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            showClientsEmptyState
                                ? l.noClientsYet
                                : l.tabServices,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            showClientsEmptyState
                                ? l.clientSearchHint
                                : l.createServicesSubtitle,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed:
                                isClients ? _startAddClient : _startAddService,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(isClients ? l.addClient : l.addService),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                content = Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isClients
                          ? l.selectClientFirst
                          : l.createServicesSubtitle,
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
            }

            return Column(
              children: [
                Divider(
                  height: isEditing ? 1 : 0,
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
                Expanded(child: content),
              ],
            );
          },
        );

        return Padding(
          padding: const EdgeInsets.all(12),
          child: FolderPanel(
            title: '${l.tabServices} · ${l.tabClients}',
            showTab: true,
            actions: [
              AnimatedBuilder(
                animation: _tab,
                builder: (context, _) {
                  final isClients = _tab.index == 0;
                  return Tooltip(
                    message: isClients ? l.addClient : l.addService,
                    child: FilledButton(
                      onPressed: isClients ? _startAddClient : _startAddService,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 36),
                      ),
                      child: const Icon(Icons.add_rounded, size: 18),
                    ),
                  );
                },
              ),
            ],
            child: Row(
              children: [
                Expanded(child: left),
                Container(
                  width: panelWidth,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      left: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: right,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
