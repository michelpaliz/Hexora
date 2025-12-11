import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class CalendarInlineErrorView extends StatelessWidget {
  const CalendarInlineErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pendingEventsError, // same key as before
            style: t.bodyMedium.copyWith(color: cs.error),
          ),
          const SizedBox(height: 8),
          Text(error, style: t.bodySmall),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(l.refresh),
          ),
        ],
      ),
    );
  }
}
