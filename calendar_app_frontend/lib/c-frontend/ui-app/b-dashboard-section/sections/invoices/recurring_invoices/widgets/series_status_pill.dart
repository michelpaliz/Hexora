import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SeriesStatusPill extends StatelessWidget {
  final String status;

  const SeriesStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final normalized = status.toLowerCase();
    final label = normalized == 'paused'
        ? l.recurringInvoicesStatusPaused
        : normalized == 'cancelled'
            ? l.recurringInvoicesStatusCancelled
            : normalized == 'completed'
                ? l.recurringInvoicesStatusCompleted
                : l.recurringInvoicesStatusActive;
    final bg = normalized == 'paused'
        ? cs.tertiaryContainer
        : normalized == 'cancelled'
            ? cs.errorContainer
            : normalized == 'completed'
                ? cs.primaryContainer
                : cs.secondaryContainer;
    final fg = normalized == 'paused'
        ? cs.onTertiaryContainer
        : normalized == 'cancelled'
            ? cs.onErrorContainer
            : normalized == 'completed'
                ? cs.onPrimaryContainer
                : cs.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
