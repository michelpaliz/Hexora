import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Compact, state-preserving workspace used by the manual expense upload.
/// The supplied field widgets retain the existing upload calculations and API
/// behaviour; this widget only groups them into the same three areas as the
/// expense editor.
class ManualExpenseTabbedForm extends StatefulWidget {
  final Widget providerPicker;
  final TextEditingController vendorController;
  final TextEditingController vendorTaxIdController;
  final TextEditingController invoiceNumberController;
  final TextEditingController currencyController;
  final TextEditingController issueDateController;
  final TextEditingController dueDateController;
  final TextEditingController notesController;
  final Widget settlementFields;
  final Widget discountFields;
  final Widget withholdingFields;
  final Widget totalsFields;
  final Widget linesEditor;
  final Widget vatBreakdown;
  final bool manualProvider;
  final bool submitting;
  final int lineCount;
  final ValueChanged<TextEditingController> onPickDate;

  const ManualExpenseTabbedForm({
    super.key,
    required this.providerPicker,
    required this.vendorController,
    required this.vendorTaxIdController,
    required this.invoiceNumberController,
    required this.currencyController,
    required this.issueDateController,
    required this.dueDateController,
    required this.notesController,
    required this.settlementFields,
    required this.discountFields,
    required this.withholdingFields,
    required this.totalsFields,
    required this.linesEditor,
    required this.vatBreakdown,
    required this.manualProvider,
    required this.submitting,
    required this.lineCount,
    required this.onPickDate,
  });

  @override
  State<ManualExpenseTabbedForm> createState() =>
      _ManualExpenseTabbedFormState();
}

enum _ManualExpenseFormTab { general, amounts, lines }

class _ManualExpenseTabbedFormState extends State<ManualExpenseTabbedForm> {
  _ManualExpenseFormTab _activeTab = _ManualExpenseFormTab.general;

  static const _fieldStyle = TextStyle(fontSize: 13);

  InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: icon == null ? null : Icon(icon, size: 16),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: .4)),
        ),
        filled: true,
        fillColor: cs.surfaceContainer,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 40),
        contentPadding: icon == null
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      );

  String _dateLabel(BuildContext context, String raw) {
    final date = DateTime.tryParse(raw.trim());
    if (date == null) return '';
    return MaterialLocalizations.of(context)
        .formatMediumDate(DateTime(date.year, date.month, date.day));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    const gap = SizedBox(height: 8);

    Widget label(String text, IconData icon) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Icon(icon, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(text.toUpperCase(),
                style: ts.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                  letterSpacing: .8,
                )),
          ]),
        );

    Widget dateField(TextEditingController controller, String fieldLabel) =>
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => InkWell(
            onTap:
                widget.submitting ? null : () => widget.onPickDate(controller),
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              isEmpty: _dateLabel(context, value.text).isEmpty,
              decoration: _decor(fieldLabel, cs, icon: Icons.event_outlined),
              child: Text(
                _dateLabel(context, value.text),
                style: _fieldStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );

    Widget content(List<Widget> children) => ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: children,
        );

    Widget general = LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 440;
      Widget row(Widget first, Widget second) => wide
          ? Row(children: [
              Expanded(child: first),
              const SizedBox(width: 8),
              Expanded(child: second)
            ])
          : Column(children: [first, gap, second]);
      return content([
        label(l.expenseUploadVendorLabel, Icons.business_outlined),
        widget.providerPicker,
        if (widget.manualProvider) ...[
          gap,
          row(
            TextField(
                controller: widget.vendorController,
                style: _fieldStyle,
                decoration: _decor(l.expenseUploadVendorLabel, cs,
                    icon: Icons.storefront_outlined)),
            TextField(
                controller: widget.vendorTaxIdController,
                style: _fieldStyle,
                decoration: _decor(l.expenseUploadVendorTaxIdLabel, cs,
                    icon: Icons.badge_outlined)),
          ),
        ],
        const SizedBox(height: 14),
        label(
            l.localeName.startsWith('es')
                ? 'Datos del gasto'
                : 'Expense details',
            Icons.receipt_outlined),
        row(
          TextField(
              controller: widget.invoiceNumberController,
              style: _fieldStyle,
              decoration: _decor(l.expenseUploadInvoiceNumberLabel, cs,
                  icon: Icons.tag_outlined)),
          TextField(
              controller: widget.currencyController,
              style: _fieldStyle,
              decoration: _decor(l.expenseUploadCurrencyLabel, cs,
                  icon: Icons.euro_outlined)),
        ),
        gap,
        row(
          dateField(widget.issueDateController, l.expenseUploadIssueDateLabel),
          dateField(widget.dueDateController, l.expenseUploadDueDateLabel),
        ),
        const SizedBox(height: 14),
        label('Tipo de gasto', Icons.tune_outlined),
        widget.settlementFields,
        const SizedBox(height: 14),
        label(l.expenseUploadNotesLabel, Icons.notes_outlined),
        TextField(
          controller: widget.notesController,
          style: _fieldStyle,
          decoration:
              _decor(l.expenseUploadNotesLabel, cs, icon: Icons.notes_outlined),
          maxLines: 2,
          minLines: 1,
        ),
      ]);
    });

    final amounts = content([
      widget.discountFields,
      const SizedBox(height: 6),
      widget.withholdingFields,
      const SizedBox(height: 10),
      widget.totalsFields,
      const SizedBox(height: 8),
      widget.vatBreakdown,
    ]);
    final lines = content([widget.linesEditor]);

    Widget tab(_ManualExpenseFormTab tab, IconData icon, String text) {
      final selected = _activeTab == tab;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            onTap: () => setState(() => _activeTab = tab),
            borderRadius: BorderRadius.circular(7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: .12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: selected
                    ? Border.all(color: cs.primary.withValues(alpha: .55))
                    : null,
              ),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 15),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(text,
                        overflow: TextOverflow.ellipsis,
                        style: ts.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700))),
              ]),
            ),
          ),
        ),
      );
    }

    final current = switch (_activeTab) {
      _ManualExpenseFormTab.general => general,
      _ManualExpenseFormTab.amounts => amounts,
      _ManualExpenseFormTab.lines => lines,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .35),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          tab(_ManualExpenseFormTab.general, Icons.description_outlined,
              'General'),
          tab(_ManualExpenseFormTab.amounts, Icons.calculate_outlined,
              'Importes'),
          tab(_ManualExpenseFormTab.lines, Icons.view_list_outlined,
              'Líneas (${widget.lineCount})'),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(child: current),
    ]);
  }
}
