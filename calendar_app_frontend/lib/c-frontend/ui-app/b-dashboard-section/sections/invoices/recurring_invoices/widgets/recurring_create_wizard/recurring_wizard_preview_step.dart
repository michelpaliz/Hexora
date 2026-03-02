import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
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
  final List<Map<String, String>> previewRows;
  final VoidCallback onLoadPreview;
  final String issueDatePolicySummary;
  final num partialSubtotal;
  final num discountAmount;
  final num taxableBase;
  final num tax;
  final num total;
  final bool showTax;

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
    required this.previewRows,
    required this.onLoadPreview,
    required this.issueDatePolicySummary,
    required this.partialSubtotal,
    required this.discountAmount,
    required this.taxableBase,
    required this.tax,
    required this.total,
    this.showTax = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final money = NumberFormat.currency(locale: l.localeName, symbol: 'EUR');

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
                  value: recurringFrequencyLabel(l, freq),
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
                if (normalizeFrequencyFromApi(freq) == recurringFreqMonthly || normalizeFrequencyFromApi(freq) == recurringFreqBimensual || normalizeFrequencyFromApi(freq) == recurringFreqTrimestral)
                  RecurringWizardSummaryRow(
                    label: l.recurringInvoicesBillDayLabel,
                    value: billDayCtrl.text.trim().isEmpty
                        ? '-'
                        : billDayCtrl.text.trim(),
                  ),
                if (normalizeFrequencyFromApi(freq) == recurringFreqWeekly)
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
                  label: 'Politica fecha factura',
                  value: issueDatePolicySummary,
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
          RecurringWizardSectionCard(
            title: l.invoiceTotalsTitle,
            icon: Icons.summarize_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (discountAmount > 0) ...[
                  RecurringWizardSummaryRow(
                    label: 'Total parcial',
                    value: money.format(partialSubtotal),
                  ),
                  RecurringWizardSummaryRow(
                    label: 'Descuento',
                    value: '-${money.format(discountAmount)}',
                  ),
                  RecurringWizardSummaryRow(
                    label: 'Base imponible',
                    value: money.format(taxableBase),
                  ),
                ] else
                  RecurringWizardSummaryRow(
                    label: l.invoiceSubtotalLabel,
                    value: money.format(taxableBase),
                  ),
                if (showTax)
                  RecurringWizardSummaryRow(
                    label: l.invoiceTaxLabel,
                    value: money.format(tax),
                  ),
                RecurringWizardSummaryRow(
                  label: l.invoiceTotalLabel,
                  value: money.format(total),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ejemplos: "Ejecuta el 24 y factura el 28" / "Dia 31 con ajuste fin de mes".',
            style: t.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          if (previewRows.isNotEmpty)
            Column(
              children: previewRows.take(12).map((row) {
                final exec = row['executionAt'] ?? '-';
                final issue = row['issueDate'] ?? '-';
                final err = (row['error'] ?? '').trim();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '$exec -> $issue',
                          style: t.bodySmall,
                        ),
                      ),
                      if (err.isNotEmpty)
                        Expanded(
                          child: Text(
                            err,
                            textAlign: TextAlign.right,
                            style: t.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}


