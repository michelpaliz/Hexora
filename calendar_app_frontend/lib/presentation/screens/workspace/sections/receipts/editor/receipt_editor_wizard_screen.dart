import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/models/receipt/receipt_line.dart';
import 'package:hexora/services/receipts/receipts_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/screens/workspace/sections/receipts/editor/widgets/receipt_line_draft.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/editor/widgets/receipt_lines_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/prompt_clipboard_helper.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/presentation/shared/widgets/feedback/snack_helper.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';
import 'package:hexora/presentation/shared/widgets/documents/pdf_inline_preview.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_editor_components.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_client_step.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  final _clientAddressCtrl = TextEditingController();
  final _clientCityCtrl = TextEditingController();
  final _clientPostalCodeCtrl = TextEditingController();
  final _clientSearchCtrl = TextEditingController();
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
    final clientSnapshot = receipt.clientSnapshot;
    _clientId = receipt.clientId.trim().isEmpty ? null : receipt.clientId;
    _clientNameCtrl.text =
        receipt.clientName ?? clientSnapshot?.legalName ?? '';
    _clientAddressCtrl.text = clientSnapshot?.addressStreet ?? '';
    _clientCityCtrl.text = clientSnapshot?.addressCity ?? '';
    _clientPostalCodeCtrl.text = clientSnapshot?.addressPostalCode ?? '';
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
    _clientAddressCtrl.dispose();
    _clientCityCtrl.dispose();
    _clientPostalCodeCtrl.dispose();
    _clientSearchCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  bool get _hasClient => _useManualClient
      ? _clientNameCtrl.text.trim().isNotEmpty
      : _clientId != null && _clientId!.trim().isNotEmpty;
  bool get _hasLines => _lines.any((line) => line.hasAnyValue);

  ClientBilling? get _manualClientSnapshot {
    if (!_useManualClient) return null;
    String? optionalText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    return ClientBilling(
      legalName: optionalText(_clientNameCtrl),
      addressStreet: optionalText(_clientAddressCtrl),
      addressCity: optionalText(_clientCityCtrl),
      addressPostalCode: optionalText(_clientPostalCodeCtrl),
      documentType: 'receipt',
    );
  }

  GroupClient? get _selectedClient {
    final id = _clientId;
    if (id == null) return null;
    for (final client in widget.clients) {
      if (client.id == id) return client;
    }
    return null;
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: FolderPanel(
          onBack: _requestClose,
          showTab: true,
          contentTopPadding: 0,
          tabContent: _buildWizardToolbarContent(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: _buildContent(context),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _buildContent(context),
        ),
      ),
    );
  }
}
