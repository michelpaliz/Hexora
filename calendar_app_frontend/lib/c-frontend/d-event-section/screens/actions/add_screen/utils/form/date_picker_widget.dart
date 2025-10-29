import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DatePickersWidget extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  const DatePickersWidget({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    // Locale-aware formats
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMEd(locale); // e.g., "Mon, Jan 1, 2025"
    final timeFmt =
        DateFormat.jm(locale); // e.g., "5:30 PM" (or 24h based on locale)

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateTile(
              label: l.startDate,
              date: startDate,
              onTap: onStartDateTap,
              dateFmt: dateFmt,
              timeFmt: timeFmt,
              accentColor: cs.primaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DateTile(
              label: l.endDate,
              date: endDate,
              onTap: onEndDateTap,
              dateFmt: dateFmt,
              timeFmt: timeFmt,
              accentColor: cs.secondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final DateFormat dateFmt;
  final DateFormat timeFmt;
  final Color accentColor;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.dateFmt,
    required this.timeFmt,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer, // readable on tonal bg
                  letterSpacing: .2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Date + time
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateFmt.format(date.toLocal()),
                    style:
                        typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  timeFmt.format(date.toLocal()),
                  style: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
