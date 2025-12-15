// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard_body_admin.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_info_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/business_hours/edit_business_hours_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/business_hours/group_business_hours_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/profile_role_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/group_time_tracking_screen_state.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../dashboard/controller/group_dashboard_state.dart';

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
          SectionHeader(title: l.sectionBusinessHours, textStyle: sectionTitle),
          GroupBusinessHoursCard(
            group: _group,
            description: l.businessHoursAdminSubtitle,
            onTap: () => _editBusinessHours(context),
          ),
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
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(l.invoicesNavLabel, style: tileTitle),
              subtitle: Text(l.invoicesNavSubtitle, style: tileSub),
              onTap: () =>
                  context.read<GroupDashboardState>().openSection('invoices'),
            ),
          ),

          const SizedBox(height: 8),
          SectionHeader(title: l.sectionInsights, textStyle: sectionTitle),
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
          if (!_group.hasCalendar)
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
