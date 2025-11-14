// lib/c-frontend/dialog_content/profile/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'action_card.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ActionCard(
            icon: Icons.dashboard_customize_rounded,
            title: l.dashboard,
            subtitle: 'Manage your group',
            color: Theme.of(context).colorScheme.primary,
            isPrimary: true,
            onTap: () {
              final groupDomain =
                  Provider.of<GroupDomain>(context, listen: false);
              groupDomain.currentGroup = group;
              Navigator.pushNamed(
                context,
                AppRoutes.groupDashboard,
                arguments: group,
              );
            },
          ),
          const SizedBox(height: 12),
          // Row(
          //   children: [
          //     Expanded(
          //       child: ActionCard(
          //         icon: Icons.people_alt_rounded,
          //         title: l.viewMembers,
          //         subtitle: '', // unused when iconOnly = true
          //         color: Theme.of(context).colorScheme.secondary,
          //         isCompact: true,
          //         iconOnly: true, // NEW
          //         semanticLabel: l.viewMembers, // optional a11y
          //         onTap: () {
          //           Navigator.pushNamed(
          //             context,
          //             AppRoutes.groupMembers,
          //             arguments: group,
          //           );
          //         },
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Expanded(
          //       child: ActionCard(
          //         icon: Icons.calendar_month_rounded,
          //         title: 'Calendar',
          //         subtitle: '', // unused when iconOnly = true
          //         color: Theme.of(context).colorScheme.tertiary,
          //         isCompact: true,
          //         iconOnly: true, // NEW
          //         semanticLabel: 'Calendar',
          //         onTap: () {
          //           // Navigate to calendar
          //           Navigator.pop(context);
          //         },
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
