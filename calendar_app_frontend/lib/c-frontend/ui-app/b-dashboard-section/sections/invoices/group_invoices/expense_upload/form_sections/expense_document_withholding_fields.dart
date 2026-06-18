import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_models.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/form_helpers.dart';

class ExpenseDocumentWithholdingFields extends StatelessWidget {
  final ExpenseWithholdingDraft withholding;
  final bool enabled;
  final ExpenseWithholdingPreview? preview;
  final VoidCallback onChanged;
  final String? helperError;
  final bool compactSummary;

  const ExpenseDocumentWithholdingFields({
    super.key,
    required this.withholding,
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
      labelStyle: const TextStyle(fontSize: 12),
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
    final taxableBase = activePreview?.taxableBase ?? 0;
    final showSummary = activePreview?.hasWithholding ?? false;

    Widget choiceChip(ExpenseWithholdingType type) {
      final selected = withholding.type == type;
      return ChoiceChip(
        label: Text(type.labelEs),
        selected: selected,
        onSelected: enabled
            ? (_) {
                withholding.setType(type);
                withholding.syncDerivedFields(taxableBase);
                onChanged();
              }
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'RETENCION',
          style: ts.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            choiceChip(ExpenseWithholdingType.none),
            choiceChip(ExpenseWithholdingType.irpf),
            choiceChip(ExpenseWithholdingType.other),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'La retencion se descuenta del total bruto para calcular el importe liquido a pagar.',
          style: ts.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        if (withholding.enabled) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: withholding.percentController,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decor(
                    'Retencion %',
                    cs,
                    icon: Icons.percent_outlined,
                  ),
                  onChanged: (_) {
                    withholding.onPercentChanged(taxableBase);
                    onChanged();
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: withholding.amountController,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decor(
                    'Retencion €',
                    cs,
                    icon: Icons.remove_circle_outline,
                  ),
                  onChanged: (_) {
                    withholding.onAmountChanged(taxableBase);
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
        if (showSummary && activePreview != null) ...[
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
                      _WithholdingSummaryChip(
                        label: 'Base',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.taxableBase,
                        ),
                        cs: cs,
                      ),
                      _WithholdingSummaryChip(
                        label: 'Retencion',
                        value:
                            '${ExpenseFormHelpers.formatAmount(activePreview.amount)} · ${activePreview.percent.toStringAsFixed(2)}%',
                        cs: cs,
                        highlight: true,
                      ),
                      _WithholdingSummaryChip(
                        label: 'Total bruto',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.grossTotal,
                        ),
                        cs: cs,
                      ),
                      _WithholdingSummaryChip(
                        label: 'A pagar',
                        value: ExpenseFormHelpers.formatAmount(
                          activePreview.payableTotal,
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
                        'Resumen de retencion',
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
                          _WithholdingSummaryChip(
                            label: 'Base imponible',
                            value: ExpenseFormHelpers.formatAmount(
                              activePreview.taxableBase,
                            ),
                            cs: cs,
                          ),
                          _WithholdingSummaryChip(
                            label: 'Retencion',
                            value:
                                '${ExpenseFormHelpers.formatAmount(activePreview.amount)} · ${activePreview.percent.toStringAsFixed(2)}%',
                            cs: cs,
                            highlight: true,
                          ),
                          _WithholdingSummaryChip(
                            label: 'Total bruto',
                            value: ExpenseFormHelpers.formatAmount(
                              activePreview.grossTotal,
                            ),
                            cs: cs,
                          ),
                          _WithholdingSummaryChip(
                            label: 'Liquido a pagar',
                            value: ExpenseFormHelpers.formatAmount(
                              activePreview.payableTotal,
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

class _WithholdingSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;
  final bool accent;

  const _WithholdingSummaryChip({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    final color = accent
        ? cs.primary
        : highlight
            ? cs.tertiary
            : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: ts.bodySmall?.copyWith(
              fontSize: 10,
              color: cs.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: ts.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
