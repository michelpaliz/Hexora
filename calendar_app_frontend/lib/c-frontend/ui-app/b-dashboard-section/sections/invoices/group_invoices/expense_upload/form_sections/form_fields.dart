import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpenseFormFields extends StatelessWidget {
  final String groupName;
  final String groupId;
  final Widget providerPicker;
  final TextEditingController vendorController;
  final TextEditingController issueDateController;
  final TextEditingController totalController;
  final TextEditingController vendorTaxIdController;
  final TextEditingController invoiceNumberController;
  final TextEditingController dueDateController;
  final TextEditingController taxTotalController;
  final TextEditingController currencyController;
  final TextEditingController notesController;
  final TextEditingController clientIdController;
  final Widget linesEditor;
  final Widget vatBreakdown;
  final Widget summaryBar;
  final bool hasLines;
  final bool submitting;
  final ValueChanged<TextEditingController> onPickDate;

  const ExpenseFormFields({
    super.key,
    required this.groupName,
    required this.groupId,
    required this.providerPicker,
    required this.vendorController,
    required this.issueDateController,
    required this.totalController,
    required this.vendorTaxIdController,
    required this.invoiceNumberController,
    required this.dueDateController,
    required this.taxTotalController,
    required this.currencyController,
    required this.notesController,
    required this.clientIdController,
    required this.linesEditor,
    required this.vatBreakdown,
    required this.summaryBar,
    required this.hasLines,
    required this.submitting,
    required this.onPickDate,
  });

  static const _fieldStyle = TextStyle(fontSize: 13);

  static const _contentPad = EdgeInsets.symmetric(horizontal: 10, vertical: 8);

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  InputDecoration _decor(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: _border,
        isDense: true,
        contentPadding: _contentPad,
        suffixIcon: suffix,
      );

  InputDecoration _dateDecor(
    String label, {
    required TextEditingController controller,
    required bool disabled,
    required ValueChanged<TextEditingController> onPick,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: _border,
        isDense: true,
        contentPadding: _contentPad,
        suffixIcon: IconButton(
          icon: const Icon(Icons.event_outlined, size: 16),
          onPressed: disabled ? null : () => onPick(controller),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: summaryBar,
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 440;
                const gap = SizedBox(height: 6);
                const hGap = SizedBox(width: 8);

                Widget row(List<Widget> children) {
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0) gap,
                          children[i],
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < children.length; i++) ...[
                        if (i > 0) hGap,
                        Expanded(child: children[i]),
                      ],
                    ],
                  );
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Provider ---
                      providerPicker,
                      gap,
                      // --- Vendor + Tax ID ---
                      row([
                        TextField(
                          controller: vendorController,
                          style: _fieldStyle,
                          decoration:
                              _decor(l.expenseUploadVendorLabel),
                        ),
                        TextField(
                          controller: vendorTaxIdController,
                          style: _fieldStyle,
                          decoration:
                              _decor(l.expenseUploadVendorTaxIdLabel),
                        ),
                      ]),
                      gap,
                      // --- Invoice # + Currency ---
                      row([
                        TextField(
                          controller: invoiceNumberController,
                          style: _fieldStyle,
                          decoration:
                              _decor(l.expenseUploadInvoiceNumberLabel),
                        ),
                        TextField(
                          controller: currencyController,
                          style: _fieldStyle,
                          decoration:
                              _decor(l.expenseUploadCurrencyLabel),
                        ),
                      ]),
                      gap,
                      // --- Issue date + Due date ---
                      row([
                        TextField(
                          controller: issueDateController,
                          style: _fieldStyle,
                          decoration: _dateDecor(
                            l.expenseUploadIssueDateLabel,
                            controller: issueDateController,
                            disabled: submitting,
                            onPick: onPickDate,
                          ),
                          readOnly: true,
                          enableInteractiveSelection: false,
                          onTap: submitting
                              ? null
                              : () => onPickDate(issueDateController),
                        ),
                        TextField(
                          controller: dueDateController,
                          style: _fieldStyle,
                          decoration: _dateDecor(
                            l.expenseUploadDueDateLabel,
                            controller: dueDateController,
                            disabled: submitting,
                            onPick: onPickDate,
                          ),
                          readOnly: true,
                          enableInteractiveSelection: false,
                          onTap: submitting
                              ? null
                              : () => onPickDate(dueDateController),
                        ),
                      ]),
                      gap,
                      // --- Total + Tax ---
                      row([
                        TextField(
                          controller: totalController,
                          style: _fieldStyle,
                          decoration: _decor(l.expenseUploadTotalLabel),
                        ),
                        TextField(
                          controller: taxTotalController,
                          style: _fieldStyle,
                          decoration: _decor(l.expenseUploadTaxTotalLabel),
                        ),
                      ]),
                      gap,
                      // --- Notes ---
                      TextField(
                        controller: notesController,
                        style: _fieldStyle,
                        decoration: _decor(l.expenseUploadNotesLabel),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 8),
                      // --- Lines ---
                      linesEditor,
                      const SizedBox(height: 6),
                      vatBreakdown,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
