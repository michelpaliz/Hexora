import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LineDraft {
  int position;
  String? id;
  String? evidenceBlobName;
  final TextEditingController description = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController(text: '1');
  final TextEditingController unitPriceCtrl = TextEditingController();
  final TextEditingController taxRateCtrl = TextEditingController(text: '21');
  final FocusNode quantityFocus = FocusNode();
  final FocusNode unitPriceFocus = FocusNode();

  LineDraft({
    required this.position,
    this.id,
    this.evidenceBlobName,
  });

  String _norm(String v) => v.trim().replaceAll(',', '.');

  InvoiceLine toLine() {
    final qty = num.tryParse(_norm(quantityCtrl.text)) ?? 1;
    final price = num.tryParse(_norm(unitPriceCtrl.text)) ?? 0;
    final tax = num.tryParse(_norm(taxRateCtrl.text)) ?? 21;
    return InvoiceLine(
      id: '',
      invoiceId: '',
      position: position,
      description: description.text.trim(),
      quantity: qty,
      unitPrice: price,
      taxRate: tax,
    );
  }

  num? get quantity => num.tryParse(_norm(quantityCtrl.text));
  num? get unitPrice => num.tryParse(_norm(unitPriceCtrl.text));
  num? get taxRate => num.tryParse(_norm(taxRateCtrl.text));

  void dispose() {
    description.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    taxRateCtrl.dispose();
    quantityFocus.dispose();
    unitPriceFocus.dispose();
  }
}

class InvoiceLinesEditor extends StatefulWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  final bool compactable;
  final bool initiallyCollapsed;
  final bool showTax;

  const InvoiceLinesEditor({
    super.key,
    required this.lines,
    required this.onChanged,
    this.compactable = false,
    this.initiallyCollapsed = false,
    this.showTax = true,
  });

  @override
  State<InvoiceLinesEditor> createState() => _InvoiceLinesEditorState();
}

class _InvoiceLinesEditorState extends State<InvoiceLinesEditor> {
  final Map<int, bool> _collapsedLines = {};
  final Set<LineDraft> _configuredLines = {};

  void _formatController(TextEditingController ctrl, {int decimals = 2}) {
    final raw = ctrl.text.trim();
    if (raw.isEmpty) return;
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) return;
    final formatted = parsed.toStringAsFixed(decimals);
    if (formatted == ctrl.text) return;
    ctrl.text = formatted;
    ctrl.selection = TextSelection.collapsed(offset: formatted.length);
    widget.onChanged();
  }

  void _ensureLineHandlers(LineDraft line) {
    if (_configuredLines.contains(line)) return;
    _configuredLines.add(line);
    line.quantityFocus.addListener(() {
      if (!line.quantityFocus.hasFocus) {
        _formatController(line.quantityCtrl);
      }
    });
    line.unitPriceFocus.addListener(() {
      if (!line.unitPriceFocus.hasFocus) {
        _formatController(line.unitPriceCtrl);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initiallyCollapsed) {
      for (final line in widget.lines) {
        _collapsedLines[line.position] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
    );
    final labelStyle = t.bodyMedium.copyWith(fontWeight: FontWeight.w700);
    final priceLabelStyle =
        labelStyle.copyWith(color: cs.primary, fontWeight: FontWeight.w800);
    final priceFill = cs.primaryContainer.withValues(alpha: 0.18);
    final currencySymbol = NumberFormat.simpleCurrency().currencySymbol;
    final currencyFormatter = NumberFormat.simpleCurrency(name: '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.invoiceLinesTitle,
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    final nextPos = widget.lines.length + 1;
                    widget.lines.add(LineDraft(position: nextPos));
                    if (widget.initiallyCollapsed) {
                      _collapsedLines[nextPos] = true;
                    }
                    widget.onChanged();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l.invoiceAddLine, style: t.bodyMedium),
                ),
              ],
            ),
          ],
        ),
        if (widget.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.invoiceLinesRequired,
              style: t.bodyMedium.copyWith(color: cs.error),
            ),
          ),
        ...widget.lines.map((line) {
          _ensureLineHandlers(line);
          final idx = widget.lines.indexOf(line);
          final isCollapsed =
              widget.compactable && (_collapsedLines[line.position] ?? false);
          final qty = line.quantity ?? 1;
          final unit = line.unitPrice ?? 0;
          final vat = line.taxRate ?? 21;
          final subtotal = qty * unit;
          final total =
              widget.showTax ? subtotal + (subtotal * (vat / 100)) : subtotal;
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${line.position}',
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        currencyFormatter.format(total),
                        style: t.bodySmall.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.compactable)
                      IconButton(
                        tooltip: isCollapsed
                            ? MaterialLocalizations.of(context)
                                .collapsedIconTapHint
                            : MaterialLocalizations.of(context)
                                .expandedIconTapHint,
                        onPressed: () {
                          setState(() {
                            _collapsedLines[line.position] = !isCollapsed;
                          });
                        },
                        icon: Icon(
                          isCollapsed
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: cs.error,
                      tooltip: l.remove,
                      onPressed: () {
                        widget.lines.removeAt(idx);
                        _collapsedLines.remove(line.position);
                        for (int i = 0; i < widget.lines.length; i++) {
                          widget.lines[i].position = i + 1;
                        }
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                if (!isCollapsed) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final compactWidth = wide ? 130.0 : double.infinity;

                      final descriptionField = TextFormField(
                        controller: line.description,
                        style: t.bodyMedium,
                        decoration: InputDecoration(
                          labelText: l.lineDescription,
                          labelStyle: labelStyle,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => widget.onChanged(),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l.fieldIsRequired
                            : null,
                      );

                      final quantityField = TextFormField(
                        controller: line.quantityCtrl,
                        focusNode: line.quantityFocus,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l.lineQuantity,
                          labelStyle: labelStyle,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );

                      final unitPriceField = TextFormField(
                        controller: line.unitPriceCtrl,
                        focusNode: line.unitPriceFocus,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l.lineUnitPrice,
                          labelStyle: priceLabelStyle,
                          filled: true,
                          fillColor: priceFill,
                          suffixText: currencySymbol,
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );

                      final taxField = TextFormField(
                        controller: line.taxRateCtrl,
                        style: t.bodyMedium,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l.lineTaxRate,
                          labelStyle: labelStyle,
                          suffixText: '%',
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        onChanged: (_) => widget.onChanged(),
                      );

                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            descriptionField,
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: quantityField),
                                const SizedBox(width: 10),
                                Expanded(child: unitPriceField),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (widget.showTax) taxField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: descriptionField),
                          const SizedBox(width: 12),
                          SizedBox(width: compactWidth, child: quantityField),
                          const SizedBox(width: 12),
                          SizedBox(width: compactWidth, child: unitPriceField),
                          if (widget.showTax) ...[
                            const SizedBox(width: 12),
                            SizedBox(width: compactWidth, child: taxField),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
