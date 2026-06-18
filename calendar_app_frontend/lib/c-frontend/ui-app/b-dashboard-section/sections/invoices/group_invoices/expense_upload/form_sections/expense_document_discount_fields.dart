import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_models.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/form_helpers.dart';

class _ExpenseDiscountTypeScale {
  static const fieldLabel = 12.0;
  static const fieldValue = 13.0;
  static const helper = 12.0;
}

class ExpenseDocumentDiscountFields extends StatelessWidget {
  final ExpenseDocumentDiscountDraft discount;
  final bool enabled;
  final VoidCallback onChanged;
  final ExpenseDocumentDiscountPreview? preview;
  final String? helperError;
  final bool compactSummary;

  const ExpenseDocumentDiscountFields({
    super.key,
    required this.discount,
    required this.enabled,
    required this.onChanged,
    this.preview,
    this.helperError,
    this.compactSummary = false,
  });

  InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: _ExpenseDiscountTypeScale.fieldLabel),
      prefixIcon: icon == null ? null : Icon(icon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.18),
      isDense: true,
      contentPadding: icon != null
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final activePreview = preview;
    final subtotalHint = activePreview?.subtotalBeforeDiscount ?? 0;
    final showDiscount = activePreview != null &&
        (activePreview.discountAmount > 0.0001 ||
            activePreview.discountPercent > 0.0001);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 180,
              child: TextField(
                controller: discount.discountAmountController,
                enabled: enabled,
                style: const TextStyle(
                  fontSize: _ExpenseDiscountTypeScale.fieldValue,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decor(
                  'Descuento total',
                  cs,
                  icon: Icons.remove_circle_outline,
                ),
                onChanged: (_) {
                  discount.onDiscountAmountChanged(subtotalHint);
                  onChanged();
                },
              ),
            ),
            SizedBox(
              width: 160,
              child: TextField(
                controller: discount.discountPercentController,
                enabled: enabled,
                style: const TextStyle(
                  fontSize: _ExpenseDiscountTypeScale.fieldValue,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decor(
                  'Descuento %',
                  cs,
                  icon: Icons.percent_outlined,
                ),
                onChanged: (_) {
                  discount.onDiscountPercentChanged(subtotalHint);
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Puedes editar importe o porcentaje. El otro valor se sincroniza para facilitar la revision.',
          style: ts.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: _ExpenseDiscountTypeScale.helper,
          ),
        ),
        if (showDiscount) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
            ),
            child: compactSummary
                ? Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _DiscountSummaryChip(
                        label: 'Subtotal',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.subtotalBeforeDiscount,
                        ),
                        cs: cs,
                      ),
                      _DiscountSummaryChip(
                        label: 'Descuento',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.discountAmount,
                        ),
                        cs: cs,
                        highlight: true,
                      ),
                      _DiscountSummaryChip(
                        label: 'Base tras descuento',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.taxableBase,
                        ),
                        cs: cs,
                      ),
                      _DiscountSummaryChip(
                        label: 'IVA',
                        value:
                            ExpenseFormHelpers.formatAmount(activePreview.tax),
                        cs: cs,
                      ),
                      _DiscountSummaryChip(
                        label: 'Total',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.total,
                        ),
                        cs: cs,
                        accent: true,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen del descuento',
                        style: ts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _DiscountSummaryChip(
                            label: 'Subtotal antes de descuento',
                            value: ExpenseFormHelpers.formatAmount(
                              activePreview.subtotalBeforeDiscount,
                            ),
                            cs: cs,
                          ),
                          _DiscountSummaryChip(
                            label: 'Descuento',
                            value:
                                '${ExpenseFormHelpers.formatAmount(activePreview.discountAmount)} · ${activePreview.discountPercent.toStringAsFixed(2)}%',
                            cs: cs,
                            highlight: true,
                          ),
                          _DiscountSummaryChip(
                            label: 'Base tras descuento',
                            value: ExpenseFormHelpers.formatAmount(
                              activePreview.taxableBase,
                            ),
                            cs: cs,
                          ),
                          _DiscountSummaryChip(
                            label: 'IVA',
                            value: ExpenseFormHelpers.formatAmount(
                                activePreview.tax),
                            cs: cs,
                          ),
                          _DiscountSummaryChip(
                            label: 'Total',
                            value: ExpenseFormHelpers.formatAmount(
                              activePreview.total,
                            ),
                            cs: cs,
                            accent: true,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
        if ((helperError ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            helperError!,
            style: ts.bodySmall?.copyWith(color: cs.error),
          ),
        ],
      ],
    );
  }
}

class _DiscountSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;
  final bool accent;

  const _DiscountSummaryChip({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    final foreground = accent
        ? cs.primary
        : highlight
            ? cs.error
            : cs.onSurface;
    final background = accent
        ? cs.primary.withValues(alpha: 0.10)
        : highlight
            ? cs.errorContainer.withValues(alpha: 0.25)
            : cs.surface.withValues(alpha: 0.5);
    final borderColor = accent
        ? cs.primary.withValues(alpha: 0.35)
        : highlight
            ? cs.error.withValues(alpha: 0.35)
            : cs.outlineVariant.withValues(alpha: 0.28);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$label $value',
        style: ts.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
