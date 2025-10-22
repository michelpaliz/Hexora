// lib/c-frontend/d-event-section/screens/event_detail/widgets/section_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 0.7),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: typo.accentHeading.copyWith(
                  color: scheme.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._withGaps(children),
        ],
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> items) {
    if (items.isEmpty) return items;
    return [
      for (var i = 0; i < items.length; i++) ...[
        items[i],
        if (i != items.length - 1) const SizedBox(height: 8),
      ]
    ];
  }
}
