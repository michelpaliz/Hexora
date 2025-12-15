import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/undone_events/group_undone_events/group_undone_events_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/screens/role_info_screen.dart';

import 'group_dashboard_sections.dart';
import 'group_dashboard_state.dart';

class DashboardActions {
  static void openSection(GroupDashboardState state, String section) {
    final context = state.context;

    if (state.isWide) {
      state.activeSection = section;
      state.notifyListeners();
      return;
    }

    switch (section) {
      case Sections.calendar:
        Navigator.pushNamed(
          context,
          AppRoutes.groupCalendar,
          arguments: state.group,
        );
        break;

      case Sections.notifications:
        Navigator.pushNamed(
          context,
          AppRoutes.groupNotifications,
          arguments: state.group,
        );
        break;

      case Sections.settings:
        Navigator.pushNamed(
          context,
          AppRoutes.groupSettings,
          arguments: state.group,
        );
        break;
      case Sections.members:
        Navigator.pushNamed(
          context,
          AppRoutes.groupMembers,
          arguments: state.group,
        );
        break;
      case Sections.services:
        Navigator.pushNamed(
          context,
          AppRoutes.groupServicesClients,
          arguments: state.group,
        );
        break;
      case Sections.invoices:
        if (!state.canSeeAdmin) return;
        Navigator.pushNamed(
          context,
          AppRoutes.groupInvoices,
          arguments: state.group,
        );
        break;
      case Sections.insights:
        Navigator.pushNamed(
          context,
          AppRoutes.groupInsights,
          arguments: state.group,
        );
        break;
      case Sections.workers:
        Navigator.pushNamed(
          context,
          AppRoutes.groupTimeTracking,
          arguments: state.group,
        );
        break;
      case Sections.profile:
        if (state.user != null && state.role != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoleInfoScreen(
                group: state.group,
                user: state.user!,
                role: state.role!,
                fetchReadSas: state.fetchReadSas,
              ),
            ),
          );
        }
        break;
      case Sections.undone:
        if (state.user != null && state.role != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupUndoneEventsScreen(
                group: state.group,
                user: state.user!,
                role: state.role!,
              ),
            ),
          );
        }
        break;
      case Sections.editGroup:
        Navigator.pushNamed(
          context,
          AppRoutes.editGroup,
          arguments: state.group,
        );
        break;

      default:
        break;
    }
  }
}
