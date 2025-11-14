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

    Widget chip(RangePreset p) => ChoiceChip(
          label: Text(labelForPreset(p)),
          selected: preset == p,
          onSelected: (_) => onPresetChanged(p),
          // tighter, compact chips
          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );

    final periodLabel = (l.localeName.startsWith('es')) ? 'Periodo' : 'Period';

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(periodLabel,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            // ---- SCROLLABLE PRESET ROW (1 line, no wrap) ----
            SizedBox(
              height: 38, // keeps chips to one tidy line
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chip(RangePreset.d7),
                    const SizedBox(width: 8),
                    chip(RangePreset.d30),
                    const SizedBox(width: 8),
                    chip(RangePreset.m3),
                    const SizedBox(width: 8),
                    chip(RangePreset.m6),
                    const SizedBox(width: 8),
                    chip(RangePreset.y1),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: Text(l.dateRangeCustom),
                      onPressed: onPickCustom,
                      visualDensity:
                          const VisualDensity(horizontal: -3, vertical: -3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ---- EMPHASIZED DATE RANGE PILL ----
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPickCustom,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  // subtle fill + hairline border for emphasis
                  color: cs.surfaceVariant.withOpacity(.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rangeText,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
