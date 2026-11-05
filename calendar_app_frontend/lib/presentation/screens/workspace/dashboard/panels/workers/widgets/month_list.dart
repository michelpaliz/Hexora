import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/monthly_overview/widgets/month_tile_content.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

import 'text_extensions.dart';

class MonthList extends StatefulWidget {
  final int year;
  final String locale;
  final int selectedMonth;
  final Map<int, Map<String, dynamic>> monthlyTotals;
  final void Function(int month) onTapMonth;
  final String Function(Map<String, dynamic>? totals) subtitleBuilder;

  const MonthList({
    super.key,
    required this.year,
    required this.locale,
    required this.selectedMonth,
    required this.monthlyTotals,
    required this.onTapMonth,
    required this.subtitleBuilder,
  });

  @override
  State<MonthList> createState() => _MonthListState();
}

class _MonthListState extends State<MonthList> {
  final ScrollController _scrollCtrl = ScrollController();
  // Compact rows: ~44px item + 1px separator.
  static const double _itemHeight = 45.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant MonthList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.year != widget.year) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!_scrollCtrl.hasClients) return;
    final targetOffset = ((widget.selectedMonth - 1) * _itemHeight)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 2),
      itemCount: 12,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        indent: 14,
        endIndent: 6,
        color: cs.outlineVariant.withValues(alpha: 0.16),
      ),
      itemBuilder: (context, index) {
        final month = index + 1;
        final isCurrentMonth = now.year == widget.year && now.month == month;
        final isSelected = widget.selectedMonth == month;
        final title = DateFormat.MMMM(widget.locale)
            .format(DateTime(widget.year, month, 1))
            .capitalize();
        final totals = widget.monthlyTotals[month];
        final metrics = MonthTotalMetrics.from(totals);
        final subtitle = widget.subtitleBuilder(totals);

        return _MonthRow(
          title: title,
          semanticsLabel: '$title, $subtitle',
          metrics: metrics,
          isSelected: isSelected,
          isCurrentMonth: isCurrentMonth,
          onTap: () => widget.onTapMonth(month),
        );
      },
    );
  }
}

/// Compact single-line month row: calendar · name · hours · amount · chevron.
class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.title,
    required this.semanticsLabel,
    required this.metrics,
    required this.isSelected,
    required this.isCurrentMonth,
    required this.onTap,
  });

  final String title;
  final String semanticsLabel;
  final MonthTotalMetrics metrics;
  final bool isSelected;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final bgColor = isSelected
        ? cs.primary.withValues(alpha: 0.10)
        : isCurrentMonth
            ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent;

    final nameColor = isSelected
        ? cs.primary
        : metrics.hasActivity
            ? cs.onSurface
            : cs.onSurfaceVariant;
    final mutedValue = cs.onSurfaceVariant.withValues(alpha: 0.75);

    const tabular = [FontFeature.tabularFigures()];

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isSelected,
      child: SizedBox(
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Thin left indicator; present only for the selected month.
                  Container(
                    width: 3,
                    color: isSelected ? cs.primary : Colors.transparent,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(9, 0, 12, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodyMedium.copyWith(
                                color: nameColor,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 54,
                            child: Text(
                              metrics.hoursLabel,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color: metrics.hasHours
                                    ? cs.onSurface
                                    : mutedValue,
                                fontWeight: FontWeight.w700,
                                fontFeatures: tabular,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 96,
                            child: Text(
                              metrics.payLabel,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall.copyWith(
                                color:
                                    metrics.hasPay ? cs.onSurface : mutedValue,
                                fontWeight: FontWeight.w700,
                                fontFeatures: tabular,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.55),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
