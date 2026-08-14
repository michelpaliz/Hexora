import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/a-models/receipt/receipt_line.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_line_draft.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/prompt_clipboard_helper.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

part 'sections/receipt_editor_wizard_import_extract_section.dart';
part 'sections/receipt_editor_wizard_flow_section.dart';
part 'sections/receipt_editor_wizard_ui_section.dart';

class ReceiptEditorWizardScreen extends StatefulWidget {
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  final Receipt? initialReceipt;
  final bool embedded;
  final ValueChanged<bool>? onClose;
  final ValueChanged<bool>? onUnsavedStateChanged;

  const ReceiptEditorWizardScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialReceipt,
    this.embedded = false,
    this.onClose,
    this.onUnsavedStateChanged,
  });

  @override
  State<ReceiptEditorWizardScreen> createState() =>
      _ReceiptEditorWizardScreenState();
}

class _ReceiptEditorWizardScreenState extends State<ReceiptEditorWizardScreen> {
  final _receiptsApi = ReceiptsApi();
  final _notesCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final List<ReceiptLineDraft> _lines = [];

  String? _clientId;
  bool _useManualClient = false;
  DateTime? _issueDate;
  Receipt? _draftReceipt;
  Uint8List? _previewPdfBytes;
  String? _previewError;
  int _step = 0;
  bool _didPersist = false;
  bool _savingDraft = false;
  bool _draftDirty = false;
  bool _draftSaveFailed = false;
  bool _loadingPreview = false;
  bool _jsonImporting = false;
  bool _jsonPromptLoading = false;
  int _linesInputTabIndex = 0;
  String? _jsonImportError;
  String? _jsonImportFileName;
  String? _jsonImportFileContent;
  bool _extractingLines = false;
  String? _extractError;
  String? _extractFileName;
  Uint8List? _extractFileBytes;
  List<Map<String, dynamic>> _extractedDraftLines = const [];
  String? _extractMethodUsed;
  List<String> _extractDiagnostics = const [];
  bool _checkingUnnumberedDraft = false;
  String? _existingUnnumberedReceiptId;
  Receipt? _existingUnnumberedReceipt;

  // ── Client receipt stats (right panel) ──────────────────────────────────
  int _clientIssuedCount = 0;
  int _clientDraftCount = 0;
  bool _loadingReceiptStats = false;
  List<Receipt> _clientPastReceipts = [];

  Future<void> _loadClientReceiptStats(String? clientId) async {
    if (clientId == null || clientId.trim().isEmpty) {
      setState(() {
        _clientIssuedCount = 0;
        _clientDraftCount = 0;
        _clientPastReceipts = [];
        _loadingReceiptStats = false;
      });
      return;
    }
    setState(() => _loadingReceiptStats = true);
    try {
      final all = await _receiptsApi.list(groupId: widget.group.id);
      final now = DateTime.now();
      final clientAll = all.where((r) => r.clientId == clientId).toList();
      final thisMonth = clientAll.where((r) {
        final d = r.issueDate ?? r.registeredAt;
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      }).toList();
      final pastReceipts = clientAll.where((r) {
        final d = r.issueDate ?? r.registeredAt;
        if (d == null) return true;
        return !(d.year == now.year && d.month == now.month);
      }).toList()
        ..sort((a, b) {
          final da = a.issueDate ?? a.registeredAt;
          final db = b.issueDate ?? b.registeredAt;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
      if (mounted) {
        setState(() {
          _clientIssuedCount =
              thisMonth.where((r) => r.status == 'issued').length;
          _clientDraftCount = thisMonth
              .where((r) => r.status == 'draft' || r.status == null)
              .length;
          _clientPastReceipts = pastReceipts;
          _loadingReceiptStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReceiptStats = false);
    }
  }

  Future<void> _previewHistoricalReceipt(Receipt r) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    try {
      final response = await _receiptsApi.previewPdf(r.id);
      final bytes = InvoiceEditorPdf.validatePdf(response);
      final fileName = (r.receiptNumber?.trim().isNotEmpty == true)
          ? 'receipt-${r.receiptNumber!.trim()}.pdf'
          : 'receipt-preview.pdf';
      await pdf_launcher.launchPdfPreview(bytes, fileName: fileName);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.receiptPreviewFailed : msg)),
      );
    }
  }

  void _applyReceiptDraft(Receipt receipt) {
    _clientId = receipt.clientId.trim().isEmpty ? null : receipt.clientId;
    _clientNameCtrl.text = receipt.clientName ?? '';
    _useManualClient = (_clientId == null || _clientId!.trim().isEmpty) &&
        _clientNameCtrl.text.trim().isNotEmpty;
    _issueDate = receipt.issueDate ?? DateTime.now();
    _draftReceipt = receipt;
    _notesCtrl.text = receipt.notes ?? '';
    for (final line in _lines) {
      line.dispose();
    }
    _lines.clear();
    if (receipt.lines.isEmpty) {
      _lines.add(ReceiptLineDraft.empty());
    } else {
      for (final line in receipt.lines) {
        _lines.add(ReceiptLineDraft.fromLine(line));
      }
    }
    _existingUnnumberedReceiptId = null;
    _existingUnnumberedReceipt = null;
    _markDraftSynced();
  }

  Future<void> _checkExistingUnnumberedDraft() async {
    if (widget.initialReceipt != null || widget.group.id.trim().isEmpty) return;
    setState(() => _checkingUnnumberedDraft = true);
    try {
      final result = await _receiptsApi.lookupUnnumberedDraft(
        groupId: widget.group.id,
      );
      if (!mounted) return;
      setState(() {
        _existingUnnumberedReceiptId =
            result.exists ? result.existingReceiptId : null;
        _existingUnnumberedReceipt = result.exists ? result.receipt : null;
      });
    } catch (_) {
      // Non-blocking helper only; creation still handles the conflict safely.
    } finally {
      if (mounted) setState(() => _checkingUnnumberedDraft = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialReceipt;
    if (initial != null) {
      _applyReceiptDraft(initial);
      _step = 1;
    } else {
      _clientId = widget.initialClientId;
      _issueDate = DateTime.now();
      _lines.add(ReceiptLineDraft.empty());
    }

    if (_clientId != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadClientReceiptStats(_clientId));
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkExistingUnnumberedDraft(),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _clientNameCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  bool get _hasClient => _useManualClient
      ? _clientNameCtrl.text.trim().isNotEmpty
      : _clientId != null && _clientId!.trim().isNotEmpty;
  String get _resolvedClientName {
    if (_useManualClient) return _clientNameCtrl.text.trim();
    return _selectedClient?.name.trim() ?? '';
  }

  bool get _hasLines => _lines.any((line) => line.hasAnyValue);

  GroupClient? get _selectedClient {
    final id = _clientId;
    if (id == null) return null;
    for (final client in widget.clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  num get _subtotal {
    num sum = 0;
    for (final line in _lines) {
      sum += line.total;
    }
    return sum;
  }

  bool get _isManualLinesMode => _linesInputTabIndex == 0;

  void _markDraftDirty() {
    if (_draftDirty && !_draftSaveFailed) return;
    _draftDirty = true;
    _draftSaveFailed = false;
    widget.onUnsavedStateChanged?.call(true);
  }

  void _markDraftSynced() {
    _draftDirty = false;
    _draftSaveFailed = false;
    widget.onUnsavedStateChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final isEmbedded = widget.embedded == true;
    if (isEmbedded) {
      final l = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: FolderPanel(
          title: l.receiptEditorTitle(_receiptNumber(l)),
          onBack: _requestClose,
          showTab: true,
          contentTopPadding: 10,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: _buildContent(context),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.receiptEditorTitle(
            _receiptNumber(AppLocalizations.of(context)!),
          ),
        ),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: _requestClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildContent(context),
        ),
      ),
    );
  }
}
