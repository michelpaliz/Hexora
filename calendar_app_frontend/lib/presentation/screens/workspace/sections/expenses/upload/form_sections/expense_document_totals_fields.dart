import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _ExpenseTotalsTypeScale {
  static const fieldLabel = 12.0;
  static const fieldValue = 13.0;
  static const title = 12.0;
}

class ExpenseDocumentTotalsFields extends StatelessWidget {
  final TextEditingController baseController;
  final TextEditingController taxController;
  final TextEditingController totalController;
  final bool enabled;
  final bool useSummaryTotals;
  final bool lockToLines;
  final ValueChanged<bool> onSummaryModeChanged;
  final ValueChanged<String> onBaseChanged;
  final ValueChanged<String> onTaxChanged;
  final ValueChanged<String> onTotalChanged;
  final String? validationError;
  final Widget? financialSummary;

  const ExpenseDocumentTotalsFields({
    super.key,
    required this.baseController,
    required this.taxController,
    required this.totalController,
    required this.enabled,
    required this.useSummaryTotals,
    required this.lockToLines,
    required this.onSummaryModeChanged,
    required this.onBaseChanged,
    required this.onTaxChanged,
    required this.onTotalChanged,
    this.validationError,
    this.financialSummary,
  });

  InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: _ExpenseTotalsTypeScale.fieldLabel),
      prefixIcon: icon == null ? null : Icon(icon, size: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      filled: true,
      fillColor: cs.surfaceContainer,
      isDense: true,
      constraints: const BoxConstraints(minHeight: 40),
      contentPadding: icon != null
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final helperText = useSummaryTotals
        ? l10n.expenseTotalsSummaryHelp
        : lockToLines
            ? l10n.expenseTotalsLockToLinesHelp
            : l10n.expenseTotalsDirectReviewHelp;

    Widget textField({
      required TextEditingController controller,
      required String label,
      required IconData icon,
      required ValueChanged<String> onChanged,
    }) {
      return TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: _ExpenseTotalsTypeScale.fieldValue),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decor(label, cs, icon: icon),
        onChanged: onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Método de cálculo',
              style: ts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontSize: _ExpenseTotalsTypeScale.title,
              ),
            ),
            const SizedBox(width: 5),
            Tooltip(
              message: helperText,
              child: Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            ),
          ),
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.format_list_numbered, size: 15),
              label: Text('Calcular desde líneas'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.receipt_long_outlined, size: 15),
              label: Text('Introducir totales del documento'),
            ),
          ],
          selected: {useSummaryTotals},
          onSelectionChanged: enabled
              ? (selection) {
                  final next = selection.first;
                  if (next != useSummaryTotals) {
                    onSummaryModeChanged(next);
                  }
                }
              : null,
        ),
        if (useSummaryTotals) ...[
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              final fields = [
                textField(
                  controller: baseController,
                  label: l10n.expenseTotalsTaxableBase,
                  icon: Icons.receipt_long_outlined,
                  onChanged: onBaseChanged,
                ),
                textField(
                  controller: taxController,
                  label: l10n.expenseTotalsTax,
                  icon: Icons.percent_outlined,
                  onChanged: onTaxChanged,
                ),
                textField(
                  controller: totalController,
                  label: l10n.expenseTotalsTotal,
                  icon: Icons.payments_outlined,
                  onChanged: onTotalChanged,
                ),
              ];

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      fields[i],
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: fields[i]),
                  ],
                ],
              );
            },
          ),
        ],
        if (financialSummary != null) ...[
          const SizedBox(height: 8),
          financialSummary!,
        ],
        if ((validationError ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            validationError!,
            style: ts.bodySmall?.copyWith(color: cs.error),
          ),
        ],
      ],
    );
  }
}
