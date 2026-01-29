import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RecurringDetailGeneratedTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Invoice> invoices;
  final VoidCallback onReload;
  final bool hasRequested;
  final int? count;
  final ValueChanged<Invoice> onOpenInvoice;
  final ValueChanged<Invoice> onDownloadPdf;

  const RecurringDetailGeneratedTab({
    super.key,
    required this.loading,
    required this.error,
    required this.invoices,
    required this.onReload,
    required this.hasRequested,
    required this.count,
    required this.onOpenInvoice,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    String statusLabel(String? status) {
      final normalized = (status ?? '').toLowerCase().trim();
      if (normalized.isEmpty) {
        return l.invoiceStatusUnknown;
      }
      if (normalized.contains('draft')) {
        return l.statusDraft;
      }
      if (normalized.contains('issued')) {
        return l.statusIssued;
      }
      if (normalized.contains('sent')) {
        return l.invoiceStatusSent;
      }
      if (normalized.contains('paid')) {
        return l.invoiceStatusPaid;
      }
      if (normalized.contains('overdue')) {
        return l.invoiceStatusOverdue;
      }
      if (normalized.contains('cancel')) {
        return l.invoiceStatusCancelled;
      }
      return status ?? '';
    }

    final header = Row(
      children: [
        Expanded(
          child: Text(
            l.recurringInvoicesSeriesInvoicesTitle,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if ((count ?? 0) > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${count ?? invoices.length}',
              style: t.bodySmall.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: loading ? null : onReload,
          icon: Icon(
            hasRequested ? Icons.refresh_rounded : Icons.receipt_long_outlined,
            size: 18,
          ),
          label: Text(
            hasRequested
                ? l.recurringInvoicesRefreshCta
                : l.recurringInvoicesSeriesInvoicesCta,
          ),
        ),
      ],
    );

    if (!hasRequested) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: Text(
              l.recurringInvoicesSeriesInvoicesHint,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Text(
            error!,
            style: t.bodySmall.copyWith(color: cs.error),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (invoices.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Text(
            l.recurringInvoicesSeriesInvoicesEmpty,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final inv = invoices[i];
              final date =
                  inv.occurrenceDate ?? inv.issueDate ?? inv.registeredAt;
              final dateLabel = date == null
                  ? '-'
                  : DateFormat.yMMMd(l.localeName).add_Hm().format(date);
              final currency = (inv.currency ?? 'EUR').trim();
              final total = inv.total;
              final money = NumberFormat.simpleCurrency(
                locale: l.localeName,
                name: currency.isEmpty ? 'EUR' : currency,
              );
              final totalLabel = total == null ? '-' : money.format(total);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.invoiceNumber.isEmpty ? '-' : inv.invoiceNumber,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateLabel,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalLabel,
                            style: t.bodySmall.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          statusLabel(inv.status),
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => onOpenInvoice(inv),
                              child: Text(l.invoiceOpenCta),
                            ),
                            const SizedBox(width: 4),
                            OutlinedButton.icon(
                              onPressed: () => onDownloadPdf(inv),
                              icon:
                                  const Icon(Icons.download_outlined, size: 18),
                              label: Text(l.invoicePdfDownloadCta),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
