// lib/c-frontend/d-event-section/screens/event_detail/widgets/header_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class HeaderCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color eventColor;
  final String statusLabel;
  final Color statusColor;
  final bool isWorkVisit;

  const HeaderCard({
    super.key,
    required this.title,
    required this.isDark,
    required this.eventColor,
    required this.statusLabel,
    required this.statusColor,
    required this.isWorkVisit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: scheme.shadow.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // colored dot
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(top: 4, right: 10),
            decoration: BoxDecoration(
              color: eventColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark ? Colors.black : Colors.white, width: 1.5),
            ),
          ),
          // title + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? loc.untitledEvent : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typo.displayMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                        icon: Icons.label_important_outline,
                        label: statusLabel,
                        color: statusColor),
                    if (isWorkVisit)
                      _Badge(
                          icon: Icons.build_outlined,
                          label: loc.workVisitBadge,
                          color: scheme.tertiary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: typo.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }
}
