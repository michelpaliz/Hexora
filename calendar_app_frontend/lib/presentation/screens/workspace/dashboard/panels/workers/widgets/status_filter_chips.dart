import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

enum WorkerStatusFilter { all, active, inactive }

class StatusFilterChips extends StatelessWidget {
  final WorkerStatusFilter value;
  final ValueChanged<WorkerStatusFilter> onChanged;

  const StatusFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: l.all,
          selected: value == WorkerStatusFilter.all,
          onTap: () => onChanged(WorkerStatusFilter.all),
        ),
        _FilterChip(
          label: l.statusActive,
          dot: const Color(0xff08662f),
          selected: value == WorkerStatusFilter.active,
          onTap: () => onChanged(WorkerStatusFilter.active),
        ),
        _FilterChip(
          label: l.statusInactive,
          dot: const Color(0xff9298ae),
          selected: value == WorkerStatusFilter.inactive,
          onTap: () => onChanged(WorkerStatusFilter.inactive),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final bg = selected
        ? cs.primary
        : cs.surfaceContainerHighest.withValues(alpha: .5);
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (dot != null && !selected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: t.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
