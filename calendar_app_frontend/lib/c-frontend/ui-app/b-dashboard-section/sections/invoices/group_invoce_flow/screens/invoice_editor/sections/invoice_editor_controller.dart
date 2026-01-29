import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_formatters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
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
  final List<InvoiceBlockDraft> blocks = <InvoiceBlockDraft>[
    InvoiceBlockDraft.item()
  ];

  String? _clientId;
  bool _saving = false;
  bool _issuing = false;
  bool _previewedPdf = false;
  bool _useBlocks = true;
  bool _deletingDraft = false;
  Invoice? _savedInvoice;
  List<Invoice> _pendingDrafts = const [];
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
  List<Invoice> get pendingDrafts => _pendingDrafts;
  bool get loadingClientStats => _loadingClientStats;
  bool get useBlocks => _useBlocks;
  bool get deletingDraft => _deletingDraft;

  String get invoiceNumber => InvoiceEditorFormatters.invoiceNumber(
        digitsText: digits.text,
        now: DateTime.now(),
      );

  String get previewInvoiceNumber =>
      _savedInvoice?.invoiceNumber ?? invoiceNumber;

  bool get hasLines => lines.isNotEmpty;

  bool get hasBillableEntries {
    if (_useBlocks) {
      return blocks.any((block) => block.hasBillableContent);
    }
    return lines.any((line) =>
        line.description.text.trim().isNotEmpty && (line.unitPrice ?? 0) > 0);
  }

  num get total => _useBlocks
      ? InvoiceEditorFormatters.totalBlocks(blocks)
      : InvoiceEditorFormatters.total(lines);

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

  void setUseBlocks(bool value) {
    if (_useBlocks == value) return;
    _useBlocks = value;
    notifyUi();
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
    for (final b in blocks) {
      b.dispose();
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
      _pendingDrafts = drafts;

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
    if (_useBlocks) {
      if (!hasBillableEntries) {
        throw Exception(l.invoiceLinesRequired);
      }
      _validateBlocks(l);
    } else if (!hasLines) {
      throw Exception(l.invoiceLinesRequired);
    }
    if (_clientId == null) {
      throw Exception(l.selectClientFirst);
    }

    _saving = true;
    notifyListeners();
    try {
      final sanitizedBlocks =
          _useBlocks ? _sanitizeBlocks(blocks) : const <InvoiceBlock>[];
      final invoice = Invoice(
        id: '',
        invoiceNumber: invoiceNumber,
        groupId: group.id,
        clientId: _clientId!,
        pdfUrl: pdfUrl.text.trim().isEmpty ? null : pdfUrl.text.trim(),
        currency: currency.text.trim().isEmpty ? 'EUR' : currency.text.trim(),
        issueDate: invoiceDate.value,
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        blocks: sanitizedBlocks,
      );

      final payload = invoice.toCreatePayload();
      debugPrint('[InvoiceDraft] create payload: $payload');
      final created = await _invoicesApi.create(invoice);
      debugPrint('[InvoiceDraft] create response: ${created.toJson()}');
      try {
        final fetched = await _invoicesApi.getById(created.id);
        debugPrint('[InvoiceDraft] fetched response: ${fetched.toJson()}');
      } catch (e) {
        debugPrint('[InvoiceDraft] fetch failed: $e');
      }

      final createdLines = <InvoiceLine>[];
      if (!_useBlocks) {
        for (final d in lines) {
          final saved = await _linesApi.create(created.id, d.toLine());
          createdLines.add(saved);
        }
        _savedInvoice = created.copyWith(lines: createdLines);
      } else {
        _savedInvoice = created.copyWith(blocks: sanitizedBlocks);
      }
      if (_savedInvoice?.status == 'draft') {
        final savedDraft = _savedInvoice!;
        _pendingDrafts = [
          savedDraft,
          ..._pendingDrafts.where((inv) => inv.id != savedDraft.id),
        ];
        _pendingDraftsCount = _pendingDrafts.length;
      }
      notifyListeners();
      return _savedInvoice!;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  List<InvoiceBlock> _sanitizeBlocks(List<InvoiceBlockDraft> draftBlocks) {
    return draftBlocks.map((draft) {
      final block = draft.toBlock();
      final type = block.type;
      if (type == InvoiceBlockType.item) {
        return InvoiceBlock(
          type: type,
          sku: block.sku,
          description: block.description,
          qty: block.qty,
          unit: block.unit,
          unitPrice: block.unitPrice,
          taxRate: block.taxRate,
          level: block.level,
          isBillable: block.isBillable,
        );
      }
      if (type == InvoiceBlockType.date ||
          type == InvoiceBlockType.section ||
          type == InvoiceBlockType.subsection) {
        return InvoiceBlock(
          type: type,
          title: block.title,
          level: type == InvoiceBlockType.subsection ? block.level : null,
        );
      }
      if (type == InvoiceBlockType.note) {
        return InvoiceBlock(
          type: type,
          text: block.text,
          level: block.level,
        );
      }
      if (type == InvoiceBlockType.checklist) {
        return InvoiceBlock(
          type: type,
          items: block.items,
          level: block.level,
        );
      }
      return InvoiceBlock(type: type);
    }).toList();
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
      debugPrint('[InvoicePreview] $e');
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

    if (!hasBillableEntries || total <= 0 || _clientId == null) {
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

  void _validateBlocks(AppLocalizations l) {
    if (blocks.isEmpty) {
      throw Exception(l.invoiceLinesRequired);
    }
    for (final block in blocks) {
      final type = block.type;
      if (type == InvoiceBlockType.item) {
        final qty = block.qty;
        final price = block.unitPrice;
        final tax = block.taxRate;
        if (qty != null && qty < 0) {
          throw Exception(l.invoiceValidationNonNegative);
        }
        if (price != null && price < 0) {
          throw Exception(l.invoiceValidationNonNegative);
        }
        if (tax != null && (tax < 0 || tax > 100)) {
          throw Exception(l.invoiceValidationTaxRate);
        }
        if (block.description.text.trim().isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
      } else if (type == InvoiceBlockType.date ||
          type == InvoiceBlockType.section ||
          type == InvoiceBlockType.subsection) {
        if (block.title.text.trim().isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
      } else if (type == InvoiceBlockType.note) {
        if (block.text.text.trim().isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
      } else if (type == InvoiceBlockType.checklist) {
        if (block.checklistItems.isEmpty) {
          throw Exception(l.fieldIsRequired);
        }
        for (final item in block.checklistItems) {
          if (item.text.text.trim().isEmpty) {
            throw Exception(l.fieldIsRequired);
          }
        }
      }
    }
  }

  Future<void> deleteDraft(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final draft = _savedInvoice;
    if (draft == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceDraftRemoveTitle),
        content: Text(l.invoiceDraftRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _deletingDraft = true;
    notifyListeners();
    try {
      await _invoicesApi.delete(draft.id);
      _savedInvoice = null;
      _previewedPdf = false;
      await _refreshClientStats();
      notifyListeners();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDraftRemovedSnack)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftRemoveFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      _deletingDraft = false;
      notifyListeners();
    }
  }

  Future<void> previewDraft(BuildContext context, Invoice draft) async {
    final l = AppLocalizations.of(context)!;
    try {
      final r = await _invoicesApi.previewPdf(draft.id);
      final Uint8List bytes = InvoiceEditorPdf.validatePdf(r);
      await pdf_launcher.launchPdfPreview(
        bytes,
        fileName: 'invoice-${draft.invoiceNumber}.pdf',
      );
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

  Future<void> deleteDraftById(BuildContext context, Invoice draft) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.invoiceDraftRemoveTitle),
        content: Text(l.invoiceDraftRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _deletingDraft = true;
    notifyListeners();
    try {
      await _invoicesApi.delete(draft.id);
      _pendingDrafts = _pendingDrafts.where((d) => d.id != draft.id).toList();
      _pendingDraftsCount = _pendingDrafts.length;
      notifyListeners();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDraftRemovedSnack)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: l.invoiceDraftRemoveFailedSnack,
            ),
          ),
        ),
      );
    } finally {
      _deletingDraft = false;
      notifyListeners();
    }
  }
}
