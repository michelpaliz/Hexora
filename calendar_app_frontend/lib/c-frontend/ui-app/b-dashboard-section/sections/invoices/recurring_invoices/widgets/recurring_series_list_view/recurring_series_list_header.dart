import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class RecurringSeriesListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final bool canManage;
  final String refreshLabel;
  final String createLabel;

  const RecurringSeriesListHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    required this.onCreate,
    required this.canManage,
    required this.refreshLabel,
    required this.createLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(refreshLabel),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: canManage ? onCreate : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(createLabel),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
