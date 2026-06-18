import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_models.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/form_helpers.dart';
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
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Theme(
      // Remove default ExpansionTile dividers
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          leading: Icon(
            Icons.list_alt_outlined,
            size: 14,
            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          title: Row(
            children: [
              Text(
                l.expenseUploadLinesTitle.toUpperCase(),
                style: ts.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                  letterSpacing: 0.8,
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${lines.length}',
                    style: ts.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          children: [
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),
            if (lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.expenseUploadLinesEmpty,
                      style: ts.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
                    if (i != lines.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onAddLine,
                icon: const Icon(Icons.add, size: 15),
                label: Text(l.expenseUploadLinesAddCta),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line card ─────────────────────────────────────────────────────────────────

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
  static InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        prefixIcon: icon != null ? Icon(icon, size: 14) : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 32),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: cs.primary.withValues(alpha: 0.6)),
        ),
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.6),
        isDense: true,
        contentPadding: icon != null
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final line = widget.line;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${l.expenseUploadLinesItemLabel} ${widget.index}',
                    style: ts.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: l.remove,
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Description ──────────────────────────────
                TextField(
                  controller: line.descriptionController,
                  style: const TextStyle(fontSize: 13),
                  decoration: _decor(
                    l.expenseUploadLinesDescriptionLabel,
                    cs,
                    icon: Icons.label_outline,
                  ),
                  onChanged: (_) {
                    setState(() {});
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 8),

                // ── Qty · Base · IVA% ─────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: line.quantityController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _decor(
                          l.expenseUploadLinesQuantityLabel,
                          cs,
                          icon: Icons.numbers_outlined,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          line.onPricingChanged();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: line.baseUnitPriceController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _decor(
                          'Precio base',
                          cs,
                          icon: Icons.euro_outlined,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          line.onPricingChanged();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: line.taxRateController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _decor(
                          l.expenseUploadLinesTaxRateLabel,
                          cs,
                          icon: Icons.percent_outlined,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          line.onPricingChanged();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Discounts ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: line.discountPercentController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _decor(
                          'Descuento %',
                          cs,
                          icon: Icons.discount_outlined,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          line.onDiscountPercentChanged();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: line.discountAmountController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _decor(
                          'Descuento €',
                          cs,
                          icon: Icons.remove_circle_outline,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          line.onDiscountAmountChanged();
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Summary strip ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label: l.expenseUploadLinesSubtotalLabel,
                        value: ExpenseFormHelpers.formatAmount(line.subtotal),
                        cs: cs,
                        ts: ts,
                      ),
                      _Dot(cs: cs),
                      _SummaryChip(
                        label: l.expenseUploadLinesTaxLabel,
                        value: ExpenseFormHelpers.formatAmount(line.taxAmount),
                        cs: cs,
                        ts: ts,
                      ),
                      _Dot(cs: cs),
                      _SummaryChip(
                        label: l.expenseUploadLinesTotalLabel,
                        value: ExpenseFormHelpers.formatAmount(line.total),
                        cs: cs,
                        ts: ts,
                        highlight: true,
                      ),
                      if (line.hasDiscount) ...[
                        _Dot(cs: cs),
                        _SummaryChip(
                          label: 'Dto',
                          value:
                              '${ExpenseFormHelpers.formatAmount(line.discountAmount)} (${line.discountPercent.toStringAsFixed(1)}%)',
                          cs: cs,
                          ts: ts,
                          isDiscount: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary helpers ───────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme ts;
  final bool highlight;
  final bool isDiscount;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.cs,
    required this.ts,
    this.highlight = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = isDiscount
        ? cs.error
        : highlight
            ? cs.primary
            : cs.onSurface;
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: ts.bodySmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant.withValues(alpha: 0.55),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: ts.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final ColorScheme cs;
  const _Dot({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
