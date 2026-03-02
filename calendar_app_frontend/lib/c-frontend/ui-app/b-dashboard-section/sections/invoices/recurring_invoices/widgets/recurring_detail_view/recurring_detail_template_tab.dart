import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/summary/summary_lines_and_totals.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_section_card.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringDetailTemplateTab extends StatelessWidget {
  final TextEditingController currencyCtrl;
  final TextEditingController notesCtrl;
  final List<LineDraft> lines;
  final VoidCallback onLinesChanged;
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
  final bool canManage;
  final bool saving;
  final VoidCallback onSave;
  final bool showTax;

  const RecurringDetailTemplateTab({
    super.key,
    required this.currencyCtrl,
    required this.notesCtrl,
    required this.lines,
    required this.onLinesChanged,
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
    required this.canManage,
    required this.saving,
    required this.onSave,
    this.showTax = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    InputDecoration fieldDecoration({required String label, IconData? icon}) {
      return InputDecoration(
        labelText: label,
        labelStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
        prefixIcon: icon == null ? null : Icon(icon),
        isDense: true,
        filled: true,
        fillColor: cs.surface,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) {
              final headerCard = RecurringDetailSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          l.recurringInvoicesTemplateTab,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currencyCtrl,
                      enabled: canManage,
                      style: t.bodyMedium,
                      decoration: fieldDecoration(
                        label: l.currencyLabel,
                        icon: Icons.currency_exchange_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
                      enabled: canManage,
                      maxLines: 2,
                      style: t.bodyMedium,
                      decoration: fieldDecoration(
                        label: l.notesLabel,
                        icon: Icons.sticky_note_2_outlined,
                      ),
                    ),
                  ],
                ),
              );

              final linesEditor = InvoiceLinesEditor(
                lines: lines,
                onChanged: onLinesChanged,
                compactable: true,
                initiallyCollapsed: false,
                showTax: showTax,
              );

              final totalsCard = RecurringDetailSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.summarize_outlined, color: cs.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          l.invoiceTotalsTitle,
                          style: t.bodySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerCard,
                  const SizedBox(height: 12),
                  Text(
                    'Descuento',
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Importe fijo (EUR)'),
                        selected: !useDiscountPercent,
                        onSelected: canManage
                            ? (_) => onDiscountModeChanged(false)
                            : null,
                      ),
                      ChoiceChip(
                        label: const Text('Porcentaje (%)'),
                        selected: useDiscountPercent,
                        onSelected: canManage
                            ? (_) => onDiscountModeChanged(true)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: discountAmountCtrl,
                          enabled: canManage && !useDiscountPercent,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Importe fijo (EUR)',
                            hintText: '0.00',
                            errorText: amountErrorText,
                          ),
                          onChanged: (_) => onLinesChanged(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: discountPercentCtrl,
                          enabled: canManage && useDiscountPercent,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Porcentaje (%)',
                            hintText: '0.00',
                            errorText: percentErrorText,
                          ),
                          onChanged: (_) => onLinesChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'El descuento se aplica antes de IVA.',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  linesEditor,
                  const SizedBox(height: 8),
                  totalsCard,
                  const SizedBox(height: 8),
                  if (canManage)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving ? null : onSave,
                        child: Text(
                          saving
                              ? l.recurringInvoicesSavingTemplate
                              : l.recurringInvoicesSaveTemplateCta,
                        ),
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

