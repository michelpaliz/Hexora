import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class WorkerAppBarTitle extends StatelessWidget {
  const WorkerAppBarTitle({
    super.key,
    required this.group,
    required this.worker,
    required this.year,
    required this.month,
  });

  final Group group;
  final Worker worker;
  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(DateTime(year, month));
    final l = AppLocalizations.of(context)!;
    final isInactive = worker.status == WorkerStatus.archived;
    final statusLabel = isInactive ? l.statusInactive : l.statusActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          worker.displayName ?? 'Worker',
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          '${group.name} • $monthLabel',
          style: t.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        _StatusChip(label: statusLabel, inactive: isInactive),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool inactive;

  const _StatusChip({
    required this.label,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final bg = inactive
        ? cs.surfaceContainerHighest
        : Colors.green.withOpacity(0.12);
    final fg = inactive
        ? cs.onSurface.withOpacity(0.7)
        : Colors.green.shade700;
    final border =
        inactive ? cs.outlineVariant : Colors.green.withOpacity(0.3);

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
