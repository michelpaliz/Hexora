import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_left_nav.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/group_dashboard_right_panel.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../controller/group_dashboard_state.dart';

class WideLayout extends StatefulWidget {
  final GroupDashboardState state;
  const WideLayout({super.key, required this.state});

  @override
  State<WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<WideLayout> {
  bool _navCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l = AppLocalizations.of(context)!;
    final leftSections = [
      (l.goToCalendar, Icons.calendar_month_rounded, 'calendar'),
      (l.notifications, Icons.notifications_none_rounded, 'notifications'),
      (l.groupSettingsTitle, Icons.settings, 'settings'),
      (l.servicesClientsTitle, Icons.design_services_outlined, 'services'),
      if (state.canSeeAdmin)
        (l.invoicesNavLabel, Icons.receipt_long_outlined, 'invoices'),
      if (state.canSeeAdmin)
        ('Enable Banking', Icons.account_balance_outlined, 'enableBanking'),
      (l.insightsTitle, Icons.insights_outlined, 'insights'),
      (l.timeTrackingTitle, Icons.access_time_rounded, 'workers'),
      (l.pendingEventsSectionTitle, Icons.pending_actions_outlined, 'undone'),
    ];
    final rightFlex = state.isUltraWide ? 3 : 2;
    final navWidth = _navCollapsed
        ? GroupDashboardLeftNav.collapsedWidth + 24
        : GroupDashboardLeftNav.expandedWidth + 24;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1800),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left navigation
              SizedBox(
                width: navWidth,
                child: GroupDashboardLeftNav(
                  group: state.group,
                  user: state.user,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  sections: leftSections,
                  selectedAnchor: state.activeSection,
                  onSectionTap: state.openSection,
                  collapsed: _navCollapsed,
                  onToggleCollapse: () =>
                      setState(() => _navCollapsed = !_navCollapsed),
                ),
              ),
              const SizedBox(width: 16),

              // Main body
              Expanded(
                flex: 2,
                child: GroupDashboardContent(
                  panelBg: state.backdrop,
                  child: state.dashboardBody,
                ),
              ),

              const SizedBox(width: 16),
              Expanded(
                flex: rightFlex,
                child: GroupDashboardRightPanel(
                  activeAnchor: state.activeSection,
                  counts: state.counts,
                  group: state.group,
                  user: state.user,
                  role: state.role,
                  fetchReadSas: state.fetchReadSas,
                  usersInGroup: const [],
                  onOpenCalendar: () => state.openSection('calendar'),
                  onOpenNotifications: () => state.openSection('notifications'),
                  onOpenSettings: () => state.openSection('settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
