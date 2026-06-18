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
  final bool previewInteractive;

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
    this.previewInteractive = true,
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

  void _openDetailsSheet() {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = l.localeName.toLowerCase().startsWith('es');

    final status = (widget.receipt.status ?? 'draft').toLowerCase();
    final isDraft = status.contains('draft') || status.isEmpty;

    final totalsTotal = widget.receipt.total ??
        widget.receipt.lines.fold<num>(
          0,
          (s, ln) => s + (ln.total ?? (ln.quantity * ln.unitPrice)),
        );
    final totalsSubtotal = widget.receipt.subtotal ?? totalsTotal;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
          children: [
            // ── Sheet title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEs ? 'Detalles del recibo' : 'Receipt details',
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          widget.receipt.receiptNumber?.trim().isNotEmpty ==
                                  true
                              ? widget.receipt.receiptNumber!.trim()
                              : l.receiptDraftNumberPlaceholder,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ────────────────────────────────────────────────────
            if (isDraft)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l.edit),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onIssue();
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(l.receiptIssueCta),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onImportJson();
                    },
                    icon: const Icon(Icons.data_object_outlined, size: 18),
                    label: const Text('Import JSON'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDeleteDraft();
                    },
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: cs.error),
                    label: Text(l.delete,
                        style: TextStyle(color: cs.error)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                          color: cs.error.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDownloadPdf();
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(l.download),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),

            // ── Notes ──────────────────────────────────────────────────────
            if ((widget.receipt.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _SheetSection(
                icon: Icons.notes_outlined,
                title: l.invoiceNotesLabel,
                child: Text(
                  widget.receipt.notes!.trim(),
                  style: t.bodyMedium.copyWith(color: cs.onSurface),
                ),
              ),
            ],

            // ── Lines ──────────────────────────────────────────────────────
            const SizedBox(height: 16),
            _SheetSection(
              icon: Icons.format_list_numbered_outlined,
              title: l.receiptLinesTitle,
              child: _LinesTable(lines: widget.receipt.lines),
            ),

            // ── Totals ─────────────────────────────────────────────────────
            const SizedBox(height: 16),
            _Totals(subtotal: totalsSubtotal, total: totalsTotal),
          ],
        ),
      ),
    );
  }

  // ── PDF area ────────────────────────────────────────────────────────────────

  Widget _buildPdfArea(ColorScheme cs, AppLocalizations l) {
    if (_loadingPreview) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.localeName.startsWith('es')
                  ? 'Generando vista previa…'
                  : 'Generating preview…',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_previewBytes != null) {
      return LayoutBuilder(
        builder: (_, constraints) {
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 400.0;
          return PdfInlinePreview(
            bytes: _previewBytes!,
            height: h,
            interactive: widget.previewInteractive,
          );
        },
      );
    }

    if ((_previewError ?? '').trim().isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: cs.error,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.localeName.startsWith('es')
                    ? 'Error al cargar el PDF'
                    : 'Failed to load PDF',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _previewError!,
                style: TextStyle(color: cs.error, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadInlinePreview,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l.tryAgain),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 40,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            l.localeName.startsWith('es') ? 'Sin vista previa' : 'No preview',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Footer bar ──────────────────────────────────────────────────────────────

  Widget _buildFooterBar(
      BuildContext context, ColorScheme cs, AppLocalizations l, bool isEs) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Details – primary CTA (expands)
          Expanded(
            child: FilledButton.icon(
              onPressed: _openDetailsSheet,
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: Text(isEs ? 'Ver detalles' : 'Details'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Download
          _FooterIconBtn(
            icon: Icons.download_outlined,
            tooltip: '${l.download} PDF',
            color: cs.onSurfaceVariant,
            onTap: widget.onDownloadPdf,
          ),
          const SizedBox(width: 2),

          // Full-screen preview
          _FooterIconBtn(
            icon: Icons.open_in_full_rounded,
            tooltip: l.preview,
            color: cs.onSurfaceVariant,
            onTap: widget.onPreviewPdf,
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = l.localeName.toLowerCase().startsWith('es');

    final status = (widget.receipt.status ?? 'draft').toLowerCase();
    final issued = status.contains('issue');
    final statusLabel = issued ? l.statusIssued : l.statusDraft;
    final statusColor = issued ? cs.primary : cs.tertiary;
    final statusIcon =
        issued ? Icons.task_alt_outlined : Icons.edit_note_outlined;

    final number = widget.receipt.receiptNumber?.trim().isNotEmpty == true
        ? widget.receipt.receiptNumber!.trim()
        : l.receiptDraftNumberPlaceholder;

    final totalsTotal = widget.receipt.total ??
        widget.receipt.lines.fold<num>(
          0,
          (s, ln) => s + (ln.total ?? (ln.quantity * ln.unitPrice)),
        );

    final fmt = DateFormat.yMMMd(l.localeName);
    final issueLabel = widget.receipt.issueDate == null
        ? null
        : fmt.format(widget.receipt.issueDate!.toLocal());

    final moneyFmt =
        NumberFormat.currency(locale: l.localeName, symbol: 'EUR ');

    return ColoredBox(
      color: Theme.of(context).canvasColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.of(context).size.height * 0.85;

          // Reserve: top padding(6) + header(~80) + gap(8) + footer(56) + bottom(8) = ~158
          final pdfHeight = (availableH - 158).clamp(240.0, double.infinity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Status icon box
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(statusIcon, size: 18, color: statusColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    number,
                                    style: t.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  moneyFmt.format(totalsTotal),
                                  style: t.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _HeaderChip(
                                  icon: Icons.person_outline,
                                  label: widget.client.name,
                                ),
                                if (issueLabel != null)
                                  _HeaderChip(
                                    icon: Icons.event_outlined,
                                    label: issueLabel,
                                  ),
                                _HeaderChip(
                                  icon: Icons.format_list_numbered,
                                  label:
                                      '${l.receiptLinesTitle}: ${widget.receipt.lines.length}',
                                ),
                                _StatusChip(
                                  issued: issued,
                                  label: statusLabel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── PDF Preview ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: pdfHeight,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _buildPdfArea(cs, l),
                  ),
                ),
              ),

              // ── Footer bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SafeArea(
                  top: false,
                  child: _buildFooterBar(context, cs, l, isEs),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Footer icon button ─────────────────────────────────────────────────────────

class _FooterIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _FooterIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: onTap == null ? color.withValues(alpha: 0.4) : color,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      ),
    );
  }
}

// ── Sheet section wrapper ──────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SheetSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Icon(icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.of(context).bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

// ── Header chip ────────────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall.copyWith(
                fontSize: 11,
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

// ── Status chip ────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool issued;
  final String label;
  const _StatusChip({required this.issued, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final bg = issued
        ? cs.secondaryContainer
        : cs.surfaceContainerHighest.withValues(alpha: 0.4);
    final fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: issued ? 0.2 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Lines table ────────────────────────────────────────────────────────────────

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
                  flex: 3,
                  child: Text(l.lineDescription, style: headerStyle)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

// ── Totals ─────────────────────────────────────────────────────────────────────

class _Totals extends StatelessWidget {
  final num subtotal;
  final num total;
  const _Totals({required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.receiptSubtotalLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                NumberFormat.simpleCurrency(name: '').format(subtotal),
                style: t.bodySmall.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.receiptTotalLabel,
                  style: t.bodyMedium.copyWith(
                    color: cs.onSurface,
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
      ),
    );
  }
}
