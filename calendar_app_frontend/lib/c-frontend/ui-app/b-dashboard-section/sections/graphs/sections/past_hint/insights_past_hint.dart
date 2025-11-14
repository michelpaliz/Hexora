import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class InsightsPastDataHint extends StatelessWidget {
  const InsightsPastDataHint({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l.insightsHintUpcomingOnly,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}
