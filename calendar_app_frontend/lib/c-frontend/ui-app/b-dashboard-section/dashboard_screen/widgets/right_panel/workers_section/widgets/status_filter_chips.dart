import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
          selected: value == WorkerStatusFilter.active,
          onTap: () => onChanged(WorkerStatusFilter.active),
        ),
        _FilterChip(
          label: l.statusInactive,
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

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final bg = selected ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: t.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}
