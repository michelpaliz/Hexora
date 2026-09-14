import 'package:flutter/material.dart';
import 'package:hexora/models/group_model/event/model/event.dart';
import 'package:hexora/presentation/viewmodels/group_vm/view_model/group_view_model.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
    this.compact = false,
  });

  final Event event;
  final GroupUndoneEventsViewModel viewModel;
  final EventOwnerInfo? owner;
  final VoidCallback? onTap;
  final VoidCallback? onMarkDone;
  final bool enableAction;
  final bool isDone;
  final Color? accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ml = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    final date = ml.formatMediumDate(event.startDate);
    final timeRange =
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.startDate))} – '
        '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(event.endDate))}';
    final durationStr = event.allDay
        ? null
        : _formatDuration(
            event.endDate.difference(event.startDate),
            Localizations.localeOf(context).toLanguageTag(),
          );
    final timeLine =
        durationStr == null ? timeRange : '$timeRange • $durationStr';
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
            if (!compact && owner!.username != null)
              Text(
                owner!.username!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ]
        : null;

    if (MediaQuery.sizeOf(context).width < 700 && !compact) {
      final cs = theme.colorScheme;
      final es = loc.localeName.startsWith('es');
      final start = event.startDate.toLocal();
      final end = event.endDate.toLocal();
      final dateLabel = DateFormat.yMMMd(loc.localeName).format(start);
      final timeLabel = event.allDay
          ? (es ? 'Todo el día' : 'All day')
          : '${ml.formatTimeOfDay(TimeOfDay.fromDateTime(start))} – ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(end))}';
      final canComplete =
          !isDone && enableAction && viewModel.canManageEvent(event);
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: Text(title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700, height: 1.3))),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant),
            ]),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 4, children: [
              Text(dateLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              Text(timeLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ]),
            if (isDone && event.completedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                  '${es ? 'Completado' : 'Completed'}: ${DateFormat.yMMMd(loc.localeName).format(event.completedAt!.toLocal())}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Icon(
                  isDone
                      ? Icons.task_alt_rounded
                      : Icons.person_outline_rounded,
                  size: 18,
                  color: isDone ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(
                      owner?.displayName ?? (es ? 'Sin asignar' : 'Unassigned'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant))),
            ]),
            if (canComplete) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: isBusy || viewModel.hasPendingWrites
                    ? null
                    : onMarkDone ?? () => viewModel.markEventAsDone(event.id),
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.done_rounded, size: 18),
                label: Text(es ? 'Completar' : 'Complete'),
              ),
            ],
          ]),
        ),
      );
    }

    return ListTile(
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 2)
          : null,
      minLeadingWidth: compact ? 0 : null,
      leading: compact
          ? null
          : Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_outlined,
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
            compact ? '$date · $timeRange' : '$date · $timeLine',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ownerLine != null) ...[
            const SizedBox(height: 2),
            ...ownerLine,
          ],
        ],
      ),
      onTap: onTap,
      trailing: enableAction && !isDone && viewModel.canManageEvent(event)
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
          : Icon(isDone ? Icons.task_alt_rounded : Icons.chevron_right_rounded,
              color: iconColor),
    );
  }
}

String _formatDuration(Duration duration, String locale) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes <= 0) return '0m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  final nf = NumberFormat.decimalPattern(locale);
  if (hours > 0 && minutes > 0) {
    return '${nf.format(hours)}h ${nf.format(minutes)}m';
  }
  if (hours > 0) return '${nf.format(hours)}h';
  return '${nf.format(minutes)}m';
}
