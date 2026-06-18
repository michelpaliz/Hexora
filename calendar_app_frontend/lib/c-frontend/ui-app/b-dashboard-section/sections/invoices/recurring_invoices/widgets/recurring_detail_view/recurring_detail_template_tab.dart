import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringDetailTemplateTab extends StatelessWidget {
  final TextEditingController currencyCtrl;
  final TextEditingController notesCtrl;
  final List<InvoiceBlockDraft> blocks;
  final VoidCallback onBlocksChanged;
  final TextEditingController discountAmountCtrl;
  final TextEditingController discountPercentCtrl;
  final bool useDiscountPercent;
  final ValueChanged<bool> onDiscountModeChanged;
  final num discountAmount;
  final num total;
  final bool canManage;
  final bool saving;
  final Future<void> Function() onSave;

  const RecurringDetailTemplateTab({
    super.key,
    required this.currencyCtrl,
    required this.notesCtrl,
    required this.blocks,
    required this.onBlocksChanged,
    required this.discountAmountCtrl,
    required this.discountPercentCtrl,
    required this.useDiscountPercent,
    required this.onDiscountModeChanged,
    required this.discountAmount,
    required this.total,
    required this.canManage,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: IgnorePointer(
            ignoring: !canManage,
            child: Opacity(
              opacity: canManage ? 1 : 0.7,
              child: InvoiceContentSection(
                blocks: blocks,
                onChanged: onBlocksChanged,
                total: total,
                discountConfig: InvoiceContentDiscountConfig(
                  readOnly: !canManage,
                  usePercent: useDiscountPercent,
                  amountCtrl: discountAmountCtrl,
                  percentCtrl: discountPercentCtrl,
                  effectiveDiscountAmount: discountAmount,
                  total: total,
                  onModePercentChanged: onDiscountModeChanged,
                  onAmountChanged: (_) => onBlocksChanged(),
                  onPercentChanged: (_) => onBlocksChanged(),
                ),
                onSaveDraft: onSave,
                savingDraft: saving,
                saveDraftLabel: l.recurringInvoicesSaveTemplateCta,
                jsonImportDisabled: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
