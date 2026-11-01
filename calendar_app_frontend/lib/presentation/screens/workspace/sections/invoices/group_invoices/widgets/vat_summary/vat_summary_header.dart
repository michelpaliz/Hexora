import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/buttons.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

class VatSummaryHeader extends StatelessWidget {
  final int year;
  final String rangeLabel;
  final String deadlineLabel;
  final bool exportingVatAudit;
  final VoidCallback? onExportVatAudit;
  final VoidCallback onPrevYear;
  final VoidCallback onNextYear;
  final VoidCallback onToday;
  final bool isCurrentPeriod;
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
    required this.onToday,
    required this.isCurrentPeriod,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final periodTooltip = '$rangeLabel · $deadlineLabel';

    final yearControl = Container(
      height: 38,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(HexoraDimensions.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HexoraButton.iconOnly(
            onPressed: onPrevYear,
            icon: Icons.chevron_left_rounded,
            tooltip: l.vatSummaryPrevYear,
            size: HexoraButtonSize.standard,
          ),
          SizedBox(
            width: 54,
            child: Text(
              '$year',
              textAlign: TextAlign.center,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          HexoraButton.iconOnly(
            onPressed: onNextYear,
            icon: Icons.chevron_right_rounded,
            tooltip: l.vatSummaryNextYear,
            size: HexoraButtonSize.standard,
          ),
        ],
      ),
    );

    final quarterSelector = Tooltip(
      message: periodTooltip,
      child: SizedBox(
        width: 320,
        height: 38,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: cs.primary,
            selectedForegroundColor: cs.onPrimary,
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
            side: BorderSide(color: cs.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HexoraDimensions.radius),
            ),
            minimumSize: const Size(68, 38),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          segments: [
            for (var quarter = 1; quarter <= 4; quarter++)
              ButtonSegment<int>(
                value: quarter,
                label: Text('T$quarter'),
                tooltip: switch (quarter) {
                  1 => l.vatSummaryQuarterQ1,
                  2 => l.vatSummaryQuarterQ2,
                  3 => l.vatSummaryQuarterQ3,
                  _ => l.vatSummaryQuarterQ4,
                },
              ),
          ],
          selected: {tabs.index + 1},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) tabs.animateTo(selection.first - 1);
          },
        ),
      ),
    );

    final todayButton = HexoraButton(
      onPressed: onToday,
      label: isEs ? 'Hoy' : 'Today',
      icon: Icons.today_outlined,
      variant: HexoraButtonVariant.ghost,
      size: HexoraButtonSize.large,
      tooltip:
          isCurrentPeriod ? (isEs ? 'Periodo actual' : 'Current period') : null,
    );

    final exportFullLabel =
        isEs ? 'Exportar auditoría IVA' : 'Export VAT audit';
    final exportButton = HexoraButton(
      onPressed: exportingVatAudit ? null : onExportVatAudit,
      label: exportingVatAudit
          ? (isEs ? 'Generando…' : 'Generating…')
          : (isEs ? 'Exportar' : 'Export'),
      icon: Icons.download_rounded,
      loading: exportingVatAudit,
      variant: HexoraButtonVariant.tonal,
      size: HexoraButtonSize.large,
      tooltip: isEs
          ? '$exportFullLabel · Descarga base, IVA y total por factura.'
          : '$exportFullLabel · Download taxable base, VAT and total per invoice.',
    );

    final controls = <Widget>[
      yearControl,
      quarterSelector,
      todayButton,
      exportButton,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 720) {
            return Row(
              children: [
                yearControl,
                const SizedBox(width: 12),
                quarterSelector,
                const SizedBox(width: 12),
                todayButton,
                const Spacer(),
                exportButton,
              ],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < controls.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  controls[index],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
