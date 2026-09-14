import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupOwnerBanner extends StatelessWidget {
  final bool isOwner;

  const GroupOwnerBanner({super.key, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final color = theme.colorScheme.primaryContainer;
    final onColor = theme.colorScheme.onPrimaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isOwner ? Icons.verified_user : Icons.info_outline,
            size: 20,
            color: onColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOwner
                  ? l.groupSettingsOwnerBannerOwner
                  : l.groupSettingsOwnerBannerNotOwner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
