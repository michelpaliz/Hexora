import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_line_draft.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptLinesEditor extends StatelessWidget {
  final List<ReceiptLineDraft> lines;
  final bool canEdit;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  const ReceiptLinesEditor({
    super.key,
    required this.lines,
    required this.canEdit,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    const colDesc = 360.0;
    const colQty = 110.0;
    const colUnit = 140.0;
    const colTotal = 140.0;
    const colDelete = 44.0;
    const gap = 10.0;
    const minWidth = colDesc + colQty + colUnit + colTotal + colDelete + gap * 4;

    final headerStyle = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: minWidth),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: colDesc,
                  child: Text(l.lineDescription, style: headerStyle),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: colQty,
                  child: Text(
                    l.lineQuantity,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: colUnit,
                  child: Text(
                    l.lineUnitPrice,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: colTotal,
                  child: Text(
                    l.receiptLineTotalLabel,
                    style: headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: gap),
                SizedBox(
                  width: colDelete,
                  child: Text(
                    l.delete,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(lines.length, (i) {
              final line = lines[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: colDesc,
                      child: TextField(
                        controller: line.descriptionCtrl,
                        enabled: canEdit,
                        onChanged: (_) => onChanged(),
                        decoration: InputDecoration(
                          hintText: l.lineDescription,
                          filled: false,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: colQty,
                      child: TextField(
                        controller: line.qtyCtrl,
                        enabled: canEdit,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => onChanged(),
                        decoration: InputDecoration(
                          hintText: '1',
                          filled: false,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: colUnit,
                      child: TextField(
                        controller: line.unitCtrl,
                        enabled: canEdit,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        onChanged: (_) => onChanged(),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          filled: false,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: colTotal,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          filled: false,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            NumberFormat.simpleCurrency(name: '')
                                .format(line.total),
                            style:
                                t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: colDelete,
                      child: IconButton(
                        onPressed: (canEdit && lines.length > 1)
                            ? () => onRemove(i)
                            : null,
                        icon: const Icon(Icons.delete_outline),
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
