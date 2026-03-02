import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerListSection extends StatelessWidget {
  const WorkerListSection({
    super.key,
    required this.workers,
    required this.onEdit,
    required this.onAddHours,
    this.onOpenOverview,
    this.onOpenOverviewIcon,
    this.onSelect,
    this.selectedWorkerId,
    this.tapSelects = false,
  });

  final List<Worker> workers;
  final void Function(Worker worker) onEdit;
  final void Function(Worker worker) onAddHours;
  final void Function(Worker worker)? onOpenOverview;
  final void Function(Worker worker)? onOpenOverviewIcon;
  final void Function(Worker worker)? onSelect;
  final String? selectedWorkerId;
  final bool tapSelects;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: workers.map((w) {
        final isLinked = (w.userId != null && w.userId!.isNotEmpty);
        final initials = (w.displayName ?? w.userId ?? '?').trim().isNotEmpty
            ? (w.displayName ?? w.userId ?? '?').trim()[0].toUpperCase()
            : '?';
        final role = w.roleTag ?? '';
        final typeLabel = isLinked ? l.linkedUser : l.externalWorker;
        final metaLine = role.isNotEmpty ? '$typeLabel · $role' : typeLabel;
        final isInactive = w.status == WorkerStatus.archived;
        final statusLabel = isInactive ? l.statusInactive : l.statusActive;
        final isSelected = selectedWorkerId != null && selectedWorkerId == w.id;
        final bg = isSelected
            ? cs.primaryContainer.withOpacity(0.6)
            : cs.surfaceContainerHighest.withOpacity(0.35);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              hoverColor: cs.primary.withOpacity(0.05),
              onTap: () {
                if (tapSelects && onSelect != null) {
                  onSelect!(w);
                  return;
                }
                onAddHours(w);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: cs.primary.withOpacity(0.12),
                          child: Text(
                            initials,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.displayName ?? w.userId ?? l.unknownWorker,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metaLine,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurface.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _StatusChip(
                          label: statusLabel,
                          tone: isInactive
                              ? _StatusTone.inactive
                              : _StatusTone.active,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionIcon(
                          tooltip: l.overviewInfoTitle,
                          icon: Icons.calendar_view_month_outlined,
                          onTap: () =>
                              (onOpenOverviewIcon ?? onOpenOverview)?.call(w),
                        ),
                        const SizedBox(width: 6),
                        _ActionIcon(
                          tooltip: l.addTimeEntryCta,
                          icon: Icons.schedule_outlined,
                          onTap: () => onAddHours(w),
                        ),
                        const SizedBox(width: 6),
                        _ActionIcon(
                          tooltip: l.editWorker,
                          icon: Icons.edit_outlined,
                          onTap: () => onEdit(w),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum _StatusTone { active, inactive }

class _StatusChip extends StatelessWidget {
  final String label;
  final _StatusTone tone;

  const _StatusChip({
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isActive = tone == _StatusTone.active;
    final bg =
        isActive ? Colors.green.withOpacity(0.12) : cs.surfaceContainerHighest;
    final fg = isActive ? Colors.green.shade700 : cs.onSurface.withOpacity(0.7);
    final border = isActive ? Colors.green.withOpacity(0.3) : cs.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: t.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: cs.onSurface.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}
