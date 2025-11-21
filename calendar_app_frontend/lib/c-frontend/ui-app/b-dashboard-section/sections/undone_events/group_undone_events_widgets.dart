import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/c-frontend/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UndoneEventsPlaceholder extends StatelessWidget {
  const UndoneEventsPlaceholder({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class PendingEventTile extends StatelessWidget {
  const PendingEventTile({
    super.key,
    required this.event,
    required this.viewModel,
    this.owner,
    this.onTap,
    this.onMarkDone,
    this.enableAction = true,
    this.isDone = false,
    this.accentColor,
  });

  final Event event;
  final GroupUndoneEventsViewModel viewModel;
  final EventOwnerInfo? owner;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;
  final bool enableAction;
  final bool isDone;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    final date = ml.formatMediumDate(event.startDate);
    final timeRange =
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.startDate))} – '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.endDate))}';
    final title = event.title.isEmpty ? loc.untitledEvent : event.title.trim();
    final isBusy = viewModel.isProcessing(event.id);
    final iconColor = accentColor ??
        (isDone ? theme.colorScheme.secondary : theme.colorScheme.primary);

    final List<Widget>? ownerLine = owner != null
        ? [
            Text(
              owner!.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (owner!.username != null)
              Text(
                owner!.username!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ]
        : null;

    return ListTile(
      leading: Icon(
        isDone ? Icons.check_circle_rounded : Icons.pending_actions_outlined,
        color: iconColor,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isDone
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$date · $timeRange',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ownerLine != null) ...[
            const SizedBox(height: 2),
            ...ownerLine,
          ],
        ],
      ),
      onTap: onTap,
      trailing: enableAction
          ? (isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: loc.pendingEventsMarkDone,
                  onPressed:
                      onMarkDone ?? () => viewModel.markEventAsDone(event.id),
                ))
          : Icon(Icons.task_alt_rounded, color: iconColor),
    );
  }
}
