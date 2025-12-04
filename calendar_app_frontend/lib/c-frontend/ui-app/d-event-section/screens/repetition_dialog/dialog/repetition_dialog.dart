import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/recurrence_rule/legacy_recurrence_rule.dart';
import 'package:hexora/a-models/group_model/recurrenceRule/utils_recurrence_rule/custom_day_week.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/utils/frequency_selector.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/utils/repetition_rule_helper.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/widgets/repeat_every_row.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/widgets/until_date_picker.dart';
import 'package:hexora/c-frontend/ui-app/d-event-section/screens/repetition_dialog/widgets/weekly_day_selector.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RepetitionScreen extends StatefulWidget {
  final DateTime selectedStartDate;
  final DateTime selectedEndDate;
  final LegacyRecurrenceRule? initialRecurrenceRule;

  const RepetitionScreen({
    super.key,
    required this.selectedStartDate,
    required this.selectedEndDate,
    this.initialRecurrenceRule,
  });

  @override
  _RepetitionScreenState createState() => _RepetitionScreenState();
}

class _RepetitionScreenState extends State<RepetitionScreen> {
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

  Future<void> _handleCancelPressed() async {
    final l = AppLocalizations.of(context)!;
    if (widget.initialRecurrenceRule != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(ctx);
          return AlertDialog(
            title: Text(l.confirm),
            content: Text(l.removeRecurrenceConfirm),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: t.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.colorScheme.error,
                  foregroundColor: t.colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.remove),
              ),
            ],
          );
        },
      );
      if (confirmed == true) {
        _goBackToParentView(null, false);
      }
      return;
    }
    _goBackToParentView(null, false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = theme.colorScheme;
    final onText = ThemeColors.textPrimary(context);
    final backdrop = ThemeColors.containerBg(context);
    final sectionBg = Color.alphaBlend(
      cs.primaryContainer.withOpacity(
        theme.brightness == Brightness.dark ? 0.18 : 0.12,
      ),
      cs.surfaceVariant,
    );

    Container section(Widget child) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sectionBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.cardShadow(context),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    final dateRange =
        '${DateFormat.yMMMd(l.localeName).format(_selectedStartDate)}  •  ${DateFormat.yMMMd(l.localeName).format(_selectedEndDate)}';

    return Scaffold(
      backgroundColor: backdrop,
      appBar: AppBar(
        backgroundColor: ThemeColors.cardBg(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancelPressed,
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.selectRepetition.toUpperCase(),
              style: t.titleLarge.copyWith(
                fontSize: 18,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w800,
                color: onText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateRange,
              style: t.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                section(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.av_timer_outlined,
                              size: 18, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            l.selectRepetition,
                            style: t.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RepeatFrequencySelector(
                        selectedFrequency: selectedFrequency,
                        onSelectFrequency: (frequency) {
                          setState(() {
                            selectedFrequency = frequency;

                            if (frequency == 'Weekly') {
                              final eventDay = CustomDayOfWeek.getPattern(
                                DateFormat('EEEE', 'en_US')
                                    .format(_selectedStartDate),
                              );
                              final requiredDay =
                                  CustomDayOfWeek.fromString(eventDay);
                              selectedDays.add(requiredDay);
                            }
                            _updateWarningMessage();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                section(
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
                ),
                if (selectedFrequency == 'Weekly')
                  section(
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
                  ),
                section(
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
                ),
                if (validationError != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(
                          theme.brightness == Brightness.dark ? 0.6 : 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            color: cs.onErrorContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            validationError!,
                            style: t.bodySmall.copyWith(
                              color: cs.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (warningMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer.withOpacity(
                          theme.brightness == Brightness.dark ? 0.6 : 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: cs.onTertiaryContainer, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warningMessage!,
                            style: t.bodySmall.copyWith(
                              color: cs.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outlineVariant),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  textStyle: t.buttonText.copyWith(color: cs.onSurface),
                ),
                onPressed: _handleCancelPressed,
                child: Text(l.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: t.buttonText,
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
                child: Text(l.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
