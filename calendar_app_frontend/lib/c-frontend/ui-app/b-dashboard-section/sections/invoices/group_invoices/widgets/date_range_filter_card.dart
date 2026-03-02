import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum DateQuickRange { none, month, quarter, custom }

class DateRangeFilterCard extends StatelessWidget {
  final DateQuickRange quickRange;
  final bool expanded;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool showLabel;
  final List<Widget>? labelActions;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClear;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final ValueChanged<DateQuickRange> onSelectQuickRange;

  const DateRangeFilterCard({
    super.key,
    required this.quickRange,
    required this.expanded,
    required this.fromDate,
    required this.toDate,
    this.showLabel = true,
    this.labelActions,
    required this.onToggleExpanded,
    required this.onClear,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSelectQuickRange,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasFilter = fromDate != null || toDate != null;
    final fromLabel = fromDate == null
        ? l.eventStartDateHint
        : DateFormat.yMMMd(l.localeName).format(fromDate!);
    final toLabel = toDate == null
        ? l.eventEndDateHint
        : DateFormat.yMMMd(l.localeName).format(toDate!);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_outlined, color: cs.primary),
              const SizedBox(width: 8),
              if (showLabel)
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l.date,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (labelActions != null && labelActions!.isNotEmpty)
                        ...labelActions!,
                    ],
                  ),
                )
              else
                const Spacer(),
              _QuickRangeSegmented(
                selected: quickRange,
                onSelected: onSelectQuickRange,
              ),
              if (hasFilter)
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    l.clearSelection,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              InkWell(
                onTap: onToggleExpanded,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 4),
            _ConnectedDateRange(
              fromLabel: fromLabel,
              toLabel: toLabel,
              onPickFrom: onPickFrom,
              onPickTo: onPickTo,
            ),
          ] else if (hasFilter) ...[
            const SizedBox(height: 4),
            Text(
              '$fromLabel — $toLabel',
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickRangeSegmented extends StatelessWidget {
  final DateQuickRange selected;
  final ValueChanged<DateQuickRange> onSelected;

  const _QuickRangeSegmented({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget segment(DateQuickRange value, String label, {Widget? trailing}) {
      final active = selected == value;
      return GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: active
                ? cs.primaryContainer
                : cs.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? cs.primaryContainer
                  : cs.outlineVariant.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing,
              ],
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        segment(DateQuickRange.month, l.dateRange30d),
        const SizedBox(width: 6),
        segment(DateQuickRange.quarter, l.dateRange3m),
        const SizedBox(width: 6),
        segment(
          DateQuickRange.custom,
          l.dateRangeCustom,
          trailing: Icon(
            Icons.expand_more,
            size: 12,
            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
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
