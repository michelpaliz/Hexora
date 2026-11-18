// lib/presentation/screens/workspace/dashboard/overview/group_dashboard_body_admin.dart
import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/presentation/shared/widgets/dialogs/hexora_dialog_route.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/group_header_view.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/widgets/mobile_dashboard_components.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/widgets/home_calendar_preview.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/overview/widgets/business_info_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_hours/edit_business_hours_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_hours/group_business_hours_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/presentation/screens/workspace/sections/role_info/profile_role_card.dart';
import 'package:hexora/presentation/screens/workspace/sections/undone_events/group_undone_events_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/presentation/screens/workspace/sections/weather/work_conditions_card.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/group_dashboard_state.dart';
import '../navigation/dashboard_sections.dart';

class GroupDashboardBodyAdmin extends StatefulWidget {
  const GroupDashboardBodyAdmin({
    super.key,
    required this.group,
    required this.counts,
    required this.onRefresh,
    required this.user,
    required this.role,
    this.onGroupChanged,
    required this.fetchReadSas,
  });

  final Group group;
  final MembersCount? counts;
  final Future<void> Function() onRefresh;

  // NEW: inject current user, role, and SAS fetcher
  final User user;
  final GroupRole role;
  final Future<String?> Function(String blobName) fetchReadSas;
  final ValueChanged<Group>? onGroupChanged;

  @override
  State<GroupDashboardBodyAdmin> createState() =>
      _GroupDashboardBodyAdminState();
}

class _GroupDashboardBodyAdminState extends State<GroupDashboardBodyAdmin> {
  late Group _group;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  @override
  void didUpdateWidget(covariant GroupDashboardBodyAdmin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group != widget.group ||
        oldWidget.group.businessHours != widget.group.businessHours) {
      _group = widget.group;
    }
  }

  Future<void> _editBusinessHours(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final hours = await showBusinessHoursDialog(
      context,
      initial: _group.businessHours,
    );
    if (hours == null || !context.mounted) return;

    final domain = context.read<GroupDomain>();
    final rootNav = Navigator.of(context, rootNavigator: true);

    if (!rootNav.mounted) return;
    showHexoraDialog<void>(
      context: rootNav.context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Group? updated;
    try {
      updated = await domain.setBusinessHours(
        groupId: _group.id,
        hours: hours,
      );
    } finally {
      if (rootNav.context.mounted) rootNav.pop();
    }

    if (!context.mounted) return;

    if (updated != null) {
      setState(() => _group = updated!);
      widget.onGroupChanged?.call(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.businessHoursUpdateSuccess)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.businessHoursUpdateError)),
      );
    }
  }

  Widget _buildMobile(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final es = l.localeName.startsWith('es');
    void open(String section) =>
        context.read<GroupDashboardState>().openSection(section);

    Widget quickAction(
      IconData icon,
      String title,
      String subtitle,
      String section,
    ) =>
        Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => open(section),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: cs.primary, size: 19),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
    Widget quickGrid(List<Widget> items) => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.42,
          children: items,
        );
    Widget financialCard(
      IconData icon,
      String title,
      Color color,
      String section,
    ) =>
        Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => open(section),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    es ? 'Ver detalle' : 'View details',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          GroupHeaderView(group: _group),
          MobileDashboardSection(
            title: es ? 'Resumen financiero' : 'Financial overview',
            action: TextButton(
              onPressed: () => open(Sections.insights),
              child: Text(es ? 'Ver reportes' : 'View reports'),
            ),
            child: SizedBox(
              height: 104,
              child: Row(
                children: [
                  Expanded(
                    child: financialCard(
                      Icons.arrow_upward_rounded,
                      es ? 'Ingresos' : 'Income',
                      const Color(0xFF20B47A),
                      Sections.invoices,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: financialCard(
                      Icons.arrow_downward_rounded,
                      es ? 'Gastos' : 'Expenses',
                      const Color(0xFFE65B73),
                      Sections.expenses,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: financialCard(
                      Icons.schedule_rounded,
                      es ? 'Por cobrar' : 'Receivable',
                      const Color(0xFFE9A21B),
                      Sections.invoices,
                    ),
                  ),
                ],
              ),
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Accesos rápidos' : 'Quick access',
            action: Text(
              es ? '4 herramientas' : '4 tools',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            child: quickGrid([
              quickAction(
                Icons.calendar_month_outlined,
                l.calendarTitle,
                es ? 'Eventos y visitas' : 'Events and visits',
                Sections.calendar,
              ),
              quickAction(
                Icons.view_agenda_outlined,
                l.agenda,
                es ? 'Visitas y tareas' : 'Visits and tasks',
                Sections.agenda,
              ),
              quickAction(
                Icons.receipt_long_outlined,
                l.invoicesNavLabel,
                es ? 'Crear o emitir' : 'Create or issue',
                Sections.invoices,
              ),
              quickAction(
                Icons.groups_outlined,
                l.tabClients,
                es ? 'Gestionar clientes' : 'Manage clients',
                Sections.services,
              ),
            ]),
          ),
          MobileDashboardSection(
            title: es ? 'Calendario y agenda' : 'Calendar and agenda',
            action: TextButton(
              onPressed: () => open(Sections.calendar),
              child: Text(es ? 'Ver agenda' : 'View agenda'),
            ),
            child: HomeCalendarPreview(
              groupId: _group.id,
              role: widget.role,
              currentUserId: widget.user.id,
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Actividad de hoy' : "Today's activity",
            child: CompactNavigationGroup(
              children: [
                if (!_group.hasCalendar)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(l.noCalendarWarning,
                        style: TextStyle(color: cs.error)),
                  ),
                GroupUndoneEventsSection(
                  group: _group,
                  user: widget.user,
                  role: widget.role,
                  onSeeAll: () => open(Sections.undone),
                  compact: true,
                ),
                WorkConditionsCard(groupId: _group.id, compact: true),
              ],
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Clientes y operación' : 'Clients and operations',
            child: CompactNavigationGroup(
              children: [
                CompactNavigationTile(
                  icon: Icons.design_services_outlined,
                  label: l.servicesClientsTitle,
                  onTap: () => open(Sections.services),
                ),
                CompactNavigationTile(
                  icon: Icons.view_kanban_outlined,
                  label: es ? 'Notas rápidas' : 'Quick notes',
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.groupQuickNotes,
                    arguments: _group,
                  ),
                ),
                CompactNavigationTile(
                  icon: Icons.map_outlined,
                  label: es ? 'Mapa y visitas' : 'Map and visits',
                  onTap: () => open(Sections.maps),
                ),
                CompactNavigationTile(
                  icon: Icons.forum_outlined,
                  label: es ? 'Chat de la empresa' : 'Business chat',
                  onTap: () => open(Sections.businessChat),
                ),
                CompactNavigationTile(
                  icon: Icons.insights_outlined,
                  label: l.insightsTitle,
                  onTap: () => open(Sections.insights),
                ),
              ],
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Finanzas' : 'Finance',
            child: CompactNavigationGroup(
              children: [
                CompactNavigationTile(
                  icon: Icons.request_quote_outlined,
                  label: es ? 'Presupuestos' : 'Estimates',
                  onTap: () => open(Sections.budgets),
                ),
                CompactNavigationTile(
                  icon: Icons.account_balance_outlined,
                  label: l.statementsNavTitle,
                  onTap: () => open(Sections.enableBanking),
                ),
              ],
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Comunicación' : 'Communication',
            child: CompactNavigationGroup(
              children: [
                CompactNavigationTile(
                  icon: Icons.mail_outline_rounded,
                  label: l.mailConsoleTitle,
                  onTap: () => open(Sections.emails),
                ),
                CompactNavigationTile(
                  icon: Icons.telegram,
                  label: 'Telegram',
                  onTap: () => open(Sections.telegram),
                ),
              ],
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Equipo' : 'Team',
            child: CompactNavigationGroup(
              children: [
                CompactNavigationTile(
                  icon: Icons.group_outlined,
                  label: l.membersTitle,
                  onTap: () => open(Sections.members),
                ),
                CompactNavigationTile(
                  icon: Icons.access_time_rounded,
                  label: l.timeTrackingTitle,
                  onTap: () => open(Sections.workers),
                ),
              ],
            ),
          ),
          MobileDashboardSection(
            title: es ? 'Configuración' : 'Configuration',
            child: Material(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                expansionAnimationStyle: HexoraMotion.expansionStyle(context),
                key: const PageStorageKey('group-details'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                title: Text(
                  es ? 'Información del negocio' : 'Business information',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                leading: Icon(Icons.info_outline, color: cs.primary, size: 20),
                childrenPadding: const EdgeInsets.only(bottom: 6),
                children: [
                  BusinessInfoSection(
                    user: widget.user,
                    role: widget.role,
                    group: _group,
                    fetchReadSas: widget.fetchReadSas,
                    onOpenProfile: () => open(Sections.profile),
                    onEditBusinessHours: () => _editBusinessHours(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final sectionTitle = t.bodyLarge.copyWith(fontWeight: FontWeight.w800);
    final tileTitle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
        );
    final tileSub = t.bodySmall;
    final tileBg = ThemeColors.listTileBg(context);

    final membersShown = widget.counts?.accepted ?? _group.userIds.length;

    if (MediaQuery.sizeOf(context).width < 700) {
      return _buildMobile(context);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l.sectionOverview, textStyle: sectionTitle),

          // Group header card
          GroupHeaderView(group: _group),
          const SizedBox(height: 16),
          // Role card (greeting + capabilities)
          ProfileRoleCard(
            user: widget.user,
            role: widget.role,
            fetchReadSas: widget.fetchReadSas,
            onTap: () =>
                context.read<GroupDashboardState>().openSection('profile'),
          ),

          const SizedBox(height: 20),
          WorkConditionsCard(groupId: _group.id),
          const SizedBox(height: 20),
          SectionHeader(title: l.sectionBusinessHours, textStyle: sectionTitle),
          GroupBusinessHoursCard(
            group: _group,
            description: l.businessHoursAdminSubtitle,
            onTap: () => _editBusinessHours(context),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: l.calendarTitle, textStyle: sectionTitle),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: Text(l.calendarTitle, style: tileTitle),
              subtitle: Text(
                _group.hasCalendar ? l.goToCalendar : l.noCalendarWarning,
                style: tileSub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => context
                  .read<GroupDashboardState>()
                  .openSection(Sections.calendar),
            ),
          ),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.view_agenda_outlined),
              title: Text(l.agenda, style: tileTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context
                  .read<GroupDashboardState>()
                  .openSection(Sections.agenda),
            ),
          ),
          if (!_group.hasCalendar) ...[
            const SizedBox(height: 8),
            Card(
              color: cs.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l.noCalendarWarning,
                  style: t.bodyMedium.copyWith(color: cs.onErrorContainer),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: l.sectionEvents,
            subtitle: l.pendingEventsSectionTitle,
            textStyle: sectionTitle,
          ),
          GroupUpcomingEventsCard(
            groupId: _group.id,
            role: widget.role,
            currentUserId: widget.user.id,
            // cardColor: sectionCardColor,
          ),
          const SizedBox(height: 12),
          GroupUndoneEventsSection(
            group: _group,
            user: widget.user,
            role: widget.role,
            onSeeAll: () =>
                context.read<GroupDashboardState>().openSection('undone'),
          ),

          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(l.insightsTitle, style: tileTitle),
              subtitle: Text(l.insightsSubtitle, style: tileSub),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('insights'),
            ),
          ),

          const SizedBox(height: 20),
          SectionHeader(title: l.sectionManage, textStyle: sectionTitle),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.group_outlined),
              title: Text(l.membersTitle, style: tileTitle),
              subtitle: Text(
                '${NumberFormat.decimalPattern(l.localeName).format(membersShown)} ${l.membersTitle.toLowerCase()}',
                style: tileSub,
              ),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('members'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.design_services_outlined),
              title: Text(l.servicesClientsTitle, style: tileTitle),
              subtitle: Text(l.servicesClientsSubtitle, style: tileSub),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('services'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(
                l.localeName.startsWith('es') ? 'Mapa' : 'Map',
                style: tileTitle,
              ),
              subtitle: Text(
                l.localeName.startsWith('es')
                    ? 'Consulta ubicaciones de clientes y visitas'
                    : 'View client locations and visits',
                style: tileSub,
              ),
              onTap: () => context
                  .read<GroupDashboardState>()
                  .openSection(Sections.maps),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l.invoicesNavLabel, style: tileTitle),
              subtitle: Text(l.invoicesNavSubtitle, style: tileSub),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('invoices'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(l.statementsNavTitle, style: tileTitle),
              subtitle: Text(l.bankProvidersTabTitle, style: tileSub),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.enableBanking,
                arguments: _group,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: Text(
                l.localeName.startsWith('es') ? 'Gastos' : 'Expenses',
                style: tileTitle,
              ),
              subtitle: Text(
                l.localeName.startsWith('es')
                    ? 'Gestiona facturas de proveedor y gastos'
                    : 'Manage supplier invoices and expenses',
                style: tileSub,
              ),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('expenses'),
            ),
          ),

          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(l.mailConsoleTitle, style: tileTitle),
              subtitle: Text(
                '${l.mailConsoleTitle} ${l.sectionManage.toLowerCase()}',
                style: tileSub,
              ),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('emails'),
            ),
          ),

          const SizedBox(height: 20),
          SectionHeader(title: l.sectionWorkersHours, textStyle: sectionTitle),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: Text(l.timeTrackingTitle, style: tileTitle),
              subtitle: Text(l.timeTrackingHeaderHint, style: tileSub),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('workers'),
            ),
          ),

          const SizedBox(height: 96),
        ],
      ),
    );
  }
}
