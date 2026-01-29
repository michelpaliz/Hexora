import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_schedule_form.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringDetailRuleTab extends StatelessWidget {
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
  final bool canManage;
  final bool saving;
  final VoidCallback onSave;

  const RecurringDetailRuleTab({
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
    required this.canManage,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    Widget summaryRow({required String label, required String value}) {
      return RecurringDetailSummaryRow(label: label, value: value);
    }

    Widget ruleSummaryCard() {
      return RecurringDetailSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l.details,
                  style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            summaryRow(
              label: l.recurringInvoicesFrequencyLabel,
              value: switch (freq) {
                'daily' => l.recurringFrequencyDaily,
                'weekly' => l.recurringFrequencyWeekly,
                'monthly' => l.recurringFrequencyMonthly,
                'yearly' => l.recurringFrequencyYearly,
                _ => freq,
              },
            ),
            summaryRow(
              label: l.recurringInvoicesIntervalLabel,
              value: intervalCtrl.text.trim().isEmpty
                  ? '1'
                  : intervalCtrl.text.trim(),
            ),
            summaryRow(
              label: l.recurringInvoicesStartLabel,
              value: DateFormat.yMMMd(l.localeName).add_Hm().format(startDate),
            ),
            summaryRow(
              label: l.recurringInvoicesEndLabel,
              value: endType == 'never'
                  ? l.recurringInvoicesEndNever
                  : endType == 'date' && endDate != null
                      ? DateFormat.yMMMd(l.localeName).format(endDate!)
                      : endType == 'count' && countCtrl.text.trim().isNotEmpty
                          ? countCtrl.text.trim()
                          : l.recurringInvoicesEndNever,
            ),
            if (freq == 'monthly')
              summaryRow(
                label: l.recurringInvoicesBillDayLabel,
                value: billDayCtrl.text.trim().isEmpty
                    ? '-'
                    : billDayCtrl.text.trim(),
              ),
            if (freq == 'weekly')
              summaryRow(
                label: l.recurringInvoicesWeekDayLabel,
                value: weekDayCtrl.text.trim().isEmpty
                    ? '-'
                    : weekDayCtrl.text.trim(),
              ),
            summaryRow(
              label: l.recurringInvoicesTimezoneLabel,
              value: timezoneLabel,
            ),
            summaryRow(
              label: l.recurringInvoicesExceptionsLabel,
              value: exceptions.isEmpty
                  ? l.recurringInvoicesNoExceptions
                  : '${exceptions.length}',
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final saveButton = canManage
                  ? FilledButton(
                      onPressed: saving ? null : onSave,
                      child: Text(
                        saving
                            ? l.recurringInvoicesSavingRule
                            : l.recurringInvoicesSaveRuleCta,
                      ),
                    )
                  : const SizedBox.shrink();

              final form = RecurringScheduleForm(
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
              );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    const SizedBox(height: 12),
                    ruleSummaryCard(),
                    if (canManage) ...[
                      const SizedBox(height: 12),
                      saveButton,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: form),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ruleSummaryCard(),
                        if (canManage) ...[
                          const SizedBox(height: 12),
                          saveButton,
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
