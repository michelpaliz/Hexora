import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:provider/provider.dart';

import 'state/group_dashboard_state.dart';
import 'layout/narrow_layout.dart';
import 'layout/wide_layout.dart';
import 'navigation/dashboard_mobile_nav.dart';

class GroupDashboard extends StatelessWidget {
  const GroupDashboard({super.key, required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GroupDashboardState(context, group),
      builder: (context, _) {
        final state = context.watch<GroupDashboardState>();

        return Scaffold(
          backgroundColor: state.backdrop,
          appBar: state.buildAppBar(),
          body: LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= state.wideBreakpoint;
              return isWide
                  ? WideLayout(state: state)
                  : NarrowLayout(state: state);
            },
          ),
          bottomNavigationBar:
              state.showBottomBar ? DashboardMobileNav(state: state) : null,
        );
      },
    );
  }
}
