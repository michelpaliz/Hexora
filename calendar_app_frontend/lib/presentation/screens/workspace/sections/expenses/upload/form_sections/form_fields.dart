import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseFormFields extends StatelessWidget {
  final String groupName;
  final String groupId;
  final Widget providerPicker;
  final TextEditingController vendorController;
  final TextEditingController issueDateController;
  final TextEditingController vendorTaxIdController;
  final TextEditingController invoiceNumberController;
  final TextEditingController dueDateController;
  final TextEditingController currencyController;
  final TextEditingController notesController;
  final TextEditingController clientIdController;
  final Widget settlementFields;
  final Widget discountFields;
  final Widget withholdingFields;
  final Widget totalsFields;
  final Widget linesEditor;
  final Widget vatBreakdown;
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
    required this.vendorTaxIdController,
    required this.invoiceNumberController,
    required this.dueDateController,
    required this.currencyController,
    required this.notesController,
    required this.clientIdController,
    required this.settlementFields,
    required this.discountFields,
    required this.withholdingFields,
    required this.totalsFields,
    required this.linesEditor,
    required this.vatBreakdown,
    required this.hasLines,
    required this.submitting,
    required this.onPickDate,
  });

  static const _fieldStyle = TextStyle(fontSize: 13);

  static InputDecoration _decor(
    String label, {
    IconData? icon,
    Widget? suffix,
    ColorScheme? cs,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon != null ? Icon(icon, size: 16) : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: cs?.outlineVariant.withValues(alpha: 0.5) ?? Colors.white24,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: cs?.outlineVariant.withValues(alpha: 0.4) ?? Colors.white24,
          ),
        ),
        filled: true,
        fillColor: cs?.surfaceContainer,
        isDense: true,
        contentPadding: icon != null
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffix,
      );

  static InputDecoration _dateDecor(
    String label, {
    required TextEditingController controller,
    required bool disabled,
    required ValueChanged<TextEditingController> onPick,
    required ColorScheme cs,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: const Icon(Icons.event_outlined, size: 16),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        filled: true,
        fillColor: cs.surfaceContainer,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(Icons.edit_calendar_outlined,
              size: 16, color: cs.onSurfaceVariant),
          onPressed: disabled ? null : () => onPick(controller),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 440;
                const gap = SizedBox(height: 8);
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

                Widget sectionLabel(String text, IconData icon) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(icon,
                              size: 12,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(width: 5),
                          Text(
                            text.toUpperCase(),
                            style: ts.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    );

                Widget sectionCard({
                  required String title,
                  required String subtitle,
                  required IconData icon,
                  required Widget child,
                  bool childProvidesHeader = false,
                }) =>
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!childProvidesHeader) ...[
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer
                                        .withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      Icon(icon, size: 19, color: cs.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: ts.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          )),
                                      const SizedBox(height: 2),
                                      Text(subtitle,
                                          style: ts.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 11,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                          child,
                        ],
                      ),
                    );

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Proveedor ──
                      sectionCard(
                        title: l.expenseUploadVendorLabel,
                        subtitle: '',
                        icon: Icons.business_outlined,
                        childProvidesHeader: true,
                        child: Column(
                          children: [
                            providerPicker,
                            gap,
                            row([
                              TextField(
                                controller: vendorController,
                                style: _fieldStyle,
                                decoration: _decor(
                                  l.expenseUploadVendorLabel,
                                  icon: Icons.storefront_outlined,
                                  cs: cs,
                                ),
                              ),
                              TextField(
                                controller: vendorTaxIdController,
                                style: _fieldStyle,
                                decoration: _decor(
                                  l.expenseUploadVendorTaxIdLabel,
                                  icon: Icons.badge_outlined,
                                  cs: cs,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Factura ──
                      sectionCard(
                        title: l.localeName.toLowerCase().startsWith('es')
                            ? 'Datos de factura'
                            : 'Invoice details',
                        subtitle: l.localeName.toLowerCase().startsWith('es')
                            ? 'Introduce los datos principales de la factura.'
                            : 'Enter the main invoice details.',
                        icon: Icons.receipt_outlined,
                        child: Column(
                          children: [
                            row([
                              TextField(
                                controller: invoiceNumberController,
                                style: _fieldStyle,
                                decoration: _decor(
                                  l.expenseUploadInvoiceNumberLabel,
                                  icon: Icons.tag_outlined,
                                  cs: cs,
                                ),
                              ),
                              TextField(
                                controller: currencyController,
                                style: _fieldStyle,
                                decoration: _decor(
                                  l.expenseUploadCurrencyLabel,
                                  icon: Icons.euro_outlined,
                                  cs: cs,
                                ),
                              ),
                            ]),
                            gap,
                            row([
                              TextField(
                                controller: issueDateController,
                                style: _fieldStyle,
                                decoration: _dateDecor(
                                  l.expenseUploadIssueDateLabel,
                                  controller: issueDateController,
                                  disabled: submitting,
                                  onPick: onPickDate,
                                  cs: cs,
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
                                  cs: cs,
                                ),
                                readOnly: true,
                                enableInteractiveSelection: false,
                                onTap: submitting
                                    ? null
                                    : () => onPickDate(dueDateController),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Importes ──
                      sectionCard(
                        title: l.localeName.toLowerCase().startsWith('es')
                            ? 'Importes y ajustes'
                            : 'Amounts and adjustments',
                        subtitle: l.localeName.toLowerCase().startsWith('es')
                            ? 'Selecciona el tipo de gasto y aplica los ajustes necesarios.'
                            : 'Select the expense type and apply any adjustments.',
                        icon: Icons.calculate_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            settlementFields,
                            const SizedBox(height: 10),
                            discountFields,
                            const SizedBox(height: 10),
                            withholdingFields,
                            const SizedBox(height: 14),
                            totalsFields,
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Notas ──
                      sectionLabel(
                          l.expenseUploadNotesLabel, Icons.notes_outlined),
                      TextField(
                        controller: notesController,
                        style: _fieldStyle,
                        decoration: _decor(
                          l.expenseUploadNotesLabel,
                          icon: Icons.notes_outlined,
                          cs: cs,
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 14),

                      // ── Líneas ──
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
