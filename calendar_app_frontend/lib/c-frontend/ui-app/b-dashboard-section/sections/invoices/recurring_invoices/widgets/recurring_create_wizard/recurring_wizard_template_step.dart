import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';

class RecurringWizardTemplateStep extends StatelessWidget {
  final List<InvoiceBlockDraft> blocks;
  final VoidCallback onChanged;
  final TextEditingController discountAmountCtrl;
  final TextEditingController discountPercentCtrl;
  final bool useDiscountPercent;
  final ValueChanged<bool> onDiscountModeChanged;
  final num discountAmount;
  final num total;

  const RecurringWizardTemplateStep({
    super.key,
    required this.blocks,
    required this.onChanged,
    required this.discountAmountCtrl,
    required this.discountPercentCtrl,
    required this.useDiscountPercent,
    required this.onDiscountModeChanged,
    required this.discountAmount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return InvoiceContentSection(
      blocks: blocks,
      onChanged: onChanged,
      total: total,
      showSaveDraftButton: false,
      jsonImportDisabled: true,
      discountConfig: InvoiceContentDiscountConfig(
        readOnly: false,
        amountCtrl: discountAmountCtrl,
        percentCtrl: discountPercentCtrl,
        usePercent: useDiscountPercent,
        effectiveDiscountAmount: discountAmount,
        total: total,
        onModePercentChanged: onDiscountModeChanged,
        onAmountChanged: (_) => onChanged(),
        onPercentChanged: (_) => onChanged(),
      ),
    );
  }
}
