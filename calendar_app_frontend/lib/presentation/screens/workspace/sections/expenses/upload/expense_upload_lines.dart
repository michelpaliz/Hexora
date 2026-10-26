import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/expense_upload_models.dart';
import 'package:hexora/presentation/screens/workspace/sections/expenses/upload/operations/form_helpers.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseLinesEditor extends StatefulWidget {
  final List<ExpenseLineDraft> lines;
  final VoidCallback onAddLine;
  final ValueChanged<int> onRemoveLine;
  final VoidCallback onLinesChanged;
  final bool compactWorkspace;

  const ExpenseLinesEditor({
    super.key,
    required this.lines,
    required this.onAddLine,
    required this.onRemoveLine,
    required this.onLinesChanged,
    this.compactWorkspace = false,
  });

  @override
  State<ExpenseLinesEditor> createState() => _ExpenseLinesEditorState();
}

class _ExpenseLinesEditorState extends State<ExpenseLinesEditor> {
  int? _expandedIndex = 0;

  @override
  void didUpdateWidget(covariant ExpenseLinesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.isEmpty) {
      _expandedIndex = null;
    } else if (widget.lines.length > oldWidget.lines.length) {
      _expandedIndex = widget.lines.length - 1;
    } else if ((_expandedIndex ?? 0) >= widget.lines.length) {
      _expandedIndex = widget.lines.length - 1;
    }
  }

  Widget _buildContents(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(Icons.inbox_outlined,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
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
          for (var i = 0; i < widget.lines.length; i++) ...[
            _ExpenseLineCard(
              key: ObjectKey(widget.lines[i]),
              line: widget.lines[i],
              index: i + 1,
              expanded: _expandedIndex == i,
              onToggle: () => setState(
                () => _expandedIndex = _expandedIndex == i ? null : i,
              ),
              onRemove: () {
                widget.onRemoveLine(i);
                setState(() {
                  if (widget.lines.isEmpty) {
                    _expandedIndex = null;
                  } else if ((_expandedIndex ?? 0) >= widget.lines.length) {
                    _expandedIndex = widget.lines.length - 1;
                  }
                });
              },
              onChanged: widget.onLinesChanged,
            ),
            if (i != widget.lines.length - 1) const SizedBox(height: 6),
          ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: widget.onAddLine,
            icon: const Icon(Icons.add, size: 15),
            label: Text(l.expenseUploadLinesAddCta),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;

    if (widget.compactWorkspace) return _buildContents(context);

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
              if (widget.lines.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.lines.length}',
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
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildContents(context),
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
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpenseLineCard({
    super.key,
    required this.line,
    required this.index,
    required this.onRemove,
    required this.onChanged,
    required this.expanded,
    required this.onToggle,
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
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.6)),
        ),
        filled: true,
        fillColor: cs.surfaceContainer,
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
          InkWell(
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 50,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.descriptionController.text.trim().isEmpty
                            ? l.expenseUploadLinesDescriptionLabel
                            : line.descriptionController.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: line.descriptionController.text.trim().isEmpty
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${ExpenseFormHelpers.formatAmount(line.quantity)} x ${ExpenseFormHelpers.formatAmount(line.baseUnitPrice)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ts.bodySmall?.copyWith(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 76,
                      child: Text(
                        ExpenseFormHelpers.formatAmount(line.total),
                        textAlign: TextAlign.right,
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
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
                    Icon(
                      widget.expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.expanded)
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                          value:
                              ExpenseFormHelpers.formatAmount(line.taxAmount),
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
