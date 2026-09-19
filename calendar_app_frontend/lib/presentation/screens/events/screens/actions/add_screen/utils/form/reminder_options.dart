import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

const int kDefaultReminderMinutes = 10;
const int kMaxReminderMinutes = 3 * 24 * 60; // 4320 minutes

class ReminderOption {
  final String label;
  final int value;
  const ReminderOption(this.label, this.value);
}

List<ReminderOption> getLocalizedReminderOptions(BuildContext context) {
  final loc = AppLocalizations.of(context)!;

  return [
    ReminderOption(loc.reminderOptionAtTime, 0),
    ReminderOption(loc.reminderOption5min, 5),
    ReminderOption(loc.reminderOption10min, 10),
    ReminderOption(loc.reminderOption30min, 30),
    ReminderOption(loc.reminderOption1hour, 60),
    ReminderOption(loc.reminderOption2hours, 120),
    ReminderOption(loc.reminderOption1day, 1440),
    ReminderOption(loc.reminderOption2days, 2880),
    ReminderOption(loc.reminderOption3days, 4320),
  ];
}

class ReminderTimeDropdownField extends StatelessWidget {
  final int? initialValue;
  final void Function(int?) onChanged;
  final String? Function(int?)? validator;

  const ReminderTimeDropdownField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final loc = AppLocalizations.of(context)!;

    final value =
        initialValue?.clamp(0, kMaxReminderMinutes) ?? kDefaultReminderMinutes;
    final options = getLocalizedReminderOptions(context);

    return DropdownButtonFormField<int>(
      initialValue: value,
      onChanged: onChanged,
      validator: validator ??
          (val) {
            if (val == null) return '${loc.reminderLabel} is required';
            if (val < 0) return '${loc.reminderLabel} cannot be negative';
            if (val > kMaxReminderMinutes) {
              return '${loc.reminderLabel} cannot exceed 3 days';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: loc.reminderLabel,
        labelStyle: typo.bodySmall,
        helperText: loc.reminderHelper,
        helperStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
        errorStyle: typo.bodySmall.copyWith(color: cs.error),
        prefixIcon: Icon(Icons.alarm, color: cs.onSurfaceVariant),
        // Feel free to add filled/background if you want the M3 filled look:
        // filled: true,
        // fillColor: cs.surfaceVariant.withValues(alpha: .25),
      ),
      iconEnabledColor: cs.onSurfaceVariant,
      items: options
          .map(
            (option) => DropdownMenuItem<int>(
              value: option.value,
              child: Text(
                option.label,
                style: typo.bodyMedium, // primary field text
              ),
            ),
          )
          .toList(),
    );
  }
}
