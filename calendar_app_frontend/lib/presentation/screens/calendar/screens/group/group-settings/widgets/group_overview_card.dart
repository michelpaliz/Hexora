import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupOverviewCard extends StatelessWidget {
  final Group group;
  final String? ownerName;
  final String createdFormatted;
  final VoidCallback? onEdit;

  const GroupOverviewCard({
    super.key,
    required this.group,
    required this.createdFormatted,
    this.ownerName,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final description = group.description.isEmpty
        ? l.groupSettingsNoDescription
        : group.description;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _GroupAvatar(group: group),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(group.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 12),
            Text(description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('${l.groupSettingsOwnerLabel}: ${ownerName ?? '—'}',
                style: theme.textTheme.bodySmall),
            Text(l.createdOnDay(createdFormatted),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (onEdit != null)
              TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l.groupSettingsEditInformation)),
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
        radius: 24,
        child: Icon(Icons.group, size: 32),
      );
    }

    return ClipOval(
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(
          radius: 24,
          child: Icon(Icons.group, size: 32),
        ),
      ),
    );
  }
}
