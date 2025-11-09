import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/graphs/enum/insights_types.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class DimensionTabs extends StatelessWidget {
  final Dimension value;
  final ValueChanged<Dimension> onChanged;
  const DimensionTabs({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    Widget tab(String text, bool selected, VoidCallback onTap) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? cs.primary.withOpacity(0.0)
                  : cs.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(
              child: Text(
                text,
                style: typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                  letterSpacing: .2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(l.filterDimensionClients, value == Dimension.clients,
            () => onChanged(Dimension.clients)),
        const SizedBox(width: 10),
        tab(l.filterDimensionServices, value == Dimension.services,
            () => onChanged(Dimension.services)),
      ],
    );
  }
}
