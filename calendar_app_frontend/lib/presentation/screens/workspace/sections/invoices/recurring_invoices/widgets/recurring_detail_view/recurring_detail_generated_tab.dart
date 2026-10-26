import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/delivery_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/shared/widgets/documents/hexora_status_badge.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum _GeneratedNumberSort { recent, asc, desc }

class _InvoiceAmounts {
  final num subtotal;
  final num tax;
  final num total;

  const _InvoiceAmounts({
    required this.subtotal,
    required this.tax,
    required this.total,
  });
}

class RecurringDetailGeneratedTab extends StatefulWidget {
  final bool loading;
  final String? error;
  final List<Invoice> invoices;
  final VoidCallback onReload;
  final bool hasRequested;
  final int? count;
  final ValueChanged<Invoice>? onOpenInvoice;
  final ValueChanged<Invoice> onDownloadPdf;
  final Future<Invoice> Function(String invoiceId) onLoadInvoiceDetails;
  final Future<Uint8List> Function(String invoiceId) onLoadInvoicePreviewBytes;
  final bool receiptsMode;

  const RecurringDetailGeneratedTab({
    super.key,
    required this.loading,
    required this.error,
    required this.invoices,
    required this.onReload,
    required this.hasRequested,
    required this.count,
    this.onOpenInvoice,
    required this.onDownloadPdf,
    required this.onLoadInvoiceDetails,
    required this.onLoadInvoicePreviewBytes,
    this.receiptsMode = false,
  });

  @override
  State<RecurringDetailGeneratedTab> createState() =>
      _RecurringDetailGeneratedTabState();
}

class _RecurringDetailGeneratedTabState
    extends State<RecurringDetailGeneratedTab> {
  _GeneratedNumberSort _numberSort = _GeneratedNumberSort.recent;
  String? _selectedInvoiceId;
  final Map<String, Invoice> _detailById = <String, Invoice>{};
  final Map<String, Uint8List> _pdfBytesById = <String, Uint8List>{};
  bool _loadingPreview = false;
  String? _previewError;
  bool _prefetchingDetails = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    if (!widget.hasRequested && !widget.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onReload();
      });
    }
  }

  @override
  void didUpdateWidget(covariant RecurringDetailGeneratedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.hasRequested && !widget.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onReload();
      });
    }
    if (widget.invoices.isEmpty) {
      _selectedInvoiceId = null;
      _showPreview = false;
      return;
    }
    final exists = widget.invoices.any((i) => i.id == _selectedInvoiceId);
    if (!exists) {
      _selectedInvoiceId = widget.invoices.first.id;
      _showPreview = false;
    }
    if (oldWidget.invoices != widget.invoices) {
      _prefetchVisibleDetails();
    }
  }

  Future<void> _loadSelectionData(String invoiceId) async {
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final loaded = await Future.wait([
        widget.onLoadInvoiceDetails(invoiceId),
        widget.onLoadInvoicePreviewBytes(invoiceId),
      ]);
      if (!mounted) return;
      setState(() {
        _detailById[invoiceId] = loaded[0] as Invoice;
        _pdfBytesById[invoiceId] = loaded[1] as Uint8List;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _previewError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _openPreview(Invoice invoice) async {
    setState(() {
      _selectedInvoiceId = invoice.id;
      _showPreview = true;
    });
    if (!_detailById.containsKey(invoice.id) ||
        !_pdfBytesById.containsKey(invoice.id)) {
      await _loadSelectionData(invoice.id);
    }
  }

  Future<void> _prefetchVisibleDetails() async {
    if (_prefetchingDetails || widget.invoices.isEmpty) return;
    final missingIds = widget.invoices
        .map((e) => e.id)
        .where((id) => !_detailById.containsKey(id))
        .toList(growable: false);
    if (missingIds.isEmpty) return;
    _prefetchingDetails = true;
    try {
      final loaded = await Future.wait(
        missingIds.map(widget.onLoadInvoiceDetails),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < missingIds.length; i++) {
          _detailById[missingIds[i]] = loaded[i];
        }
      });
    } catch (_) {
      // Silent fallback: list keeps rendering base payload when detail prefetch fails.
    } finally {
      _prefetchingDetails = false;
    }
  }

  int _compareInvoiceNumberAsc(Invoice a, Invoice b) {
    final aNumber = a.invoiceNumber.trim();
    final bNumber = b.invoiceNumber.trim();
    if (aNumber.isEmpty || bNumber.isEmpty) {
      final aDate = a.issueDate ?? a.registeredAt;
      final bDate = b.issueDate ?? b.registeredAt;
      if (aDate != null && bDate != null) {
        final dateComparison = aDate.compareTo(bDate);
        if (dateComparison != 0) return dateComparison;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return a.id.compareTo(b.id);
    }

    final aDigits = RegExp(r'\d+')
        .allMatches(aNumber)
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList();
    final bDigits = RegExp(r'\d+')
        .allMatches(bNumber)
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList();

    final common =
        aDigits.length < bDigits.length ? aDigits.length : bDigits.length;
    for (var i = 0; i < common; i++) {
      final c = aDigits[i].compareTo(bDigits[i]);
      if (c != 0) return c;
    }
    if (aDigits.length != bDigits.length) {
      return aDigits.length.compareTo(bDigits.length);
    }
    return aNumber.toLowerCase().compareTo(bNumber.toLowerCase());
  }

  List<Invoice> _sortedInvoices() {
    if (_numberSort == _GeneratedNumberSort.recent) return widget.invoices;
    final sorted = [...widget.invoices]..sort((a, b) {
        final cmp = _compareInvoiceNumberAsc(a, b);
        return _numberSort == _GeneratedNumberSort.asc ? cmp : -cmp;
      });
    return sorted;
  }

  HexoraDocumentStatus _documentStatus(String? value) {
    final status = (value ?? '').trim().toLowerCase();
    if (status.contains('cancel')) return HexoraDocumentStatus.cancelled;
    if (status.contains('rectif')) return HexoraDocumentStatus.rectified;
    if (status.contains('issue')) return HexoraDocumentStatus.issued;
    if (status.isEmpty || status.contains('draft')) {
      return HexoraDocumentStatus.draft;
    }
    return HexoraDocumentStatus.warning;
  }

  _InvoiceAmounts _amountsFor(Invoice invoice) {
    num subtotal = invoice.subtotal ?? 0;
    num tax = invoice.taxTotal ?? 0;
    num total = invoice.total ?? 0;
    final hasHeaderAmounts = invoice.subtotal != null ||
        invoice.taxTotal != null ||
        invoice.total != null;

    num linesSubtotal = 0;
    num linesTax = 0;
    num linesTotal = 0;
    for (final line in invoice.lines) {
      final ls = line.lineSubtotal ?? (line.quantity * line.unitPrice);
      final lt = line.lineTax ?? (ls * line.taxRate / 100);
      final ltot = line.lineTotal ?? (ls + lt);
      linesSubtotal += ls;
      linesTax += lt;
      linesTotal += ltot;
    }

    num blocksSubtotal = 0;
    num blocksTax = 0;
    num blocksTotal = 0;
    for (final block in invoice.blocks) {
      if (block.type != 'item') continue;
      final bs = block.lineSubtotal;
      final bt = block.lineTax;
      final btot = block.lineTotal;
      if (bs != null) blocksSubtotal += bs;
      if (bt != null) blocksTax += bt;
      if (btot != null) blocksTotal += btot;
      if (bs == null && bt == null && btot == null) {
        final qty = block.qty ?? 0;
        final unitPrice = block.unitPrice ?? 0;
        final rate = block.taxRate ?? 0;
        final calcBase = qty * unitPrice;
        final calcTax = calcBase * rate / 100;
        blocksSubtotal += calcBase;
        blocksTax += calcTax;
        blocksTotal += calcBase + calcTax;
      }
    }

    final fallbackSubtotal = linesSubtotal > 0 ? linesSubtotal : blocksSubtotal;
    final fallbackTax = linesTax > 0 ? linesTax : blocksTax;
    final fallbackTotal = linesTotal > 0 ? linesTotal : blocksTotal;
    final hasFallbackAmounts =
        fallbackSubtotal > 0 || fallbackTax > 0 || fallbackTotal > 0;

    final headerLooksEmpty = subtotal == 0 && tax == 0 && total == 0;
    if ((!hasHeaderAmounts || headerLooksEmpty) && hasFallbackAmounts) {
      subtotal = fallbackSubtotal;
      tax = fallbackTax;
      total = fallbackTotal;
    }

    if (total == 0 && (subtotal != 0 || tax != 0)) {
      total = subtotal + tax;
    }
    if (subtotal == 0 && total != 0 && tax != 0) {
      subtotal = total - tax;
    }

    return _InvoiceAmounts(subtotal: subtotal, tax: tax, total: total);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final emptyGeneratedLabel = widget.receiptsMode
        ? (isEs ? 'No hay recibos generados.' : 'No generated receipts.')
        : l.recurringInvoicesSeriesInvoicesEmpty;
    final listHeaderLabel = widget.receiptsMode
        ? (isEs ? 'Recibos' : 'Receipts')
        : (isEs ? 'Facturas' : 'Invoices');
    final visibleInvoices = _sortedInvoices();
    final Invoice? selectedInvoice = visibleInvoices.isEmpty
        ? null
        : visibleInvoices.firstWhere(
            (i) => i.id == _selectedInvoiceId,
            orElse: () => visibleInvoices.first,
          );
    final Invoice? selectedResolved = selectedInvoice == null
        ? null
        : (_detailById[selectedInvoice.id] ?? selectedInvoice);

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

    Widget sortIcon({
      required _GeneratedNumberSort value,
      required IconData icon,
      required String tooltip,
    }) {
      final active = _numberSort == value;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _numberSort = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active
                  ? cs.primaryContainer
                  : cs.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active
                    ? cs.primaryContainer
                    : cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final header = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Text(
            listHeaderLabel,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${widget.count ?? widget.invoices.length}',
              style: t.bodySmall.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          sortIcon(
            value: _GeneratedNumberSort.recent,
            icon: Icons.schedule_outlined,
            tooltip: l.invoiceSortByNumberRecent,
          ),
          const SizedBox(width: 4),
          sortIcon(
            value: _GeneratedNumberSort.asc,
            icon: Icons.arrow_upward,
            tooltip: l.invoiceSortByNumberAsc,
          ),
          const SizedBox(width: 4),
          sortIcon(
            value: _GeneratedNumberSort.desc,
            icon: Icons.arrow_downward,
            tooltip: l.invoiceSortByNumberDesc,
          ),
          const Spacer(),
          Tooltip(
            message: l.recurringInvoicesRefreshCta,
            child: IconButton(
              onPressed: widget.loading ? null : widget.onReload,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            ),
          ),
        ],
      ),
    );

    if (!widget.hasRequested || widget.loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (widget.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 8),
          Text(
            widget.error!,
            style: t.bodySmall.copyWith(color: cs.error),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (visibleInvoices.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 8),
          Text(
            emptyGeneratedLabel,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    Widget buildInvoicePreview(Invoice inv) {
      final date = inv.occurrenceDate ?? inv.issueDate ?? inv.registeredAt;
      final dateLabel = date == null
          ? '-'
          : DateFormat.yMMMd(l.localeName).add_Hm().format(date);
      final pdfBytes = _pdfBytesById[inv.id];

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  inv.displayNumber(draftLabel: l.statusDraft),
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  dateLabel,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                Text(
                  statusLabel(inv.status),
                  style: t.bodySmall.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingPreview && pdfBytes == null)
              const Center(child: CircularProgressIndicator()),
            if ((_previewError ?? '').trim().isNotEmpty && pdfBytes == null)
              Text(
                _previewError!,
                style: t.bodySmall.copyWith(color: cs.error),
              ),
            if (pdfBytes != null)
              Expanded(
                child: PdfInlinePreview(bytes: pdfBytes),
              ),
          ],
        ),
      );
    }

    if (_showPreview && selectedResolved != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _showPreview = false),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(isEs ? 'Atrás' : 'Back'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEs ? 'Previsualización PDF' : 'PDF preview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: buildInvoicePreview(selectedResolved)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 8),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              Widget buildInvoiceCard(Invoice inv) {
                final resolved = _detailById[inv.id] ?? inv;
                final selected = inv.id == selectedInvoice?.id;
                final date = resolved.issueDate ??
                    resolved.registeredAt ??
                    resolved.occurrenceDate;
                final dateLabel = date == null
                    ? '-'
                    : DateFormat.yMMMd(l.localeName).format(date.toLocal());
                final currency = (resolved.currency ?? 'EUR').trim();
                final amounts = _amountsFor(resolved);
                final money = NumberFormat.simpleCurrency(
                  locale: l.localeName,
                  name: currency.isEmpty ? 'EUR' : currency,
                );
                final isLinked = resolved.isLinkedResolved;
                final linkedCount = resolved.linkedEntriesCountSafe;
                final linkedLabel = isLinked
                    ? (linkedCount > 0
                        ? (isEs
                            ? 'Vinculada a $linkedCount movimientos bancarios'
                            : 'Linked to $linkedCount bank transactions')
                        : (isEs ? 'Vinculada' : 'Linked'))
                    : (isEs ? 'No vinculada' : 'Not linked');

                Future<void> selectInvoice() async {
                  if (wide) {
                    setState(() => _selectedInvoiceId = inv.id);
                    if (!_detailById.containsKey(inv.id) ||
                        !_pdfBytesById.containsKey(inv.id)) {
                      await _loadSelectionData(inv.id);
                    }
                  } else {
                    await _openPreview(inv);
                  }
                }

                void handleMenuAction(String value) {
                  switch (value) {
                    case 'preview':
                      _openPreview(inv);
                    case 'download':
                      widget.onDownloadPdf(inv);
                    case 'details':
                      widget.onOpenInvoice?.call(resolved);
                  }
                }

                return InkWell(
                  key: ValueKey('generated-invoice-row-${inv.id}'),
                  onTap: selectInvoice,
                  borderRadius: BorderRadius.circular(HexoraDimensions.radius),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: HexoraDocumentTokens.rowHeight,
                      maxHeight: 68,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primaryContainer.withValues(alpha: 0.28)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(HexoraDimensions.radius),
                      border: Border.all(
                        color: selected
                            ? cs.primary.withValues(alpha: 0.65)
                            : cs.outlineVariant.withValues(
                                alpha: HexoraTableTokens.separatorOpacity,
                              ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 28,
                          child: Center(
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color:
                                  selected ? cs.primary : cs.onSurfaceVariant,
                              size: HexoraDocumentTokens.icon,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                resolved.displayNumber(
                                  draftLabel: l.statusDraft,
                                ),
                                style: t.bodySmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: HexoraTypography.fontFamily,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontFamily: HexoraTypography.fontFamily,
                                  fontSize: HexoraTypography.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          key: ValueKey('generated-invoice-total-${inv.id}'),
                          width: constraints.maxWidth < 520 ? 82 : 108,
                          child: Text(
                            money.format(amounts.total),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: t.bodySmall.copyWith(
                              fontFamily: HexoraTypography.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: HexoraTypography.numericFeatures,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 96),
                          child: HexoraStatusBadge.document(
                            context,
                            key: ValueKey('generated-invoice-status-${inv.id}'),
                            status: _documentStatus(resolved.status),
                            label: statusLabel(resolved.status),
                          ),
                        ),
                        if (!widget.receiptsMode) ...[
                          const SizedBox(width: 4),
                          SizedBox.square(
                            key: ValueKey(
                                'generated-invoice-delivery-${inv.id}'),
                            dimension: 28,
                            child: Center(
                              child: DeliveryStatusBadge(
                                status: resolved.deliveryStatus,
                                channel: resolved.deliveryChannel,
                                sentAt: resolved.sentAt,
                                deliveryError: resolved.deliveryError,
                                compact: true,
                                feminine: true,
                              ),
                            ),
                          ),
                          SizedBox.square(
                            key: ValueKey('generated-invoice-link-${inv.id}'),
                            dimension: 28,
                            child: Tooltip(
                              message: linkedLabel,
                              child: Center(
                                child: Icon(
                                  isLinked
                                      ? Icons.link_rounded
                                      : Icons.link_off_rounded,
                                  size: 16,
                                  color: isLinked
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox.square(
                          dimension: 32,
                          child: PopupMenuButton<String>(
                            key: ValueKey('generated-invoice-menu-${inv.id}'),
                            tooltip: MaterialLocalizations.of(context)
                                .moreButtonTooltip,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: handleMenuAction,
                            itemBuilder: (_) => [
                              NavigationPopupMenuItem<String>(
                                value: 'preview',
                                child: Row(children: [
                                  const Icon(Icons.visibility_outlined,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(isEs ? 'Mostrar PDF' : 'Show PDF'),
                                ]),
                              ),
                              NavigationPopupMenuItem<String>(
                                value: 'download',
                                child: Row(children: [
                                  const Icon(Icons.download_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(l.invoicePdfDownloadCta),
                                ]),
                              ),
                              if (widget.onOpenInvoice != null)
                                NavigationPopupMenuItem<String>(
                                  value: 'details',
                                  child: Row(children: [
                                    const Icon(Icons.open_in_new_rounded,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                        isEs ? 'Ver detalles' : 'View details'),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final list = ListView.separated(
                key: const PageStorageKey<String>(
                    'recurring-generated-invoice-history'),
                itemCount: visibleInvoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => buildInvoiceCard(visibleInvoices[i]),
              );

              if (!wide) {
                return list;
              }

              return Row(
                children: [
                  Expanded(flex: 4, child: list),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: selectedResolved == null
                        ? Center(
                            child: Text(
                              isEs
                                  ? 'Selecciona una factura para ver el PDF.'
                                  : 'Select an invoice to preview the PDF.',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : buildInvoicePreview(selectedResolved),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
