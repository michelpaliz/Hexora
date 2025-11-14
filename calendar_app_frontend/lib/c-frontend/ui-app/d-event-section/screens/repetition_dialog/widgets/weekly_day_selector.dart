import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WeeklyDaySelector extends StatelessWidget {
  final Set<CustomDayOfWeek> selectedDays;
  final Function(CustomDayOfWeek, bool isSelected) onDayToggle;

  const WeeklyDaySelector({
    Key? key,
    required this.selectedDays,
    required this.onDayToggle,
  }) : super(key: key);

  String _translateDayAbbreviation(BuildContext context, String dayAbbr) {
    switch (dayAbbr.toLowerCase()) {
      case 'mon':
        return AppLocalizations.of(context)!.mon;
      case 'tue':
        return AppLocalizations.of(context)!.tue;
      case 'wed':
        return AppLocalizations.of(context)!.wed;
      case 'thu':
        return AppLocalizations.of(context)!.thu;
      case 'fri':
        return AppLocalizations.of(context)!.fri;
      case 'sat':
        return AppLocalizations.of(context)!.sat;
      case 'sun':
        return AppLocalizations.of(context)!.sun;
      default:
        return dayAbbr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context)!.selectDay,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: customDaysOfWeek.map((day) {
            final isSelected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () => onDayToggle(day, !isSelected),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.blue
                      : const Color.fromARGB(255, 240, 239, 239),
                ),
                alignment: Alignment.center,
                child: Text(
                  _translateDayAbbreviation(context, day.name.substring(0, 3)),
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
