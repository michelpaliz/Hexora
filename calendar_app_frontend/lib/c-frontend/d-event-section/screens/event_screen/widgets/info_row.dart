// lib/c-frontend/d-event-section/screens/event_detail/widgets/info_row.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool chipStyle;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  }) : chipStyle = false;

  const InfoRow.chip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  }) : chipStyle = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    if (chipStyle) {
      return Row(
        children: [
          Icon(icon, size: 18, color: scheme.tertiary),
          const SizedBox(width: 8),
          Text(label,
              style: typo.caption.copyWith(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Chip(
            backgroundColor: scheme.secondaryContainer,
            side: BorderSide(color: scheme.outlineVariant, width: 0.5),
            label: Text(value,
                style: typo.bodySmall.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: typo.caption.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: typo.bodyLarge
                      .copyWith(color: scheme.onSurface, height: 1.25)),
            ],
          ),
        ),
      ],
    );
  }
}
