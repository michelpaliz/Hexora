import 'package:hexora/models/calendar/recurrence/utils/custom_day_week.dart';
import 'package:hexora/presentation/screens/events/utils/number_selector.dart';
import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RepeatEveryRow extends StatelessWidget {
  final String selectedFrequency;
  final int repeatInterval;
  final List<CustomDayOfWeek> selectedDays;
  final DateTime selectedStartDate;
  final Function(int) onIntervalChanged;

  const RepeatEveryRow({
    super.key,
    required this.selectedFrequency,
    required this.repeatInterval,
    required this.selectedDays,
    required this.selectedStartDate,
    required this.onIntervalChanged,
  });

  int _getMaxRepeatValue(String frequency) {
    switch (frequency) {
      case 'Daily':
        return 500;
      case 'Weekly':
        return 18;
      case 'Monthly':
        return 18;
      case 'Yearly':
        return 10;
      default:
        return 0;
    }
  }

  String _getTranslatedFrequencyDays(
    BuildContext context,
    List<String> dayNames,
  ) {
    final translated = dayNames.map((day) {
      switch (day.toLowerCase()) {
        case 'monday':
          return AppLocalizations.of(context)!.monday;
        case 'tuesday':
          return AppLocalizations.of(context)!.tuesday;
        case 'wednesday':
          return AppLocalizations.of(context)!.wednesday;
        case 'thursday':
          return AppLocalizations.of(context)!.thursday;
        case 'friday':
          return AppLocalizations.of(context)!.friday;
        case 'saturday':
          return AppLocalizations.of(context)!.saturday;
        case 'sunday':
          return AppLocalizations.of(context)!.sunday;
        default:
          return day;
      }
    }).toList();

    return translated.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formattedDate =
        DateFormat.MMMMd(l.localeName).format(selectedStartDate);
    final selectedDayNames = selectedDays.map((day) => day.name).toList();
    final t = AppTypography.of(context);
    final onText = ThemeColors.textPrimary(context);
    final secondaryText = ThemeColors.textSecondary(context);

    selectedDayNames.sort((a, b) {
      final orderA = customDaysOfWeek.firstWhere((d) => d.name == a).order;
      final orderB = customDaysOfWeek.firstWhere((d) => d.name == b).order;
      return orderA.compareTo(orderB);
    });

    final repeatMessage = switch (selectedFrequency) {
      'Daily' => l.recurrenceDailySummary(repeatInterval),
      'Weekly' => selectedDayNames.isEmpty
          ? l.noDaysSelected
          : l.recurrenceWeeklySummary(
              repeatInterval,
              _getTranslatedFrequencyDays(context, selectedDayNames),
            ),
      'Monthly' =>
        l.recurrenceMonthlySummary(repeatInterval, selectedStartDate.day),
      'Yearly' => l.recurrenceYearlySummary(repeatInterval, formattedDate),
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_graph_rounded,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.repetitionDetails,
                style: t.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              l.every,
              style: t.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: onText,
              ),
            ),
            const Spacer(),
            NumberSelector(
              key: Key(selectedFrequency),
              value: repeatInterval,
              minValue: 1,
              maxValue: _getMaxRepeatValue(selectedFrequency),
              onChanged: (value) {
                if (value != null) onIntervalChanged(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          repeatMessage,
          style: t.bodySmall.copyWith(color: secondaryText),
        ),
      ],
    );
  }
}
