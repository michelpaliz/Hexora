import 'package:flutter/material.dart';
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
  final num subtotal;
  final num tax;
  final num total;
  final bool canManage;
  final bool saving;
  final VoidCallback onSave;

  const RecurringDetailTemplateTab({
    super.key,
    required this.currencyCtrl,
    required this.notesCtrl,
    required this.lines,
    required this.onLinesChanged,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.canManage,
    required this.saving,
    required this.onSave,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
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
                      style: t.bodyMedium,
                      decoration: fieldDecoration(
                        label: l.currencyLabel,
                        icon: Icons.currency_exchange_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notesCtrl,
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
              );

              final totals = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerCard,
                  const SizedBox(height: 12),
                  RecurringDetailSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.summarize_outlined, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              l.invoiceTotalsTitle,
                              style: t.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InvoiceSummaryLinesAndTotals(
                          lines: lines,
                          subtotal: subtotal,
                          tax: tax,
                          total: total,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
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

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerCard,
                    const SizedBox(height: 12),
                    linesEditor,
                    const SizedBox(height: 12),
                    totals,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: linesEditor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: totals),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
