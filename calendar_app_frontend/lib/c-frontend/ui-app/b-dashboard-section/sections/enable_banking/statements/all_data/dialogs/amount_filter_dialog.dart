import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Dialog for filtering statements by amount range and type
class AmountFilterDialog {
  static Future<AmountFilterResult?> show(
    BuildContext context, {
    required double? currentMinFilter,
    required double? currentMaxFilter,
    required String currentTypeFilter,
  }) async {
    final minController = TextEditingController(
      text: currentMinFilter?.toStringAsFixed(2) ?? '',
    );
    final maxController = TextEditingController(
      text: currentMaxFilter?.toStringAsFixed(2) ?? '',
    );
    var localType = currentTypeFilter;
    String? error;

    double? parseAmountInput(String raw) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final cleaned = trimmed.replaceAll(',', '.');
      return double.tryParse(cleaned);
    }

    void normalizeExpenseInputs() {
      if (localType != 'expense') return;
      final minRaw = minController.text.trim();
      final maxRaw = maxController.text.trim();
      final minVal = parseAmountInput(minRaw);
      final maxVal = parseAmountInput(maxRaw);
      if (minVal != null && minVal > 0) {
        minController.text = (-minVal).toStringAsFixed(2);
      }
      if (maxVal != null && maxVal > 0) {
        maxController.text = (-maxVal).toStringAsFixed(2);
      }
    }

    return showDialog<AmountFilterResult>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final l = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l.statementsHeaderAmount),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: localType == 'all',
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.7),
                          ),
                          onSelected: (_) => setState(() => localType = 'all'),
                        ),
                        ChoiceChip(
                          label: Text(l.statementsSummaryIncome),
                          selected: localType == 'income',
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.7),
                          ),
                          onSelected: (_) =>
                              setState(() => localType = 'income'),
                        ),
                        ChoiceChip(
                          label: Text(l.statementsSummaryExpense),
                          selected: localType == 'expense',
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.7),
                          ),
                          onSelected: (_) => setState(() {
                            localType = 'expense';
                            normalizeExpenseInputs();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      minController.clear();
                      maxController.clear();
                      localType = 'all';
                      error = null;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
                FilledButton(
                  onPressed: () {
                    normalizeExpenseInputs();
                    var min = parseAmountInput(minController.text);
                    var max = parseAmountInput(maxController.text);
                    if (localType == 'expense') {
                      if (min != null) min = -min.abs();
                      if (max != null) max = -max.abs();
                      if (min != null && max != null && min > max) {
                        final tmp = min;
                        min = max;
                        max = tmp;
                      }
                    }
                    final minInvalid =
                        minController.text.trim().isNotEmpty && min == null;
                    final maxInvalid =
                        maxController.text.trim().isNotEmpty && max == null;
                    if (minInvalid || maxInvalid) {
                      setState(() => error = 'Importe invalido');
                      return;
                    }
                    if (min != null && max != null && min > max) {
                      setState(() => error = 'Min debe ser menor o igual a Max');
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      AmountFilterResult(
                        minFilter: min,
                        maxFilter: max,
                        typeFilter: localType,
                      ),
                    );
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Result from the amount filter dialog
class AmountFilterResult {
  final double? minFilter;
  final double? maxFilter;
  final String typeFilter;

  const AmountFilterResult({
    required this.minFilter,
    required this.maxFilter,
    required this.typeFilter,
  });
}
