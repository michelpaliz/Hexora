import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/widgets/group_dashboard_content.dart';

import '../controller/group_dashboard_state.dart';
class NarrowLayout extends StatelessWidget {
  final GroupDashboardState state;
  const NarrowLayout({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return GroupDashboardContent(
      panelBg: state.backdrop,
      child: state.dashboardBody,
    );
  }
}
