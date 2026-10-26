import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseErrorsAndSubmit extends StatelessWidget {
  final String? error;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;
  final bool canSubmit;
  final String? submitLabel;

  const ExpenseErrorsAndSubmit({
    super.key,
    required this.error,
    required this.submitting,
    required this.onSubmit,
    this.onCancel,
    this.canSubmit = true,
    this.submitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 4,
      shadowColor: cs.shadow.withValues(alpha: 0.10),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: error == null
                    ? Text(
                        submitting
                            ? (l.localeName.startsWith('es')
                                ? 'Guardando gasto…'
                                : 'Saving expense…')
                            : (l.localeName.startsWith('es')
                                ? 'Revisa los datos antes de guardar.'
                                : 'Review the details before saving.'),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      )
                    : Text(
                        error!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.error, fontSize: 12),
                      ),
              ),
              const SizedBox(width: 12),
              if (onCancel != null) ...[
                OutlinedButton(
                  onPressed: submitting ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l.cancel),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton.icon(
                onPressed: (submitting || !canSubmit) ? null : onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 16),
                label: Text(submitLabel ?? l.expenseUploadSubmitCta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
