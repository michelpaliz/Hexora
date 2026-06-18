import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/enum/insights_types.dart';
import 'package:hexora/l10n/app_localizations.dart';

class InsightsFiltersSection extends StatelessWidget {
  final RangePreset preset;
  final ValueChanged<RangePreset> onPresetChanged;
  final VoidCallback onPickCustom;
  final String rangeText;

  const InsightsFiltersSection({
    super.key,
    required this.preset,
    required this.onPresetChanged,
    required this.onPickCustom,
    required this.rangeText,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1180;

    String labelForPreset(RangePreset p) {
      switch (p) {
        case RangePreset.d7:
          return l.dateRange7d;
        case RangePreset.d30:
          return l.dateRange30d;
        case RangePreset.m3:
          return l.dateRange3m;
        case RangePreset.m4:
          return l.dateRange4m;
        case RangePreset.m6:
          return l.dateRange6m;
        case RangePreset.y1:
          return l.dateRange1y;
        case RangePreset.ytd:
          return l.dateRangeYTD;
        case RangePreset.custom:
          return l.dateRangeCustom;
      }
    }

    final periodLabel = l.localeName.startsWith('es') ? 'Periodo' : 'Period';
    final quickPresets = <RangePreset>[
      RangePreset.d7,
      RangePreset.d30,
      RangePreset.m3,
      RangePreset.m6,
    ];
    final segments = <ButtonSegment<RangePreset>>[
      for (final value in [
        RangePreset.d7,
        RangePreset.d30,
        RangePreset.m3,
        RangePreset.m6,
        RangePreset.y1,
        RangePreset.custom,
      ])
        ButtonSegment(value: value, label: Text(labelForPreset(value))),
    ];

    Widget datePicker({required bool compact}) {
      return InkWell(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        onTap: onPickCustom,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(
              alpha: compact ? 0.5 : 0.32,
            ),
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .55)),
            boxShadow: compact
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 26 : 30,
                height: compact ? 26 : 30,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(compact ? 8 : 9),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: compact ? 15 : 17,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rangeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact ? tt.bodySmall : tt.bodyMedium)?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                compact
                    ? Icons.chevron_right_rounded
                    : Icons.expand_more_rounded,
                size: compact ? 18 : 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    Widget mobilePresetChip(RangePreset value) {
      final selected = preset == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onPresetChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? cs.primary.withValues(alpha: 0.55)
                    : cs.outlineVariant.withValues(alpha: 0.42),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: cs.onPrimary,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  labelForPreset(value),
                  style: tt.bodySmall?.copyWith(
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget customChip() {
      final selected = preset == RangePreset.custom;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPickCustom,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary
                : cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.55)
                  : cs.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 15,
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                l.dateRangeCustom,
                style: tt.bodySmall?.copyWith(
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        periodLabel,
                        style:
                            tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<RangePreset>(
                            segments: segments,
                            selected: <RangePreset>{preset},
                            onSelectionChanged: (selection) {
                              final selected = selection.first;
                              if (selected == RangePreset.custom) {
                                onPickCustom();
                                return;
                              }
                              onPresetChanged(selected);
                            },
                            showSelectedIcon: true,
                            multiSelectionEnabled: false,
                            style: ButtonStyle(
                              visualDensity: const VisualDensity(
                                horizontal: -4,
                                vertical: -4,
                              ),
                              padding: const WidgetStatePropertyAll(
                                EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              ),
                              textStyle: WidgetStatePropertyAll(
                                tt.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  datePicker(compact: false),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodLabel,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final value in quickPresets)
                          mobilePresetChip(value),
                        customChip(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  datePicker(compact: true),
                ],
              ),
      ),
    );
  }
}
