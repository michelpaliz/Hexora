import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_formatters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/l10n/app_localizations.dart';

class InvoiceEditorController extends ChangeNotifier {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;

  InvoiceEditorController({
    required this.group,
    required this.clients,
    this.initialClientId,
  }) {
    if (clients.isNotEmpty) {
      final existing = clients
          .firstWhere(
            (c) => c.id == initialClientId,
            orElse: () => clients.first,
          )
          .id;
      _clientId = existing;
    }
    _refreshClientStats();
  }

  // --- form/state ---
  final formKey = GlobalKey<FormState>();

  final invoiceDate = ValueNotifier<DateTime?>(DateTime.now());
  final dueDate = ValueNotifier<DateTime?>(null);

  final currency = TextEditingController(text: 'EUR');
  final notes = TextEditingController();
  final digits = TextEditingController(text: '001');
  final pdfUrl = TextEditingController();

  final List<LineDraft> lines = <LineDraft>[LineDraft(position: 1)];

  String? _clientId;
  bool _saving = false;
  bool _issuing = false;
  bool _previewedPdf = false;
  Invoice? _savedInvoice;
  int _issuedThisMonthCount = 0;
  int _pendingDraftsCount = 0;
  bool _loadingClientStats = false;

  // --- apis ---
  final _invoicesApi = InvoicesApi();
  final _linesApi = InvoiceLinesApi();

  // --- getters ---
  String? get clientId => _clientId;
  bool get saving => _saving;
  bool get issuing => _issuing;
  bool get previewedPdf => _previewedPdf;
  Invoice? get savedInvoice => _savedInvoice;
  int get issuedThisMonthCount => _issuedThisMonthCount;
  int get pendingDraftsCount => _pendingDraftsCount;
  bool get loadingClientStats => _loadingClientStats;

  String get invoiceNumber => InvoiceEditorFormatters.invoiceNumber(
        digitsText: digits.text,
        now: DateTime.now(),
      );

  String get previewInvoiceNumber =>
      _savedInvoice?.invoiceNumber ?? invoiceNumber;

  bool get hasLines => lines.isNotEmpty;

  num get total => InvoiceEditorFormatters.total(lines);

  String _safeErrorMessage(
    BuildContext context,
    Object error, {
    String? fallback,
  }) {
    final l = AppLocalizations.of(context)!;
    final raw = error.toString().trim();
    final msg = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length).trim()
        : raw;
    final normalized = msg.toLowerCase();
    final technical = <String>[
      'socketexception',
      'clientexception',
      'httpexception',
      'handshakeexception',
      'oserror',
      'formatexception',
    ];
    if (msg.isEmpty || technical.any(normalized.contains)) {
      return fallback ?? l.somethingWentWrong;
    }
    return msg;
  }

  // --- UI hooks ---
  void notifyUi() {
    // Any form change makes the saved draft stale (there is no update API).
    _savedInvoice = null;
    _previewedPdf = false;
    notifyListeners();
  }

  void setClientId(String? v) {
    _clientId = v;
    _savedInvoice = null;
    _previewedPdf = false;
    _refreshClientStats();
    notifyListeners();
  }

  @override
  void dispose() {
    invoiceDate.dispose();
    dueDate.dispose();
    currency.dispose();
    notes.dispose();
    digits.dispose();
    pdfUrl.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.dispose();
  }

  // --- actions ---
  Future<void> pickDate(
      BuildContext context, ValueNotifier<DateTime?> target) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: target.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (selected != null) {
      target.value = selected;
      _savedInvoice = null;
      notifyListeners();
    }
  }

  Future<void> _refreshClientStats() async {
    _loadingClientStats = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final issued = await _invoicesApi.listByGroup(group.id, status: 'issued');
      final drafts = await _invoicesApi.listByGroup(group.id, status: 'draft');

      _pendingDraftsCount = drafts.length;

      if (_clientId == null) {
        _issuedThisMonthCount = 0;
      } else {
        _issuedThisMonthCount = issued.where((inv) {
          if (inv.clientId != _clientId) return false;
          final d = inv.registeredAt ?? inv.issueDate;
          if (d == null) return false;
          return d.year == now.year && d.month == now.month;
        }).length;
      }
    } catch (_) {
      // Keep previous values; stats are a best-effort UI enhancement.
    } finally {
      _loadingClientStats = false;
      notifyListeners();
    }
  }

  Future<Invoice> saveDraft(BuildContext context) async {
    final l = AppLocalizations.of(context)!;

    if (!formKey.currentState!.validate()) {
      throw Exception(l.invoiceFillRequiredFieldsError);
    }
    if (!hasLines) {
      throw Exception(l.invoiceLinesRequired);
    }
    if (_clientId == null) {
      throw Exception(l.selectClientFirst);
    }

    _saving = true;
    notifyListeners();
    try {
      final invoice = Invoice(
        id: '',
        invoiceNumber: invoiceNumber,
        groupId: group.id,
        clientId: _clientId!,
        pdfUrl: pdfUrl.text.trim().isEmpty ? null : pdfUrl.text.trim(),
        registeredAt: invoiceDate.value,
        status: 'draft',
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );

      final created = await _invoicesApi.create(invoice);

      final createdLines = <InvoiceLine>[];
      for (final d in lines) {
        final saved = await _linesApi.create(created.id, d.toLine());
        createdLines.add(saved);
      }

      final merged = created.copyWith(lines: createdLines);
      _savedInvoice = merged;
      notifyListeners();
      return merged;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> handleSaveDraft(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    try {
      final inv = await saveDraft(context);
      if (!context.mounted) return;

      final msg = inv.invoiceNumber.isNotEmpty
          ? l.invoiceDraftSavedSnack(inv.invoiceNumber)
          : l.invoiceDraftSavedSnackNoNumber;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftSaveFailedSnack,
            ),
          ),
        ),
      );
    }
  }

  Future<void> previewPdf(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    if (_savedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoicePreviewNeedsDraft)),
      );
      return;
    }

    try {
      final r = await _invoicesApi.previewPdf(_savedInvoice!.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);

      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'invoice-${_savedInvoice!.invoiceNumber}.pdf',
      );
      _previewedPdf = true;
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoicePdfPreviewFailedSnack,
            ),
          ),
        ),
      );
    }
  }

  Future<void> issue(BuildContext context) async {
    final l = AppLocalizations.of(context)!;

    if (!hasLines || total <= 0 || _clientId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invoiceLinesRequired)));
      return;
    }

    try {
      if (_savedInvoice == null) {
        await saveDraft(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftSaveFailedSnack,
            ),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceIssueConfirmTitle),
        content: Text(l.invoiceIssueConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.invoiceIssueCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _issuing = true;
    notifyListeners();
    try {
      final issued = await _invoicesApi.issue(_savedInvoice!.id);
      _savedInvoice = issued;
      notifyListeners();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.invoiceIssueSuccessSnack(issued.invoiceNumber)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceIssueFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      _issuing = false;
      notifyListeners();
    }
  }
}
