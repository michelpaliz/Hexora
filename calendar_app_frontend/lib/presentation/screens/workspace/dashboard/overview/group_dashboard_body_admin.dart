// lib/presentation/screens/workspace/dashboard/overview/group_dashboard_body_admin.dart
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/presentation/routes/app_routes.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/group_header_view.dart';
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
    showDialog<void>(
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

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
        );
    Widget destination(IconData icon, String title, String section) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(icon, color: cs.primary, size: 22),
          title: Text(title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  )),
          trailing:
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          onTap: () => open(section),
        );
    Widget group(List<Widget> items) => Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: cs.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 54,
                    color: cs.outlineVariant.withValues(alpha: 0.4)),
              items[i],
            ],
          ]),
        );

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          GroupHeaderView(group: _group),
          heading(l.sectionEvents),
          group([
            destination(Icons.view_agenda_outlined, l.agenda, Sections.agenda),
          ]),
          const SizedBox(height: 12),
          if (!_group.hasCalendar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Text(l.noCalendarWarning, style: TextStyle(color: cs.error)),
            ),
          GroupUndoneEventsSection(
            group: _group,
            user: widget.user,
            role: widget.role,
            onSeeAll: () => open(Sections.undone),
          ),
          const SizedBox(height: 12),
          GroupUpcomingEventsCard(
            limit: 3,
            groupId: _group.id,
            role: widget.role,
            currentUserId: widget.user.id,
          ),
          const SizedBox(height: 12),
          WorkConditionsCard(groupId: _group.id),
          heading(es ? 'Accesos rápidos' : 'Quick access'),
          group([
            destination(Icons.design_services_outlined, l.servicesClientsTitle,
                Sections.services),
            destination(Icons.map_outlined,
                es ? 'Mapa y visitas' : 'Map and visits', Sections.maps),
          ]),
          const SizedBox(height: 12),
          group([
            destination(
                Icons.insights_outlined, l.insightsTitle, Sections.insights),
          ]),
          heading(es ? 'Finanzas y comunicación' : 'Finance and communication'),
          group([
            destination(Icons.receipt_long_outlined, l.invoicesNavLabel,
                Sections.invoices),
            destination(Icons.account_balance_outlined, l.statementsNavTitle,
                Sections.enableBanking),
            destination(Icons.payments_outlined, es ? 'Gastos' : 'Expenses',
                Sections.expenses),
            destination(Icons.mail_outline_rounded, l.mailConsoleTitle,
                Sections.emails),
            destination(Icons.telegram, 'Telegram', Sections.telegram),
          ]),
          heading(es ? 'Equipo' : 'Team'),
          group([
            destination(Icons.group_outlined, l.membersTitle, Sections.members),
            destination(Icons.access_time_rounded, l.timeTrackingTitle,
                Sections.workers),
          ]),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: cs.surfaceContainerLow,
            child: ExpansionTile(
              key: const PageStorageKey('group-details'),
              title: Text(es ? 'Información del grupo' : 'Group information'),
              leading: const Icon(Icons.info_outline),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                ProfileRoleCard(
                  user: widget.user,
                  role: widget.role,
                  fetchReadSas: widget.fetchReadSas,
                  onTap: () => open(Sections.profile),
                ),
                const SizedBox(height: 12),
                GroupBusinessHoursCard(
                  group: _group,
                  description: l.businessHoursAdminSubtitle,
                  onTap: () => _editBusinessHours(context),
                ),
              ],
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
