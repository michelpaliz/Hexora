// lib/c-frontend/dialog_content/profile/profile_dialog_content.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/alert_dialog/widgets/quick_actions_grid.dart';
import 'package:hexora/l10n/app_localizations.dart';
class ProfileDialogContent extends StatelessWidget {
  const ProfileDialogContent({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    // Responsive max width: compact on phones, roomy on desktop/tablet
    final screenW = MediaQuery.of(context).size.width;
    final maxW = screenW >= 900 ? 720.0 : (screenW >= 600 ? 640.0 : 520.0);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QuickActionsGrid(group: group, isWide: isWide),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
