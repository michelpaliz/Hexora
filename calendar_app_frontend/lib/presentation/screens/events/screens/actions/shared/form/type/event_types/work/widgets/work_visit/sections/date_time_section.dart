import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'section_card_builder.dart';

class DateTimeSection extends StatelessWidget {
  final String title;
  final SectionCardBuilder cardBuilder;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const DateTimeSection({
    super.key,
    required this.title,
    required this.cardBuilder,
    required this.startDate,
    required this.endDate,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final startField = _DateFieldTile(
      label: l.startDate,
      date: startDate.toLocal(),
      onTap: onStartTap,
      icon: Icons.event_available_outlined,
    );
    final endField = _DateFieldTile(
      label: l.endDate,
      date: endDate.toLocal(),
      onTap: onEndTap,
      icon: Icons.event_outlined,
    );

    final cs = Theme.of(context).colorScheme;
    return cardBuilder(
      title: title,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 560) {
              return Row(
                children: [
                  Expanded(child: startField),
                  SizedBox(
                    height: 64,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: cs.outlineVariant,
                    ),
                  ),
                  Expanded(child: endField),
                ],
              );
            }
            return Column(
              children: [
                startField,
                Divider(height: 1, thickness: 1, color: cs.outlineVariant),
                endField,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DateFieldTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final IconData icon;

  const _DateFieldTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.icon,
  });

  String _dateLabel(AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return l.today;
    if (dateOnly == today.add(const Duration(days: 1))) return l.tomorrow;
    return DateFormat.yMMMd(l.localeName).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final dateText = _dateLabel(l);
    final timeText = DateFormat.jm(l.localeName).format(date);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '$dateText · $timeText',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge!.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
