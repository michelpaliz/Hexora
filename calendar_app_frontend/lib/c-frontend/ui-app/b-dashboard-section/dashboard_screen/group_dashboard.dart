import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/group_header_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/members/presentation/domain/models/members_count.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/upcoming_events/group_upcoming_events.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/group_time_tracking_screen_state.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/e-drawer-style-menu/contextual_fab/contextual_fab.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class GroupDashboard extends StatefulWidget {
  final Group group;
  const GroupDashboard({super.key, required this.group});

  @override
  State<GroupDashboard> createState() => _GroupDashboardState();
}

class _GroupDashboardState extends State<GroupDashboard> {
  late GroupDomain _gm;
  MembersCount? _counts;

  @override
  void initState() {
    super.initState();
    _gm = context.read<GroupDomain>();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final c = await _gm.groupRepository.getMembersCount(
      widget.group.id,
      mode: 'union',
    );
    if (!mounted) return;
    setState(() => _counts = c);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;

    // typography hierarchy
    final sectionTitleStyle = t.bodyLarge.copyWith(fontWeight: FontWeight.w800);
    final tileTitleStyle = t.accentText.copyWith(fontWeight: FontWeight.w600);
    final tileSubtitleStyle = t.bodySmall;

    // Fallbacks / server-first for members shown in the Manage tile
    final fallbackMembers = group.userIds.length;
    final showMembers = _counts?.accepted ?? fallbackMembers;

    final tileBg = ThemeColors.listTileBg(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.dashboardTitle, style: t.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: l.sectionOverview, style: sectionTitleStyle),

            // Header
            GroupHeaderView(group: group),

            const SizedBox(height: 20),
            _SectionHeader(title: l.sectionUpcoming, style: sectionTitleStyle),
            GroupUpcomingEventsCard(groupId: group.id),

            const SizedBox(height: 20),
            _SectionHeader(title: l.sectionManage, style: sectionTitleStyle),

            Card(
              color: tileBg,
              child: ListTile(
                leading: const Icon(Icons.group_outlined),
                title: Text(l.membersTitle, style: tileTitleStyle),
                subtitle: Text(
                  '${NumberFormat.decimalPattern(l.localeName).format(showMembers)} ${l.membersTitle.toLowerCase()}',
                  style: tileSubtitleStyle,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.groupMembers,
                    arguments: group,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: tileBg,
              child: ListTile(
                leading: const Icon(Icons.design_services_outlined),
                title: Text(l.servicesClientsTitle, style: tileTitleStyle),
                subtitle:
                    Text(l.servicesClientsSubtitle, style: tileSubtitleStyle),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.groupServicesClients,
                    arguments: group,
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            _SectionHeader(title: l.sectionInsights, style: sectionTitleStyle),
            Card(
              color: tileBg,
              child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: Text(l.insightsTitle, style: tileTitleStyle),
                subtitle: Text(l.insightsSubtitle, style: tileSubtitleStyle),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.groupInsights,
                    arguments: group,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            if (!group.hasCalendar) ...[
              _SectionHeader(title: l.sectionStatus, style: sectionTitleStyle),
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
            _SectionHeader(
              title: l.sectionWorkersHours,
              style: sectionTitleStyle,
            ),
            Card(
              color: tileBg,
              child: ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: Text(l.timeTrackingTitle, style: tileTitleStyle),
                subtitle:
                    Text(l.timeTrackingHeaderHint, style: tileSubtitleStyle),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GroupTimeTrackingScreen(group: group),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 96),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 56,
          child: FilledButton.icon(
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(l.goToCalendar, style: t.buttonText),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.groupCalendar,
                arguments: group,
              );
            },
          ),
        ),
      ),
      floatingActionButton: const ContextualFab(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? style;
  const _SectionHeader({required this.title, this.style});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style:
                (style ?? t.titleLarge).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}
