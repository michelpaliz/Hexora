import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GroupDangerZoneCard extends StatelessWidget {
  final bool isOwner;
  final bool isLoading;
  final bool isRemoving;
  final VoidCallback onRemove;

  const GroupDangerZoneCard({
    super.key,
    required this.isOwner,
    required this.isLoading,
    required this.isRemoving,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  l.groupSettingsDangerZoneTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? l.groupSettingsDangerZoneOwner
                  : l.groupSettingsDangerZoneNonOwner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (isOwner)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: isRemoving ? null : onRemove,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isRemoving
                        ? SizedBox(
                            key: const ValueKey('removing'),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onError,
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('idle'),
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.delete_forever_rounded,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(l.remove),
                            ],
                          ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.permissionDeniedInf,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
