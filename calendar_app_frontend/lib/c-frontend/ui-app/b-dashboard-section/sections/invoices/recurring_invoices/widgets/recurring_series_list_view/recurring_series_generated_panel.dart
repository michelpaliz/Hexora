import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_detail_view/recurring_detail_generated_tab.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringSeriesGeneratedPanel extends StatefulWidget {
  const RecurringSeriesGeneratedPanel({
    super.key,
    required this.api,
    required this.series,
    this.receiptsMode = false,
  });

  final RecurringInvoicesApi api;
  final Map<String, dynamic> series;
  final bool receiptsMode;

  @override
  State<RecurringSeriesGeneratedPanel> createState() =>
      _RecurringSeriesGeneratedPanelState();
}

class _RecurringSeriesGeneratedPanelState
    extends State<RecurringSeriesGeneratedPanel> {
  final InvoicesApi _invoicesApi = InvoicesApi();
  final ReceiptsApi _receiptsApi = ReceiptsApi();
  bool _loading = false;
  bool _hasRequested = false;
  String? _error;
  int? _count;
  List<Invoice> _invoices = const [];

  @override
  void didUpdateWidget(covariant RecurringSeriesGeneratedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (seriesId(oldWidget.series) == seriesId(widget.series)) return;
    setState(() {
      _loading = false;
      _hasRequested = false;
      _error = null;
      _count = null;
      _invoices = const [];
    });
  }

  Future<void> _loadGenerated() async {
    final id = seriesId(widget.series);
    if (id.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _hasRequested = true;
      _error = null;
    });
    try {
      final result = await widget.api.listGeneratedInvoices(id);
      if (!mounted) return;
      setState(() {
        _invoices = result.invoices;
        _count = result.count;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Invoice> _loadInvoiceDetails(String invoiceId) {
    if (widget.receiptsMode) {
      return Future.value(
        _invoices.firstWhere(
          (invoice) => invoice.id == invoiceId,
          orElse: () => Invoice(
            id: invoiceId,
            invoiceNumber: '',
            groupId: '',
            clientId: '',
          ),
        ),
      );
    }
    return _invoicesApi.getById(invoiceId);
  }

  Future<Uint8List> _loadInvoicePreviewBytes(String invoiceId) async {
    final response = widget.receiptsMode
        ? await _receiptsApi.previewPdf(invoiceId)
        : await _invoicesApi.previewPdf(invoiceId);
    return InvoiceEditorPdf.validatePdf(response);
  }

  Future<void> _downloadInvoicePdf(Invoice invoice) async {
    if (invoice.id.trim().isEmpty) return;
    try {
      final response = widget.receiptsMode
          ? await _receiptsApi.downloadPdf(invoice.id)
          : await _invoicesApi.downloadPdf(invoice.id);
      final fallback = invoice.invoiceNumber.trim().isNotEmpty
          ? invoice.invoiceNumber.trim()
          : invoice.id.trim();
      await launchFileDownload(
        response.bodyBytes,
        fileName: fallback.endsWith('.pdf')
            ? fallback
            : '${widget.receiptsMode ? 'receipt' : 'invoice'}-$fallback.pdf',
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final generatedTitle = widget.receiptsMode
        ? (isEs ? 'PDFs de recibos' : 'Receipt PDFs')
        : (isEs ? 'PDFs generados' : 'Generated PDFs');
    final title =
        (widget.series['clientName'] ?? widget.series['client']?['name'] ?? '')
            .toString()
            .trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 18,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generatedTitle,
                      style: t.bodyMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RecurringDetailGeneratedTab(
              loading: _loading,
              error: _error,
              invoices: _invoices,
              onReload: _loadGenerated,
              hasRequested: _hasRequested,
              count: _count,
              onOpenInvoice: (_) {},
              onDownloadPdf: _downloadInvoicePdf,
              onLoadInvoiceDetails: _loadInvoiceDetails,
              onLoadInvoicePreviewBytes: _loadInvoicePreviewBytes,
              receiptsMode: widget.receiptsMode,
            ),
          ),
        ],
      ),
    );
  }
}
