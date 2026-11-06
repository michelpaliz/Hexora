import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';

class WorkerMonthNavigator extends StatefulWidget {
  const WorkerMonthNavigator({
    super.key,
    required this.selectedMonth,
    required this.onChanged,
    this.firstYear = 2020,
    this.maxYear,
    this.enabled = true,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;
  final int firstYear;
  final int? maxYear;
  final bool enabled;

  @override
  State<WorkerMonthNavigator> createState() => _WorkerMonthNavigatorState();
}

class _WorkerMonthNavigatorState extends State<WorkerMonthNavigator> {
  final MenuController _menuController = MenuController();
  late int _visibleYear;

  @override
  void initState() {
    super.initState();
    _visibleYear = widget.selectedMonth.year;
  }

  @override
  void didUpdateWidget(covariant WorkerMonthNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth.year != widget.selectedMonth.year) {
      _visibleYear = widget.selectedMonth.year;
    }
  }

  String _monthName(BuildContext context, int month) {
    final locale = Localizations.localeOf(context).toString();
    final value = DateFormat.MMM(locale).format(DateTime(2024, month));
    return value.isEmpty
        ? '$month'
        : '${value[0].toUpperCase()}${value.substring(1)}';
  }

  DateTime _normalized(DateTime value) => DateTime(value.year, value.month, 1);

  void _moveMonth(int offset) {
    final next = DateTime(
      widget.selectedMonth.year,
      widget.selectedMonth.month + offset,
      1,
    );
    final maxYear = widget.maxYear ?? DateTime.now().year + 10;
    if (next.year < widget.firstYear || next.year > maxYear) return;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = Localizations.localeOf(context).languageCode == 'es';
    final now = DateTime.now();
    final maxYear = widget.maxYear ?? now.year + 10;
    final canGoPrevious = _visibleYear > widget.firstYear;
    final canGoNext = _visibleYear < maxYear;
    final closedLabel =
        '${_monthName(context, widget.selectedMonth.month)} ${widget.selectedMonth.year}';

    final borderColor = cs.outlineVariant.withValues(alpha: 0.55);
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(cs.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
        ),
      ),
      menuChildren: [
        SizedBox(
          key: const ValueKey('worker-month-popover'),
          width: 264,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _MonthArrowButton(
                      tooltip: l ? 'Año anterior' : 'Previous year',
                      icon: Icons.chevron_left_rounded,
                      onPressed: canGoPrevious
                          ? () => setState(() => _visibleYear--)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        '$_visibleYear',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _MonthArrowButton(
                      tooltip: l ? 'Año siguiente' : 'Next year',
                      icon: Icons.chevron_right_rounded,
                      onPressed: canGoNext
                          ? () => setState(() => _visibleYear++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (row) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: row == 3 ? 0 : 6),
                      child: Row(
                        children: List.generate(3, (column) {
                          final month = row * 3 + column + 1;
                          final selected =
                              _visibleYear == widget.selectedMonth.year &&
                                  month == widget.selectedMonth.month;
                          final current =
                              _visibleYear == now.year && month == now.month;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: column == 2 ? 0 : 6,
                              ),
                              child: Semantics(
                                selected: selected,
                                button: true,
                                label:
                                    '${_monthName(context, month)} $_visibleYear',
                                child: TextButton(
                                  key: ValueKey('worker-month-$month'),
                                  onPressed: () {
                                    widget.onChanged(
                                      DateTime(_visibleYear, month, 1),
                                    );
                                    _menuController.close();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 34),
                                    maximumSize: const Size.fromHeight(34),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor:
                                        selected ? cs.onPrimary : cs.onSurface,
                                    backgroundColor: selected
                                        ? cs.primary
                                        : Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      side: BorderSide(
                                        color: selected
                                            ? cs.primary
                                            : current
                                                ? cs.primary.withValues(
                                                    alpha: 0.55,
                                                  )
                                                : cs.outlineVariant.withValues(
                                                    alpha: 0.28,
                                                  ),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _monthName(context, month),
                                    style: t.bodySmall.copyWith(
                                      fontSize: 11.5,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: selected ? cs.onPrimary : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      widget.onChanged(_normalized(now));
                      _menuController.close();
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l ? 'Mes actual' : 'Current month'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        final center = TextButton(
          key: const ValueKey('worker-month-open'),
          onPressed: widget.enabled
              ? () {
                  setState(() => _visibleYear = widget.selectedMonth.year);
                  controller.open();
                }
              : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(100, 30),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: cs.onSurface,
            shape: const RoundedRectangleBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                closedLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 3),
              Icon(Icons.expand_more_rounded,
                  size: 14, color: cs.onSurfaceVariant),
            ],
          ),
        );

        return Container(
          key: const ValueKey('worker-month-navigation'),
          height: 32,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MonthArrowButton(
                key: const ValueKey('worker-month-previous'),
                tooltip: l ? 'Mes anterior' : 'Previous month',
                icon: Icons.chevron_left_rounded,
                onPressed: widget.enabled ? () => _moveMonth(-1) : null,
              ),
              Container(width: 1, height: 18, color: borderColor),
              SizedBox(width: 130, child: center),
              Container(width: 1, height: 18, color: borderColor),
              _MonthArrowButton(
                key: const ValueKey('worker-month-next'),
                tooltip: l ? 'Mes siguiente' : 'Next month',
                icon: Icons.chevron_right_rounded,
                onPressed: widget.enabled ? () => _moveMonth(1) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthArrowButton extends StatelessWidget {
  const _MonthArrowButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 17),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(30, 30),
        maximumSize: const Size(30, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
