import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class StatsHeader extends StatefulWidget {
  const StatsHeader({
    super.key,
    required this.entries,
    required this.totals,
    required this.worker,
    this.totalsLoading = false,
    this.totalsError,
  });

  final List<TimeEntry> entries;
  final Map<String, dynamic>? totals;
  final Worker worker;
  final bool totalsLoading;
  final String? totalsError;

  @override
  State<StatsHeader> createState() => _StatsHeaderState();
}

class _StatsHeaderState extends State<StatsHeader> {
  final ScrollController _chipsScrollController = ScrollController();
  Timer? _autoSlideTimer;
  bool _slideForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
  }

  @override
  void didUpdateWidget(covariant StatsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _chipsScrollController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) async {
      if (!mounted || !_chipsScrollController.hasClients) return;
      final pos = _chipsScrollController.position;
      if (pos.maxScrollExtent <= 0) return;

      const step = 140.0;
      final current = pos.pixels;
      double target = _slideForward ? current + step : current - step;

      if (target >= pos.maxScrollExtent) {
        target = pos.maxScrollExtent;
        _slideForward = false;
      } else if (target <= 0) {
        target = 0;
        _slideForward = true;
      }

      await _chipsScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 760),
        curve: Curves.easeInOut,
      );
    });
  }

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

  bool _isEs(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  String _advanceLabel(BuildContext context) =>
      _isEs(context) ? 'Anticipo' : 'Advance';

  String _grossLabel(BuildContext context) =>
      _isEs(context) ? 'Bruto' : 'Gross pay';

  String _netLabel(BuildContext context) => _isEs(context) ? 'Neto' : 'Net pay';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final totalHours = _fmt(widget.totals?['totalHours']);
    final currency = ((widget.totals?['currency'] ?? widget.worker.currency) ?? '')
        .toString();

    final totalPayNum = _toNum(widget.totals?['totalPay']);
    final grossPayNum =
        _toNum(widget.totals?['grossPay'] ?? widget.totals?['totalPay']);
    final advanceNum = _toNum(widget.totals?['advanceAmount']);
    final netPayNum =
        _toNum(widget.totals?['netPay'] ?? (grossPayNum - advanceNum));
    final safeNetPayNum = netPayNum < 0 ? 0 : netPayNum;

    final grossPayStr = grossPayNum.toStringAsFixed(2);
    final advanceStr = advanceNum.toStringAsFixed(2);
    final netPayStr = safeNetPayNum.toStringAsFixed(2);

    final hourlyValue = widget.totals?['hourlyRate'] ??
        widget.totals?['defaultHourlyRate'] ??
        widget.worker.defaultHourlyRate;
    final hourlyRate = hourlyValue == null ? null : _fmt(hourlyValue);

    final totalMinutes = widget.entries.fold<int>(
      0,
      (sum, e) =>
          sum + (e.end != null ? e.end!.difference(e.start).inMinutes : 0),
    );
    final uniqueDays = widget.entries
        .map((e) => DateTime(
            e.start.toLocal().year, e.start.toLocal().month, e.start.toLocal().day))
        .toSet();
    final daysWorked = uniqueDays.length;
    final avgHoursPerWorkedDay =
        daysWorked == 0 ? 0.0 : (totalMinutes / 60.0) / daysWorked;

    final sampleDate = widget.entries.first.start.toLocal();
    final daysInMonth = DateUtils.getDaysInMonth(sampleDate.year, sampleDate.month);
    var sundaysInMonth = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final weekday = DateTime(sampleDate.year, sampleDate.month, d).weekday;
      if (weekday == DateTime.sunday) sundaysInMonth++;
    }
    final sundaysWorked =
        uniqueDays.where((d) => d.weekday == DateTime.sunday).length;

    final nonSundayDays = daysInMonth - sundaysInMonth;
    final workedNonSunday =
        uniqueDays.where((d) => d.weekday != DateTime.sunday).length;
    final daysMissedNoSunday =
        (nonSundayDays - workedNonSunday).clamp(0, nonSundayDays);

    final Color incomeColor = totalPayNum > 0
        ? Colors.green.shade600
        : totalPayNum < 0
            ? Colors.red.shade600
            : cs.secondary;

    final allPills = <Widget>[
      _pill(
        context,
        icon: Icons.schedule_rounded,
        label: '${l.totalHours} $totalHours h',
        color: cs.onSurface,
      ),
      _pill(
        context,
        icon: Icons.list_alt,
        label: '${widget.entries.length} ${l.entries}',
        color: cs.primary,
      ),
      _pill(
        context,
        icon: Icons.payments_outlined,
        label: '${_grossLabel(context)}: $grossPayStr $currency',
        color: cs.primary,
      ),
      _pillCustom(
        context,
        icon: Icons.remove_circle_outline_rounded,
        label: '${_advanceLabel(context)}: -$advanceStr $currency',
        fg: cs.error,
        bg: cs.errorContainer.withValues(alpha: 0.25),
        border: cs.error.withValues(alpha: 0.4),
      ),
      _pill(
        context,
        icon: Icons.account_balance_wallet_outlined,
        label: '${_netLabel(context)}: $netPayStr $currency',
        color: incomeColor,
      ),
      if (hourlyRate != null)
        _pill(
          context,
          icon: Icons.hourglass_top_rounded,
          label: '$hourlyRate $currency/h',
          color: cs.tertiary,
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
      _pillCustom(
        context,
        icon: Icons.event_repeat_outlined,
        label: l.daysMissedNoSunday(daysMissedNoSunday),
        fg: cs.error,
        bg: cs.errorContainer.withValues(alpha: 0.25),
        border: cs.error.withValues(alpha: 0.4),
      ),
      _pill(
        context,
        icon: Icons.wb_sunny_outlined,
        label: l.sundaysWorked(sundaysWorked),
        color: cs.secondary,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _chipsScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allPills
                    .expand((w) => [w, const SizedBox(width: 6)])
                    .toList(),
              ),
            ),
          ),
          if (widget.totalsLoading)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
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
  }) =>
      _pillCustom(
        context,
        icon: icon,
        label: label,
        fg: color,
        bg: color.withValues(alpha: 0.12),
        border: color.withValues(alpha: 0.18),
      );

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
