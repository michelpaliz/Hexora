import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class VatSummaryHeader extends StatelessWidget {
  final int year;
  final String rangeLabel;
  final String deadlineLabel;
  final bool exportingVatAudit;
  final VoidCallback? onExportVatAudit;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final TabController tabs;

  const VatSummaryHeader({
    super.key,
    required this.year,
    required this.rangeLabel,
    required this.deadlineLabel,
    required this.exportingVatAudit,
    required this.onExportVatAudit,
    required this.onPrevYear,
    required this.onNextYear,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedQuarter = tabs.index + 1;

    Widget quarterButton({
      required int quarter,
      required String label,
      required String tooltip,
    }) {
      final selected = selectedQuarter == quarter;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => tabs.animateTo(quarter - 1),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: selected ? cs.primary : Colors.transparent,
              border: Border.all(
                color: selected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.55),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }

    Widget navButton({
      required IconData icon,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(icon, size: 16, color: cs.onSurface),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bar = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message:
                      'Descarga un Excel con base, IVA y total por factura para revisión contable.',
                  child: FilledButton.tonalIcon(
                    onPressed: exportingVatAudit ? null : onExportVatAudit,
                    icon: exportingVatAudit
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 16),
                    label: Text(
                      exportingVatAudit
                          ? 'Generando Excel...'
                          : 'Exportar auditoría IVA',
                    ),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.event_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  rangeLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: deadlineLabel,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(Icons.schedule_outlined,
                        size: 14, color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                // Year display with nav buttons
                navButton(
                  icon: Icons.chevron_left,
                  onTap: onPrevYear,
                  tooltip: l.vatSummaryPrevYear,
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Year: $year',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.5),
                      ),
                      color: cs.primary.withValues(alpha: 0.07),
                    ),
                    child: Text(
                      year.toString(),
                      style: t.bodySmall.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                navButton(
                  icon: Icons.chevron_right,
                  onTap: onNextYear,
                  tooltip: l.vatSummaryNextYear,
                ),
                const SizedBox(width: 10),
                // Quarter selector
                quarterButton(
                  quarter: 1,
                  label: 'T1',
                  tooltip: l.vatSummaryQuarterQ1,
                ),
                const SizedBox(width: 5),
                quarterButton(
                  quarter: 2,
                  label: 'T2',
                  tooltip: l.vatSummaryQuarterQ2,
                ),
                const SizedBox(width: 5),
                quarterButton(
                  quarter: 3,
                  label: 'T3',
                  tooltip: l.vatSummaryQuarterQ3,
                ),
                const SizedBox(width: 5),
                quarterButton(
                  quarter: 4,
                  label: 'T4',
                  tooltip: l.vatSummaryQuarterQ4,
                ),
              ],
            ),
          );
          return Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: bar,
              ),
            ),
          );
        },
      ),
    );
  }
}
