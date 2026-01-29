import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/summary/summary_lines_and_totals.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_create_wizard/recurring_wizard_section_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringWizardTemplateStep extends StatelessWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  final num subtotal;
  final num tax;
  final num total;

  const RecurringWizardTemplateStep({
    super.key,
    required this.lines,
    required this.onChanged,
    required this.subtotal,
    required this.tax,
    required this.total,
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
          InvoiceLinesEditor(lines: lines, onChanged: onChanged),
          const SizedBox(height: 12),
          InvoiceSummaryLinesAndTotals(
            lines: lines,
            subtotal: subtotal,
            tax: tax,
            total: total,
          ),
        ],
      ),
    );
  }
}
