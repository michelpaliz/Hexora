import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_schedule_form.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringWizardScheduleStep extends StatelessWidget {
  final String freq;
  final TextEditingController intervalCtrl;
  final DateTime startDate;
  final String endType;
  final DateTime? endDate;
  final TextEditingController countCtrl;
  final TextEditingController billDayCtrl;
  final TextEditingController weekDayCtrl;
  final TextEditingController timezoneCtrl;
  final String timezoneLabel;
  final List<DateTime> exceptions;
  final ValueChanged<String> onFreqChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEnd;
  final ValueChanged<String> onEndTypeChanged;
  final ValueChanged<String> onTimezoneChanged;
  final VoidCallback onPickTimezone;
  final VoidCallback onAddException;
  final ValueChanged<DateTime> onRemoveException;

  const RecurringWizardScheduleStep({
    super.key,
    required this.freq,
    required this.intervalCtrl,
    required this.startDate,
    required this.endType,
    required this.endDate,
    required this.countCtrl,
    required this.billDayCtrl,
    required this.weekDayCtrl,
    required this.timezoneCtrl,
    required this.timezoneLabel,
    required this.exceptions,
    required this.onFreqChanged,
    required this.onPickStart,
    required this.onPickStartTime,
    required this.onPickEnd,
    required this.onEndTypeChanged,
    required this.onTimezoneChanged,
    required this.onPickTimezone,
    required this.onAddException,
    required this.onRemoveException,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return RecurringWizardSectionCard(
      title: l.recurringInvoicesStepSchedule,
      icon: Icons.schedule_outlined,
      child: RecurringScheduleForm(
        freq: freq,
        intervalCtrl: intervalCtrl,
        startDate: startDate,
        endType: endType,
        endDate: endDate,
        countCtrl: countCtrl,
        billDayCtrl: billDayCtrl,
        weekDayCtrl: weekDayCtrl,
        timezoneCtrl: timezoneCtrl,
        timezoneLabel: timezoneLabel,
        exceptions: exceptions,
        onFreqChanged: onFreqChanged,
        onPickStart: onPickStart,
        onPickStartTime: onPickStartTime,
        onPickEnd: onPickEnd,
        onEndTypeChanged: onEndTypeChanged,
        onTimezoneChanged: onTimezoneChanged,
        onPickTimezone: onPickTimezone,
        onAddException: onAddException,
        onRemoveException: onRemoveException,
      ),
    );
  }
}
