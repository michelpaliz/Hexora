// lib/c-frontend/ui-app/b-dashboard-section/dashboard_screen/group_dashboard_body_admin.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_info_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/widgets/common/section_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/role_info/profile_role_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/group_time_tracking_screen_state.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class GroupDashboardBodyAdmin extends StatelessWidget {
  const GroupDashboardBodyAdmin({
    super.key,
    required this.group,
    required this.counts,
    required this.onRefresh,
    required this.user,
    required this.role,
    required this.fetchReadSas,
  });

  final Group group;
  final MembersCount? counts;
  final Future<void> Function() onRefresh;

  // NEW: inject current user, role, and SAS fetcher
  final User user;
  final GroupRole role;
  final Future<String?> Function(String blobName) fetchReadSas;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final sectionTitle = t.bodyLarge.copyWith(fontWeight: FontWeight.w800);
    final tileTitle = t.accentText.copyWith(fontWeight: FontWeight.w600);
    final tileSub = t.bodySmall;
    final tileBg = ThemeColors.listTileBg(context);

    final membersShown = counts?.accepted ?? group.userIds.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(title: l.sectionOverview, textStyle: sectionTitle),

          // Group header card
          GroupHeaderView(group: group),
          const SizedBox(height: 16),
          // Role card (greeting + capabilities)
          ProfileRoleCard(
            user: user,
            role: role,
            fetchReadSas: fetchReadSas,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RoleInfoScreen(
                  group: group,
                  user: user,
                  role: role,
                  fetchReadSas: fetchReadSas,
                ),
              ));
            },
          ),

          const SizedBox(height: 20),
          SectionHeader(title: l.sectionUpcoming, textStyle: sectionTitle),
          GroupUpcomingEventsCard(groupId: group.id),

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
              onTap: () => Navigator.pushNamed(context, AppRoutes.groupMembers,
                  arguments: group),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: tileBg,
            child: ListTile(
              leading: const Icon(Icons.design_services_outlined),
              title: Text(l.servicesClientsTitle, style: tileTitle),
              subtitle: Text(l.servicesClientsSubtitle, style: tileSub),
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.groupServicesClients,
                  arguments: group),
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
              onTap: () => Navigator.pushNamed(context, AppRoutes.groupInsights,
                  arguments: group),
            ),
          ),

          const SizedBox(height: 20),
          if (!group.hasCalendar)
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => GroupTimeTrackingScreen(group: group)),
              ),
            ),
          ),

          const SizedBox(height: 96),
        ],
      ),
    );
  }
}
