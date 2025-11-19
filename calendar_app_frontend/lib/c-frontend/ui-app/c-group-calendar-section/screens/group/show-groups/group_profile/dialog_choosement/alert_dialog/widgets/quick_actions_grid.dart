// lib/c-frontend/dialog_content/profile/widgets/quick_actions_grid.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/alert_dialog/widgets/group_hero_card.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.group, this.isWide = false});
  final Group group;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 16),
      child: Column(
        children: [
          // HEADER CARD AS THE DASHBOARD ENTRY (now supports wide size)
          GroupHeroCard(
            group: group,
            isPrimary: true,
            size: isWide ? GroupHeroSize.wide : GroupHeroSize.compact,
            onTap: () {
              final groupDomain =
                  Provider.of<GroupDomain>(context, listen: false);
              groupDomain.currentGroup = group;
              Navigator.pushNamed(context, AppRoutes.groupDashboard,
                  arguments: group);
            },
          ),
          SizedBox(height: isWide ? 16 : 12),

          // Add more quick tiles below if needed...
        ],
      ),
    );
  }
}
