import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class UntilDatePicker extends StatelessWidget {
  final bool isForever;
  final DateTime startDate;
  final DateTime? untilDate;
  final Function(bool) onForeverChanged;
  final Function(DateTime) onDateSelected;

  const UntilDatePicker({
    super.key,
    required this.isForever,
    required this.startDate,
    required this.untilDate,
    required this.onForeverChanged,
    required this.onDateSelected,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(startDate.year, startDate.month, startDate.day);
    final firstDate = eventStart.isAfter(today) ? eventStart : today;
    final lastDate =
        DateTime(firstDate.year + 10, firstDate.month, firstDate.day);
    final initialDate = untilDate != null &&
            !untilDate!.isBefore(firstDate) &&
            !untilDate!.isAfter(lastDate)
        ? untilDate!
        : firstDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateLabel = untilDate == null
        ? l.recurrenceChooseDate
        : DateFormat.yMMMd(l.localeName).format(untilDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          value: !isForever,
          onChanged: (value) => onForeverChanged(!value),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: cs.primary,
          title: Text(
            l.recurrenceEndDate,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            isForever ? l.recurrenceNever : dateLabel,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        if (!isForever)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              key: const Key('recurrence-date-button'),
              onPressed: () => _pickDate(context),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(dateLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.outlineVariant),
                minimumSize: const Size.fromHeight(44),
                alignment: Alignment.centerLeft,
                textStyle: t.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}
