import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import '../statements_formatters.dart';
import '../statements_shared.dart';

class StatementsAllDataDetails {
  static Future<void> show(
    BuildContext context,
    AppLocalizations l,
    Map<String, dynamic> entry,
  ) async {
    final batchId = entry['_batchId']?.toString() ?? '-';
    final date = StatementsShared.entryText(entry, ['date']);
    final valueDate = StatementsShared.entryText(entry, ['valueDate']);
    final desc = StatementsShared.entryText(entry, ['description']);
    final details = StatementsShared.entryText(entry, ['details']);
    final amount = StatementsShared.entryText(entry, ['amount']);
    final balance = StatementsShared.entryText(entry, ['balance']);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l.close,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        final typography = AppTypography.of(dialogContext);
        final width = MediaQuery.of(dialogContext).size.width;
        final panelWidth = width < 520 ? width : 460.0;
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Theme.of(dialogContext).colorScheme.surface,
            elevation: 12,
            child: SizedBox(
              width: panelWidth,
              height: double.infinity,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.statementsRowDetailsTitle,
                              style: typography.titleLarge,
                            ),
                          ),
                          IconButton(
                            tooltip: l.close,
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.statementsRowDetailsSubtitle(batchId),
                        style: typography.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(label: l.statementsHeaderDate, value: date),
                      _DetailRow(
                          label: l.statementsHeaderDate, value: valueDate),
                      _DetailRow(
                          label: l.statementsHeaderDescription, value: desc),
                      _DetailRow(
                          label: l.statementsHeaderDetails, value: details),
                      _DetailRow(
                        label: l.statementsHeaderAmount,
                        value: StatementsFormatters.formatAmount(
                            dialogContext, amount),
                      ),
                      _DetailRow(
                        label: l.statementsHeaderBalance,
                        value: StatementsFormatters.formatAmount(
                            dialogContext, balance),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l.statementsRowDetailsRaw,
                        style: typography.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Text(entry.toString(), style: typography.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typography = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: typography.bodySmall),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value.isEmpty ? '-' : value,
                  style: typography.bodyMedium)),
        ],
      ),
    );
  }
}
