part of '../recent_uploads_tab.dart';

extension _ExpenseRecentUploadsPreviewSection on _ExpenseRecentUploadsTabState {
  Widget _buildPreviewPanel(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
    Map<String, String>? selectedExpense,
  ) {
    final item = selectedExpense;
    final empty = item == null || item.isEmpty;
    final suspended = _suspendBackgroundPreview;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simple header only for empty / suspended states
          if (empty || suspended)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border(
                  bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.preview_outlined, color: cs.onSurface, size: 15),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      suspended ? 'Vista previa pausada' : l.preview,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: suspended
                ? _buildSuspendedPreview(t, cs)
                : item == null || item.isEmpty
                    ? _buildEmptyPreview(l, t, cs)
                    : _buildPreviewContent(item, l, t, cs),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreview(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.receipt_long_outlined,
                  size: 22, color: cs.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'Selecciona una factura',
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige un gasto de la lista para ver su factura, OCR, impuestos y detalles.',
              style:
                  t.bodySmall.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 14),
            for (final feat in const [
              'Datos del proveedor',
              'Imagen o PDF de factura',
              'Resultado OCR',
              'Base imponible e IVA',
              'Categoria y estado',
            ]) ...[
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feat,
                      style: t.bodySmall.copyWith(
                          color: cs.onSurface, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (feat != 'Categoria y estado') const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuspendedPreview(AppTypography t, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pause_circle_outline_rounded,
            size: 28,
            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 8),
          Text(
            'La vista previa se pausa mientras el resolvedor de duplicados esta abierto.',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(
    Map<String, String> item,
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final isLight = cs.brightness == Brightness.light;

    final id = (item['id'] ?? '').toString();
    final reprocessing = _reprocessingExpenseIds.contains(id);
    final vendor = (item['vendor'] ?? '-').toString();
    final total = (item['total'] ?? '').toString();
    final currency = (item['currency'] ?? '').toString();
    final date = (item['date'] ?? '').toString();
    final uploadedAt = (item['uploadedAt'] ?? '').toString();
    final due = (item['due'] ?? '').toString();
    final tax = (item['tax'] ?? '').toString();
    final file = (item['file'] ?? '').toString();
    final invoice = (item['invoice'] ?? '').toString();
    final provider = (item['providerName'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final expenseType =
        ExpenseDocumentTypeX.fromApi((item['expenseType'] ?? '').toString());
    final discountAmount =
        _formatAmountOrText((item['discountAmount'] ?? '').toString());
    final discountPercent = (item['discountPercent'] ?? '').toString().trim();
    final linesCount = (item['linesCount'] ?? '').toString();
    final linesSummary = (item['linesSummary'] ?? '').toString();
    final advancePercent = (item['advancePercent'] ?? '').toString();
    final advanceProjectBaseAmount = _formatAmountOrText(
        (item['advanceProjectBaseAmount'] ?? '').toString());
    final advanceTaxRate = (item['advanceTaxRate'] ?? '').toString();
    final finalAdvanceInvoiceNumber =
        (item['finalAdvanceInvoiceNumber'] ?? '').toString();
    final settlementDeductedTotal =
        _formatAmountOrText((item['settlementDeductedTotal'] ?? '').toString());
    final settlementRemainingTotal = _formatAmountOrText(
        (item['settlementRemainingTotal'] ?? '').toString());
    final settlementGrossTotal =
        _formatAmountOrText((item['settlementGrossTotal'] ?? '').toString());
    final base = _computeBaseAmount(
      total,
      tax,
      '',
      subtotal: (item['subtotal'] ?? '').trim(),
    );
    final taxDisplay = _formatAmountOrText(tax);
    final taxNum = _parseMoney(tax);
    final hasZeroVat = taxNum != null && taxNum.abs() < 0.0001;
    final shortDate = _shortDate(date);
    final uploadDateDisplay = _shortDateTime(uploadedAt);
    final totalDisplay = _formatAmountOrText(total);
    final fileUrl = (item['fileUrl'] ?? '').toString();
    final mimeType = (item['mimeType'] ?? '').toString();
    final lcUrl = fileUrl.toLowerCase();
    final lcFile = file.toLowerCase();
    final isImage = mimeType.startsWith('image/') ||
        lcUrl.endsWith('.png') ||
        lcUrl.endsWith('.jpg') ||
        lcUrl.endsWith('.jpeg') ||
        lcUrl.endsWith('.jpe') ||
        lcFile.endsWith('.png') ||
        lcFile.endsWith('.jpg') ||
        lcFile.endsWith('.jpeg') ||
        lcFile.endsWith('.jpe');
    final isPdf = mimeType == 'application/pdf' ||
        lcUrl.endsWith('.pdf') ||
        lcFile.endsWith('.pdf');

    // OCR completeness heuristic: count how many key fields are populated
    final ocrScore = [
      vendor != '-' && vendor.isNotEmpty,
      total.isNotEmpty,
      date.isNotEmpty,
      tax.isNotEmpty || (item['subtotal'] ?? '').isNotEmpty,
    ].where((v) => v).length;

    // Total color matching summary bar
    final totalColor = isLight ? const Color(0xFFE65100) : cs.secondary;

    // ── Preview media widget ──────────────────────────────────────
    Widget previewMedia;
    if (widget.previewLoading) {
      previewMedia = const SizedBox(
        height: 480,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (fileUrl.isNotEmpty && isImage) {
      previewMedia = SizedBox(
        height: 480,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 8.0,
            child: Image.network(fileUrl,
                fit: BoxFit.contain, width: double.infinity),
          ),
        ),
      );
    } else if (fileUrl.isNotEmpty && isPdf) {
      previewMedia = FutureBuilder<Uint8List?>(
        future: _loadPdfPreviewBytes(fileUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 480,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return PdfInlinePreview(bytes: bytes, height: 520);
          }
          return SizedBox(
            height: 220,
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.tryParse(fileUrl);
                  if (url != null) await launchUrl(url);
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(l.viewDetails),
              ),
            ),
          );
        },
      );
    } else if (fileUrl.isNotEmpty) {
      previewMedia = SizedBox(
        height: 220,
        child: Center(
          child: OutlinedButton.icon(
            onPressed: () async {
              final url = Uri.tryParse(fileUrl);
              if (url != null) await launchUrl(url);
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(l.viewDetails),
          ),
        ),
      );
    } else {
      previewMedia = SizedBox(
        height: 220,
        child: Center(
          child: Text(
            widget.previewError ?? 'Preview unavailable',
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    // ── Secondary metadata fields list ────────────────────────────
    final secondaryFields = <Widget>[
      if (uploadDateDisplay.isNotEmpty)
        _InfoBox(
            label: 'Subido el',
            value: uploadDateDisplay,
            icon: Icons.cloud_upload_outlined,
            cs: cs),
      if (due.isNotEmpty)
        _InfoBox(
            label: l.expenseUploadDueDateLabel,
            value: _shortDate(due),
            icon: Icons.calendar_month_outlined,
            cs: cs),
      if (invoice.isNotEmpty)
        _InfoBox(
            label: l.expenseUploadInvoiceNumberLabel,
            value: invoice,
            icon: Icons.tag_outlined,
            cs: cs),
      if (provider.isNotEmpty)
        _InfoBox(
            label: l.expenseUploadVendorLabel,
            value: provider,
            icon: Icons.business_outlined,
            cs: cs),
      if (discountAmount.isNotEmpty)
        _InfoBox(
            label: 'Descuento aplicado',
            value: discountPercent.isNotEmpty
                ? '$discountAmount · $discountPercent%'
                : discountAmount,
            icon: Icons.discount_outlined,
            cs: cs),
      if (expenseType.isAdvance && advancePercent.trim().isNotEmpty)
        _InfoBox(
            label: 'Anticipo',
            value: '$advancePercent%',
            icon: Icons.percent_outlined,
            cs: cs),
      if (expenseType.isAdvance && advanceProjectBaseAmount.isNotEmpty)
        _InfoBox(
            label: 'Base del proyecto',
            value: advanceProjectBaseAmount,
            icon: Icons.account_tree_outlined,
            cs: cs),
      if (expenseType.isAdvance && advanceTaxRate.trim().isNotEmpty)
        _InfoBox(
            label: 'IVA %',
            value: advanceTaxRate,
            icon: Icons.request_quote_outlined,
            cs: cs),
      if (expenseType.isFinal && finalAdvanceInvoiceNumber.trim().isNotEmpty)
        _InfoBox(
            label: 'Anticipo relacionado',
            value: finalAdvanceInvoiceNumber,
            icon: Icons.link_outlined,
            cs: cs),
      if (expenseType.isFinal && settlementGrossTotal.isNotEmpty)
        _InfoBox(
            label: 'Original',
            value: settlementGrossTotal,
            icon: Icons.receipt_long_outlined,
            cs: cs),
      if (expenseType.isFinal && settlementDeductedTotal.isNotEmpty)
        _InfoBox(
            label: 'Anticipo descontado',
            value: settlementDeductedTotal,
            icon: Icons.remove_circle_outline,
            cs: cs),
      if (expenseType.isFinal && settlementRemainingTotal.isNotEmpty)
        _InfoBox(
            label: 'Resto pendiente',
            value: settlementRemainingTotal,
            icon: Icons.payments_outlined,
            cs: cs),
    ];

    // ── Subtitle line: date · base · IVA · lines ─────────────────
    final subtitleParts = [
      if (shortDate.isNotEmpty) shortDate,
      if (base.isNotEmpty) 'Base $base',
      if (taxDisplay.isNotEmpty) 'IVA $taxDisplay',
      if (linesCount.isNotEmpty)
        '$linesCount ${linesCount == '1' ? 'línea' : 'líneas'}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Sticky KPI header ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
            border: Border(
              bottom:
                  BorderSide(color: cs.outlineVariant.withValues(alpha: 0.28)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Vendor + Total + Pills
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      vendor,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (totalDisplay.isNotEmpty)
                    Text(
                      [
                        totalDisplay,
                        if (currency.isNotEmpty) currency,
                      ].join(' '),
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: totalColor,
                      ),
                    ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    _StatusPill(label: status, cs: cs),
                  ],
                  if (expenseType != ExpenseDocumentType.standard) ...[
                    const SizedBox(width: 5),
                    _ExpenseTypePill(type: expenseType, cs: cs),
                  ],
                  if (hasZeroVat) ...[
                    const SizedBox(width: 5),
                    _VatZeroPill(cs: cs),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              // Row 2: Subtitle + OCR badge + Open action
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitleParts.join(' · '),
                      style: t.bodySmall.copyWith(
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _OcrBadge(score: ocrScore),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: reprocessing
                        ? 'Releyendo factura...'
                        : 'Releer factura',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: id.isEmpty || reprocessing
                          ? null
                          : () => _reprocessExpense(item),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: reprocessing
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.document_scanner_outlined,
                                size: 13,
                                color: const Color(0xFFD97706),
                              ),
                      ),
                    ),
                  ),
                  if (fileUrl.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: l.viewDetails,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () async {
                          final url = Uri.tryParse(fileUrl);
                          if (url != null) {
                            await launchUrl(url, webOnlyWindowName: '_blank');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(Icons.open_in_new,
                              size: 13, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // ── Scrollable body ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Preview media (dominant element)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: previewMedia,
                ),

                // PDF open button
                if (fileUrl.isNotEmpty && isPdf) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.tryParse(fileUrl);
                        if (url != null) {
                          await launchUrl(url, webOnlyWindowName: '_blank');
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(l.invoicePreviewCta),
                    ),
                  ),
                ],

                // Line items — structured presentation
                if (linesSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _LineItemsCard(
                      linesSummary: linesSummary, cs: cs, t: t, l: l),
                ],

                // Secondary metadata (collapsible)
                if (secondaryFields.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ExpandableMetaSection(fields: secondaryFields, cs: cs, t: t),
                ],

                // Filename
                if (file.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.attach_file,
                          size: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          file,
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
