import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptSummaryCard extends StatelessWidget {
  final String status;
  final String clientName;
  final String issueDateLabel;
  final int lineCount;
  final num subtotal;
  final num total;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onIssue;
  final VoidCallback? onDownload;

  const ReceiptSummaryCard({
    super.key,
    required this.status,
    required this.clientName,
    required this.issueDateLabel,
    required this.lineCount,
    required this.subtotal,
    required this.total,
    required this.onSaveDraft,
    required this.onIssue,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final issued = status.contains('issue');
    final statusBg = issued ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final statusFg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptSummaryTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    status.isEmpty ? 'draft' : status,
                    style: t.bodySmall.copyWith(
                      color: statusFg,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: l.invoiceBillToLabel, value: clientName),
            _SummaryRow(label: l.receiptIssueDateLabel, value: issueDateLabel),
            _SummaryRow(label: l.receiptLinesTitle, value: '$lineCount'),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _SummaryRow(
              label: l.receiptSubtotalLabel,
              value: NumberFormat.simpleCurrency(name: '').format(subtotal),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptTotalLabel,
                    style: t.bodyMedium.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  NumberFormat.simpleCurrency(name: '').format(total),
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onIssue,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l.receiptIssueCta),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onSaveDraft,
                icon: const Icon(Icons.save_outlined),
                label: Text(l.saveDraft),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined),
                label: Text(l.download),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

