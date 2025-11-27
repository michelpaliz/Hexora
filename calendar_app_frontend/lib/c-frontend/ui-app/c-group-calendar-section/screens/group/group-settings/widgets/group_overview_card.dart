import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupOverviewCard extends StatelessWidget {
  final Group group;
  final String createdFormatted;

  const GroupOverviewCard({
    super.key,
    required this.group,
    required this.createdFormatted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final description =
        group.description.isEmpty ? l.groupSettingsNoDescription : group.description;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _GroupAvatar(group: group)),
            const SizedBox(height: 16),
            Text(
              l.groupSettingsOverviewTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.groupSettingsOverviewSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            _InfoTile(
              icon: Icons.description_outlined,
              title: l.groupSettingsDescriptionLabel,
              value: description,
              selectable: false,
            ),
            _InfoTile(
              icon: Icons.person_outline,
              title: l.groupSettingsOwnerIdLabel,
              value: group.ownerId,
              selectable: true,
            ),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              title: l.groupSettingsCreatedOnLabel,
              value: createdFormatted,
            ),
            _InfoTile(
              icon: Icons.groups_outlined,
              title: l.groupSettingsMemberCountLabel,
              value: '${group.userIds.length}',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final Group group;

  const _GroupAvatar({required this.group});

  @override
  Widget build(BuildContext context) {
    final url = group.photoUrl ?? group.computedPhotoUrl ?? '';
    if (url.isEmpty) {
      return const CircleAvatar(
        radius: 40,
        child: Icon(Icons.group, size: 32),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(
          radius: 40,
          child: Icon(Icons.group, size: 32),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool selectable;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value.isEmpty ? '—' : value;
    Widget valueWidget = Text(
      text,
      style: theme.textTheme.bodyMedium,
    );
    if (selectable) {
      valueWidget = SelectableText(
        text,
        style: theme.textTheme.bodyMedium,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                valueWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
