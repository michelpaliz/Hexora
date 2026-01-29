import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_section_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringWizardPreviewStep extends StatelessWidget {
  final String freq;
  final TextEditingController intervalCtrl;
  final DateTime startDate;
  final String endType;
  final DateTime? endDate;
  final TextEditingController countCtrl;
  final TextEditingController billDayCtrl;
  final TextEditingController weekDayCtrl;
  final String timezoneLabel;
  final List<DateTime> exceptions;
  final bool loadingPreview;
  final List<String> previewDates;
  final VoidCallback onLoadPreview;

  const RecurringWizardPreviewStep({
    super.key,
    required this.freq,
    required this.intervalCtrl,
    required this.startDate,
    required this.endType,
    required this.endDate,
    required this.countCtrl,
    required this.billDayCtrl,
    required this.weekDayCtrl,
    required this.timezoneLabel,
    required this.exceptions,
    required this.loadingPreview,
    required this.previewDates,
    required this.onLoadPreview,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    return RecurringWizardSectionCard(
      title: l.recurringInvoicesStepPreview,
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecurringWizardSectionCard(
            title: l.details,
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecurringWizardSummaryRow(
                  label: l.recurringInvoicesFrequencyLabel,
                  value: switch (freq) {
                    'daily' => l.recurringFrequencyDaily,
                    'weekly' => l.recurringFrequencyWeekly,
                    'monthly' => l.recurringFrequencyMonthly,
                    'yearly' => l.recurringFrequencyYearly,
                    _ => freq,
                  },
                ),
                RecurringWizardSummaryRow(
                  label: l.recurringInvoicesIntervalLabel,
                  value: intervalCtrl.text.trim().isEmpty
                      ? '1'
                      : intervalCtrl.text.trim(),
                ),
                RecurringWizardSummaryRow(
                  label: l.recurringInvoicesStartLabel,
                  value: DateFormat.yMMMd(l.localeName)
                      .add_Hm()
                      .format(startDate),
                ),
                RecurringWizardSummaryRow(
                  label: l.recurringInvoicesEndLabel,
                  value: endType == 'never'
                      ? l.recurringInvoicesEndNever
                      : endType == 'date' && endDate != null
                          ? DateFormat.yMMMd(l.localeName).format(endDate!)
                          : endType == 'count' &&
                                  countCtrl.text.trim().isNotEmpty
                              ? countCtrl.text.trim()
                              : l.recurringInvoicesEndNever,
                ),
                if (freq == 'monthly')
                  RecurringWizardSummaryRow(
                    label: l.recurringInvoicesBillDayLabel,
                    value: billDayCtrl.text.trim().isEmpty
                        ? '-'
                        : billDayCtrl.text.trim(),
                  ),
                if (freq == 'weekly')
                  RecurringWizardSummaryRow(
                    label: l.recurringInvoicesWeekDayLabel,
                    value: weekDayCtrl.text.trim().isEmpty
                        ? '-'
                        : weekDayCtrl.text.trim(),
                  ),
                RecurringWizardSummaryRow(
                  label: l.recurringInvoicesTimezoneLabel,
                  value: timezoneLabel,
                ),
                RecurringWizardSummaryRow(
                  label: l.recurringInvoicesExceptionsLabel,
                  value: exceptions.isEmpty
                      ? l.recurringInvoicesNoExceptions
                      : '${exceptions.length}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onLoadPreview,
            icon: loadingPreview
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calendar_today_outlined),
            label: Text(l.recurringInvoicesPreviewCta),
          ),
          const SizedBox(height: 12),
          if (previewDates.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: previewDates
                  .take(12)
                  .map(
                    (d) => Chip(
                      label: Text(d, style: t.bodySmall),
                      labelStyle: t.bodySmall,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
