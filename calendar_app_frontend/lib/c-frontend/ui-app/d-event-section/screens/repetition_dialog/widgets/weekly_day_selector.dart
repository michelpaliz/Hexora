import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';
import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final onText = ThemeColors.textPrimary(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.selectDay,
              style: t.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: onText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: customDaysOfWeek.map((day) {
            final isSelected = selectedDays.contains(day);
            return ChoiceChip(
              label: Text(
                _translateDayAbbreviation(
                  context,
                  day.name.substring(0, 3),
                ),
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? cs.onPrimaryContainer : onText,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onDayToggle(day, !isSelected),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
              selectedColor: cs.primaryContainer,
              backgroundColor: cs.surfaceVariant.withOpacity(0.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? cs.primary
                      : cs.outlineVariant.withOpacity(0.55),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
