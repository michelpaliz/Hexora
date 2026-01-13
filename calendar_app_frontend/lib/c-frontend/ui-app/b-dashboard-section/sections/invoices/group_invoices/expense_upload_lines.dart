import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_models.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseLinesEditor extends StatelessWidget {
  final List<ExpenseLineDraft> lines;
  final VoidCallback onAddLine;
  final ValueChanged<int> onRemoveLine;
  final VoidCallback onLinesChanged;

  const ExpenseLinesEditor({
    super.key,
    required this.lines,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onLinesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return ExpansionTile(
      title: Text(l.expenseUploadLinesTitle, style: t.bodyMedium),
      childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      children: [
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l.expenseUploadLinesEmpty, style: t.bodySmall),
          )
        else
          Column(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                _ExpenseLineCard(
                  line: lines[i],
                  index: i + 1,
                  onRemove: () => onRemoveLine(i),
                  onChanged: onLinesChanged,
                ),
                if (i != lines.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAddLine,
            icon: const Icon(Icons.add),
            label: Text(l.expenseUploadLinesAddCta),
          ),
        ),
      ],
    );
  }
}

class _ExpenseLineCard extends StatefulWidget {
  final ExpenseLineDraft line;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExpenseLineCard({
    required this.line,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ExpenseLineCard> createState() => _ExpenseLineCardState();
}

class _ExpenseLineCardState extends State<_ExpenseLineCard> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.expenseUploadLinesItemLabel} ${widget.index}',
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: l.remove,
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.line.descriptionController,
              decoration: InputDecoration(
                labelText: l.expenseUploadLinesDescriptionLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) {
                setState(() {});
                widget.onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.line.quantityController,
                    decoration: InputDecoration(
                      labelText: l.expenseUploadLinesQuantityLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.line.unitPriceController,
                    decoration: InputDecoration(
                      labelText: l.expenseUploadLinesUnitPriceLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.line.taxRateController,
                    decoration: InputDecoration(
                      labelText: l.expenseUploadLinesTaxRateLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _LinePill(
                  label: l.expenseUploadLinesSubtotalLabel,
                  value: widget.line.subtotal.toStringAsFixed(2),
                ),
                _LinePill(
                  label: l.expenseUploadLinesTaxLabel,
                  value: widget.line.taxAmount.toStringAsFixed(2),
                ),
                _LinePill(
                  label: l.expenseUploadLinesTotalLabel,
                  value: widget.line.total.toStringAsFixed(2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePill extends StatelessWidget {
  final String label;
  final String value;

  const _LinePill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
