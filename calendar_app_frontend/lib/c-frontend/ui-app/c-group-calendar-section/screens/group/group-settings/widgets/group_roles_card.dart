import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'group_section_header.dart';

class GroupRolesCard extends StatelessWidget {
  final Group group;

  const GroupRolesCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = group.userRoles.entries.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupSectionHeader(
              icon: Icons.badge_outlined,
              title: l.groupSettingsUserRolesTitle,
              subtitle: l.groupSettingsUserRolesSubtitle,
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.groupSettingsNoRoles,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Column(
                children: entries
                    .map(
                      (role) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person_outline, size: 18),
                        ),
                        title: SelectableText(
                          '${l.groupSettingsUserIdLabel} ${role.key}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${l.groupSettingsRoleLabel} ${role.value}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
