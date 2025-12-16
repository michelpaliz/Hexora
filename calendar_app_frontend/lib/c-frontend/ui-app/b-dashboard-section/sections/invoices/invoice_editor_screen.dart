import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class InvoiceEditorScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  const InvoiceEditorScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
  });

  @override
  State<InvoiceEditorScreen> createState() => _InvoiceEditorScreenState();
}

class _InvoiceEditorScreenState extends State<InvoiceEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceDate = ValueNotifier<DateTime?>(DateTime.now());
  final _dueDate = ValueNotifier<DateTime?>(null);
  final _currency = TextEditingController(text: 'EUR');
  final _notes = TextEditingController();
  final _digits = TextEditingController(text: '001');
  final _pdfUrl = TextEditingController();
  final _lines = <LineDraft>[LineDraft(position: 1)];

  String? _clientId;
  bool _saving = false;
  bool _issuing = false;
  Invoice? _savedInvoice;

  final _invoicesApi = InvoicesApi();
  final _linesApi = InvoiceLinesApi();

  String get _yearSuffix => DateFormat('yy').format(DateTime.now());
  String get _invoiceNumber => '${_digits.text.padLeft(3, '0')}-$_yearSuffix';

  bool get _hasLines => _lines.isNotEmpty;
  num get _total => _lines.fold<num>(0, (sum, line) {
        final qty = line.quantity ?? 1;
        final price = line.unitPrice ?? 0;
        final taxRate = line.taxRate ?? 21;
        final subtotal = qty * price;
        final tax = subtotal * (taxRate / 100);
        return sum + subtotal + tax;
      });

  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) {
      final existing = widget.clients
          .firstWhere(
            (c) => c.id == widget.initialClientId,
            orElse: () => widget.clients.first,
          )
          .id;
      _clientId = existing;
    }
  }

  @override
  void dispose() {
    _invoiceDate.dispose();
    _dueDate.dispose();
    _currency.dispose();
    _notes.dispose();
    _digits.dispose();
    _pdfUrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(ValueNotifier<DateTime?> target) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: target.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selected != null) target.value = selected;
  }

  Future<Invoice> _saveDraft() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      throw Exception(l.failedWithReason('Please fill required fields'));
    }
    if (!_hasLines) {
      throw Exception(l.invoiceLinesRequired);
    }
    if (_clientId == null) {
      throw Exception(l.selectClientFirst);
    }
    setState(() => _saving = true);
    try {
      final invoice = Invoice(
        id: '',
        invoiceNumber: _invoiceNumber,
        groupId: widget.group.id,
        clientId: _clientId!,
        pdfUrl: _pdfUrl.text.trim().isEmpty ? null : _pdfUrl.text.trim(),
        registeredAt: _invoiceDate.value,
        status: 'draft',
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      final created = await _invoicesApi.create(invoice);
      final createdLines = <InvoiceLine>[];
      for (final d in _lines) {
        final saved = await _linesApi.create(created.id, d.toLine());
        createdLines.add(saved);
      }
      final merged = created.copyWith(lines: createdLines);
      setState(() => _savedInvoice = merged);
      return merged;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _previewPdf() async {
    if (_savedInvoice == null) await _saveDraft();
    if (_savedInvoice == null) return;
    try {
      final r = await _invoicesApi.previewPdf(_savedInvoice!.id);
      final bytes = _validatePdf(r);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'invoice-${_savedInvoice!.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleSaveDraft() async {
    final l = AppLocalizations.of(context)!;
    try {
      final inv = await _saveDraft();
      if (!mounted) return;
      final msg = inv.invoiceNumber.isNotEmpty
          ? 'Draft saved: ${inv.invoiceNumber}'
          : 'Draft saved';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _issue() async {
    final l = AppLocalizations.of(context)!;
    if (!_hasLines || _total <= 0 || _clientId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }
    try {
      if (_savedInvoice == null) {
        await _saveDraft();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.billingTaxRate), // reuse string
        content: Text(
          'Assign final number and lock invoice?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.createInvoiceCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _issuing = true);
    try {
      final issued = await _invoicesApi.issue(_savedInvoice!.id);
      setState(() => _savedInvoice = issued);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issued ${issued.invoiceNumber}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    Widget left = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _clientId,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: widget.clients
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _clientId = v),
                  validator: (v) => v == null ? 'Select client' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<DateTime?>(
                  valueListenable: _invoiceDate,
                  builder: (_, v, __) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Invoice date'),
                    subtitle:
                        Text(v != null ? DateFormat.yMMMd().format(v) : 'None'),
                    trailing: TextButton(
                      onPressed: () => _pickDate(_invoiceDate),
                      child: const Text('Change'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<DateTime?>(
                  valueListenable: _dueDate,
                  builder: (_, v, __) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Due date'),
                    subtitle:
                        Text(v != null ? DateFormat.yMMMd().format(v) : 'None'),
                    trailing: TextButton(
                      onPressed: () => _pickDate(_dueDate),
                      child: const Text('Change'),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l.invoiceNotesLabel,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InvoiceLinesEditor(lines: _lines, onChanged: () => setState(() {})),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${l.invoiceTotalLabel}: ${NumberFormat.simpleCurrency(name: '').format(_total)}',
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    Widget right = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview',
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            _savedInvoice?.invoiceNumber ?? _invoiceNumber,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(_notes.text.isEmpty ? 'No notes' : _notes.text),
          const SizedBox(height: 8),
          Text('Lines: ${_lines.length}'),
          const SizedBox(height: 8),
          Text(
              'Total: ${NumberFormat.simpleCurrency(name: '').format(_total)}'),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _previewPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF Preview'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice editor', style: t.titleLarge),
        actions: [
          TextButton(
            onPressed: _saving ? null : _handleSaveDraft,
            child: Text(_saving ? l.saving : 'Save draft'),
          ),
          TextButton(
            onPressed: _issuing ? null : _issue,
            child: Text(_issuing ? l.saving : 'Issue'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(flex: 3, child: left),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: right),
          ],
        ),
      ),
    );
  }

  Uint8List _validatePdf(http.Response r) {
    final bytes = r.bodyBytes;
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    final looksPdf =
        bytes.length > 4 && String.fromCharCodes(bytes.take(4)) == '%PDF';
    if (bytes.isNotEmpty && (ct.contains('pdf') || looksPdf)) return bytes;

    // Some backends return a JSON object of byte values. Try to reconstruct.
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
      // fall through to error
    }

    final sample = utf8.decode(bytes.take(200).toList(), allowMalformed: true);
    throw Exception(sample.isNotEmpty
        ? 'Preview failed: $sample'
        : 'Preview failed: empty response (${r.statusCode})');
  }
}
