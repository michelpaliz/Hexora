// lib/c-frontend/dialog_content/profile/profile_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'widgets/group_hero_card.dart';
import 'widgets/quick_actions_grid.dart';

class ProfileDialogContent extends StatelessWidget {
  const ProfileDialogContent({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GroupHeroCard(group: group),
          const SizedBox(height: 16),
          QuickActionsGrid(group: group),
        ],
      ),
    );
  }
}
