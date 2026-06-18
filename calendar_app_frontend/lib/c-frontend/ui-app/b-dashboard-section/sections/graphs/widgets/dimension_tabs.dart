import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/enum/insights_types.dart';
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
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Material(
      color: Colors.transparent,
      child: Container(
      height: isMobile ? 46 : 38,
      padding: EdgeInsets.all(isMobile ? 4 : 3),
      decoration: BoxDecoration(
        color: isMobile
            ? cs.surfaceContainerHighest.withValues(alpha: 0.28)
            : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(isMobile ? 18 : 12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isMobile ? 0.42 : 0.35),
        ),
      ),
      child: Row(
        children: [
          _DimTab(
            icon: Icons.people_alt_outlined,
            label: l.filterDimensionClients,
            selected: value == Dimension.clients,
            onTap: () => onChanged(Dimension.clients),
            cs: cs,
            typo: typo,
            isMobile: isMobile,
          ),
          SizedBox(width: isMobile ? 6 : 3),
          _DimTab(
            icon: Icons.build_circle_outlined,
            label: l.filterDimensionServices,
            selected: value == Dimension.services,
            onTap: () => onChanged(Dimension.services),
            cs: cs,
            typo: typo,
            isMobile: isMobile,
          ),
        ],
      ),
      ),
    );
  }
}

class _DimTab extends StatelessWidget {
  const _DimTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
    required this.typo,
    required this.isMobile,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final AppTypography typo;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? cs.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isMobile ? 14 : 9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.22),
                      blurRadius: isMobile ? 10 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isMobile ? 16 : 14,
                color: selected
                    ? cs.onPrimary
                    : cs.onSurfaceVariant.withValues(alpha: 0.72),
              ),
              SizedBox(width: isMobile ? 7 : 5),
              Text(
                label,
                style: typo.bodySmall.copyWith(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant.withValues(alpha: 0.8),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
