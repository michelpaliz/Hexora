part of '../recent_uploads_tab.dart';

extension _ExpenseRecentUploadsPreviewSection on _ExpenseRecentUploadsTabState {
  Widget _buildPreviewPanel(
    AppLocalizations l,
    AppTypography t,
    ColorScheme cs,
  ) {
    final item = widget.selectedExpense;
    final empty = item == null || item.isEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.preview_outlined, color: cs.onSurface, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.preview,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!empty)
                  IconButton(
                    tooltip: l.viewDetails,
                    onPressed: () async {
                      final fileUrl = (item['fileUrl'] ?? '').toString();
                      final url = Uri.tryParse(fileUrl);
                      if (url != null) {
                        await launchUrl(url, webOnlyWindowName: '_blank');
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 15),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: empty
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 28,
            color: cs.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 6),
          Text(
            l.groupInvoicesSelectInvoiceHint,
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
    final vendor = (item['vendor'] ?? '-').toString();
    final total = (item['total'] ?? '').toString();
    final currency = (item['currency'] ?? '').toString();
    final date = (item['date'] ?? '').toString();
    final due = (item['due'] ?? '').toString();
    final tax = (item['tax'] ?? '').toString();
    final file = (item['file'] ?? '').toString();
    final invoice = (item['invoice'] ?? '').toString();
    final provider = (item['providerName'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final linesCount = (item['linesCount'] ?? '').toString();
    final linesSummary = (item['linesSummary'] ?? '').toString();
    final base = _computeBaseAmount(total, tax, '');
    final taxDisplay = _formatAmountOrText(tax);
    final shortDate = _shortDate(date);
    final totalDisplay = _formatAmountOrText(total);
    final fileUrl = (item['fileUrl'] ?? '').toString();
    final mimeType = (item['mimeType'] ?? '').toString();
    final lcUrl = fileUrl.toLowerCase();
    final lcFile = file.toLowerCase();
    final isImage = mimeType.startsWith('image/') ||
        lcUrl.endsWith('.png') ||
        lcUrl.endsWith('.jpg') ||
        lcUrl.endsWith('.jpeg') ||
        lcFile.endsWith('.png') ||
        lcFile.endsWith('.jpg') ||
        lcFile.endsWith('.jpeg');
    final isPdf = mimeType == 'application/pdf' ||
        lcUrl.endsWith('.pdf') ||
        lcFile.endsWith('.pdf');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vendor,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (status.isNotEmpty) ...[
                const SizedBox(width: 6),
                _StatusPill(label: status, cs: cs),
              ],
            ],
          ),
          const SizedBox(height: 2),
          if (total.isNotEmpty)
            Text(
              [totalDisplay, if (currency.isNotEmpty) currency].join(' '),
              style: t.bodySmall.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              if (shortDate.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadIssueDateLabel,
                  value: shortDate,
                  icon: Icons.event_outlined,
                  cs: cs,
                ),
              if (due.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadDueDateLabel,
                  value: _shortDate(due),
                  icon: Icons.calendar_month_outlined,
                  cs: cs,
                ),
              if (invoice.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadInvoiceNumberLabel,
                  value: invoice,
                  icon: Icons.tag_outlined,
                  cs: cs,
                ),
              if (provider.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadVendorLabel,
                  value: provider,
                  icon: Icons.business_outlined,
                  cs: cs,
                ),
              if (totalDisplay.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadTotalLabel,
                  value: [
                    totalDisplay,
                    if (currency.isNotEmpty) currency,
                  ].join(' '),
                  icon: Icons.payments_outlined,
                  cs: cs,
                ),
              if (base.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadLinesSubtotalLabel,
                  value: base,
                  icon: Icons.layers_outlined,
                  cs: cs,
                ),
              if (tax.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadTaxTotalLabel,
                  value: taxDisplay,
                  icon: Icons.percent_outlined,
                  cs: cs,
                ),
              if (linesCount.isNotEmpty)
                _InfoBox(
                  label: l.expenseUploadLinesTitle,
                  value: linesCount,
                  icon: Icons.format_list_numbered,
                  cs: cs,
                ),
            ],
          ),
          if (linesSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.expenseUploadLinesTitle,
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    linesSummary,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          if (file.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.attach_file, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    file,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
          const SizedBox(height: 6),
          if (widget.previewLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (fileUrl.isNotEmpty && isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                fileUrl,
                fit: BoxFit.contain,
              ),
            )
          else if (fileUrl.isNotEmpty && isPdf)
            FutureBuilder<Uint8List?>(
              future: _loadPdfPreviewBytes(fileUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final bytes = snapshot.data;
                if (bytes != null && bytes.isNotEmpty) {
                  return PdfInlinePreview(
                    bytes: bytes,
                    height: 420,
                  );
                }
                return OutlinedButton.icon(
                  onPressed: () async {
                    final url = Uri.tryParse(fileUrl);
                    if (url != null) await launchUrl(url);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.viewDetails),
                );
              },
            )
          else if (fileUrl.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.tryParse(fileUrl);
                if (url != null) await launchUrl(url);
              },
              icon: const Icon(Icons.open_in_new),
              label: Text(l.viewDetails),
            )
          else if (widget.previewError != null)
            Text(
              'Preview unavailable',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
