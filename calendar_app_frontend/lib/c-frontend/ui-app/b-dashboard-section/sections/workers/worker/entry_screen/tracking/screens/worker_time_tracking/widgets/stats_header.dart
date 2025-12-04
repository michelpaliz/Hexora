import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.entries,
    required this.totals,
    required this.worker,
  });

  final List<TimeEntry> entries;
  final Map<String, dynamic>? totals;
  final Worker worker;

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
    final currency =
        ((totals?['currency'] ?? worker.currency) ?? '').toString();
    final hourlyValue = totals?['hourlyRate'] ??
        totals?['defaultHourlyRate'] ??
        worker.defaultHourlyRate;
    final hourlyRate = hourlyValue == null ? null : _fmt(hourlyValue);

    final totalMinutes = entries.fold<int>(
      0,
      (sum, e) =>
          sum + (e.end != null ? e.end!.difference(e.start).inMinutes : 0),
    );
    final uniqueDays = entries
        .map((e) => DateTime(e.start.toLocal().year, e.start.toLocal().month,
            e.start.toLocal().day))
        .toSet();
    final daysWorked = uniqueDays.length;
    final avgHoursPerWorkedDay =
        daysWorked == 0 ? 0.0 : (totalMinutes / 60.0) / daysWorked;

    final sampleDate = entries.first.start.toLocal();
    final daysInMonth =
        DateUtils.getDaysInMonth(sampleDate.year, sampleDate.month);
    int sundaysInMonth = 0;
    int sundaysWorked = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final weekday = DateTime(sampleDate.year, sampleDate.month, d).weekday;
      if (weekday == DateTime.sunday) sundaysInMonth++;
    }
    sundaysWorked =
        uniqueDays.where((d) => d.weekday == DateTime.sunday).length;

    final daysMissedAll = (daysInMonth - daysWorked).clamp(0, daysInMonth);
    final nonSundayDays = daysInMonth - sundaysInMonth;
    final workedNonSunday = uniqueDays
        .where(
          (d) => d.weekday != DateTime.sunday,
        )
        .length;
    final daysMissedNoSunday =
        (nonSundayDays - workedNonSunday).clamp(0, nonSundayDays);

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
    final missedFg = cs.error;
    final missedBg = cs.errorContainer.withOpacity(0.25);
    final missedBorder = cs.error.withOpacity(0.4);
    final sundayFg = cs.secondary;
    final sundayBg = cs.secondaryContainer.withOpacity(0.28);
    final sundayBorder = cs.secondary.withOpacity(0.35);

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
              color: cs.onSurface.withOpacity(0.85),
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
          const SizedBox(height: 6),
          // Big number (noticeably larger than before)
          Text(
            '$totalHours h',
            style: t.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // Pills row (entries • income colored • avg h/day)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                context,
                icon: Icons.list_alt,
                label: '${entries.length} ${l.entries}',
                color: cs.primary,
              ),
              _pillCustom(
                context,
                icon: incomeIcon,
                label: '$totalPayStr $currency',
                fg: incomeColor,
                bg: incomeBg,
                border: incomeBorder,
              ),
              _pill(
                context,
                icon: Icons.hourglass_top_rounded,
                label: hourlyRate != null
                    ? '$hourlyRate $currency/h'
                    : l.hourlyRateLabel,
                color: cs.tertiary,
              ),
              _pillCustom(
                context,
                icon: Icons.event_busy_outlined,
                label: l.daysMissedAll(daysMissedAll),
                fg: missedFg,
                bg: missedBg,
                border: missedBorder,
              ),
              _pillCustom(
                context,
                icon: Icons.event_repeat_outlined,
                label: l.daysMissedNoSunday(daysMissedNoSunday),
                fg: missedFg,
                bg: missedBg,
                border: missedBorder,
              ),
              _pill(
                context,
                icon: Icons.calendar_today_outlined,
                label: l.daysWorked(daysWorked),
                color: cs.primary,
              ),
              _pill(
                context,
                icon: Icons.wb_sunny_outlined,
                label: l.sundaysWorked(sundaysWorked),
                color: cs.secondary,
              ),
              _pill(
                context,
                icon: Icons.speed_outlined,
                label: l.avgHoursPerDayWorkedWithCount(
                  avgHoursPerWorkedDay.toStringAsFixed(1),
                  daysWorked,
                ),
                color: cs.onSurface,
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
