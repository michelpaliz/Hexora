import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptDetailCard extends StatelessWidget {
  final Receipt receipt;
  final GroupClient client;
  final BillingProfile? billingProfile;

  final VoidCallback onEdit;
  final VoidCallback onPreviewPdf;
  final VoidCallback onDownloadPdf;
  final VoidCallback onIssue;
  final VoidCallback onDeleteDraft;

  const ReceiptDetailCard({
    super.key,
    required this.receipt,
    required this.client,
    required this.billingProfile,
    required this.onEdit,
    required this.onPreviewPdf,
    required this.onDownloadPdf,
    required this.onIssue,
    required this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final status = (receipt.status ?? 'draft').toLowerCase();
    final issued = status.contains('issue');
    final isDraft = status.contains('draft') || status.isEmpty;

    final number = (receipt.receiptNumber?.trim().isNotEmpty == true)
        ? receipt.receiptNumber!.trim()
        : l.receiptDraftNumberPlaceholder;

    final fmt = DateFormat.yMMMd(l.localeName);
    final issueLabel = receipt.issueDate == null
        ? '-'
        : fmt.format(receipt.issueDate!.toLocal());

    final totalsTotal = receipt.total ??
        receipt.lines.fold<num>(
          0,
          (sum, line) =>
              sum + ((line.total ?? (line.quantity * line.unitPrice))),
        );
    final totalsSubtotal = receipt.subtotal ?? totalsTotal;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    number,
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    title: l.invoiceFromLabel,
                    value: (receipt.issuerSnapshot?.legalName ??
                                billingProfile?.legalName ??
                                '')
                            .trim()
                            .isEmpty
                        ? l.billingProfileEmpty
                        : (receipt.issuerSnapshot?.legalName ??
                                billingProfile?.legalName ??
                                '')
                            .trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    title: l.invoiceBillToLabel,
                    value: client.name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    title: l.receiptIssueDateLabel,
                    value: issueLabel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    title: l.receiptLinesTitle,
                    value: '${receipt.lines.length}',
                  ),
                ),
              ],
            ),
            if ((receipt.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoBox(title: l.invoiceNotesLabel, value: receipt.notes!.trim()),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.receiptLinesTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onPreviewPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l.preview),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LinesTable(lines: receipt.lines),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _Totals(
              subtotal: totalsSubtotal,
              total: totalsTotal,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (isDraft) ...[
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l.edit),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: onIssue,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(l.receiptIssueCta),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l.delete,
                    onPressed: onDeleteDraft,
                    icon: const Icon(Icons.delete_outline),
                    color: cs.onSurfaceVariant,
                  ),
                ] else ...[
                  FilledButton.tonalIcon(
                    onPressed: onDownloadPdf,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(l.download),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  _SmallHint(
                    text: issued ? l.receiptLockedHint : l.receiptLockedHint,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallHint extends StatelessWidget {
  final String text;
  const _SmallHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final issued = normalized.contains('issue');

    final bg = issued ? cs.secondaryContainer : cs.surfaceContainerHighest;
    final fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Text(
        normalized.isEmpty ? 'draft' : normalized,
        style: t.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;
  const _InfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.trim().isEmpty ? '-' : value.trim(),
            style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LinesTable extends StatelessWidget {
  final List<ReceiptLine> lines;
  const _LinesTable({required this.lines});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    final headerStyle = t.bodySmall.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );

    if (lines.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l.receiptNoLinesYet,
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: Text(l.lineDescription, style: headerStyle)),
            Expanded(child: Text(l.lineQuantity, style: headerStyle, textAlign: TextAlign.right)),
            Expanded(child: Text(l.lineUnitPrice, style: headerStyle, textAlign: TextAlign.right)),
            Expanded(child: Text(l.receiptLineTotalLabel, style: headerStyle, textAlign: TextAlign.right)),
          ],
        ),
        const SizedBox(height: 8),
        ...lines.map((line) {
          final desc = line.description.trim();
          final qty = line.quantity;
          final unit = line.unitPrice;
          final total = line.total ?? (qty * unit);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    desc.isEmpty ? '—' : desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.compact().format(qty),
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.compactCurrency(name: '').format(unit),
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.compactCurrency(name: '').format(total),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  final num subtotal;
  final num total;
  const _Totals({required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        _RowLabel(
          label: l.receiptSubtotalLabel,
          value: NumberFormat.simpleCurrency(name: '').format(subtotal),
        ),
        const SizedBox(height: 10),
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
      ],
    );
  }
}

class _RowLabel extends StatelessWidget {
  final String label;
  final String value;
  const _RowLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Row(
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
        Text(
          value,
          style: t.bodySmall.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
