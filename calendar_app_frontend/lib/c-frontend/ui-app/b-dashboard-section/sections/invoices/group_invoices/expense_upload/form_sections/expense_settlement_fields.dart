import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_models.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/money_format_utils.dart';

class ExpenseSettlementTypeScale {
  static const fieldLabel = 12.0;
  static const fieldValue = 13.0;
  static const helper = 12.0;
}

class ExpenseSettlementFields extends StatelessWidget {
  final ExpenseSettlementDraft settlement;
  final List<ExpenseAdvanceOption> advanceOptions;
  final bool enabled;
  final ValueChanged<ExpenseDocumentType> onTypeChanged;
  final ValueChanged<String?> onAdvanceExpenseChanged;
  final VoidCallback onChanged;
  final String? helperError;

  const ExpenseSettlementFields({
    super.key,
    required this.settlement,
    required this.advanceOptions,
    required this.enabled,
    required this.onTypeChanged,
    required this.onAdvanceExpenseChanged,
    required this.onChanged,
    this.helperError,
  });

  InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: ExpenseSettlementTypeScale.fieldLabel),
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
    final selectedAdvance =
        advanceOptions.cast<ExpenseAdvanceOption?>().firstWhere(
              (option) => option?.id == settlement.selectedAdvanceExpenseId,
              orElse: () => null,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ExpenseDocumentType>(
          initialValue: settlement.expenseType,
          isExpanded: true,
          style: TextStyle(
            fontSize: ExpenseSettlementTypeScale.fieldValue,
            color: cs.onSurface,
          ),
          decoration:
              _decor('Tipo de gasto', cs, icon: Icons.category_outlined),
          items: ExpenseDocumentType.values
              .map(
                (type) => DropdownMenuItem<ExpenseDocumentType>(
                  value: type,
                  child: Text(
                    type.labelEs,
                    style: TextStyle(
                      fontSize: ExpenseSettlementTypeScale.fieldValue,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: enabled
              ? (nextType) {
                  if (nextType == null) return;
                  onTypeChanged(nextType);
                }
              : null,
        ),
        if (settlement.isAdvance) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 160,
                child: TextField(
                  controller: settlement.advancePercentController,
                  enabled: enabled,
                  style: const TextStyle(
                    fontSize: ExpenseSettlementTypeScale.fieldValue,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decor(
                    'Porcentaje',
                    cs,
                    icon: Icons.percent_outlined,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: settlement.projectBaseAmountController,
                  enabled: enabled,
                  style: const TextStyle(
                    fontSize: ExpenseSettlementTypeScale.fieldValue,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decor(
                    'Base del proyecto',
                    cs,
                    icon: Icons.request_quote_outlined,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: settlement.advanceTaxRateController,
                  enabled: enabled,
                  style: const TextStyle(
                    fontSize: ExpenseSettlementTypeScale.fieldValue,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decor(
                    'IVA %',
                    cs,
                    icon: Icons.percent_outlined,
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Usa estos campos si quieres registrar el anticipo con su porcentaje y base del proyecto.',
            style: ts.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: ExpenseSettlementTypeScale.helper,
            ),
          ),
        ],
        if (settlement.isFinal) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedAdvance == null
                ? null
                : settlement.selectedAdvanceExpenseId,
            isExpanded: true,
            style: TextStyle(
              fontSize: ExpenseSettlementTypeScale.fieldValue,
              color: cs.onSurface,
            ),
            decoration: _decor(
              'Anticipo relacionado',
              cs,
              icon: Icons.link_outlined,
            ),
            items: advanceOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option.id,
                    child: Text(
                      option.menuLabel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ExpenseSettlementTypeScale.fieldValue,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: enabled ? onAdvanceExpenseChanged : null,
          ),
          const SizedBox(height: 6),
          Text(
            advanceOptions.isEmpty
                ? 'No hay anticipos disponibles para este proveedor. Selecciona un proveedor con gastos de tipo anticipo.'
                : 'El backend descontara automaticamente el anticipo elegido cuando guardes la factura final.',
            style: ts.bodySmall?.copyWith(
              color: advanceOptions.isEmpty ? cs.error : cs.onSurfaceVariant,
              fontSize: ExpenseSettlementTypeScale.helper,
            ),
          ),
          if (selectedAdvance != null) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anticipo seleccionado',
                    style: ts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedAdvance.detailLabel,
                    style: ts.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _SettlementChip(
                        label: 'Base',
                        value:
                            formatMoneyEu(selectedAdvance.base, fallback: '-'),
                        cs: cs,
                      ),
                      _SettlementChip(
                        label: 'IVA',
                        value:
                            formatMoneyEu(selectedAdvance.tax, fallback: '-'),
                        cs: cs,
                      ),
                      _SettlementChip(
                        label: 'Total',
                        value:
                            '${formatMoneyEu(selectedAdvance.total, fallback: '-')} ${selectedAdvance.currency}',
                        cs: cs,
                        highlight: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

class _SettlementChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;

  const _SettlementChip({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: highlight
            ? cs.primary.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(
          color: highlight
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        '$label $value',
        style: ts.bodySmall?.copyWith(
          color: highlight ? cs.primary : cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
