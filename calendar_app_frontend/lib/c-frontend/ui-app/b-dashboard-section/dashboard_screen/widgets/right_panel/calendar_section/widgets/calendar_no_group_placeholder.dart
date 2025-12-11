import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CalendarNoGroupPlaceholder extends StatelessWidget {
  const CalendarNoGroupPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.goToCalendar,
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l.noGroupAvailable,
            style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
