import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceFormSheet extends StatefulWidget {
  final String groupId;
  final List<GroupClient> clients;
  final InvoicesApi api;
  final InvoiceLinesApi linesApi;
  final String? selectedClientId;
  const InvoiceFormSheet({
    super.key,
    required this.groupId,
    required this.clients,
    required this.api,
    required this.linesApi,
    this.selectedClientId,
  });

  @override
  State<InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<InvoiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _digits = TextEditingController(text: '001');
  final _pdfUrl = TextEditingController();
  final _notes = TextEditingController();
  String? _clientId;
  DateTime? _registeredAt;
  String _status = 'draft';
  bool _saving = false;
  final List<LineDraft> _lines = [];

  String get _yearSuffix => DateFormat('yy').format(DateTime.now());
  String get _invoiceNumber => '${_digits.text.padLeft(3, '0')}-$_yearSuffix';

  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) {
      _clientId = widget.selectedClientId ?? widget.clients.first.id;
    }
    _lines.add(LineDraft(position: 1));
  }

  @override
  void dispose() {
    _digits.dispose();
    _pdfUrl.dispose();
    _notes.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> _pickRegisteredAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _registeredAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_registeredAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _registeredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }
    final lineDrafts = _lines.map((d) => d.toLine()).toList();
    setState(() => _saving = true);
    try {
      final invoice = Invoice(
        id: '',
        invoiceNumber: _invoiceNumber,
        groupId: widget.groupId,
        clientId: _clientId!,
        pdfUrl: _pdfUrl.text.trim().isEmpty ? null : _pdfUrl.text.trim(),
        registeredAt: _registeredAt,
        status: _status,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      final created = await widget.api.create(invoice);

      final createdLines = <InvoiceLine>[];
      for (final draft in lineDrafts) {
        final saved = await widget.linesApi.create(created.id, draft);
        createdLines.add(saved);
      }

      if (!mounted) return;
      Navigator.of(context).pop<Invoice>(created.copyWith(lines: createdLines));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final pad = MediaQuery.of(context).viewInsets.bottom + 16;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
    );

    final total = _lines.fold<num>(0, (sum, line) {
      final qty = line.quantity ?? 1;
      final price = line.unitPrice ?? 0;
      final taxRate = line.taxRate ?? 21;
      final subtotal = qty * price;
      final tax = subtotal * (taxRate / 100);
      return sum + subtotal + tax;
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, pad),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.createInvoiceCta,
                      style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Chip(
                    label: Text(
                      _invoiceNumber,
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: l.invoiceStatusLabel,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 'draft', child: Text(l.statusDraft)),
                  DropdownMenuItem(
                      value: 'issued', child: Text(l.statusIssued)),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'draft'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _digits,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: l.invoiceNumberLabel,
                  helperText: l.invoiceNumberHelper(_yearSuffix),
                  suffixText: '-$_yearSuffix',
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
                validator: (v) {
                  final value = (v ?? '').padLeft(3, '0');
                  if (value.length != 3) return l.invoiceNumberInvalid;
                  if (!RegExp(r'^[0-9]{3}$').hasMatch(value)) {
                    return l.invoiceNumberInvalid;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _clientId,
                decoration: InputDecoration(
                  labelText: l.invoiceClientLabel,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
                items: widget.clients
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _clientId = v),
                validator: (v) => v == null ? l.invoiceClientRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pdfUrl,
                decoration: InputDecoration(
                  labelText: l.invoicePdfUrl,
                  prefixIcon: const Icon(Icons.link),
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l.invoiceRegisteredAt),
                subtitle: Text(
                  _registeredAt == null
                      ? l.optionalLabel
                      : DateFormat.yMMMd(l.localeName)
                          .add_Hm()
                          .format(_registeredAt!.toLocal()),
                ),
                trailing: TextButton(
                  onPressed: _pickRegisteredAt,
                  child: Text(
                    _registeredAt == null ? l.select : l.change,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l.invoiceNotesLabel,
                  enabledBorder: inputBorder,
                  focusedBorder: inputBorder.copyWith(
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InvoiceLinesEditor(
                  lines: _lines, onChanged: () => setState(() {})),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${l.invoiceTotalLabel}: ${NumberFormat.simpleCurrency(name: '').format(total)}',
                  style: t.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving ? l.saving : l.createInvoiceCta,
                    style: t.bodySmall.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
