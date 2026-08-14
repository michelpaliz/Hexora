import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/widgets/month_tile_content.dart';
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
  static const double _itemHeight = 78.0;

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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        final bgColor = isSelected
            ? cs.primary.withValues(alpha: 0.09)
            : isCurrentMonth
                ? cs.primary.withValues(alpha: 0.05)
                : metrics.hasActivity
                    ? cs.surface
                    : cs.surfaceContainerHighest.withValues(alpha: 0.30);
        final borderColor = isSelected
            ? cs.primary.withValues(alpha: 0.35)
            : isCurrentMonth
                ? cs.primary.withValues(alpha: 0.22)
                : cs.outlineVariant.withValues(
                    alpha: metrics.hasActivity ? 0.42 : 0.26,
                  );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onTapMonth(month),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: MonthTileContent(
                  title: title,
                  subtitle: subtitle,
                  totals: totals,
                  isSelected: isSelected,
                  isCurrentMonth: isCurrentMonth,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
