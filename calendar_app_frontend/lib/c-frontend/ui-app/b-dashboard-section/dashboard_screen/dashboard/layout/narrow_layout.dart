import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/right_panel/members_section/group_dashboard_right_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/enable_banking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/expenses/gastos_module_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/telegram/telegram_section_screen.dart';

import '../controller/group_dashboard_sections.dart';
import '../controller/group_dashboard_state.dart';

class NarrowLayout extends StatelessWidget {
  final GroupDashboardState state;
  const NarrowLayout({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (state.activeSection) {
      case Sections.invoices:
        child = GroupInvoicesScreen(
          group: state.group,
          embedded: true,
        );
        break;
      case Sections.expenses:
        child = GastosModuleScreen(
          group: state.group,
          embedded: true,
        );
        break;
      case Sections.enableBanking:
        child = EnableBankingScreen(
          group: state.group,
          embedded: true,
        );
        break;
      case Sections.emails:
        child = const MailConsoleScreen(embedded: true);
        break;
      case Sections.telegram:
        child = const TelegramSectionScreen();
        break;
      case Sections.chat:
      case Sections.notifications:
      case Sections.settings:
      case Sections.members:
      case Sections.services:
      case Sections.insights:
      case Sections.workers:
      case Sections.undone:
      case Sections.profile:
      case Sections.editGroup:
        child = GroupDashboardRightPanel(
          activeAnchor: state.activeSection,
          counts: state.counts,
          group: state.group,
          user: state.user,
          role: state.role,
          fetchReadSas: state.fetchReadSas,
          usersInGroup: const [],
          onOpenCalendar: () => state.openSection(Sections.calendar),
          onOpenNotifications: () => state.openSection(Sections.notifications),
          onOpenSettings: () => state.openSection(Sections.settings),
        );
        break;
      default:
        child = state.dashboardBody;
    }

    return GroupDashboardContent(
      panelBg: state.backdrop,
      child: child,
    );
  }
}
