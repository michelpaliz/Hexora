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

  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final totalHours = _fmt(totals?['totalHours']);
    final totalPayStr = _fmt(totals?['totalPay']);
    final totalPayNum = _toNum(totals?['totalPay']);
    final currency = (totals?['currency'] ?? '').toString();

    // compute avg hours/day (compact, informative)
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

    // income color logic
    final Color incomeColor = totalPayNum > 0
        ? Colors.green.shade600
        : totalPayNum < 0
            ? Colors.red.shade600
            : cs.secondary; // neutral

    final Color incomeBg = totalPayNum > 0
        ? Colors.green.withOpacity(0.12)
        : totalPayNum < 0
            ? Colors.red.withOpacity(0.12)
            : cs.secondary.withOpacity(0.12);

    final Color incomeBorder = totalPayNum > 0
        ? Colors.green.withOpacity(0.18)
        : totalPayNum < 0
            ? Colors.red.withOpacity(0.18)
            : cs.secondary.withOpacity(0.18);

    final IconData incomeIcon = totalPayNum > 0
        ? Icons.trending_up
        : totalPayNum < 0
            ? Icons.trending_down
            : Icons.attach_money;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title (slightly larger)
          Text(
            l.totalHours,
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          // Big number (noticeably larger than before)
          Text(
            '$totalHours h',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // Pills row (entries • income colored • avg h/day)
          Row(
            children: [
              _pill(
                context,
                icon: Icons.list_alt,
                label: '${entries.length} ${l.entries}',
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              _pillCustom(
                context,
                icon: incomeIcon,
                label: '$totalPayStr $currency',
                fg: incomeColor,
                bg: incomeBg,
                border: incomeBorder,
              ),
              const SizedBox(width: 8),
              _pill(
                context,
                icon: Icons.timeline,
                label: '${avgHours.toStringAsFixed(2)} h/day',
                color: cs.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
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

  Widget _pillCustom(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
  }) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}
