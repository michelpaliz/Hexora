import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/calendar/recurrence/legacy_recurrence_rule.dart';
import 'package:hexora/models/calendar/recurrence/utils/custom_day_week.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/utils/frequency_selector.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/utils/repetition_rule_helper.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/widgets/repeat_every_row.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/widgets/until_date_picker.dart';
import 'package:hexora/presentation/screens/events/screens/repetition_dialog/widgets/weekly_day_selector.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  State<RepetitionScreen> createState() => _RepetitionScreenState();
}

class _RepetitionScreenState extends State<RepetitionScreen> {
  String selectedFrequency = 'Daily';
  int? repeatInterval = 1; // default to 1 instead of 0
  int? dayOfMonth;
  int? selectedMonth;
  bool isForever = true;
  DateTime? untilDate;
  Set<CustomDayOfWeek> selectedDays = {};
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
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
    Navigator.of(context)
        .pop(<Object?>[recurrenceRule, isRepetitiveUpdated ?? false]);
  }

  void _handleClosePressed() {
    _goBackToParentView(
      widget.initialRecurrenceRule,
      widget.initialRecurrenceRule != null,
    );
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

  Future<void> _handleRemovePressed() async {
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
      if (!mounted) return;
      if (confirmed == true) {
        _goBackToParentView(null, false);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = theme.colorScheme;
    final onText = ThemeColors.textPrimary(context);
    final backdrop = ThemeColors.containerBg(context);
    Container section(Widget child) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: child,
      );
    }

    final startDate = DateFormat.yMMMd(l.localeName).format(_selectedStartDate);
    final dateRange = DateUtils.isSameDay(_selectedStartDate, _selectedEndDate)
        ? startDate
        : '$startDate  •  ${DateFormat.yMMMd(l.localeName).format(_selectedEndDate)}';
    const isWeb = kIsWeb;
    const maxContentWidth = isWeb ? 1040.0 : 640.0;

    return Scaffold(
      backgroundColor: backdrop,
      appBar: AppBar(
        backgroundColor: ThemeColors.cardBg(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l.cancel,
          onPressed: _handleClosePressed,
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.selectRepetition,
              style: t.titleLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: onText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              dateRange,
              style: t.bodySmall.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            isWeb ? 24 : 16,
            isWeb ? 16 : 12,
            isWeb ? 24 : 16,
            isWeb ? 28 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
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
                            Expanded(
                              child: Text(
                                l.recurrenceFrequency,
                                style: t.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: onText,
                                ),
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
                      startDate: _selectedStartDate,
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
                  if (widget.initialRecurrenceRule != null)
                    TextButton.icon(
                      onPressed: _handleRemovePressed,
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l.removeRecurrence),
                    ),
                  if (validationError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.6
                                : 0.9),
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
                        color: cs.tertiaryContainer.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.6
                                : 0.9),
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
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size.fromHeight(50),
            textStyle: t.buttonText,
          ),
          onPressed: () {
            final result = validateAndCreateRecurrenceRule(
              context: context,
              frequency: selectedFrequency,
              repeatInterval: (repeatInterval == null || repeatInterval == 0)
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
    );
  }
}
