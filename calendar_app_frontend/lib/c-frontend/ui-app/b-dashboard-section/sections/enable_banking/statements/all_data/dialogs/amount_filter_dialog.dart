import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AmountFilterDialog {
  static Future<AmountFilterResult?> show(
    BuildContext context, {
    required double? currentMinFilter,
    required double? currentMaxFilter,
    required String currentTypeFilter,
  }) async {
    final minController = TextEditingController(
      text: currentMinFilter != null
          ? currentMinFilter.abs().toStringAsFixed(2)
          : '',
    );
    final maxController = TextEditingController(
      text: currentMaxFilter != null
          ? currentMaxFilter.abs().toStringAsFixed(2)
          : '',
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
      final minVal = parseAmountInput(minController.text);
      final maxVal = parseAmountInput(maxController.text);
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
        final t = AppTypography.of(dialogContext);
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final l = AppLocalizations.of(dialogContext)!;
        final isEs = l.localeName.toLowerCase().startsWith('es');

        return StatefulBuilder(
          builder: (ctx, setState) {
            final minVal = parseAmountInput(minController.text);
            final maxVal = parseAmountInput(maxController.text);
            final hasRange = minVal != null || maxVal != null;

            Widget typeButton(String value, String label, IconData icon) {
              final active = localType == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    localType = value;
                    error = null;
                    if (value == 'expense') normalizeExpenseInputs();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: active
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? cs.primary.withValues(alpha: 0.5)
                            : cs.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: active
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: t.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? cs.onPrimaryContainer
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            InputDecoration fieldDecoration(String label) => InputDecoration(
                  labelText: label,
                  prefixText: '€ ',
                  prefixStyle: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.30)
                      : cs.surfaceContainerLow.withValues(alpha: 0.60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                );

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? cs.surfaceContainer
                        : cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.20 : 0.25,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header ──────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: cs.outlineVariant.withValues(
                                alpha: isDark ? 0.18 : 0.22,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.euro_rounded,
                                size: 16,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              l.statementsHeaderAmount,
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Body ────────────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Type selector
                            Row(
                              children: [
                                typeButton(
                                  'all',
                                  isEs ? 'Todos' : 'All',
                                  Icons.swap_horiz_rounded,
                                ),
                                const SizedBox(width: 6),
                                typeButton(
                                  'income',
                                  isEs ? 'Ingresos' : 'Income',
                                  Icons.arrow_downward_rounded,
                                ),
                                const SizedBox(width: 6),
                                typeButton(
                                  'expense',
                                  isEs ? 'Gastos' : 'Expenses',
                                  Icons.arrow_upward_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Range preview chip
                            AnimatedSize(
                              duration: const Duration(milliseconds: 180),
                              child: hasRange
                                  ? Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cs.primary
                                                .withValues(alpha: 0.10),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: cs.primary
                                                  .withValues(alpha: 0.25),
                                            ),
                                          ),
                                          child: Text(
                                            [
                                              if (minVal != null)
                                                '≥ €${minVal.toStringAsFixed(2)}',
                                              if (maxVal != null)
                                                '≤ €${maxVal.toStringAsFixed(2)}',
                                            ].join('  ·  '),
                                            style: t.bodySmall.copyWith(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: cs.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            // Min field
                            TextField(
                              controller: minController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,\-]'),
                                ),
                              ],
                              decoration: fieldDecoration('Min'),
                              onChanged: (_) => setState(() => error = null),
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Max field
                            TextField(
                              controller: maxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,\-]'),
                                ),
                              ],
                              decoration: fieldDecoration('Max'),
                              onChanged: (_) => setState(() => error = null),
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // Error
                            AnimatedSize(
                              duration: const Duration(milliseconds: 160),
                              child: error != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            size: 14,
                                            color: cs.error,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            error!,
                                            style: t.bodySmall.copyWith(
                                              color: cs.error,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      // ── Footer ──────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: cs.outlineVariant.withValues(
                                alpha: isDark ? 0.18 : 0.22,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                minController.clear();
                                maxController.clear();
                                localType = 'all';
                                error = null;
                              }),
                              style: TextButton.styleFrom(
                                foregroundColor: cs.onSurfaceVariant,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: Text(isEs ? 'Limpiar' : 'Clear'),
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: Text(l.close),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                normalizeExpenseInputs();
                                var min =
                                    parseAmountInput(minController.text);
                                var max =
                                    parseAmountInput(maxController.text);
                                if (localType == 'expense') {
                                  if (min != null) min = -min.abs();
                                  if (max != null) max = -max.abs();
                                  if (min != null &&
                                      max != null &&
                                      min > max) {
                                    final tmp = min;
                                    min = max;
                                    max = tmp;
                                  }
                                }
                                final minInvalid =
                                    minController.text.trim().isNotEmpty &&
                                        min == null;
                                final maxInvalid =
                                    maxController.text.trim().isNotEmpty &&
                                        max == null;
                                if (minInvalid || maxInvalid) {
                                  setState(() => error = isEs
                                      ? 'Importe inválido'
                                      : 'Invalid amount');
                                  return;
                                }
                                if (min != null &&
                                    max != null &&
                                    min > max) {
                                  setState(() => error = isEs
                                      ? 'Min debe ser menor o igual a Max'
                                      : 'Min must be ≤ Max');
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
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                minimumSize: const Size(0, 36),
                              ),
                              child: Text(isEs ? 'Aplicar' : 'Apply'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

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
