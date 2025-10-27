import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.entries,
    required this.totals,
  });

  final List<TimeEntry> entries;
  final Map<String, dynamic>? totals;

  String _fmt(dynamic v) {
    if (v == null) return '0.00';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    final totalHours = _fmt(totals?['totalHours']);
    final totalPay = _fmt(totals?['totalPay']);
    final currency = (totals?['currency'] ?? '').toString();

    final minutes = entries.fold<int>(
      0,
      (sum, e) =>
          sum + (e.end != null ? e.end!.difference(e.start).inMinutes : 0),
    );
    final activeDays = entries
        .map((e) => DateTime(e.start.year, e.start.month, e.start.day))
        .toSet()
        .length;
    final avgHours = activeDays == 0 ? 0.0 : (minutes / 60.0) / activeDays;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            l.totalHours,
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          // Big number
          Text(
            '$totalHours h',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          // Pills
          Row(
            children: [
              _pill(
                context,
                icon: Icons.list_alt,
                label: '${entries.length} ${l.entries}',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _pill(
                context,
                icon: Icons.attach_money,
                label: '$totalPay $currency',
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              _pill(
                context,
                icon: Icons.timeline,
                label: '${avgHours.toStringAsFixed(2)} h/day',
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
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
