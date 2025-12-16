import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class LineDraft {
  int position;
  final TextEditingController description = TextEditingController();
  final TextEditingController quantityCtrl = TextEditingController(text: '1');
  final TextEditingController unitPriceCtrl = TextEditingController();
  final TextEditingController taxRateCtrl = TextEditingController(text: '21');

  LineDraft({required this.position});

  InvoiceLine toLine() {
    final qty = num.tryParse(quantityCtrl.text.trim()) ?? 1;
    final price = num.tryParse(unitPriceCtrl.text.trim()) ?? 0;
    final tax = num.tryParse(taxRateCtrl.text.trim()) ?? 21;
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

  num? get quantity => num.tryParse(quantityCtrl.text.trim());
  num? get unitPrice => num.tryParse(unitPriceCtrl.text.trim());
  num? get taxRate => num.tryParse(taxRateCtrl.text.trim());

  void dispose() {
    description.dispose();
    quantityCtrl.dispose();
    unitPriceCtrl.dispose();
    taxRateCtrl.dispose();
  }
}

class InvoiceLinesEditor extends StatelessWidget {
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  const InvoiceLinesEditor(
      {super.key, required this.lines, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.invoiceLinesTitle,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            TextButton.icon(
              onPressed: () {
                final nextPos = lines.length + 1;
                lines.add(LineDraft(position: nextPos));
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: Text(l.invoiceAddLine),
            ),
          ],
        ),
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.invoiceLinesRequired,
              style: t.bodySmall.copyWith(color: cs.error),
            ),
          ),
        ...lines.map((line) {
          final idx = lines.indexOf(line);
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${line.position}',
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: cs.error,
                        tooltip: l.remove,
                        onPressed: () {
                          lines.removeAt(idx);
                          for (int i = 0; i < lines.length; i++) {
                            lines[i].position = i + 1;
                          }
                          onChanged();
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: line.description,
                    decoration: InputDecoration(
                      labelText: l.lineDescription,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => onChanged(),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.fieldIsRequired
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: line.quantityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: l.lineQuantity,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide:
                                  BorderSide(color: cs.primary, width: 1.5),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: line.unitPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: l.lineUnitPrice,
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide:
                                  BorderSide(color: cs.primary, width: 1.5),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          onChanged: (_) => onChanged(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: line.taxRateCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l.lineTaxRate,
                      suffixText: '%',
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: BorderSide(color: cs.primary, width: 1.5),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
