import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _ExpenseTotalsTypeScale {
  static const fieldLabel = 12.0;
  static const fieldValue = 13.0;
  static const helper = 12.0;
  static const title = 13.0;
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
  });

  InputDecoration _decor(
    String label,
    ColorScheme cs, {
    IconData? icon,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: _ExpenseTotalsTypeScale.fieldLabel),
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
      fillColor: readOnly
          ? cs.surfaceContainerHighest.withValues(alpha: 0.10)
          : cs.surfaceContainerHighest.withValues(alpha: 0.18),
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
    final l10n = AppLocalizations.of(context)!;
    final readOnly = lockToLines && !useSummaryTotals;
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
        enabled: enabled && !readOnly,
        readOnly: readOnly,
        style: const TextStyle(fontSize: _ExpenseTotalsTypeScale.fieldValue),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decor(label, cs, icon: icon, readOnly: readOnly),
        onChanged: onChanged,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
            color: cs.surfaceContainerHighest.withValues(
              alpha: useSummaryTotals ? 0.20 : 0.12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.expenseTotalsUseSummaryLabel,
                          style: ts.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                            fontSize: _ExpenseTotalsTypeScale.title,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          useSummaryTotals
                              ? l10n.expenseTotalsSummaryMode
                              : l10n.expenseTotalsCalculateMode,
                          style: ts.bodySmall?.copyWith(
                            color: useSummaryTotals
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: _ExpenseTotalsTypeScale.helper,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: useSummaryTotals,
                    onChanged: enabled ? onSummaryModeChanged : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                helperText,
                style: ts.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: _ExpenseTotalsTypeScale.helper,
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 460;
                  final firstRow = <Widget>[
                    Expanded(
                      child: textField(
                        controller: baseController,
                        label: l10n.expenseTotalsTaxableBase,
                        icon: Icons.receipt_long_outlined,
                        onChanged: onBaseChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: textField(
                        controller: taxController,
                        label: l10n.expenseTotalsTax,
                        icon: Icons.percent_outlined,
                        onChanged: onTaxChanged,
                      ),
                    ),
                  ];
                  final totalField = textField(
                    controller: totalController,
                    label: l10n.expenseTotalsTotal,
                    icon: Icons.payments_outlined,
                    onChanged: onTotalChanged,
                  );

                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        textField(
                          controller: baseController,
                          label: l10n.expenseTotalsTaxableBase,
                          icon: Icons.receipt_long_outlined,
                          onChanged: onBaseChanged,
                        ),
                        const SizedBox(height: 8),
                        textField(
                          controller: taxController,
                          label: l10n.expenseTotalsTax,
                          icon: Icons.percent_outlined,
                          onChanged: onTaxChanged,
                        ),
                        const SizedBox(height: 8),
                        totalField,
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: firstRow),
                      const SizedBox(height: 8),
                      totalField,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
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
