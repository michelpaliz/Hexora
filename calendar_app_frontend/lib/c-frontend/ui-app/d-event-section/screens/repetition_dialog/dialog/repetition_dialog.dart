import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/utils/frequency_selector.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/utils/repetition_rule_helper.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/widgets/repeat_every_row.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/widgets/until_date_picker.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/widgets/weekly_day_selector.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RepetitionDialog extends StatefulWidget {
  final DateTime selectedStartDate;
  final DateTime selectedEndDate;
  final LegacyRecurrenceRule? initialRecurrenceRule;

  const RepetitionDialog({
    super.key,
    required this.selectedStartDate,
    required this.selectedEndDate,
    this.initialRecurrenceRule,
  });

  @override
  _RepetitionDialogState createState() => _RepetitionDialogState();
}

class _RepetitionDialogState extends State<RepetitionDialog> {
  String selectedFrequency = 'Daily';
  int? repeatInterval = 1; // default to 1 instead of 0
  int? dayOfMonth;
  int? selectedMonth;
  bool isForever = false;
  DateTime? untilDate;
  Set<CustomDayOfWeek> selectedDays = {};
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  bool isRepeated = false;
  String? validationError;
  String? warningMessage;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.selectedStartDate;
    _selectedEndDate = widget.selectedEndDate;
    _fillVariablesFromInitialRecurrenceRule(widget.initialRecurrenceRule);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateWarningMessage());
  }

  void _fillVariablesFromInitialRecurrenceRule(LegacyRecurrenceRule? rule) {
    if (rule != null) {
      selectedFrequency = rule.name;
      repeatInterval = (rule.repeatInterval == null || rule.repeatInterval == 0)
          ? 1
          : rule.repeatInterval;
      dayOfMonth = rule.dayOfMonth;
      selectedMonth = rule.month;
      untilDate = rule.untilDate;
      isForever = rule.untilDate == null;
      selectedDays = Set<CustomDayOfWeek>.from(rule.daysOfWeek ?? []);
    }
  }

  void _goBackToParentView(
    LegacyRecurrenceRule? recurrenceRule,
    bool? isRepetitiveUpdated,
  ) {
    setState(() {
      isRepeated = isRepetitiveUpdated ?? false;
    });
    Navigator.of(context).pop(<Object?>[recurrenceRule, isRepeated]);
  }

  void _updateWarningMessage() {
    final eventDay = CustomDayOfWeek.getPattern(
      DateFormat('EEEE', 'en_US').format(_selectedStartDate),
    );
    final requiredDay = CustomDayOfWeek.fromString(eventDay);

    setState(() {
      if (selectedFrequency == 'Weekly' &&
          !selectedDays.contains(requiredDay)) {
        warningMessage =
            AppLocalizations.of(context)!.eventDayNotIncludedWarning(
          DateFormat('EEEE').format(_selectedStartDate),
        );
      } else {
        warningMessage = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.selectRepetition.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RepeatFrequencySelector(
              selectedFrequency: selectedFrequency,
              onSelectFrequency: (frequency) {
                setState(() {
                  selectedFrequency = frequency;

                  if (frequency == 'Weekly') {
                    final eventDay = CustomDayOfWeek.getPattern(
                      DateFormat('EEEE', 'en_US').format(_selectedStartDate),
                    );
                    final requiredDay = CustomDayOfWeek.fromString(eventDay);
                    selectedDays.add(requiredDay);
                  }
                  _updateWarningMessage();
                });
              },
            ),
            const SizedBox(height: 12),
            RepeatEveryRow(
              selectedFrequency: selectedFrequency,
              repeatInterval: repeatInterval ?? 1,
              selectedDays: selectedDays.toList(),
              selectedStartDate: _selectedStartDate,
              onIntervalChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    repeatInterval = value == 0 ? 1 : value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            if (selectedFrequency == 'Weekly')
              WeeklyDaySelector(
                selectedDays: selectedDays,
                onDayToggle: (day, isSelected) {
                  setState(() {
                    if (isSelected) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                    _updateWarningMessage();
                  });
                },
              ),
            const SizedBox(height: 12),
            UntilDatePicker(
              isForever: isForever,
              untilDate: untilDate,
              onForeverChanged: (newValue) {
                setState(() {
                  isForever = newValue;
                  if (isForever) untilDate = null;
                });
              },
              onDateSelected: (date) {
                setState(() {
                  untilDate = date;
                });
              },
            ),
            if (validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  validationError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ),
            if (warningMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  warningMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                if (widget.initialRecurrenceRule != null) {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final t = Theme.of(ctx);
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.confirm),
                        content: Text(AppLocalizations.of(context)!
                            .removeRecurrenceConfirm),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: t.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: t.colorScheme.error,
                              foregroundColor: t.colorScheme.onError,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(AppLocalizations.of(context)!.remove),
                          ),
                        ],
                      );
                    },
                  ).then((confirmed) {
                    if (confirmed == true) {
                      Navigator.of(context).pop(<Object?>[null, false]);
                    }
                  });
                } else {
                  _goBackToParentView(null, false);
                }
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: () {
                final result = validateAndCreateRecurrenceRule(
                  context: context,
                  frequency: selectedFrequency,
                  repeatInterval:
                      (repeatInterval == null || repeatInterval == 0)
                          ? 1
                          : repeatInterval,
                  isForever: isForever,
                  untilDate: untilDate,
                  selectedStartDate: _selectedStartDate,
                  selectedEndDate: _selectedEndDate,
                  selectedDays: selectedDays,
                  dayOfMonth: dayOfMonth,
                  selectedMonth: selectedMonth,
                );

                _updateWarningMessage();

                setState(() {
                  validationError = result.error;

                  if (result.error == null && warningMessage == null) {
                    _goBackToParentView(result.rule, true);
                  }
                });
              },
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      ],
    );
  }
}
