import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RepetitionResult {
  final LegacyRecurrenceRule? rule;
  final String? error;

  RepetitionResult({this.rule, this.error});
}

RepetitionResult validateAndCreateRecurrenceRule({
  required BuildContext context,
  required String frequency,
  required int? repeatInterval,
  required bool isForever,
  required DateTime? untilDate,
  required DateTime selectedStartDate,
  required DateTime selectedEndDate,
  required Set<CustomDayOfWeek> selectedDays,
  int? dayOfMonth,
  int? selectedMonth,
}) {
  final localizations = AppLocalizations.of(context)!;

  if (repeatInterval == null || repeatInterval == 0) {
    return RepetitionResult(error: localizations.specifyRepeatInterval);
  }

  if (!isForever && untilDate == null) {
    return RepetitionResult(error: localizations.untilDate);
  }

  if (frequency == 'Weekly' && selectedDays.isEmpty) {
    return RepetitionResult(error: localizations.selectOneDayAtLeast);
  }

  final rule = switch (frequency) {
    'Daily' => LegacyRecurrenceRule.daily(
        repeatInterval: repeatInterval,
        untilDate: isForever ? null : untilDate,
        startDate: selectedStartDate, // ← added
      ),
    'Weekly' => LegacyRecurrenceRule.weekly(
        selectedDays.toList(),
        repeatInterval: repeatInterval,
        untilDate: isForever ? null : untilDate,
        startDate: selectedStartDate, // ← added
      ),
    'Monthly' => LegacyRecurrenceRule.monthly(
        dayOfMonth: dayOfMonth,
        repeatInterval: repeatInterval,
        untilDate: isForever ? null : untilDate,
        startDate: selectedStartDate, // ← added
      ),
    'Yearly' => LegacyRecurrenceRule.yearly(
        month: selectedMonth,
        dayOfMonth: dayOfMonth,
        repeatInterval: repeatInterval,
        untilDate: isForever ? null : untilDate,
        startDate: selectedStartDate, // ← added
      ),
    _ => LegacyRecurrenceRule.daily(
        repeatInterval: repeatInterval,
        untilDate: isForever ? null : untilDate,
        startDate: selectedStartDate, // ← added
      ),
  };

  return RepetitionResult(rule: rule);
}
