import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_line.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_api.dart' as line_ev;
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_flow.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_formatters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

part 'controller/invoice_editor_controller_draft_flow.dart';
part 'controller/invoice_editor_controller_evidence_flow.dart';
part 'controller/invoice_editor_controller_draft_file_ops.dart';
part 'controller/invoice_editor_controller_json_import_flow.dart';

class InvoiceEditorController extends ChangeNotifier {
  bool _disposed = false;
  final Group group;
  final List<GroupClient> clients;
  final String? initialClientId;
  final Invoice? initialInvoice;

  InvoiceEditorController({
    required this.group,
    required this.clients,
    this.initialClientId,
    this.initialInvoice,
  }) {
    _bindOcrFlow();
    if (initialInvoice != null) {
      _applyInitialInvoice(initialInvoice!);
    } else if (clients.isNotEmpty) {
      final existing = clients
          .firstWhere(
            (c) => c.id == initialClientId,
            orElse: () => clients.first,
          )
          .id;
      _clientId = existing;
    }
    digits.addListener(_handleDigitsChanged);
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
  final discountAmountCtrl = TextEditingController();
  final discountPercentCtrl = TextEditingController();

  final List<LineDraft> lines = <LineDraft>[LineDraft(position: 1)];
  final List<InvoiceBlockDraft> blocks = <InvoiceBlockDraft>[
    InvoiceBlockDraft.item()
  ];

  String? _clientId;
  bool _saving = false;
  bool _issuing = false;
  bool _previewedPdf = false;
  bool _previewing = false;
  Uint8List? _previewPdfBytes;
  bool _confirmSaveDraft = false;
  int _currentStepIndex = 0;
  bool _useBlocks = true;
  bool _deletingDraft = false;
  Invoice? _savedInvoice;
  List<Invoice> _pendingDrafts = const [];
  int _issuedThisMonthCount = 0;
  int _pendingDraftsCount = 0;
  bool _loadingClientStats = false;
  bool _invoiceNumberTouched = false;
  bool _settingInvoiceNumber = false;
  bool _useDiscountPercent = false;
  String? _editingDraftId;
  bool _editingDraftMode = false;
  Uint8List? _lastOcrImageBytes;
  String? _lastOcrImageName;
  Uint8List? _jsonImportFileBytes;
  String? _jsonImportFileName;
  bool _importingJsonLines = false;
  bool _loadingJsonPromptTemplate = false;
  String? _jsonImportError;
  InvoiceLinesOcrFlowState _ocrState = InvoiceLinesOcrFlowState.initial();
  late final InvoiceLinesOcrFlowController _ocrFlow;
  StreamSubscription<InvoiceLinesOcrFlowState>? _ocrSub;

  // --- apis ---
  final _invoicesApi = InvoicesApi();
  final _linesApi = line_ev.InvoiceLinesApi();

  // --- getters ---
  String? get clientId => _clientId;
  bool get saving => _saving;
  bool get issuing => _issuing;
  bool get previewedPdf => _previewedPdf;
  bool get previewing => _previewing;
  Uint8List? get previewPdfBytes => _previewPdfBytes;
  bool get confirmSaveDraft => _confirmSaveDraft;
  int get currentStepIndex => _currentStepIndex;
  Invoice? get savedInvoice => _savedInvoice;
  int get issuedThisMonthCount => _issuedThisMonthCount;
  int get pendingDraftsCount => _pendingDraftsCount;
  List<Invoice> get pendingDrafts => _pendingDrafts;
  bool get loadingClientStats => _loadingClientStats;
  bool get useBlocks => _useBlocks;
  bool get deletingDraft => _deletingDraft;
  String? get editingDraftId => _editingDraftId;
  bool get editingDraft => _editingDraftMode;
  bool get hasLastOcrImagePreview => _lastOcrImageBytes != null;
  Uint8List? get jsonImportFileBytes => _jsonImportFileBytes;
  String? get jsonImportFileName => _jsonImportFileName;
  bool get importingJsonLines => _importingJsonLines;
  bool get loadingJsonPromptTemplate => _loadingJsonPromptTemplate;
  String? get jsonImportError => _jsonImportError;
  InvoiceLinesOcrFlowState get ocrState => _ocrState;
  bool get extractingLinesFromImage =>
      _ocrState.stage == OcrExtractionStage.extracting;
  bool get canApplyExtractedLines => _ocrState.extractedLines.isNotEmpty;

  void updateOcrExtractedLineField(
    int index, {
    String? description,
    double? quantity,
    double? unitPrice,
    double? taxRate,
  }) {
    final patch = <String, dynamic>{};
    if (description != null) patch['description'] = description;
    if (quantity != null) patch['quantity'] = quantity;
    if (unitPrice != null) patch['unitPrice'] = unitPrice;
    if (taxRate != null) patch['taxRate'] = taxRate;
    if (patch.isEmpty) return;
    _ocrFlow.updateExtractedLine(index, patch);
  }

  void removeOcrExtractedLine(int index) => _ocrFlow.removeExtractedLine(index);
  void addOcrExtractedLine() => _ocrFlow.addExtractedLine();

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

  bool get useDiscountPercent => _useDiscountPercent;
  bool get discountReadOnly {
    final status = (_savedInvoice?.status ?? '').toLowerCase();
    return status.contains('issue');
  }

  num? _parseAmountValue(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return num.tryParse(normalized);
  }

  num get rawSubtotal => _useBlocks
      ? blocks.fold<num>(0, (sum, block) {
          if (!block.isBillableLine) return sum;
          final qty = block.qty ?? 1;
          final price = block.unitPrice ?? 0;
          return sum + (qty * price);
        })
      : lines.fold<num>(0, (sum, line) {
          final qty = line.quantity ?? 1;
          final price = line.unitPrice ?? 0;
          return sum + (qty * price);
        });

  num get rawTax => _useBlocks
      ? blocks.fold<num>(0, (sum, block) {
          if (!block.isBillableLine) return sum;
          final qty = block.qty ?? 1;
          final price = block.unitPrice ?? 0;
          final taxRate = block.taxRate ?? 21;
          final subtotal = qty * price;
          return sum + (subtotal * (taxRate / 100));
        })
      : lines.fold<num>(0, (sum, line) {
          final qty = line.quantity ?? 1;
          final price = line.unitPrice ?? 0;
          final taxRate = line.taxRate ?? 21;
          final subtotal = qty * price;
          return sum + (subtotal * (taxRate / 100));
        });

  num? get discountAmountValue {
    final v = _parseAmountValue(discountAmountCtrl.text);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return v;
  }

  num? get discountPercentValue {
    final v = _parseAmountValue(discountPercentCtrl.text);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return v;
  }

  num get effectiveDiscountAmount {
    final subtotal = rawSubtotal;
    if (subtotal <= 0) return 0;
    final amount = discountAmountValue;
    final percent = discountPercentValue;
    if (amount != null && amount > 0) {
      return amount.clamp(0, subtotal);
    }
    if (percent != null && percent > 0) {
      final boundedPercent = percent.clamp(0, 100);
      return (subtotal * boundedPercent) / 100;
    }
    return 0;
  }

  num get subtotalAfterDiscount {
    final subtotal = rawSubtotal;
    final discounted = subtotal - effectiveDiscountAmount;
    return discounted < 0 ? 0 : discounted;
  }

  num get taxAfterDiscount {
    final subtotal = rawSubtotal;
    final tax = rawTax;
    if (subtotal <= 0 || tax <= 0) return 0;
    final ratio = subtotalAfterDiscount / subtotal;
    return tax * ratio;
  }

  num get total => subtotalAfterDiscount + taxAfterDiscount;

  bool get canPreviewDraft {
    final hasClient = _clientId != null;
    final inv = invoiceDate.value;
    final due = dueDate.value;
    final datesComplete = inv != null;
    final invalidDates = inv != null && due != null && due.isBefore(inv);
    final hasSavedDraft = _savedInvoice != null;
    return hasClient &&
        datesComplete &&
        !invalidDates &&
        hasBillableEntries &&
        hasSavedDraft;
  }

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

  void _bindOcrFlow() {
    _ocrFlow = InvoiceLinesOcrFlowController(
      service: InvoiceLinesOcrService(),
    );
    _ocrSub = _ocrFlow.stream.listen((next) {
      _ocrState = next;
      notifyListeners();
    });
  }

  List<InvoiceLine> _draftLinesForInvoice(String invoiceId) {
    if (_useBlocks) {
      final billable = blocks.where((b) => b.hasBillableContent).toList();
      return List<InvoiceLine>.generate(billable.length, (index) {
        final block = billable[index];
        String desc;
        if (block.isChecklist) {
          final title = block.title.text.trim();
          final items = block.checklistItems
              .map((item) => item.text.text.trim())
              .where((text) => text.isNotEmpty)
              .toList();
          if (items.isEmpty) {
            desc = title;
          } else {
            final lines = <String>[];
            if (title.isNotEmpty) {
              lines.add(title);
            }
            lines.addAll(items.map((item) => '- $item'));
            desc = lines.join('\n');
          }
        } else if (block.isSection) {
          desc = block.title.text.trim();
        } else {
          desc = block.description.text.trim();
        }
        return InvoiceLine(
          id: '',
          invoiceId: invoiceId,
          position: index + 1,
          description: desc,
          quantity: block.qty ?? 1,
          unitPrice: block.unitPrice ?? 0,
          taxRate: block.taxRate ?? 0,
        );
      });
    }
    return lines
        .map(
          (d) => d.toLine().copyWith(
                id: '',
                invoiceId: invoiceId,
              ),
        )
        .toList(growable: false);
  }

  Future<int> _syncLinesForInvoice(String invoiceId) async {
    final draftLines = _draftLinesForInvoice(invoiceId);
    final existing = await _linesApi.list(invoiceId);
    for (final line in existing) {
      final id = line.id;
      if (id != null && id.isNotEmpty) {
        await _linesApi.delete(invoiceId, id);
      }
    }
    for (final line in draftLines) {
      await _linesApi.create(invoiceId, line);
    }
    final verified = await _linesApi.list(invoiceId);
    return verified.length;
  }

  // --- UI hooks ---
  void notifyUi() {
    // Any form change makes the saved draft stale (there is no update API).
    _savedInvoice = null;
    _previewedPdf = false;
    _previewPdfBytes = null;
    _confirmSaveDraft = false;
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
    _previewPdfBytes = null;
    _confirmSaveDraft = false;
    _refreshClientStats();
    notifyListeners();
  }

  void setConfirmSaveDraft(bool value) {
    if (_confirmSaveDraft == value) return;
    _confirmSaveDraft = value;
    notifyListeners();
  }

  void setCurrentStepIndex(int value) {
    if (_currentStepIndex == value) return;
    _currentStepIndex = value.clamp(0, 99);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    invoiceDate.dispose();
    dueDate.dispose();
    currency.dispose();
    notes.dispose();
    digits.removeListener(_handleDigitsChanged);
    digits.dispose();
    pdfUrl.dispose();
    discountAmountCtrl.dispose();
    discountPercentCtrl.dispose();
    for (final l in lines) {
      l.dispose();
    }
    for (final b in blocks) {
      b.dispose();
    }
    if (_ocrSub != null) {
      unawaited(_ocrSub!.cancel());
    }
    unawaited(_ocrFlow.dispose());
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _handleDigitsChanged() {
    if (_settingInvoiceNumber) return;
    _invoiceNumberTouched = true;
  }

  void _applyInitialInvoice(Invoice invoice) {
    _savedInvoice = invoice;
    _editingDraftId = invoice.id.trim().isEmpty ? null : invoice.id.trim();
    _editingDraftMode = _editingDraftId != null;
    _clientId = invoice.clientId.isNotEmpty ? invoice.clientId : _clientId;
    if (invoice.currency != null && invoice.currency!.trim().isNotEmpty) {
      currency.text = invoice.currency!.trim();
    }
    if (invoice.notes != null) {
      notes.text = invoice.notes!.trim();
    }
    final initialDiscountAmount = invoice.discountAmount;
    final initialDiscountPercent = invoice.discountPercent;
    if (initialDiscountAmount != null && initialDiscountAmount > 0) {
      discountAmountCtrl.text = initialDiscountAmount.toString();
      discountPercentCtrl.clear();
      _useDiscountPercent = false;
    } else if (initialDiscountPercent != null && initialDiscountPercent > 0) {
      discountPercentCtrl.text = initialDiscountPercent.toString();
      discountAmountCtrl.clear();
      _useDiscountPercent = true;
    } else {
      discountAmountCtrl.clear();
      discountPercentCtrl.clear();
    }
    if (invoice.pdfUrl != null) {
      pdfUrl.text = invoice.pdfUrl!.trim();
    }
    invoiceDate.value =
        invoice.issueDate ?? invoice.registeredAt ?? invoiceDate.value;

    final number = invoice.invoiceNumber.trim();
    final match = RegExp(r'^(\\d{1,})').firstMatch(number);
    if (match != null) {
      _settingInvoiceNumber = true;
      digits.text = match.group(1)!.padLeft(3, '0');
      _settingInvoiceNumber = false;
      _invoiceNumberTouched = true;
    }

    _useBlocks = invoice.blocks.isNotEmpty;
    _resetDraftLines();
    _resetDraftBlocks();
    if (_useBlocks) {
      final drafts =
          invoice.blocks.map(_draftFromBlock).whereType<InvoiceBlockDraft>();
      blocks.addAll(drafts);
      if (blocks.isEmpty) {
        blocks.add(InvoiceBlockDraft.item());
      }
    } else {
      final sorted = [...invoice.lines]
        ..sort((a, b) => a.position.compareTo(b.position));
      for (final line in sorted) {
        lines.add(_draftFromLine(line));
      }
      if (lines.isEmpty) {
        lines.add(LineDraft(position: 1));
      }
    }
  }

  void setDiscountModePercent(bool value) {
    if (_useDiscountPercent == value) return;
    _useDiscountPercent = value;
    if (value) {
      discountAmountCtrl.clear();
    } else {
      discountPercentCtrl.clear();
    }
    notifyUi();
  }

  void setDiscountAmountText(String value) {
    if (discountReadOnly) return;
    if (_useDiscountPercent) return;
    notifyUi();
  }

  void setDiscountPercentText(String value) {
    if (discountReadOnly) return;
    if (!_useDiscountPercent) return;
    notifyUi();
  }

  Map<String, dynamic> buildDiscountPayload() {
    final amount = discountAmountValue;
    final percent = discountPercentValue;
    if (amount != null && amount > 0) {
      return {'discountAmount': amount};
    }
    if (percent != null && percent > 0) {
      return {'discountPercent': percent.clamp(0, 100)};
    }
    return const {
      'discountAmount': 0,
      'discountPercent': 0,
    };
  }

  void _resetDraftLines() {
    for (final l in lines) {
      l.dispose();
    }
    lines.clear();
  }

  void _resetDraftBlocks() {
    for (final b in blocks) {
      b.dispose();
    }
    blocks.clear();
  }

  LineDraft _draftFromLine(InvoiceLine line) {
    final draft = LineDraft(
      position: line.position,
      id: line.id,
      evidenceBlobName: line.evidenceBlobName,
    );
    draft.description.text = line.description;
    draft.quantityCtrl.text = line.quantity.toString();
    draft.unitPriceCtrl.text = line.unitPrice.toString();
    draft.taxRateCtrl.text = line.taxRate.toString();
    return draft;
  }

  InvoiceBlockDraft _draftFromBlock(InvoiceBlock block) {
    final draft = InvoiceBlockDraft(
      type: block.type,
      sku: block.sku,
      description: block.description,
      qty: block.qty?.toString(),
      unit: block.unit,
      unitPrice: block.unitPrice?.toString(),
      taxRate: block.taxRate?.toString(),
      level: block.level?.toString(),
      isBillable: block.isBillable ?? true,
      title: block.title,
      dateValue: block.value,
      text: block.text,
      checklistItems: block.items
          ?.map((item) => InvoiceChecklistItemDraft(
                initialText: item.text,
                checked: item.checked,
              ))
          .toList(),
    );
    if (draft.type == InvoiceBlockType.checklist &&
        draft.checklistItems.isEmpty) {
      draft.checklistItems.add(InvoiceChecklistItemDraft());
    }
    return draft;
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
      _maybeAutofillInvoiceDigits([...issued, ...drafts]);

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

  void _maybeAutofillInvoiceDigits(List<Invoice> invoices) {
    if (_invoiceNumberTouched || _savedInvoice != null) return;
    final raw = digits.text.trim();
    if (raw.isNotEmpty && raw != '001') return;

    final suggestion = InvoiceEditorFormatters.nextInvoiceDigits(
      invoiceNumbers: invoices.map((inv) => inv.invoiceNumber),
      now: DateTime.now(),
    );
    if (raw == suggestion) return;
    _settingInvoiceNumber = true;
    digits.text = suggestion;
    _settingInvoiceNumber = false;
  }
}
