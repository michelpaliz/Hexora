import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ExpenseErrorsAndSubmit extends StatelessWidget {
  final String? error;
  final bool submitting;
  final VoidCallback onSubmit;
  final bool canSubmit;

  const ExpenseErrorsAndSubmit({
    super.key,
    required this.error,
    required this.submitting,
    required this.onSubmit,
    this.canSubmit = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: (submitting || !canSubmit) ? null : onSubmit,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.expenseUploadSubmitCta),
            ),
          ),
        ],
      ),
    );
  }
}
