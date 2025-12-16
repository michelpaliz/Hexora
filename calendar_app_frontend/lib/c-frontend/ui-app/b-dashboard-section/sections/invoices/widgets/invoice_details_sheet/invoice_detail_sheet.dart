import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_details_sheet/invoice_detail_lines.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_details_sheet/invoice_detail_party.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class InvoiceDetailSheet extends StatefulWidget {
  final Invoice invoice;
  final GroupClient client;
  final BillingProfile? billingProfile;

  const InvoiceDetailSheet({
    super.key,
    required this.invoice,
    required this.client,
    required this.billingProfile,
  });

  @override
  State<InvoiceDetailSheet> createState() => _InvoiceDetailSheetState();
}

class _InvoiceDetailSheetState extends State<InvoiceDetailSheet> {
  final _invoicesApi = InvoicesApi();
  final _linesApi = InvoiceLinesApi();
  bool _loading = true;
  String? _error;
  List<InvoiceLine> _lines = const [];
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _lines = widget.invoice.lines;
    _fetchLines();
  }

  Future<void> _fetchLines() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _linesApi.list(widget.invoice.id);
      if (!mounted) return;
      setState(() => _lines = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num get _total => _lines.fold<num>(0, (sum, l) => sum + (l.lineTotal ?? 0));

  Future<void> _previewPdf() async {
    setState(() => _previewing = true);
    try {
      final r = await _invoicesApi.previewPdf(widget.invoice.id);
      final bytes = _validatePdf(r);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'invoice-${widget.invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Uint8List _validatePdf(http.Response r) {
    final bytes = r.bodyBytes;
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    final looksPdf =
        bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';
    if (bytes.isNotEmpty && (ct.contains('pdf') || looksPdf)) return bytes;

    // Try rebuilding if server returned JSON map of byte values.
    try {
      final parsed =
          jsonDecode(utf8.decode(bytes, allowMalformed: true)) as Map?;
      if (parsed != null && parsed.isNotEmpty) {
        final orderedKeys = parsed.keys
            .map((k) => int.tryParse(k.toString()) ?? -1)
            .where((k) => k >= 0)
            .toList()
          ..sort();
        final buffer = List<int>.generate(
          orderedKeys.length,
          (i) => parsed[orderedKeys[i].toString()] as int? ?? 0,
        );
        final rebuilt = Uint8List.fromList(buffer);
        final looksRebuiltPdf = rebuilt.length > 4 &&
            String.fromCharCodes(rebuilt.take(4)) == '%PDF';
        if (looksRebuiltPdf) return rebuilt;
      }
    } catch (_) {
      // fall through
    }

    final sample =
        utf8.decode(bytes.take(200).toList(), allowMalformed: true);
    throw Exception(sample.isNotEmpty
        ? 'Preview failed: $sample'
        : 'Preview failed: empty response (${r.statusCode})');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final issuer = widget.invoice.issuerSnapshot ?? widget.billingProfile;
    final clientBilling =
        widget.invoice.clientSnapshot ?? widget.client.billing;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.invoice.invoiceNumber,
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _previewing ? null : _previewPdf,
                      icon: _previewing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(l.invoicePdfUrl),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(status: widget.invoice.status ?? 'draft'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.client.name,
              textAlign: TextAlign.start,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: l.invoiceRegisteredAt,
              value: widget.invoice.registeredAt != null
                  ? DateFormat.yMMMd(l.localeName)
                      .add_Hm()
                      .format(widget.invoice.registeredAt!.toLocal())
                  : l.invoiceRegisteredUnknown,
            ),
            if (widget.invoice.pdfUrl != null &&
                widget.invoice.pdfUrl!.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: Text(l.invoicePdfUrl),
                subtitle: Text(widget.invoice.pdfUrl!),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () {
                    final uri = Uri.tryParse(widget.invoice.pdfUrl!);
                    if (uri != null) {
                      launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            const SizedBox(height: 12),
            InvoiceDetailParty(
              issuer: issuer,
              clientBilling: clientBilling,
            ),
            const SizedBox(height: 12),
            InvoiceDetailLines(
              loading: _loading,
              error: _error,
              lines: _lines,
              onRefresh: _fetchLines,
              totalLabel:
                  '${l.invoiceTotalLabel}: ${NumberFormat.simpleCurrency(name: '').format(_total)}',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: t.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final normalized = status.toLowerCase();
    final bool issued = normalized.contains('issue');
    final Color bg = issued ? cs.secondaryContainer : cs.surfaceVariant;
    final Color fg = issued ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Text(
        normalized.isEmpty ? 'draft' : normalized,
        style: t.bodySmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
