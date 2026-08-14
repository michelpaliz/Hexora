import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class MonthTileContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final Map<String, dynamic>? totals;
  final bool isSelected;
  final bool isCurrentMonth;

  const MonthTileContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totals,
    required this.isSelected,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final metrics = MonthTotalMetrics.from(totals);
    final emphasisColor = isSelected
        ? cs.primary
        : metrics.hasActivity
            ? cs.tertiary
            : cs.onSurfaceVariant;
    final textColor =
        metrics.hasActivity || isSelected ? cs.onSurface : cs.onSurfaceVariant;

    return Semantics(
      label: '$title, $subtitle',
      button: true,
      selected: isSelected,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: emphasisColor.withValues(alpha: isSelected ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 17,
              color: emphasisColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  children: [
                    MonthMetricPill(
                      icon: Icons.schedule_rounded,
                      label: metrics.hoursLabel,
                      color: cs.primary,
                      muted: !metrics.hasHours,
                    ),
                    MonthMetricPill(
                      icon: Icons.payments_outlined,
                      label: metrics.payLabel,
                      color: cs.tertiary,
                      muted: !metrics.hasPay,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class MonthMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool muted;

  const MonthMetricPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = muted ? cs.onSurfaceVariant : color;

    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: muted ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: effectiveColor.withValues(alpha: muted ? 0.12 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: effectiveColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: effectiveColor,
                fontWeight: muted ? FontWeight.w600 : FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthTotalMetrics {
  final num hours;
  final num pay;
  final String currency;

  const MonthTotalMetrics({
    required this.hours,
    required this.pay,
    required this.currency,
  });

  factory MonthTotalMetrics.from(Map<String, dynamic>? totals) {
    return MonthTotalMetrics(
      hours: _toNum(totals?['totalHours']),
      pay: _toNum(totals?['totalPay']),
      currency: (totals?['currency'] ?? '').toString().trim(),
    );
  }

  bool get hasHours => hours > 0;

  bool get hasPay => pay != 0;

  bool get hasActivity => hasHours || hasPay;

  String get hoursLabel => '${_formatNumber(hours)}h';

  String get payLabel {
    final amount = _formatNumber(pay);
    return currency.isEmpty ? amount : '$amount $currency';
  }

  static num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  static String _formatNumber(num value) {
    final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    return fixed.replaceFirst(RegExp(r'\.0$'), '');
  }
}
