import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/mail/mail_console_screen.dart';

import '../controller/group_dashboard_state.dart';
import '../controller/group_dashboard_sections.dart';
class NarrowLayout extends StatelessWidget {
  final GroupDashboardState state;
  const NarrowLayout({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.activeSection == Sections.emails) {
      return GroupDashboardContent(
        panelBg: state.backdrop,
        child: const MailConsoleScreen(embedded: true),
      );
    }
    return GroupDashboardContent(
      panelBg: state.backdrop,
      child: state.dashboardBody,
    );
  }
}
