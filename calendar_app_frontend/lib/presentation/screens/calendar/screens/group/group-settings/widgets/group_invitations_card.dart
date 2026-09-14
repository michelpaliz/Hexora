import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'group_section_header.dart';

class GroupInvitationsCard extends StatelessWidget {
  final VoidCallback? onViewInvitations;

  const GroupInvitationsCard({super.key, this.onViewInvitations});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupSectionHeader(
              icon: Icons.mail_outline,
              title: l.groupSettingsInvitationsTitle,
              subtitle: l.groupSettingsInvitationsSubtitle,
            ),
            const SizedBox(height: 8),
            Text(
              l.groupSettingsInvitationsInfo,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                icon: const Icon(Icons.mail_outline),
                label: Text(l.groupSettingsViewInvitations),
                onPressed: onViewInvitations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
