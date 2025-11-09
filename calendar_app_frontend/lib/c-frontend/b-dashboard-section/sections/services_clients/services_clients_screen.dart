import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/business_logic/service/service_api_client.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'sheets/add_client_sheet.dart';
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

  List<Client> _clients = [];
  List<Service> _services = [];
  bool _loadingClients = true, _loadingServices = true;
  String? _errClients, _errServices;

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

  // ---------- Create flows ----------
  Future<void> _openAddClient() async {
    final created = await showModalBottomSheet<Client>(
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
            content: Text(l.serviceCreatedWithName(created.name),
                style: t.bodySmall)),
      );
    }
  }

  // ---------- Edit flows ----------
  Future<void> _openEditClient(Client c) async {
    final updated = await showModalBottomSheet<Client>(
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
            content: Text(l.serviceUpdatedWithName(updated.name),
                style: t.bodySmall)),
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

    // Optional: show counts in tab labels for quick context
    final clientsTabLabel = '${l.tabClients} · ${_clients.length}';
    final servicesTabLabel = '${l.tabServices} · ${_services.length}';

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
      body: TabBarView(
        controller: _tab,
        children: [
          ClientsTab(
            items: _clients,
            loading: _loadingClients,
            error: _errClients,
            onRefresh: _loadClients,
            showInlineCTA: false,
            onEdit: _openEditClient,
          ),
          ServicesTab(
            items: _services,
            loading: _loadingServices,
            error: _errServices,
            onRefresh: _loadServices,
            showInlineCTA: false,
            onEdit: _openEditService,
          ),
        ],
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
            onPressed: () =>
                _tab.index == 0 ? _openAddClient() : _openAddService(),
          ),
        ),
      ),
    );
  }
}
