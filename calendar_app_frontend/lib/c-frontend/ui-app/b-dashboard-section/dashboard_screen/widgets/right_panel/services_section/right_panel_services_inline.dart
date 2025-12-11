import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_client_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/sheets/add_service_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/tabs/clients/clients_tab.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/tabs/services/services_tab.dart';
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
  bool _loadingClients = true, _loadingServices = true;
  String? _errClients, _errServices;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
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
      final data = await _clientsApi.list(groupId: widget.group.id);
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

  Future<void> _openAddClient() async {
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

  Future<void> _openAddService() async {
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

  Future<void> _openEditClient(GroupClient c) async {
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

  Future<void> _openEditService(Service s) async {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    final Color primary = cs.primary;
    final Color selectedText = ThemeColors.contrastOn(primary);
    final Color unselectedText =
        ThemeColors.textPrimary(context).withOpacity(0.7);
    final Color trackBg = ThemeColors.cardBg(context);

    final clientsTabLabel = '${l.tabClients} · ${_clients.length}';
    final servicesTabLabel = '${l.tabServices} · ${_services.length}';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
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
                      showInlineCTA: true,
                      onAddTap: _openAddClient,
                      onEdit: _openEditClient,
                    ),
                    ServicesTab(
                      items: _services,
                      loading: _loadingServices,
                      error: _errServices,
                      onRefresh: _loadServices,
                      showInlineCTA: true,
                      onAddTap: _openAddService,
                      onEdit: _openEditService,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: AnimatedBuilder(
              animation: _tab,
              builder: (_, __) {
                final isClients = _tab.index == 0;
                final label = isClients ? l.addClient : l.addService;
                final onPressed = isClients ? _openAddClient : _openAddService;
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
}
