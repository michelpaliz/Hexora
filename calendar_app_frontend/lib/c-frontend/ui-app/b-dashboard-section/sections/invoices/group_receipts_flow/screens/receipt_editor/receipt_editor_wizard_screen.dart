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
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_line_draft.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_receipts_flow/screens/receipt_editor/widgets/receipt_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
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

  const ReceiptEditorWizardScreen({
    super.key,
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialReceipt,
    this.embedded = false,
    this.onClose,
  });

  @override
  State<ReceiptEditorWizardScreen> createState() =>
      _ReceiptEditorWizardScreenState();
}

class _ReceiptEditorWizardScreenState extends State<ReceiptEditorWizardScreen> {
  final _receiptsApi = ReceiptsApi();
  final _notesCtrl = TextEditingController();
  final List<ReceiptLineDraft> _lines = [];

  String? _clientId;
  DateTime? _issueDate;
  Receipt? _draftReceipt;
  Uint8List? _previewPdfBytes;
  String? _previewError;
  int _step = 0;
  bool _didPersist = false;
  bool _savingDraft = false;
  bool _loadingPreview = false;
  bool _issuing = false;
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

  @override
  void initState() {
    super.initState();
    _clientId = widget.initialClientId ?? widget.initialReceipt?.clientId;
    _issueDate = widget.initialReceipt?.issueDate ?? DateTime.now();
    _draftReceipt = widget.initialReceipt;
    _notesCtrl.text = widget.initialReceipt?.notes ?? '';

    final initialLines = widget.initialReceipt?.lines ?? const [];
    if (initialLines.isEmpty) {
      _lines.add(ReceiptLineDraft.empty());
    } else {
      for (final line in initialLines) {
        _lines.add(ReceiptLineDraft.fromLine(line));
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  bool get _hasClient => _clientId != null && _clientId!.trim().isNotEmpty;
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

  @override
  Widget build(BuildContext context) {
    final isEmbedded = widget.embedded == true;
    if (isEmbedded) {
      final l = AppLocalizations.of(context)!;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: FolderPanel(
          title: l.receiptEditorTitle(_receiptNumber(l)),
          onBack: () => _close(changed: _didPersist),
          showTab: true,
          contentTopPadding: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
        title: Text(AppLocalizations.of(context)!.receiptIssueCta),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => _close(changed: _didPersist),
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


