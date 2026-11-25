import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/presentation/utils/roles/group_role_labels.dart';
import 'package:provider/provider.dart';

import 'state/group_dashboard_state.dart';
import 'layout/narrow_layout.dart';
import 'layout/wide_layout.dart';
import 'navigation/dashboard_mobile_nav.dart';

class GroupDashboard extends StatefulWidget {
  const GroupDashboard({
    super.key,
    required this.group,
    this.invitationOnboardingRole,
  });

  final Group group;
  final String? invitationOnboardingRole;

  @override
  State<GroupDashboard> createState() => _GroupDashboardState();
}

class _GroupDashboardState extends State<GroupDashboard> {
  bool _onboardingShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.invitationOnboardingRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showInvitationOnboarding();
      });
    }
  }

  Future<void> _showInvitationOnboarding() async {
    if (_onboardingShown) return;
    _onboardingShown = true;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final role = GroupRole.fromWire(widget.invitationOnboardingRole);
    final modules = <(IconData, String)>[
      (
        Icons.dashboard_outlined,
        es ? 'Resumen y actividad del negocio' : 'Business overview and activity'
      ),
      (
        Icons.calendar_month_outlined,
        es ? 'Calendario y planificación compartida' : 'Shared calendar and planning'
      ),
      (
        Icons.folder_shared_outlined,
        es
            ? 'Facturas, gastos y registros disponibles para tu rol'
            : 'Invoices, expenses, and records available to your role'
      ),
      if (role.rank >= GroupRole.coAdmin.rank)
        (
          Icons.group_outlined,
          es ? 'Miembros e invitaciones' : 'Members and invitations'
        ),
      if (role.rank >= GroupRole.admin.rank)
        (
          Icons.admin_panel_settings_outlined,
          es ? 'Roles y configuración del negocio' : 'Roles and business settings'
        ),
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration_outlined, size: 36),
        title: Text(es
            ? 'Te damos la bienvenida a ${widget.group.name}'
            : 'Welcome to ${widget.group.name}'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${es ? 'Tu rol' : 'Your role'}: ${roleLabelOf(dialogContext, role)}',
                style: Theme.of(dialogContext)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(es
                  ? 'Hexora mostrará las herramientas permitidas para este rol. Puedes empezar por estas áreas:'
                  : 'Hexora will show the tools allowed for this role. You can start with these areas:'),
              const SizedBox(height: 14),
              for (final module in modules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(module.$1, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(module.$2)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(es ? 'Empezar a trabajar' : 'Start working'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupDashboardState(context, widget.group),
      builder: (context, _) {
        final state = context.watch<GroupDashboardState>();

        return Scaffold(
          backgroundColor: state.backdrop,
          appBar: state.buildAppBar(),
          body: LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= state.wideBreakpoint;
              return isWide
                  ? WideLayout(state: state)
                  : NarrowLayout(state: state);
            },
          ),
          bottomNavigationBar:
              state.showBottomBar ? DashboardMobileNav(state: state) : null,
        );
      },
    );
  }
}
