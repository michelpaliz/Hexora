import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum DateQuickRange { none, month, quarter, custom }

class DateRangeFilterCard extends StatelessWidget {
  const DateRangeFilterCard(
      {super.key,
      required this.quickRange,
      required this.expanded,
      required this.fromDate,
      required this.toDate,
      this.showLabel = true,
      this.showCollapsedRange = true,
      this.trailingActions,
      this.quickRangeControls,
      this.showClearAction = true,
      required this.onToggleExpanded,
      required this.onClear,
      required this.onPickFrom,
      required this.onPickTo,
      required this.onSelectQuickRange});
  final DateQuickRange quickRange;
  final bool expanded, showLabel, showCollapsedRange, showClearAction;
  final DateTime? fromDate, toDate;
  final List<Widget>? trailingActions;
  final Widget? quickRangeControls;
  final VoidCallback onToggleExpanded, onClear, onPickFrom, onPickTo;
  final ValueChanged<DateQuickRange> onSelectQuickRange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final hasFilter = fromDate != null || toDate != null;
    final fromLabel = fromDate == null
        ? l.eventStartDateHint
        : DateFormat.yMMMd(l.localeName).format(fromDate!);
    final toLabel = toDate == null
        ? l.eventEndDateHint
        : DateFormat.yMMMd(l.localeName).format(toDate!);
    final touch = MediaQuery.sizeOf(context).width < 650 ||
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    final height = touch ? 48.0 : 28.0;
    final filters = Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showLabel)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.date_range_outlined,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(l.date, style: t.bodySmall)
            ]),
          quickRangeControls ??
              _QuickRangeSegmented(
                  selected: quickRange,
                  expanded: expanded,
                  height: height,
                  onSelected: (value) {
                    if (value == DateQuickRange.custom &&
                        quickRange == DateQuickRange.custom) {
                      onToggleExpanded();
                    } else {
                      onSelectQuickRange(value);
                    }
                  }),
          if (hasFilter && showClearAction)
            TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                    minimumSize: Size(0, height),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: Text(l.clearSelection, style: t.bodySmall)),
        ]);
    final actions =
        Wrap(spacing: 4, runSpacing: 4, children: trailingActions ?? const []);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        final stacked = constraints.maxWidth < 640 ||
            MediaQuery.textScalerOf(context).scale(13) > 18;
        return ConstrainedBox(
            constraints: BoxConstraints(minHeight: touch ? 48 : 32),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        filters,
                        if (trailingActions?.isNotEmpty ?? false)
                          Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: actions)
                      ])
                : Row(children: [
                    Expanded(child: filters),
                    if (trailingActions?.isNotEmpty ?? false) ...[
                      const SizedBox(width: 16),
                      actions
                    ]
                  ]));
      }),
      if (expanded) ...[
        const SizedBox(height: 8),
        _ConnectedDateRange(
            fromLabel: fromLabel,
            toLabel: toLabel,
            onPickFrom: onPickFrom,
            onPickTo: onPickTo)
      ] else if (hasFilter && showCollapsedRange) ...[
        const SizedBox(height: 4),
        Text('$fromLabel — $toLabel',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant))
      ],
    ]);
  }
}

class _QuickRangeSegmented extends StatelessWidget {
  const _QuickRangeSegmented(
      {required this.selected,
      required this.expanded,
      required this.height,
      required this.onSelected});
  final DateQuickRange selected;
  final bool expanded;
  final double height;
  final ValueChanged<DateQuickRange> onSelected;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Material(
        color: cs.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(6),
        child: Wrap(spacing: 0, runSpacing: 0, children: [
          for (final item in [
            (DateQuickRange.month, l.dateRange30d),
            (DateQuickRange.quarter, l.dateRange3m),
            (DateQuickRange.custom, l.dateRangeCustom)
          ])
            Semantics(
                selected: selected == item.$1,
                expanded: item.$1 == DateQuickRange.custom ? expanded : null,
                child: TextButton(
                  key: ValueKey('date-range-${item.$1.name}'),
                  onPressed: () => onSelected(item.$1),
                  style: TextButton.styleFrom(
                      minimumSize: Size(0, height),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: selected == item.$1
                          ? cs.primary
                          : cs.onSurfaceVariant,
                      backgroundColor: selected == item.$1
                          ? cs.primary.withValues(alpha: .08)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      textStyle: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(item.$2),
                    if (item.$1 == DateQuickRange.custom) ...[
                      const SizedBox(width: 4),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more,
                          size: 14)
                    ]
                  ]),
                )),
        ]));
  }
}

class _ConnectedDateRange extends StatelessWidget {
  final String fromLabel;
  final String toLabel;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  const _ConnectedDateRange({
    required this.fromLabel,
    required this.toLabel,
    required this.onPickFrom,
    required this.onPickTo,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPickFrom,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  fromLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: cs.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(
            child: InkWell(
              onTap: onPickTo,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  toLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
