import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class OverviewLegendRow extends StatelessWidget {
  const OverviewLegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        OverviewLegendChip(
          icon: Icons.timer_outlined,
          label: l.hours,
          color: theme.colorScheme.primary,
        ),
        OverviewLegendChip(
          icon: Icons.attach_money,
          label: l.pay,
          color: theme.colorScheme.secondary,
        ),
        OverviewLegendChip(
          icon: Icons.task_alt,
          label: l.entries,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }
}

class OverviewLegendChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const OverviewLegendChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
