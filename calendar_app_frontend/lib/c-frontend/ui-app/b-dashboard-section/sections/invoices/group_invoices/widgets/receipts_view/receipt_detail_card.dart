import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ReceiptDetailCard extends StatefulWidget {
  final Receipt receipt;
  final GroupClient client;
  final BillingProfile? billingProfile;

  final VoidCallback onEdit;
  final VoidCallback onPreviewPdf;
  final VoidCallback onDownloadPdf;
  final VoidCallback onIssue;
  final VoidCallback onDeleteDraft;
  final VoidCallback onImportJson;
  final Future<Uint8List?> Function() onLoadInlinePdf;

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
    required this.onImportJson,
    required this.onLoadInlinePdf,
  });

  @override
  State<ReceiptDetailCard> createState() => _ReceiptDetailCardState();
}

class _ReceiptDetailCardState extends State<ReceiptDetailCard> {
  bool _loadingPreview = false;
  Uint8List? _previewBytes;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    _loadInlinePreview();
  }

  @override
  void didUpdateWidget(covariant ReceiptDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt.id != widget.receipt.id) {
      _previewBytes = null;
      _previewError = null;
      _loadInlinePreview();
    }
  }

  Future<void> _loadInlinePreview() async {
    if (_loadingPreview) return;
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final bytes = await widget.onLoadInlinePdf();
      if (!mounted) return;
      setState(() => _previewBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() => _previewError = msg);
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final status = (widget.receipt.status ?? 'draft').toLowerCase();
    final issued = status.contains('issue');
    final isDraft = status.contains('draft') || status.isEmpty;
    final statusLabel = issued ? l.statusIssued : l.statusDraft;

    final number = (widget.receipt.receiptNumber?.trim().isNotEmpty == true)
        ? widget.receipt.receiptNumber!.trim()
        : l.receiptDraftNumberPlaceholder;

    final fmt = DateFormat.yMMMd(l.localeName);
    final issueLabel = widget.receipt.issueDate == null
        ? '-'
        : fmt.format(widget.receipt.issueDate!.toLocal());

    final totalsTotal = widget.receipt.total ??
        widget.receipt.lines.fold<num>(
          0,
          (sum, line) =>
              sum + ((line.total ?? (line.quantity * line.unitPrice))),
        );
    final totalsSubtotal = widget.receipt.subtotal ?? totalsTotal;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
                color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          number,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      _StatusChip(
                        issued: issued,
                        label: statusLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _HeaderMetaChip(
                        icon: Icons.person_outline,
                        text: widget.client.name,
                      ),
                      _HeaderMetaChip(
                        icon: Icons.event_outlined,
                        text: issueLabel,
                      ),
                      _HeaderMetaChip(
                        icon: Icons.format_list_numbered,
                        text:
                            '${l.receiptLinesTitle}: ${widget.receipt.lines.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if ((widget.receipt.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InfoBox(
                  title: l.invoiceNotesLabel,
                  value: widget.receipt.notes!.trim()),
            ],
            const SizedBox(height: 12),
            if (_loadingPreview)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_previewBytes != null)
              PdfInlinePreview(
                bytes: _previewBytes!,
                height: 340,
              )
            else if ((_previewError ?? '').trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.error.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, color: cs.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _previewError!,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                    IconButton(
                      tooltip: l.tryAgain,
                      onPressed: _loadInlinePreview,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.receiptLinesTitle,
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onPreviewPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: Text(l.preview),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LinesTable(lines: widget.receipt.lines),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _Totals(
              subtotal: totalsSubtotal,
              total: totalsTotal,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final compactActions = constraints.maxWidth < 560;
                if (isDraft && compactActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(l.edit),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: widget.onIssue,
                            icon: const Icon(Icons.check_circle_outline,
                                size: 18),
                            label: Text(l.receiptIssueCta),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: widget.onImportJson,
                            icon: const Icon(Icons.data_object_outlined,
                                size: 18),
                            label: const Text('Import JSON'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: l.delete,
                          onPressed: widget.onDeleteDraft,
                          icon: const Icon(Icons.delete_outline, size: 22),
                          color: cs.error.withValues(alpha: 0.8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    if (isDraft) ...[
                      OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l.edit),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: widget.onIssue,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(l.receiptIssueCta),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onImportJson,
                        icon: const Icon(Icons.data_object_outlined, size: 18),
                        label: const Text('Import JSON'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                      IconButton(
                        tooltip: l.delete,
                        onPressed: widget.onDeleteDraft,
                        icon: const Icon(Icons.delete_outline, size: 22),
                        color: cs.error.withValues(alpha: 0.8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ] else ...[
                      FilledButton.tonalIcon(
                        onPressed: widget.onDownloadPdf,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: Text(l.download),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _SmallHint(
                        text:
                            issued ? l.receiptLockedHint : l.receiptLockedHint,
                      ),
                    ],
                  ],
                );
              },
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
  final bool issued;
  final String label;
  const _StatusChip({
    required this.issued,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final bg = issued
        ? cs.secondaryContainer
        : cs.surfaceContainerHighest.withValues(alpha: 0.4);
    final fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: issued ? 0.25 : 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: t.bodyMedium.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _HeaderMetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderMetaChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.trim().isEmpty ? '-' : value.trim(),
            style: t.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 3, child: Text(l.lineDescription, style: headerStyle)),
              Expanded(
                  child: Text(l.lineQuantity,
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  child: Text(l.lineUnitPrice,
                      style: headerStyle, textAlign: TextAlign.right)),
              Expanded(
                  child: Text(l.receiptLineTotalLabel,
                      style: headerStyle, textAlign: TextAlign.right)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...lines.map((line) {
          final desc = line.description.trim();
          final qty = line.quantity;
          final unit = line.unitPrice;
          final total = line.total ?? (qty * unit);
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    desc.isEmpty ? '—' : desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.compact().format(qty),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.compactCurrency(name: '').format(unit),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.compactCurrency(name: '').format(total),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
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
