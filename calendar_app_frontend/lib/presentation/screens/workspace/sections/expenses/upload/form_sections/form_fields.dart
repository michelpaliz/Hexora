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
  final bool manualProvider;
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
    required this.manualProvider,
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: cs?.outlineVariant.withValues(alpha: 0.5) ?? Colors.white24,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: cs?.outlineVariant.withValues(alpha: 0.4) ?? Colors.white24,
          ),
        ),
        filled: true,
        fillColor: cs?.surfaceContainer,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 40),
        contentPadding: icon != null
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffix,
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

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Proveedor ──
                      sectionLabel(
                          l.expenseUploadVendorLabel, Icons.business_outlined),
                      providerPicker,
                      if (manualProvider) ...[
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
                      const SizedBox(height: 16),

                      // ── Factura ──
                      sectionLabel(
                          l.localeName.toLowerCase().startsWith('es')
                              ? 'Datos del gasto'
                              : 'Expense details',
                          Icons.receipt_outlined),
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
                        _ExpenseLocalizedDateField(
                          controller: issueDateController,
                          label: l.expenseUploadIssueDateLabel,
                          disabled: submitting,
                          onPick: onPickDate,
                        ),
                        _ExpenseLocalizedDateField(
                          controller: dueDateController,
                          label: l.expenseUploadDueDateLabel,
                          disabled: submitting,
                          onPick: onPickDate,
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Importes ──
                      sectionLabel(
                          l.localeName.toLowerCase().startsWith('es')
                              ? 'Impuestos y ajustes'
                              : 'Tax and adjustments',
                          Icons.calculate_outlined),
                      settlementFields,
                      const SizedBox(height: 8),
                      discountFields,
                      const SizedBox(height: 8),
                      withholdingFields,
                      const SizedBox(height: 12),
                      totalsFields,
                      const SizedBox(height: 16),

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

class _ExpenseLocalizedDateField extends StatelessWidget {
  const _ExpenseLocalizedDateField({
    required this.controller,
    required this.label,
    required this.disabled,
    required this.onPick,
  });

  final TextEditingController controller;
  final String label;
  final bool disabled;
  final ValueChanged<TextEditingController> onPick;

  String _displayDate(BuildContext context, DateTime date) {
    if (Localizations.localeOf(context).languageCode == 'es') {
      const months = <String>[
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sept',
        'oct',
        'nov',
        'dic',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final parsed = DateTime.tryParse(value.text.trim());
        final display = parsed == null
            ? ''
            : _displayDate(
                context,
                DateTime(parsed.year, parsed.month, parsed.day),
              );
        return InkWell(
          onTap: disabled ? null : () => onPick(controller),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            isEmpty: display.isEmpty,
            decoration: ExpenseFormFields._decor(
              label,
              icon: Icons.event_outlined,
              cs: cs,
              suffix: Icon(
                Icons.edit_calendar_outlined,
                size: 16,
                color: disabled
                    ? cs.onSurface.withValues(alpha: 0.38)
                    : cs.onSurfaceVariant,
              ),
            ),
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: disabled
                    ? cs.onSurface.withValues(alpha: 0.38)
                    : cs.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}
