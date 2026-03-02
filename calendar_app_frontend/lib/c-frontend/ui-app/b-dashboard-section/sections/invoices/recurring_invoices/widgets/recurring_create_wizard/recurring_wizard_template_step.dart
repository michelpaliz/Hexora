import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/summary/summary_lines_and_totals.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_section_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringWizardTemplateStep extends StatelessWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  final TextEditingController discountAmountCtrl;
  final TextEditingController discountPercentCtrl;
  final bool useDiscountPercent;
  final ValueChanged<bool> onDiscountModeChanged;
  final num rawSubtotal;
  final num discountAmount;
  final num subtotal;
  final num tax;
  final num total;
  final String? amountErrorText;
  final String? percentErrorText;
  final bool showTax;

  const RecurringWizardTemplateStep({
    super.key,
    required this.lines,
    required this.onChanged,
    required this.discountAmountCtrl,
    required this.discountPercentCtrl,
    required this.useDiscountPercent,
    required this.onDiscountModeChanged,
    required this.rawSubtotal,
    required this.discountAmount,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.amountErrorText,
    this.percentErrorText,
    this.showTax = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return RecurringWizardSectionCard(
      title: l.recurringInvoicesStepTemplate,
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Descuento',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Importe fijo (EUR)'),
                selected: !useDiscountPercent,
                onSelected: (_) => onDiscountModeChanged(false),
              ),
              ChoiceChip(
                label: const Text('Porcentaje (%)'),
                selected: useDiscountPercent,
                onSelected: (_) => onDiscountModeChanged(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: discountAmountCtrl,
                  enabled: !useDiscountPercent,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Importe fijo (EUR)',
                    hintText: '0.00',
                    errorText: amountErrorText,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: discountPercentCtrl,
                  enabled: useDiscountPercent,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Porcentaje (%)',
                    hintText: '0.00',
                    errorText: percentErrorText,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'El descuento se aplica antes de IVA.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          InvoiceLinesEditor(
            lines: lines,
            onChanged: onChanged,
            showTax: showTax,
          ),
          const SizedBox(height: 12),
          InvoiceSummaryLinesAndTotals(
            lines: lines,
            partialSubtotal: rawSubtotal,
            discountAmount: discountAmount,
            taxableBase: subtotal,
            subtotal: subtotal,
            tax: tax,
            total: total,
            showTax: showTax,
          ),
        ],
      ),
    );
  }
}

