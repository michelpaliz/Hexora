import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/budget_sort_query.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_advance_final_flow.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/prompt_clipboard_helper.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/snack_helper.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/wizard_steps_header.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

part 'sections/group_invoices_budgets_view_flow_section.dart';
part 'sections/group_invoices_budgets_view_import_extract_section.dart';
part 'sections/group_invoices_budgets_view_payload_section.dart';
part 'sections/group_invoices_budgets_view_step_content_section.dart';

enum GroupInvoicesBudgetsMode { list, create }

enum _ClientSource { existing, manual }

enum BudgetSortBy { date, number }

enum BudgetSortDir { asc, desc }

class BudgetSortState {
  final BudgetSortBy by;
  final BudgetSortDir dir;

  const BudgetSortState({
    required this.by,
    required this.dir,
  });

  BudgetSortState copyWith({
    BudgetSortBy? by,
    BudgetSortDir? dir,
  }) {
    return BudgetSortState(
      by: by ?? this.by,
      dir: dir ?? this.dir,
    );
  }
}

BudgetSortState nextBudgetSortState(
  BudgetSortState current,
  BudgetSortBy selectedBy,
) {
  if (current.by == selectedBy) {
    return current.copyWith(
      dir: current.dir == BudgetSortDir.desc
          ? BudgetSortDir.asc
          : BudgetSortDir.desc,
    );
  }
  return BudgetSortState(by: selectedBy, dir: BudgetSortDir.desc);
}

class GroupInvoicesBudgetsView extends StatefulWidget {
  const GroupInvoicesBudgetsView({
    super.key,
    required this.groupId,
    required this.clients,
    this.mode = GroupInvoicesBudgetsMode.list,
    this.initialSelectedBudgetId,
    this.onOpenInvoiceId,
    this.onEditDraftBudget,
    this.onExitEditor,
    this.onUnsavedStateChanged,
  });

  final String groupId;
  final List<GroupClient> clients;
  final GroupInvoicesBudgetsMode mode;
  final String? initialSelectedBudgetId;
  final ValueChanged<String>? onOpenInvoiceId;
  final ValueChanged<String>? onEditDraftBudget;
  final VoidCallback? onExitEditor;
  final ValueChanged<bool>? onUnsavedStateChanged;

  @override
  State<GroupInvoicesBudgetsView> createState() =>
      _GroupInvoicesBudgetsViewState();
}

class _GroupInvoicesBudgetsViewState extends State<GroupInvoicesBudgetsView> {
  final PresupuestosApi _presupuestosApi = PresupuestosApi();
  bool _loadingBudgets = false;
  bool _downloadingBudgetsZip = false;
  final Set<String> _issuingBudgetIds = <String>{};
  final Set<String> _deletingBudgetIds = <String>{};
  // ignore: unused_field
  final Set<String> _convertingBudgetIds = <String>{};
  final Set<String> _creatingAdvanceInvoiceBudgetIds = <String>{};
  final Set<String> _creatingFinalInvoiceBudgetIds = <String>{};
  BudgetSortState? _budgetSortState;
  String? _budgetsError;
  List<Map<String, dynamic>> _budgets = const [];
  String? _selectedBudgetId;
  int _budgetsTabIndex = 0;
  String? _selectedClientId;
  int _clientBudgetIssuedCount = 0;
  int _clientBudgetDraftCount = 0;
  bool _loadingClientBudgetStats = false;
  List<Map<String, dynamic>> _clientPastBudgets = [];
  final TextEditingController _clientNameCtrl = TextEditingController();
  final TextEditingController _clientAddressCtrl = TextEditingController();
  final TextEditingController _clientCityCtrl = TextEditingController();
  final TextEditingController _clientPostalCodeCtrl = TextEditingController();
  final TextEditingController _budgetNotesCtrl = TextEditingController();
  final TextEditingController _issuedEditReasonCtrl = TextEditingController();
  final TextEditingController _budgetCurrencyCtrl =
      TextEditingController(text: 'EUR');
  final TextEditingController _budgetDiscountAmountCtrl =
      TextEditingController();
  final TextEditingController _budgetDiscountPercentCtrl =
      TextEditingController();
  _ClientSource _clientSource = _ClientSource.existing;
  final List<LineDraft> _budgetLines = <LineDraft>[LineDraft(position: 1)];
  final List<InvoiceBlockDraft> _budgetBlocks = <InvoiceBlockDraft>[
    InvoiceBlockDraft.item(),
  ];
  bool _useBlocks = true;
  int _visibleStep = 0;
  String? _error;
  bool _confirmPreview = false;
  bool _useBudgetDiscountPercent = false;
  bool _issuing = false;
  String? _draftId;
  Future<String>? _draftCreateInFlight;
  String? _issuedPresupuestoNumber;
  DateTime? _budgetIssueDate;
  bool _loadingEditableBudget = false;
  String? _editableBudgetError;
  bool _editableBudgetDirty = false;
  String? _editableBudgetStatus;
  int? _editableBudgetVersion;
  bool _loadingPreview = false;
  String? _previewError;
  List<int>? _previewPdfBytes;
  String? _previewForId;
  bool _loadingDetailPreview = false;
  String? _detailPreviewError;
  List<int>? _detailPreviewPdfBytes;
  String? _detailPreviewForId;
  Map<String, dynamic>? _historyBudget;
  int _linesInputTabIndex = 0;
  bool _jsonImportLoading = false;
  bool _jsonPromptLoading = false;
  String? _jsonImportError;
  String? _jsonImportFileName;
  String? _jsonImportFileContent;
  bool _extractingBlocks = false;
  String? _extractError;
  String? _extractFileName;
  Uint8List? _extractFileBytes;
  List<Map<String, dynamic>> _extractedBlocks = const [];
  String? _extractMethodUsed;
  List<String> _extractDiagnostics = const [];

  bool get _isPhotoLinesMode => _linesInputTabIndex == 1;
  bool get _isJsonLinesMode => _linesInputTabIndex == 2;
  bool get _isSpanishLocale =>
      Localizations.localeOf(context).languageCode == 'es';
  BudgetSortState get _effectiveBudgetSortState =>
      _budgetSortState ??
      const BudgetSortState(by: BudgetSortBy.date, dir: BudgetSortDir.desc);

  num? _parseBudgetDiscountInput(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parsed = num.tryParse(text.replaceAll(',', '.'));
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    return parsed;
  }

  num get _budgetRawSubtotal {
    if (_useBlocks) {
      return _budgetBlocks.where((b) => b.hasBillableContent).fold<num>(0,
          (sum, block) {
        final qty = block.qty ?? 1;
        final unitPrice = block.unitPrice ?? 0;
        final discountRate = block.discountRate ?? 0;
        final grossBase = qty * unitPrice;
        return sum + (grossBase - (grossBase * discountRate / 100));
      });
    }
    return _budgetLines.where(_budgetLineHasBillableContent).fold<num>(0,
        (sum, line) {
      final qty = line.quantity ?? 1;
      final unitPrice = line.unitPrice ?? 0;
      final discountRate = line.discountRate ?? 0;
      final grossBase = qty * unitPrice;
      return sum + (grossBase - (grossBase * discountRate / 100));
    });
  }

  num get _budgetRawTax {
    if (_useBlocks) {
      return _budgetBlocks.where((b) => b.hasBillableContent).fold<num>(0,
          (sum, block) {
        final qty = block.qty ?? 1;
        final unitPrice = block.unitPrice ?? 0;
        final discountRate = block.discountRate ?? 0;
        final taxRate = block.taxRate ?? 21;
        final grossBase = qty * unitPrice;
        final base = grossBase - (grossBase * discountRate / 100);
        return sum + (base * (taxRate / 100));
      });
    }
    return _budgetLines.where(_budgetLineHasBillableContent).fold<num>(0,
        (sum, line) {
      final qty = line.quantity ?? 1;
      final unitPrice = line.unitPrice ?? 0;
      final discountRate = line.discountRate ?? 0;
      final taxRate = line.taxRate ?? 21;
      final grossBase = qty * unitPrice;
      final base = grossBase - (grossBase * discountRate / 100);
      return sum + (base * (taxRate / 100));
    });
  }

  num get _budgetDiscountAmountValue =>
      _parseBudgetDiscountInput(_budgetDiscountAmountCtrl.text) ?? 0;

  num get _budgetDiscountPercentValue =>
      _parseBudgetDiscountInput(_budgetDiscountPercentCtrl.text) ?? 0;

  num get _budgetEffectiveDiscountAmount {
    final subtotal = _budgetRawSubtotal;
    if (subtotal <= 0) return 0;
    if (!_useBudgetDiscountPercent && _budgetDiscountAmountValue > 0) {
      return _budgetDiscountAmountValue.clamp(0, subtotal);
    }
    if (_useBudgetDiscountPercent && _budgetDiscountPercentValue > 0) {
      return (subtotal * _budgetDiscountPercentValue.clamp(0, 100)) / 100;
    }
    return 0;
  }

  num get _budgetTotalAfterDiscount {
    final subtotal = _budgetRawSubtotal;
    final tax = _budgetRawTax;
    if (subtotal <= 0) return 0;
    final discountedSubtotal = subtotal - _budgetEffectiveDiscountAmount;
    final safeSubtotal = discountedSubtotal < 0 ? 0 : discountedSubtotal;
    final ratio = safeSubtotal / subtotal;
    return safeSubtotal + (tax * ratio);
  }

  void _setBudgetDiscountModePercent(bool value) {
    if (_useBudgetDiscountPercent == value) return;
    setState(() {
      _useBudgetDiscountPercent = value;
      if (value) {
        _budgetDiscountAmountCtrl.clear();
      } else {
        _budgetDiscountPercentCtrl.clear();
      }
      _markDraftDirty();
      _error = null;
    });
  }

  void _setBudgetDiscountAmountText(String _) {
    setState(() {
      _markDraftDirty();
      _error = null;
    });
  }

  void _setBudgetDiscountPercentText(String _) {
    setState(() {
      _markDraftDirty();
      _error = null;
    });
  }

  void _applyBudgetDiscountPayload(Map<String, dynamic> payload) {
    final totals = payload['totals'] is Map
        ? Map<String, dynamic>.from(payload['totals'] as Map)
        : const <String, dynamic>{};
    final discount = payload['discount'] is Map
        ? Map<String, dynamic>.from(payload['discount'] as Map)
        : const <String, dynamic>{};
    final amount = _parseBudgetDiscountInput(
          (payload['discountAmount'] ??
                  totals['discountAmount'] ??
                  totals['discount'] ??
                  discount['amount'] ??
                  '')
              .toString(),
        ) ??
        0;
    final percent = _parseBudgetDiscountInput(
          (payload['discountPercent'] ??
                  totals['discountPercent'] ??
                  discount['percent'] ??
                  discount['percentage'] ??
                  '')
              .toString(),
        ) ??
        0;
    if (amount > 0) {
      _useBudgetDiscountPercent = false;
      _budgetDiscountAmountCtrl.text = amount.toString();
      _budgetDiscountPercentCtrl.clear();
    } else if (percent > 0) {
      _useBudgetDiscountPercent = true;
      _budgetDiscountPercentCtrl.text = percent.toString();
      _budgetDiscountAmountCtrl.clear();
    } else {
      _useBudgetDiscountPercent = false;
      _budgetDiscountAmountCtrl.clear();
      _budgetDiscountPercentCtrl.clear();
    }
  }

  Map<String, dynamic> _buildBudgetDiscountTotalsPayload() {
    if (!_useBudgetDiscountPercent && _budgetDiscountAmountValue > 0) {
      return <String, dynamic>{
        'discountAmount': _budgetDiscountAmountValue,
        'discountPercent': 0,
      };
    }
    if (_useBudgetDiscountPercent && _budgetDiscountPercentValue > 0) {
      return <String, dynamic>{
        'discountAmount': 0,
        'discountPercent': _budgetDiscountPercentValue.clamp(0, 100),
      };
    }
    return const <String, dynamic>{
      'discountAmount': 0,
      'discountPercent': 0,
    };
  }

  // ignore: unused_element
  String get _createAdvanceInvoiceLabel =>
      _isSpanishLocale ? 'Crear factura de anticipo' : 'Create advance invoice';

  // ignore: unused_element
  String get _createFinalInvoiceLabel =>
      _isSpanishLocale ? 'Crear factura final' : 'Create final invoice';

  // ignore: unused_element
  String get _advanceInvoiceExistsLabel => _isSpanishLocale
      ? 'Ya existe una factura de anticipo.'
      : 'Advance invoice already exists.';

  // ignore: unused_element
  String get _finalInvoiceExistsLabel => _isSpanishLocale
      ? 'Ya existe una factura final.'
      : 'Final invoice already exists.';

  // ignore: unused_element
  String get _budgetMustBeIssuedLabel => _isSpanishLocale
      ? 'El presupuesto debe estar emitido.'
      : 'Presupuesto must be issued.';

  bool get _isEditingBudget =>
      widget.mode == GroupInvoicesBudgetsMode.create &&
      (widget.initialSelectedBudgetId ?? '').trim().isNotEmpty;

  bool get _isDraftEditable =>
      !_isEditingBudget ||
      ((_editableBudgetStatus ?? '').toLowerCase().contains('draft'));

  bool get _isIssuedEditable =>
      _isEditingBudget &&
      ((_editableBudgetStatus ?? '').toLowerCase().contains('issued'));

  int get _minVisibleStep => _isEditingBudget ? 1 : 0;

  Future<void> _loadClientBudgetStats(String? clientId) async {
    if (clientId == null || clientId.trim().isEmpty) {
      setState(() {
        _clientBudgetIssuedCount = 0;
        _clientBudgetDraftCount = 0;
        _clientPastBudgets = [];
        _loadingClientBudgetStats = false;
      });
      return;
    }
    setState(() => _loadingClientBudgetStats = true);
    try {
      final all = (await _presupuestosApi.listByGroup(
        groupId: widget.groupId.trim(),
        clientId: clientId.trim(),
        limit: 500,
      ))
          .where((item) => item['hasDocumentContent'] != true)
          .toList(growable: false);
      final now = DateTime.now();
      DateTime? _budgetDate(Map<String, dynamic> b) {
        final v = b['registeredAt'] ?? b['issueDate'] ?? b['createdAt'];
        if (v == null) return null;
        if (v is DateTime) return v;
        return DateTime.tryParse(v.toString());
      }

      final thisMonth = all.where((b) {
        final d = _budgetDate(b);
        if (d == null) return false;
        return d.year == now.year && d.month == now.month;
      }).toList();

      final past = all.where((b) {
        final d = _budgetDate(b);
        if (d == null) return true;
        return !(d.year == now.year && d.month == now.month);
      }).toList()
        ..sort((a, b) {
          final da = _budgetDate(a);
          final db = _budgetDate(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });

      if (mounted) {
        setState(() {
          _clientBudgetIssuedCount = thisMonth
              .where((b) => (b['status'] ?? '').toString().contains('issue'))
              .length;
          _clientBudgetDraftCount = thisMonth
              .where((b) => !(b['status'] ?? '').toString().contains('issue'))
              .length;
          _clientPastBudgets = past;
          _loadingClientBudgetStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClientBudgetStats = false);
    }
  }

  Future<void> _previewHistoricalBudget(Map<String, dynamic> budget) async {
    final id = (budget['_id'] ?? budget['id'] ?? '').toString();
    final number =
        (budget['presupuestoNumber'] ?? budget['budgetNumber'] ?? 'preview')
            .toString();
    try {
      final r = await _presupuestosApi.previewPdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      await pdf_launcher.launchPdfPreview(bytes,
          fileName: 'presupuesto-$number.pdf');
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _releaseCreatePreviewSurface() {
    _loadingPreview = false;
    _previewError = null;
    _previewPdfBytes = null;
    _previewForId = null;
  }

  void _releaseDetailPreviewSurface() {
    _loadingDetailPreview = false;
    _detailPreviewError = null;
    _detailPreviewPdfBytes = null;
    _detailPreviewForId = null;
  }

  void _resetEditableBudgetState() {
    _editableBudgetStatus = null;
    _editableBudgetError = null;
    _loadingEditableBudget = false;
    _editableBudgetDirty = false;
    _editableBudgetVersion = null;
    _draftId = null;
    _issuedPresupuestoNumber = null;
    _budgetIssueDate = null;
    _budgetCurrencyCtrl.text = 'EUR';
    _budgetNotesCtrl.clear();
    _issuedEditReasonCtrl.clear();
    _useBudgetDiscountPercent = false;
    _budgetDiscountAmountCtrl.clear();
    _budgetDiscountPercentCtrl.clear();
    _selectedClientId = null;
    _clientNameCtrl.clear();
    _clientAddressCtrl.clear();
    _clientCityCtrl.clear();
    _clientPostalCodeCtrl.clear();
    _clientSource = _ClientSource.existing;
    _confirmPreview = false;
    _visibleStep = 0;
    _applyPresupuestoPayload(const <String, dynamic>{});
  }

  Future<void> _loadEditableBudget(String budgetId) async {
    final trimmedId = budgetId.trim();
    if (trimmedId.isEmpty) {
      setState(_resetEditableBudgetState);
      return;
    }
    setState(() {
      _loadingEditableBudget = true;
      _editableBudgetError = null;
    });
    try {
      final payload = await _presupuestosApi.getById(trimmedId);
      if (!mounted) return;
      setState(() {
        _loadingEditableBudget = false;
        _editableBudgetError = null;
        _applyEditableBudgetPayload(payload);
      });
      if (_draftId != null && _draftId!.isNotEmpty) {
        _loadPreviewPdf(force: true);
      }
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEditableBudget = false;
        _editableBudgetError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEditableBudget = false;
        _editableBudgetError =
            e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  void _setVisibleStep(int value) {
    if (_visibleStep == 3 && value != 3) {
      _releaseCreatePreviewSurface();
    }
    _visibleStep = value;
    _error = null;
  }

  void _handleBudgetBack() {
    if (_visibleStep <= _minVisibleStep && _isEditingBudget) {
      _requestExitBudgetEditor();
      return;
    }
    setState(() {
      _setVisibleStep(_visibleStep - 1);
    });
  }

  Future<void> _requestExitBudgetEditor() async {
    if (!_editableBudgetDirty || _issuing) {
      widget.onExitEditor?.call();
      return;
    }
    final isEs = _isSpanishLocale;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Tienes cambios sin guardar' : 'Unsaved changes'),
        content: Text(
          isEs
              ? 'Puedes quedarte, salir sin guardar o guardar el borrador antes de salir.'
              : 'You can stay, leave without saving, or save the draft before leaving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('stay'),
            child: Text(isEs ? 'Quedarme' : 'Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('leave'),
            child: Text(isEs ? 'Salir sin guardar' : 'Leave without saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(isEs ? 'Guardar y salir' : 'Save & leave'),
          ),
        ],
      ),
    );
    if (!mounted || result == null || result == 'stay') return;
    if (result == 'save') {
      await _saveDraftOnly();
      if (!mounted || _editableBudgetDirty) return;
    }
    widget.onUnsavedStateChanged?.call(false);
    widget.onExitEditor?.call();
  }

  Widget _budgetDraftStatusChip(ColorScheme cs, AppTypography t) {
    final hasSavedDraft = (_draftId ?? '').trim().isNotEmpty;
    final text = _issuing
        ? (_isSpanishLocale ? 'Guardando...' : 'Saving...')
        : _editableBudgetDirty
            ? (_isSpanishLocale ? 'Cambios sin guardar' : 'Unsaved changes')
            : hasSavedDraft
                ? (_isSpanishLocale ? 'Borrador guardado' : 'Draft saved')
                : (_isSpanishLocale
                    ? 'Pulsa guardar para crear borrador'
                    : 'Press save to create draft');
    final icon = _issuing
        ? Icons.sync_rounded
        : _editableBudgetDirty
            ? Icons.edit_note_rounded
            : hasSavedDraft
                ? Icons.cloud_done_outlined
                : Icons.save_outlined;
    final color = _issuing || _editableBudgetDirty ? cs.tertiary : cs.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode == GroupInvoicesBudgetsMode.list) {
      _loadBudgets();
    } else if (_isEditingBudget) {
      _loadEditableBudget(widget.initialSelectedBudgetId!.trim());
    }
  }

  @override
  void didUpdateWidget(covariant GroupInvoicesBudgetsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modeChanged = oldWidget.mode != widget.mode;
    final modeChangedToList = oldWidget.mode != GroupInvoicesBudgetsMode.list &&
        widget.mode == GroupInvoicesBudgetsMode.list;
    final modeChangedToCreate =
        oldWidget.mode != GroupInvoicesBudgetsMode.create &&
            widget.mode == GroupInvoicesBudgetsMode.create;
    final groupChanged = oldWidget.groupId != widget.groupId;
    final initialBudgetChanged =
        oldWidget.initialSelectedBudgetId != widget.initialSelectedBudgetId;
    if (modeChanged || groupChanged) {
      _releaseCreatePreviewSurface();
      _releaseDetailPreviewSurface();
    }
    if (modeChangedToList || groupChanged) {
      _loadBudgets();
      return;
    }
    if (modeChangedToCreate) {
      _selectedBudgetId = null;
      final targetId = (widget.initialSelectedBudgetId ?? '').trim();
      if (targetId.isNotEmpty) {
        _loadEditableBudget(targetId);
      } else {
        _resetEditableBudgetState();
      }
      return;
    }
    if ((modeChanged || initialBudgetChanged) &&
        widget.mode == GroupInvoicesBudgetsMode.create) {
      final targetId = (widget.initialSelectedBudgetId ?? '').trim();
      if (targetId.isNotEmpty) {
        _loadEditableBudget(targetId);
      } else {
        _resetEditableBudgetState();
      }
    }
    if (initialBudgetChanged && widget.mode == GroupInvoicesBudgetsMode.list) {
      final targetId = (widget.initialSelectedBudgetId ?? '').trim();
      if (targetId.isNotEmpty &&
          _budgets.any((item) => _budgetId(item).trim() == targetId)) {
        setState(() => _selectedBudgetId = targetId);
        _loadDetailPreviewPdf(targetId);
      }
    }
  }

  @override
  void dispose() {
    _releaseCreatePreviewSurface();
    _releaseDetailPreviewSurface();
    _clientNameCtrl.dispose();
    _clientAddressCtrl.dispose();
    _clientCityCtrl.dispose();
    _clientPostalCodeCtrl.dispose();
    _budgetNotesCtrl.dispose();
    _issuedEditReasonCtrl.dispose();
    _budgetCurrencyCtrl.dispose();
    _budgetDiscountAmountCtrl.dispose();
    _budgetDiscountPercentCtrl.dispose();
    for (final line in _budgetLines) {
      line.dispose();
    }
    for (final block in _budgetBlocks) {
      block.dispose();
    }
    super.dispose();
  }

  bool get _hasClientInfo {
    if (_clientSource == _ClientSource.existing) {
      return (_selectedClientId ?? '').trim().isNotEmpty;
    }
    return _clientNameCtrl.text.trim().isNotEmpty;
  }

  bool get _hasLineItems => _budgetLines.any(_budgetLineHasBillableContent);
  bool get _hasBillableBlocks => _budgetBlocks.any((b) => b.hasBillableContent);
  bool get _hasLineContent => _useBlocks ? _hasBillableBlocks : _hasLineItems;

  int get _billableItemsCount => _useBlocks
      ? _budgetBlocks.where((b) => b.hasBillableContent).length
      : _budgetLines.where(_budgetLineHasBillableContent).length;

  int get _maxAllowedStep => !_hasClientInfo
      ? 0
      : !_hasLineContent
          ? 2
          : 3;

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == GroupInvoicesBudgetsMode.create;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final selectedClient = widget.clients
        .where((c) => c.id == _selectedClientId)
        .cast<GroupClient?>()
        .firstWhere((_) => true, orElse: () => null);
    final selectedClientName = selectedClient?.name.trim().isNotEmpty == true
        ? selectedClient!.name.trim()
        : _clientNameCtrl.text.trim();
    if (_visibleStep > _maxAllowedStep) {
      if (_visibleStep == 3) {
        _releaseCreatePreviewSurface();
      }
      _visibleStep = _maxAllowedStep;
    }

    final steps = <Step>[
      Step(
        title: Text(l.budgetStepClient),
        subtitle: const SizedBox.shrink(),
        content: const SizedBox.shrink(),
        isActive: _visibleStep == 0,
        state: _visibleStep > 0 ? StepState.complete : StepState.editing,
      ),
      Step(
        title: Text(_isSpanishLocale ? 'Detalles' : 'Details'),
        subtitle: const SizedBox.shrink(),
        content: const SizedBox.shrink(),
        isActive: _visibleStep == 1,
        state: _visibleStep > 1
            ? StepState.complete
            : (_visibleStep == 1 ? StepState.editing : StepState.indexed),
      ),
      Step(
        title: Text(l.budgetStepLines),
        subtitle: const SizedBox.shrink(),
        content: const SizedBox.shrink(),
        isActive: _visibleStep == 2,
        state: _visibleStep > 2
            ? StepState.complete
            : (_visibleStep == 2 ? StepState.editing : StepState.indexed),
      ),
      Step(
        title: Text(l.budgetStepPreview),
        subtitle: const SizedBox.shrink(),
        content: const SizedBox.shrink(),
        isActive: _visibleStep == 3,
        state: _visibleStep == 3 ? StepState.editing : StepState.indexed,
      ),
    ];

    if (_historyBudget != null) {
      final budget = _historyBudget!;
      return ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height - 150)
                .clamp(680.0, 980.0)
                .toDouble(),
            child: _BudgetHistoryDialog(
              api: _presupuestosApi,
              presupuestoId: _budgetId(budget),
              title: _budgetClientName(budget, l),
              localeName: l.localeName,
              isSpanish: _isSpanishLocale,
              embedded: true,
              onBack: () => setState(() => _historyBudget = null),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCreate) ...[
                _buildBudgetsListLayout(context),
              ] else ...[
                if (_loadingEditableBudget)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                else if ((_editableBudgetError ?? '').trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: cs.error.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editableBudgetError!,
                          style: TextStyle(color: cs.error),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _loadEditableBudget(
                            (widget.initialSelectedBudgetId ?? '').trim(),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l.tryAgain),
                        ),
                      ],
                    ),
                  )
                else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final showInlineClient = selectedClientName.isNotEmpty &&
                          constraints.maxWidth >= 860;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: WizardStepsHeader(
                                  steps: steps,
                                  currentStep: _visibleStep,
                                  isWide: true,
                                  maxWidth: double.infinity,
                                  height: 112,
                                  onStepTapped: (target) {
                                    if (target >= _minVisibleStep &&
                                        target <= _maxAllowedStep) {
                                      setState(() {
                                        _setVisibleStep(target);
                                      });
                                      if (target == 3) {
                                        _createDraftAndPreparePreview();
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              _budgetDraftStatusChip(cs, t),
                              if (showInlineClient) ...[
                                const SizedBox(width: 10),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 320),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color:
                                            cs.primary.withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      l.budgetConfirmClientValue(
                                          selectedClientName),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!showInlineClient &&
                              selectedClientName.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              l.budgetConfirmClientValue(selectedClientName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStepContent(cs, l),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    _BudgetInlineErrorCard(
                      message: _error!,
                      visibleStep: _visibleStep,
                      isSpanishLocale: _isSpanishLocale,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (_visibleStep > _minVisibleStep ||
                          (_isEditingBudget && widget.onExitEditor != null))
                        TextButton(
                          onPressed: _issuing ? null : _handleBudgetBack,
                          child: Text(l.budgetBackCta),
                        ),
                      const Spacer(),
                      if (_visibleStep < 3)
                        FilledButton(
                          onPressed: !_issuing
                              ? () async {
                                  if (!_validateCurrentStep()) return;
                                  final target = _visibleStep + 1;
                                  setState(() {
                                    _setVisibleStep(target);
                                  });
                                  if (target == 3) {
                                    await _createDraftAndPreparePreview();
                                  }
                                }
                              : null,
                          child: Text(l.budgetNextCta),
                        )
                      else ...[
                        if (_isEditingBudget &&
                            (_editableBudgetVersion ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text('Versión $_editableBudgetVersion'),
                            ),
                          ),
                        if (_isEditingBudget &&
                            (_draftId ?? '').trim().isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () => _showBudgetHistoryDialog({
                              'id': _draftId,
                              'clientName': _clientNameCtrl.text.trim(),
                              'presupuestoNumber': _issuedPresupuestoNumber,
                            }),
                            icon: const Icon(Icons.history_rounded),
                            label: Text(
                              _isSpanishLocale ? 'Historial' : 'History',
                            ),
                          ),
                        if (_isEditingBudget &&
                            !_isDraftEditable &&
                            !_isIssuedEditable)
                          Text(
                            _isSpanishLocale
                                ? 'Este presupuesto no se puede editar.'
                                : 'This presupuesto cannot be edited.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          )
                        else
                          FilledButton.icon(
                            onPressed: (_issuing ||
                                    (_isEditingBudget &&
                                        !_editableBudgetDirty &&
                                        (_draftId ?? '').trim().isNotEmpty))
                                ? null
                                : _saveDraftOnly,
                            icon: _issuing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _isEditingBudget
                                  ? (_isIssuedEditable
                                      ? (_isSpanishLocale
                                          ? 'Guardar nueva versión'
                                          : 'Save new version')
                                      : (_isSpanishLocale
                                          ? 'Guardar cambios'
                                          : 'Save changes'))
                                  : (_isSpanishLocale
                                      ? 'Guardar borrador'
                                      : 'Save draft'),
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _budgetId(Map<String, dynamic> item) {
    return (item['_id'] ?? item['id'] ?? '').toString();
  }

  String _budgetNumber(Map<String, dynamic> item) {
    final number = (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
    return number.isEmpty ? '-' : number;
  }

  String _budgetStatus(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString().trim().toLowerCase();
    return status.isEmpty ? 'draft' : status;
  }

  bool _isDraftBudget(Map<String, dynamic> item) =>
      _budgetStatus(item).contains('draft');

  int _budgetVersion(Map<String, dynamic> item) {
    final raw = item['currentVersion'] ??
        item['version'] ??
        item['snapshotVersion'] ??
        item['revision'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 1;
  }

  // ignore: unused_element
  bool _hasBudgetChangeHistory(Map<String, dynamic> item) {
    if (_budgetVersion(item) > 1) return true;
    final snapshots = item['snapshots'];
    if (snapshots is List && snapshots.isNotEmpty) return true;
    final changedFields = item['changedFields'];
    if (changedFields is List && changedFields.isNotEmpty) return true;
    return false;
  }

  String? _convertedInvoiceId(Map<String, dynamic> item) {
    final direct = (item['convertedInvoiceId'] ??
            item['invoiceId'] ??
            item['convertedToInvoiceId'] ??
            '')
        .toString()
        .trim();
    if (direct.isNotEmpty) return direct;
    final nested = item['conversion'];
    if (nested is Map) {
      final n = (nested['invoiceId'] ?? '').toString().trim();
      if (n.isNotEmpty) return n;
    }
    return null;
  }

  bool _isConvertedToInvoice(Map<String, dynamic> item) =>
      (_convertedInvoiceId(item) ?? '').isNotEmpty;

  // ignore: unused_element
  bool _canConvertToInvoice(Map<String, dynamic> item) {
    if (_isDraftBudget(item) || _isConvertedToInvoice(item)) return false;
    final status = _budgetStatus(item);
    return status.contains('issued') || status.contains('accept');
  }

  // ignore: unused_element
  String _convertDisabledReason(Map<String, dynamic> item) {
    if (_isConvertedToInvoice(item)) return 'Convertido previamente';
    if (_isDraftBudget(item)) return 'Solo presupuestos emitidos/aceptados';
    final status = _budgetStatus(item);
    if (!(status.contains('issued') || status.contains('accept'))) {
      return 'Estado no elegible para conversión';
    }
    return '';
  }

  PresupuestoInvoiceActionState _invoiceActionState(
    Map<String, dynamic> item,
  ) {
    return resolvePresupuestoInvoiceActionState(item);
  }

  num? _budgetBaseAmount(Map<String, dynamic> item) {
    final candidates = <dynamic>[
      item['subtotal'],
      item['baseAmount'],
      item['taxableBase'],
    ];
    for (final value in candidates) {
      if (value is num) return value;
      final parsed =
          num.tryParse((value ?? '').toString().trim().replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
    return null;
  }

  double _budgetDefaultTaxRate(Map<String, dynamic> item) {
    double? parse(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(
        (value ?? '').toString().trim().replaceAll(',', '.'),
      );
    }

    final lines = item['lines'];
    if (lines is List) {
      for (final raw in lines.whereType<Map>()) {
        final tax =
            parse(raw['taxRate'] ?? raw['tax'] ?? raw['vat'] ?? raw['iva']);
        if (tax != null && tax >= 0) return tax;
      }
    }

    final blocks = item['blocks'];
    if (blocks is List) {
      for (final raw in blocks.whereType<Map>()) {
        final tax =
            parse(raw['taxRate'] ?? raw['tax'] ?? raw['vat'] ?? raw['iva']);
        if (tax != null && tax >= 0) return tax;
      }
    }

    return 21;
  }

  DateTime? _budgetDate(Map<String, dynamic> item) {
    final raw = item['issueDate'] ??
        item['registeredAt'] ??
        item['createdAt'] ??
        item['occurrenceDate'];
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  String _budgetMonthLabel(DateTime dt, String locale) {
    final formatter = DateFormat.yMMMM(locale);
    final raw = formatter.format(dt.toLocal());
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _budgetClientName(Map<String, dynamic> item, AppLocalizations l) {
    final byField = (item['clientName'] ?? '').toString().trim();
    if (byField.isNotEmpty) return byField;
    final client = item['client'];
    if (client is Map) {
      final nested = (client['name'] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
    }
    final byId = (item['clientId'] ?? '').toString().trim();
    if (byId.isNotEmpty) {
      final match = widget.clients
          .cast<GroupClient?>()
          .firstWhere((c) => c?.id == byId, orElse: () => null);
      if (match != null && match.name.trim().isNotEmpty) return match.name;
    }
    return l.unknownClient;
  }

  List<String> _missingClientBillingFieldsForBudget(Map<String, dynamic> item) {
    final clientId = (item['clientId'] ?? '').toString().trim();
    if (clientId.isEmpty) return const <String>[];
    final client = widget.clients
        .cast<GroupClient?>()
        .firstWhere((c) => c?.id == clientId, orElse: () => null);
    final billing = client?.billing;
    if (billing == null) {
      return const <String>[
        'legalName',
        'taxId',
        'addressStreet',
        'addressCity',
        'addressPostalCode',
        'addressCountry',
      ];
    }
    String cleaned(String? v) => (v ?? '').trim();
    final missing = <String>[];
    if (cleaned(billing.legalName).isEmpty) missing.add('legalName');
    if (cleaned(billing.taxId).isEmpty) missing.add('taxId');
    if (cleaned(billing.addressStreet).isEmpty) missing.add('addressStreet');
    if (cleaned(billing.addressCity).isEmpty) missing.add('addressCity');
    if (cleaned(billing.addressPostalCode).isEmpty)
      missing.add('addressPostalCode');
    if (cleaned(billing.addressCountry).isEmpty) missing.add('addressCountry');
    return missing;
  }

  num _budgetTotal(Map<String, dynamic> item) {
    num parseNum(dynamic value, {num fallback = 0}) {
      if (value is num) return value;
      return num.tryParse((value ?? '').toString().replaceAll(',', '.')) ??
          fallback;
    }

    final candidates = <dynamic>[
      item['total'],
      item['grandTotal'],
      item['amountTotal'],
      item['subtotal'],
    ];
    for (final value in candidates) {
      if (value is num) return value;
      final parsed =
          num.tryParse((value ?? '').toString().replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }

    final lines = item['lines'];
    if (lines is List && lines.isNotEmpty) {
      num sum = 0;
      for (final raw in lines.whereType<Map>()) {
        final line = Map<String, dynamic>.from(raw);
        final qty = parseNum(line['quantity'] ?? line['qty'] ?? 1, fallback: 1);
        final unit = parseNum(
          line['unitPrice'] ?? line['price'] ?? line['unit_price'] ?? 0,
        );
        final discount = parseNum(
          line['discountRate'] ?? line['discountPercent'] ?? 0,
        ).clamp(0, 100);
        final tax = parseNum(
          line['taxRate'] ?? line['tax'] ?? line['vat'] ?? line['iva'] ?? 0,
        );
        final grossBase = qty * unit;
        final base = grossBase - (grossBase * discount / 100);
        sum += base + (base * (tax / 100));
      }
      if (sum > 0) return sum;
    }

    final blocks = item['blocks'];
    if (blocks is List && blocks.isNotEmpty) {
      num sum = 0;
      for (final raw in blocks.whereType<Map>()) {
        final block = Map<String, dynamic>.from(raw);
        final qty =
            parseNum(block['qty'] ?? block['quantity'] ?? 1, fallback: 1);
        final unit = parseNum(
          block['unitPrice'] ?? block['price'] ?? block['unit_price'] ?? 0,
        );
        final discount = parseNum(
          block['discountRate'] ?? block['discountPercent'] ?? 0,
        ).clamp(0, 100);
        final tax = parseNum(
          block['taxRate'] ?? block['tax'] ?? block['vat'] ?? block['iva'] ?? 0,
        );
        final grossBase = qty * unit;
        final base = grossBase - (grossBase * discount / 100);
        sum += base + (base * (tax / 100));
      }
      if (sum > 0) return sum;
    }

    return 0;
  }

  // ignore: unused_element
  int _budgetLinesCount(Map<String, dynamic> item) {
    final lines = item['lines'];
    if (lines is List) return lines.length;
    final blocks = item['blocks'];
    if (blocks is List) return blocks.length;
    final count =
        int.tryParse((item['lineCount'] ?? item['count'] ?? '').toString());
    return count ?? 0;
  }

  Future<void> _loadBudgets() async {
    if (_loadingBudgets) return;
    setState(() {
      _loadingBudgets = true;
      _budgetsError = null;
    });
    try {
      final qp = budgetSortToQuery(_effectiveBudgetSortState);
      final list = await _presupuestosApi.listByGroup(
        groupId: widget.groupId,
        sortBy: qp.sortBy,
        sortDir: qp.sortDir,
        limit: 500,
      );
      if (!mounted) return;
      setState(() {
        _budgets = list
            .where((item) => item['hasDocumentContent'] != true)
            .toList(growable: false);
        final selected = (_selectedBudgetId ?? '').trim();
        final preferred = (widget.initialSelectedBudgetId ?? '').trim();
        if (selected.isEmpty ||
            !_budgets.any((e) => _budgetId(e).trim() == selected)) {
          if (preferred.isNotEmpty &&
              _budgets.any((e) => _budgetId(e).trim() == preferred)) {
            _selectedBudgetId = preferred;
          } else {
            _selectedBudgetId =
                _budgets.isEmpty ? null : _budgetId(_budgets.first);
          }
        }
      });
      if (_selectedBudgetId != null && _selectedBudgetId!.trim().isNotEmpty) {
        _loadDetailPreviewPdf(_selectedBudgetId!);
      }
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() => _budgetsError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _budgetsError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingBudgets = false);
    }
  }

  Future<void> _downloadBudgetPdf(Map<String, dynamic> budget) async {
    final l = AppLocalizations.of(context)!;
    final id = _budgetId(budget).trim();
    if (id.isEmpty) return;
    try {
      final response = _isDraftBudget(budget)
          ? await _presupuestosApi.previewPdf(id)
          : await _presupuestosApi.downloadPdf(id);
      final number = _budgetNumber(budget).replaceAll('/', '-');
      final fileName =
          number == '-' ? 'presupuesto-$id.pdf' : 'presupuesto-$number.pdf';
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.failedWithReason('') : msg);
    }
  }

  Future<void> _downloadBudgetsZip() async {
    if (_downloadingBudgetsZip) return;
    final l = AppLocalizations.of(context)!;
    setState(() => _downloadingBudgetsZip = true);
    try {
      final response =
          await _presupuestosApi.downloadAllPdfsZip(groupId: widget.groupId);
      await launchFileDownload(
        response.bodyBytes,
        fileName: 'presupuestos-${widget.groupId}.zip',
        mimeType: 'application/zip',
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.failedWithReason('') : msg);
    } finally {
      if (mounted) setState(() => _downloadingBudgetsZip = false);
    }
  }

  Future<void> _showBudgetHistoryDialog(Map<String, dynamic> budget) async {
    final id = _budgetId(budget).trim();
    if (id.isEmpty) return;
    setState(() => _historyBudget = Map<String, dynamic>.from(budget));
  }

  Future<void> _issueBudgetFromList(Map<String, dynamic> budget) async {
    final l = AppLocalizations.of(context)!;
    final id = _budgetId(budget).trim();
    if (id.isEmpty || _issuingBudgetIds.contains(id)) return;
    setState(() => _issuingBudgetIds.add(id));
    try {
      final updated = await _presupuestosApi.issue(id);
      final number =
          (updated['presupuestoNumber'] ?? updated['budgetNumber'] ?? '-')
              .toString()
              .trim();
      if (!mounted) return;
      showSuccessSnack(
          context, l.budgetIssuedSnack(number.isEmpty ? '-' : number));
      await _loadBudgets();
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.failedWithReason('') : msg);
    } finally {
      if (mounted) {
        setState(() => _issuingBudgetIds.remove(id));
      }
    }
  }

  Future<void> _deleteDraftBudget(Map<String, dynamic> budget) async {
    final l = AppLocalizations.of(context)!;
    final id = _budgetId(budget).trim();
    if (id.isEmpty || _deletingBudgetIds.contains(id)) return;
    final number = _budgetNumber(budget);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.groupInvoicesRemoveDraftTitle),
            content: Text('Esto eliminará el presupuesto $number.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child:
                    Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _deletingBudgetIds.add(id));
    try {
      await _presupuestosApi.remove(id);
      if (!mounted) return;
      showSuccessSnack(context, l.budgetDeletedSnack);
      await _loadBudgets();
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.failedWithReason('') : msg);
    } finally {
      if (mounted) {
        setState(() => _deletingBudgetIds.remove(id));
      }
    }
  }

  // ignore: unused_element
  String? _extractInvoiceIdFromConvertResponse(Map<String, dynamic> payload) {
    final direct =
        (payload['invoiceId'] ?? payload['invoice'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final data = payload['data'];
    if (data is Map) {
      final nested = (data['invoiceId'] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
    }
    return null;
  }

  String _mapIssuePresupuestoError(PresupuestosApiException e) {
    final code = (e.code ?? '').trim().toLowerCase();
    final message = e.message.trim();
    final details = e.details ?? const <String, dynamic>{};
    final missing = details['missingFields'];
    final missingFields = missing is List
        ? missing
            .map((v) => v.toString().trim())
            .where((v) => v.isNotEmpty)
            .toList()
        : const <String>[];

    final snapshotMissingByCode = code.contains('snapshot');
    final snapshotMissingByMessage =
        message.toLowerCase().contains('snapshot') &&
            message.toLowerCase().contains('missing required fields');
    if (snapshotMissingByCode || snapshotMissingByMessage) {
      if (missingFields.isNotEmpty) {
        return 'No se puede emitir: faltan datos fiscales del cliente '
            '(${missingFields.join(', ')}). Completa la ficha del cliente y vuelve a emitir.';
      }
      return 'No se puede emitir: faltan datos fiscales del cliente en el snapshot. '
          'Completa la ficha del cliente y vuelve a emitir.';
    }
    return message;
  }

  AdvanceInvoiceConfigInput _defaultAdvanceInputForBudget(
    Map<String, dynamic> budget,
  ) {
    final number = _budgetNumber(budget);
    return AdvanceInvoiceConfigInput(
      percent: 70,
      description: number == '-'
          ? 'Anticipo 70% presupuesto'
          : 'Anticipo 70% presupuesto $number',
    );
  }

  // ignore: unused_element
  Future<void> _createAdvanceInvoiceAutomatically(
    Map<String, dynamic> budget,
  ) async {
    final presupuestoId = _budgetId(budget).trim();
    if (presupuestoId.isEmpty ||
        _creatingAdvanceInvoiceBudgetIds.contains(presupuestoId)) {
      return;
    }
    final actionState = _invoiceActionState(budget);
    if (!actionState.canCreateAdvance) return;

    setState(() => _creatingAdvanceInvoiceBudgetIds.add(presupuestoId));
    try {
      final payload = buildAdvanceInvoiceRequest(
        _defaultAdvanceInputForBudget(budget),
      );
      final result = await _presupuestosApi.createAdvanceInvoiceFromPresupuesto(
        presupuestoId,
        payload: payload,
      );
      final invoiceId = result.invoiceId?.trim().isNotEmpty == true
          ? result.invoiceId!.trim()
          : _extractInvoiceIdFromCreateResponse(result.raw);
      if (!mounted) return;
      showSuccessSnack(context,
          AppLocalizations.of(context)!.budgetAdvanceInvoiceCreatedSnack);
      await _loadBudgets();
      if (invoiceId != null && invoiceId.isNotEmpty) {
        widget.onOpenInvoiceId?.call(invoiceId);
      }
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _creatingAdvanceInvoiceBudgetIds.remove(presupuestoId));
      }
    }
  }

  String? _extractInvoiceIdFromCreateResponse(Map<String, dynamic> payload) {
    final direct = (payload['invoiceId'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final invoice = payload['invoice'];
    if (invoice is Map) {
      final nested = (invoice['_id'] ?? invoice['id'] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
    }
    return null;
  }

  // ignore: unused_element
  Future<void> _openCreateAdvanceInvoiceDialog(
    Map<String, dynamic> budget,
  ) async {
    final isSpanish = _isSpanishLocale;
    final presupuestoId = _budgetId(budget).trim();
    if (presupuestoId.isEmpty ||
        _creatingAdvanceInvoiceBudgetIds.contains(presupuestoId)) {
      return;
    }

    final actionState = _invoiceActionState(budget);
    if (!actionState.canCreateAdvance) return;
    setState(() => _creatingAdvanceInvoiceBudgetIds.add(presupuestoId));

    final percentCtrl = TextEditingController(text: '70');
    final baseAmount = _budgetBaseAmount(budget);
    final baseCtrl = TextEditingController(
      text: baseAmount == null ? '' : baseAmount.toStringAsFixed(2),
    );
    final vatCtrl = TextEditingController(text: '21');
    final descCtrl = TextEditingController(
      text: 'Anticipo 70% presupuesto',
    );

    String? errorText;
    bool submitting = false;

    try {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    title: Text(
                      isSpanish
                          ? 'Crear factura de anticipo'
                          : 'Create Advance Invoice',
                    ),
                    content: SizedBox(
                      width: 420,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: percentCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: isSpanish ? 'Porcentaje' : 'Percent',
                              hintText: '70',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: baseCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: isSpanish
                                  ? 'Base del proyecto (opcional)'
                                  : 'Project Base Amount (optional)',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: vatCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: isSpanish ? 'IVA %' : 'VAT %',
                              hintText: '21',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descCtrl,
                            decoration: InputDecoration(
                              labelText: isSpanish
                                  ? 'Descripción (opcional)'
                                  : 'Description (optional)',
                            ),
                          ),
                          if ((errorText ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.of(ctx).pop(false),
                        child: Text(MaterialLocalizations.of(context)
                            .cancelButtonLabel),
                      ),
                      FilledButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final percent = double.tryParse(
                                  percentCtrl.text.trim().replaceAll(',', '.'),
                                );
                                final base = baseCtrl.text.trim().isEmpty
                                    ? null
                                    : double.tryParse(
                                        baseCtrl.text
                                            .trim()
                                            .replaceAll(',', '.'),
                                      );
                                final vat = vatCtrl.text.trim().isEmpty
                                    ? null
                                    : double.tryParse(
                                        vatCtrl.text
                                            .trim()
                                            .replaceAll(',', '.'),
                                      );
                                if (percent == null) {
                                  setDialogState(() {
                                    errorText = isSpanish
                                        ? 'El porcentaje es obligatorio.'
                                        : 'Percent is required.';
                                  });
                                  return;
                                }

                                final input = AdvanceInvoiceConfigInput(
                                  percent: percent,
                                  description: descCtrl.text,
                                );
                                final validation = validateAdvanceConfig(input);
                                if (!validation.isValid) {
                                  setDialogState(() {
                                    errorText = validation.message;
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  submitting = true;
                                  errorText = null;
                                });
                                try {
                                  final payload =
                                      buildAdvanceInvoiceRequest(input);
                                  final result = await _presupuestosApi
                                      .createAdvanceInvoiceFromPresupuesto(
                                    presupuestoId,
                                    payload: payload,
                                  );
                                  final invoiceId =
                                      result.invoiceId?.trim().isNotEmpty ==
                                              true
                                          ? result.invoiceId!.trim()
                                          : _extractInvoiceIdFromCreateResponse(
                                              result.raw);
                                  if (!mounted) return;
                                  Navigator.of(ctx).pop(true);
                                  showSuccessSnack(
                                      context,
                                      AppLocalizations.of(context)!
                                          .budgetAdvanceInvoiceCreatedSimpleSnack);
                                  await _loadBudgets();
                                  if (invoiceId != null &&
                                      invoiceId.isNotEmpty) {
                                    widget.onOpenInvoiceId?.call(invoiceId);
                                  }
                                } on PresupuestosApiException catch (e) {
                                  setDialogState(() {
                                    errorText = e.message;
                                    submitting = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    errorText = e
                                        .toString()
                                        .replaceFirst('Exception: ', '');
                                    submitting = false;
                                  });
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isSpanish ? 'Crear' : 'Create'),
                      ),
                    ],
                  );
                },
              );
            },
          ) ??
          false;
      if (!confirmed || !mounted) return;
    } finally {
      percentCtrl.dispose();
      baseCtrl.dispose();
      vatCtrl.dispose();
      descCtrl.dispose();
      if (mounted) {
        setState(() => _creatingAdvanceInvoiceBudgetIds.remove(presupuestoId));
      }
    }
  }

  Future<List<AdvanceInvoiceCandidate>> _loadAdvanceInvoiceCandidates(
    String presupuestoId,
  ) async {
    final detail = await _presupuestosApi.getById(presupuestoId);
    return extractAdvanceInvoiceCandidatesFromPresupuesto(detail);
  }

  // ignore: unused_element
  Future<void> _openCreateFinalInvoiceDialog(
    Map<String, dynamic> budget,
  ) async {
    final isSpanish = _isSpanishLocale;
    final presupuestoId = _budgetId(budget).trim();
    if (presupuestoId.isEmpty ||
        _creatingFinalInvoiceBudgetIds.contains(presupuestoId)) {
      return;
    }
    final actionState = _invoiceActionState(budget);
    if (!actionState.canCreateFinal) return;

    setState(() => _creatingFinalInvoiceBudgetIds.add(presupuestoId));
    try {
      final candidates = await _loadAdvanceInvoiceCandidates(presupuestoId);
      if (!mounted) return;

      AdvanceInvoiceCandidate? selectedCandidate =
          candidates.cast<AdvanceInvoiceCandidate?>().firstWhere(
                (e) => e != null && e.isIssued,
                orElse: () => candidates.isEmpty ? null : candidates.first,
              );
      String? errorText;
      bool submitting = false;

      final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return StatefulBuilder(
                builder: (ctx, setDialogState) {
                  return AlertDialog(
                    title: Text(
                      isSpanish
                          ? 'Crear factura final'
                          : 'Create Final Invoice',
                    ),
                    content: SizedBox(
                      width: 420,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownMenu<String>(
                            width: 380,
                            initialSelection: selectedCandidate?.id,
                            label: Text(
                              isSpanish
                                  ? 'Factura de anticipo (opcional)'
                                  : 'Advance invoice (optional)',
                            ),
                            hintText: isSpanish
                                ? 'Selecciona una factura de anticipo'
                                : 'Select advance invoice',
                            enableFilter: true,
                            onSelected: (id) {
                              setDialogState(() {
                                if ((id ?? '').trim().isEmpty) {
                                  selectedCandidate = null;
                                  return;
                                }
                                selectedCandidate = candidates
                                    .where((e) => e.id == id)
                                    .cast<AdvanceInvoiceCandidate?>()
                                    .firstWhere((e) => true,
                                        orElse: () => null);
                              });
                            },
                            dropdownMenuEntries: <DropdownMenuEntry<String>>[
                              DropdownMenuEntry<String>(
                                value: '',
                                label: isSpanish
                                    ? 'Sin factura de anticipo'
                                    : 'No advance invoice',
                              ),
                              ...candidates.map(
                                (c) => DropdownMenuEntry<String>(
                                  value: c.id,
                                  label:
                                      '${c.number}${c.status.isEmpty ? '' : ' · ${c.status}'}',
                                ),
                              ),
                            ],
                          ),
                          if ((errorText ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: submitting
                            ? null
                            : () => Navigator.of(ctx).pop(false),
                        child: Text(MaterialLocalizations.of(context)
                            .cancelButtonLabel),
                      ),
                      FilledButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                setDialogState(() {
                                  submitting = true;
                                  errorText = null;
                                });
                                try {
                                  final payload = buildFinalInvoiceRequest(
                                    advanceInvoiceId: selectedCandidate?.id,
                                  );
                                  final result = await _presupuestosApi
                                      .createFinalInvoiceFromPresupuesto(
                                    presupuestoId,
                                    payload: payload,
                                  );
                                  final invoiceId =
                                      result.invoiceId?.trim().isNotEmpty ==
                                              true
                                          ? result.invoiceId!.trim()
                                          : _extractInvoiceIdFromCreateResponse(
                                              result.raw);
                                  if (!mounted) return;
                                  Navigator.of(ctx).pop(true);
                                  showSuccessSnack(
                                      context,
                                      AppLocalizations.of(context)!
                                          .budgetFinalInvoiceCreatedSnack);
                                  await _loadBudgets();
                                  if (invoiceId != null &&
                                      invoiceId.isNotEmpty) {
                                    widget.onOpenInvoiceId?.call(invoiceId);
                                  }
                                } on PresupuestosApiException catch (e) {
                                  setDialogState(() {
                                    errorText = e.message;
                                    submitting = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    errorText = e
                                        .toString()
                                        .replaceFirst('Exception: ', '');
                                    submitting = false;
                                  });
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isSpanish ? 'Crear' : 'Create'),
                      ),
                    ],
                  );
                },
              );
            },
          ) ??
          false;
      if (!confirmed || !mounted) return;
      await _loadBudgets();
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, _mapIssuePresupuestoError(e));
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _creatingFinalInvoiceBudgetIds.remove(presupuestoId));
      }
    }
  }

  // ignore: unused_element
  Future<void> _convertBudgetToInvoice(Map<String, dynamic> budget) async {
    final l = AppLocalizations.of(context)!;
    final id = _budgetId(budget).trim();
    if (id.isEmpty || _convertingBudgetIds.contains(id)) return;

    debugPrint('presupuesto_convert_click id=$id');
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Convertir presupuesto a factura'),
            content: const Text(
              'Se creará una factura en borrador con las líneas del presupuesto.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child:
                    Text(MaterialLocalizations.of(context).cancelButtonLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Convertir'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    setState(() => _convertingBudgetIds.add(id));
    try {
      final response = await _presupuestosApi.convertToInvoice(id);
      final invoiceId = _extractInvoiceIdFromConvertResponse(response);
      if (!mounted) return;
      debugPrint('presupuesto_convert_success id=$id invoiceId=$invoiceId');
      showSuccessSnack(context, l.budgetConvertedToInvoiceSnack);
      await _loadBudgets();
      if (invoiceId != null && invoiceId.trim().isNotEmpty) {
        widget.onOpenInvoiceId?.call(invoiceId.trim());
      }
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      final code = (e.code ?? '').trim();
      debugPrint('presupuesto_convert_error id=$id code=$code');
      String msg;
      SnackBarAction? action;
      if (code == 'PRESUPUESTO_NOT_ACCEPTED') {
        msg = 'Solo presupuestos emitidos/aceptados se pueden convertir.';
      } else if (code == 'PRESUPUESTO_CLIENT_REQUIRED') {
        msg =
            'Este presupuesto necesita un cliente registrado para convertirse a factura.';
      } else if (code == 'PRESUPUESTO_ALREADY_CONVERTED') {
        msg = 'Ya convertido previamente';
        final existingId =
            _extractInvoiceIdFromConvertResponse(e.details ?? {});
        if (existingId != null && existingId.isNotEmpty) {
          action = SnackBarAction(
            label: 'Abrir factura',
            onPressed: () => widget.onOpenInvoiceId?.call(existingId),
          );
        }
      } else if (code == 'PRESUPUESTO_NOT_FOUND') {
        msg = 'No se encontró el presupuesto.';
      } else if (code == 'FORBIDDEN') {
        msg = 'No tienes permisos para convertir este presupuesto.';
      } else if (code == 'PRESUPUESTO_EMPTY') {
        msg = 'El presupuesto no tiene líneas para convertir.';
      } else {
        msg = e.message;
      }
      showErrorSnack(context, msg, action: action);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(context, msg.isEmpty ? l.failedWithReason('') : msg);
    } finally {
      if (mounted) setState(() => _convertingBudgetIds.remove(id));
    }
  }

  Widget _buildBudgetsListLayout(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final drafts = _budgets.where(_isDraftBudget).toList(growable: false);
    final issuedBudgets =
        _budgets.where((item) => !_isDraftBudget(item)).toList(growable: false);
    final activeList = _budgetsTabIndex == 0 ? drafts : issuedBudgets;
    final sortState = _effectiveBudgetSortState;
    final sortByDate = sortState.by == BudgetSortBy.date;
    final sortByNumber = sortState.by == BudgetSortBy.number;
    final isAsc = sortState.dir == BudgetSortDir.asc;
    final selected = activeList.cast<Map<String, dynamic>?>().firstWhere(
          (e) =>
              _budgetId(e ?? const {}).trim() ==
              (_selectedBudgetId ?? '').trim(),
          orElse: () => activeList.isNotEmpty ? activeList.first : null,
        );

    Widget budgetListCard(Map<String, dynamic> item) {
      final isLight = Theme.of(context).brightness == Brightness.light;
      final id = _budgetId(item);
      final selectedRow = (_selectedBudgetId ?? '').trim() == id.trim();
      final date = _budgetDate(item);
      final dateLabel = date == null
          ? '-'
          : DateFormat.yMMMd(l.localeName).format(date.toLocal());
      final totalLabel = NumberFormat.currency(
        locale: l.localeName,
        symbol: '€',
      ).format(_budgetTotal(item));
      final isDraft = _isDraftBudget(item);
      final isIssuing = _issuingBudgetIds.contains(id);
      final missingClientFields = _missingClientBillingFieldsForBudget(item);
      final canIssueBudget = isDraft && missingClientFields.isEmpty;
      final isDeleting = _deletingBudgetIds.contains(id);
      final issueTooltip = !isDraft
          ? (_isSpanishLocale ? 'Presupuesto emitido' : 'Budget already issued')
          : missingClientFields.isNotEmpty
              ? 'Completa datos del cliente antes de emitir: ${missingClientFields.join(', ')}'
              : 'Emitir';

      Widget busySpinner(Color color) => SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          );

      Widget budgetActionButton({
        required String tooltip,
        required IconData icon,
        required VoidCallback? onPressed,
        required Color color,
        Widget? busyIcon,
      }) {
        final enabled = onPressed != null;
        var hovered = false;
        return StatefulBuilder(
          builder: (context, setHoverState) {
            return Tooltip(
              message: tooltip,
              child: MouseRegion(
                cursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                onEnter: (_) => setHoverState(() => hovered = true),
                onExit: (_) => setHoverState(() => hovered = false),
                child: InkWell(
                  borderRadius: BorderRadius.circular(7),
                  onTap: onPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 110),
                    curve: Curves.easeOut,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: enabled
                          ? color.withValues(alpha: hovered ? 0.16 : 0.07)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: enabled && hovered
                            ? color.withValues(alpha: 0.30)
                            : enabled
                                ? Colors.transparent
                                : cs.outlineVariant.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Center(
                      child: busyIcon ??
                          Icon(
                            icon,
                            size: 14,
                            color: enabled
                                ? color.withValues(alpha: hovered ? 1.0 : 0.75)
                                : cs.onSurfaceVariant.withValues(alpha: 0.42),
                          ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _selectedBudgetId = id);
          _loadDetailPreviewPdf(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selectedRow
                ? cs.primaryContainer.withValues(alpha: 0.28)
                : isLight
                    ? Colors.white
                    : cs.surfaceContainerHighest.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectedRow
                  ? cs.primary.withValues(alpha: 0.55)
                  : cs.outlineVariant.withValues(alpha: 0.28),
            ),
            boxShadow: isLight || selectedRow
                ? [
                    BoxShadow(
                      color: (selectedRow ? cs.primary : Colors.black)
                          .withValues(alpha: selectedRow ? 0.10 : 0.035),
                      blurRadius: selectedRow ? 16 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: selectedRow ? 0.24 : 0.14),
                      cs.tertiary.withValues(alpha: selectedRow ? 0.16 : 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.request_quote_outlined,
                  size: 17,
                  color: selectedRow ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _budgetClientName(item, l),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          t.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_budgetNumber(item)} · $dateLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    budgetActionButton(
                      tooltip: issueTooltip,
                      icon: Icons.publish_outlined,
                      onPressed: (canIssueBudget && !isIssuing)
                          ? () => _issueBudgetFromList(item)
                          : null,
                      color: cs.tertiary,
                      busyIcon: isIssuing ? busySpinner(cs.tertiary) : null,
                    ),
                    const SizedBox(width: 6),
                    budgetActionButton(
                      tooltip: l.download,
                      icon: Icons.download_rounded,
                      onPressed: () => _downloadBudgetPdf(item),
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    budgetActionButton(
                      tooltip: _isSpanishLocale
                          ? 'Editar presupuesto'
                          : 'Edit presupuesto',
                      onPressed: widget.onEditDraftBudget == null
                          ? null
                          : () => widget.onEditDraftBudget!.call(id),
                      icon: Icons.edit_outlined,
                      color: cs.primary,
                    ),
                    if (isDraft) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 1,
                        height: 14,
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      budgetActionButton(
                        tooltip: l.delete,
                        onPressed: (!isDeleting && !isIssuing)
                            ? () => _deleteDraftBudget(item)
                            : null,
                        icon: Icons.delete_outline_rounded,
                        color: cs.error,
                        busyIcon: isDeleting ? busySpinner(cs.error) : null,
                      ),
                    ],
                    const SizedBox(width: 10),
                    Text(
                      totalLabel,
                      style: t.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget detailPanel() {
      if (selected == null) {
        return Center(
          child: Text(
            l.groupInvoicesSelectInvoiceHint,
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        );
      }
      final budgetId = _budgetId(selected);
      final date = _budgetDate(selected);
      final dateLabel = date == null
          ? '-'
          : DateFormat.yMMMd(l.localeName).format(date.toLocal());
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _budgetClientName(selected, l),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: t.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (_loadingDetailPreview)
              const Expanded(
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (_detailPreviewError != null &&
                _detailPreviewError!.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 32, color: cs.error.withValues(alpha: 0.7)),
                      const SizedBox(height: 8),
                      Text(
                        _detailPreviewError!,
                        style: TextStyle(color: cs.error, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _loadDetailPreviewPdf(budgetId),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l.tryAgain),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_detailPreviewPdfBytes != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: PdfInlinePreview(
                        bytes: Uint8List.fromList(_detailPreviewPdfBytes!),
                        height: double.infinity,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final fileName = budgetId.isEmpty
                            ? 'presupuesto-preview.pdf'
                            : 'presupuesto-$budgetId-preview.pdf';
                        await pdf_launcher.launchPdfPreview(
                          Uint8List.fromList(_detailPreviewPdfBytes!),
                          fileName: fileName,
                        );
                      },
                      icon: const Icon(Icons.open_in_new_outlined, size: 16),
                      label: Text(l.budgetPreviewOpenCta),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_outlined,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _loadDetailPreviewPdf(budgetId),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: Text(l.budgetPreviewOpenCta),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height - 170;
        final contentHeight = availableHeight.clamp(680.0, 920.0);
        return SizedBox(
          height: contentHeight,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color:
                                      cs.outlineVariant.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () =>
                                          setState(() => _budgetsTabIndex = 0),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          color: _budgetsTabIndex == 0
                                              ? cs.primaryContainer
                                              : Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            l.groupInvoicesTabDrafts(
                                                drafts.length),
                                            style: t.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: _budgetsTabIndex == 0
                                                  ? cs.onPrimaryContainer
                                                  : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () =>
                                          setState(() => _budgetsTabIndex = 1),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          color: _budgetsTabIndex == 1
                                              ? cs.primaryContainer
                                              : Colors.transparent,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Presupuestos (${issuedBudgets.length})',
                                            style: t.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: _budgetsTabIndex == 1
                                                  ? cs.onPrimaryContainer
                                                  : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: l.refreshAction,
                            onPressed: _loadingBudgets ? null : _loadBudgets,
                            icon: _loadingBudgets
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                          IconButton(
                            tooltip: '${l.download} ZIP',
                            onPressed: (_loadingBudgets ||
                                    _downloadingBudgetsZip ||
                                    _budgets.isEmpty)
                                ? null
                                : _downloadBudgetsZip,
                            icon: _downloadingBudgetsZip
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.folder_zip_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.sort_rounded,
                              size: 13,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(width: 5),
                          Text(
                            _isSpanishLocale ? 'Ordenar:' : 'Sort:',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  cs.onSurfaceVariant.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Segmented sort control
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BudgetSortButton(
                                  label: l.date,
                                  icon: Icons.calendar_today_outlined,
                                  active: sortByDate,
                                  ascending: isAsc,
                                  enabled: !_loadingBudgets,
                                  onTap: () async {
                                    final next = nextBudgetSortState(
                                      _effectiveBudgetSortState,
                                      BudgetSortBy.date,
                                    );
                                    if (next.by ==
                                            _effectiveBudgetSortState.by &&
                                        next.dir ==
                                            _effectiveBudgetSortState.dir) {
                                      return;
                                    }
                                    setState(() => _budgetSortState = next);
                                    await _loadBudgets();
                                  },
                                ),
                                const SizedBox(width: 2),
                                _BudgetSortButton(
                                  label: _isSpanishLocale ? 'Número' : 'Number',
                                  icon: Icons.tag_rounded,
                                  active: sortByNumber,
                                  ascending: isAsc,
                                  enabled: !_loadingBudgets,
                                  onTap: () async {
                                    final next = nextBudgetSortState(
                                      _effectiveBudgetSortState,
                                      BudgetSortBy.number,
                                    );
                                    if (next.by ==
                                            _effectiveBudgetSortState.by &&
                                        next.dir ==
                                            _effectiveBudgetSortState.dir) {
                                      return;
                                    }
                                    setState(() => _budgetSortState = next);
                                    await _loadBudgets();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _loadingBudgets
                            ? const Center(child: CircularProgressIndicator())
                            : (_budgetsError ?? '').trim().isNotEmpty
                                ? Center(
                                    child: Text(
                                      _budgetsError!,
                                      style: TextStyle(color: cs.error),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : activeList.isEmpty
                                    ? Center(
                                        child: Text(
                                          l.noInvoicesYet,
                                          style: t.bodyMedium?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    : Builder(builder: (context) {
                                        final locale =
                                            Localizations.localeOf(context)
                                                .toString();
                                        final items = <Object>[];
                                        String? lastKey;
                                        for (final b in activeList) {
                                          final date = _budgetDate(b);
                                          final key = date == null
                                              ? '__none__'
                                              : '${date.year}-${date.month.toString().padLeft(2, '0')}';
                                          if (key != lastKey) {
                                            items.add(date == null
                                                ? '—'
                                                : _budgetMonthLabel(
                                                    date, locale));
                                            lastKey = key;
                                          }
                                          items.add(b);
                                        }
                                        return ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: items.length,
                                          itemBuilder: (_, i) {
                                            final item = items[i];
                                            if (item is String) {
                                              return _BudgetMonthDivider(
                                                  label: item, first: i == 0);
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: budgetListCard(
                                                  item as Map<String, dynamic>),
                                            );
                                          },
                                        );
                                      }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: detailPanel(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetMonthDivider extends StatelessWidget {
  const _BudgetMonthDivider({required this.label, this.first = false});
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 14, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              height: 1,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetHistoryDialog extends StatefulWidget {
  const _BudgetHistoryDialog({
    required this.api,
    required this.presupuestoId,
    required this.title,
    required this.localeName,
    required this.isSpanish,
    this.embedded = false,
    this.onBack,
  });

  final PresupuestosApi api;
  final String presupuestoId;
  final String title;
  final String localeName;
  final bool isSpanish;
  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<_BudgetHistoryDialog> createState() => _BudgetHistoryDialogState();
}

class _BudgetHistoryDialogState extends State<_BudgetHistoryDialog> {
  late Future<Map<String, dynamic>> _historyFuture;
  final Map<String, Future<Map<String, dynamic>>> _snapshotFutures = {};
  final Map<String, List<String>> _snapshotRowRefs = {};
  String? _selectedSnapshotId;
  bool _showRawHistoryChanges = false;

  @override
  void initState() {
    super.initState();
    _historyFuture = widget.api.listSnapshots(widget.presupuestoId).then(
      (payload) {
        final snapshots = _snapshots(payload);
        if (snapshots.isNotEmpty) {
          final id = _snapshotId(snapshots.first).trim();
          if (id.isNotEmpty) {
            _selectedSnapshotId ??= id;
            _snapshotFutures.putIfAbsent(
              id,
              () => widget.api.getSnapshot(
                id: widget.presupuestoId,
                snapshotId: id,
              ),
            );
          }
        }
        return payload;
      },
    );
  }

  List<Map<String, dynamic>> _snapshots(Map<String, dynamic> payload) {
    final raw = payload['snapshots'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  String _dateLabel(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '-';
    return DateFormat.yMMMd(widget.localeName)
        .add_Hm()
        .format(parsed.toLocal());
  }

  String _snapshotId(Map<String, dynamic> item) =>
      (item['id'] ?? item['_id'] ?? item['snapshotId'] ?? '').toString();

  String _friendlyField(String field) {
    switch (field) {
      case 'blocks':
        return 'Líneas';
      case 'totals':
        return 'Totales';
      case 'notes':
        return 'Notas';
      case 'clientSnapshot':
        return 'Cliente';
      case 'issuerSnapshot':
        return 'Emisor';
      case 'currency':
        return 'Moneda';
      case 'issueDate':
        return 'Fecha emisión';
      default:
        return field;
    }
  }

  List<String> _fieldList(Object? value) {
    if (value is List) {
      return value
          .map((item) => _friendlyField(item.toString()))
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? const <String>[] : <String>[_friendlyField(text)];
  }

  String _displayValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') {
      return widget.isSpanish ? 'No establecido' : 'Not set';
    }
    return text;
  }

  String _userLabel(Map<String, dynamic> item) {
    final user = item['user'];
    if (user is Map) {
      final name = user['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    final userName = item['userName']?.toString().trim() ?? '';
    if (userName.isNotEmpty) return userName;
    return widget.isSpanish ? 'Usuario desconocido' : 'Unknown user';
  }

  String _versionTransition(Map<String, dynamic> item) {
    final from = item['fromVersion'] ?? item['previousVersion'];
    final to = item['toVersion'] ?? item['version'];
    return '${_displayValue(from)} -> ${_displayValue(to)}';
  }

  String _formatHistoryChangeValue(String field, Object? value) {
    if (value == null || value.toString().trim() == 'null') {
      return widget.isSpanish ? 'No establecido' : 'Not set';
    }
    if (field == 'issueDate' || field.endsWith('.issueDate')) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return DateFormat.yMMMd(widget.localeName).format(parsed.toLocal());
      }
    }
    if (field == 'totals' || field.startsWith('totals.')) {
      if (value is num) {
        return NumberFormat.currency(locale: widget.localeName, symbol: '€')
            .format(value);
      }
    }
    if (field == 'blocks') {
      if (value is List) {
        return widget.isSpanish
            ? '${value.length} lineas'
            : '${value.length} lines';
      }
      return widget.isSpanish ? 'Lineas modificadas' : 'Lines changed';
    }
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    final text = value.toString().trim();
    return text.isEmpty
        ? (widget.isSpanish ? 'No establecido' : 'Not set')
        : text;
  }

  List<String> _changeSummaryRows(Object? changes) {
    if (changes is! List) return const <String>[];
    return changes
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final field = (item['field'] ?? item['path'] ?? '').toString();
          final label = _friendlyField(field);
          if (field == 'blocks') {
            return widget.isSpanish
                ? '$label: lineas agregadas, eliminadas o modificadas'
                : '$label: lines added, removed, or modified';
          }
          final oldValue = _formatHistoryChangeValue(field, item['oldValue']);
          final newValue = _formatHistoryChangeValue(field, item['newValue']);
          return '$label: $oldValue -> $newValue';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList(growable: false);
  }

  void _selectSnapshot(Map<String, dynamic> item) {
    final id = _snapshotId(item).trim();
    if (id.isEmpty) return;
    setState(() {
      _selectedSnapshotId = id;
      _snapshotFutures.putIfAbsent(
        id,
        () => widget.api.getSnapshot(
          id: widget.presupuestoId,
          snapshotId: id,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final title = Row(
      children: [
        if (widget.embedded && widget.onBack != null)
          IconButton(
            tooltip: widget.isSpanish ? 'Volver' : 'Back',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.history_rounded, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isSpanish ? 'Historial de versiones' : 'Version history',
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
              ),
              if (widget.title.isNotEmpty)
                Text(
                  widget.title,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
    final content = SizedBox(
      width: widget.embedded ? double.infinity : 980,
      height: widget.embedded ? double.infinity : 560,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                style: TextStyle(color: cs.error),
                textAlign: TextAlign.center,
              ),
            );
          }
          final payload = snapshot.data ?? const <String, dynamic>{};
          final snapshots = _snapshots(payload);
          final currentVersion = payload['currentVersion'] ??
              (payload['current'] is Map
                  ? (payload['current'] as Map)['version']
                  : null);
          return Row(
            children: [
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.tertiary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.radio_button_checked_rounded,
                              size: 14, color: cs.tertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.isSpanish
                                  ? 'Versión $currentVersion'
                                  : 'Version ${_displayValue(currentVersion)}',
                              style: t.bodySmall.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.isSpanish ? 'Actual' : 'Current',
                              style: t.caption.copyWith(
                                color: cs.tertiary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: snapshots.isEmpty
                          ? Center(
                              child: Text(
                                widget.isSpanish
                                    ? 'No hay versiones guardadas.'
                                    : 'No saved versions yet.',
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: snapshots.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 6),
                              itemBuilder: (_, index) {
                                final item = snapshots[index];
                                final id = _snapshotId(item);
                                final selected = id == _selectedSnapshotId;
                                final fields =
                                    _fieldList(item['changedFields']);
                                final rowRefs = _snapshotRowRefs[id] ??
                                    _changedBlockReferences(item['changes']);
                                final reason =
                                    item['reason']?.toString().trim() ?? '';
                                final userLabel = _userLabel(item);
                                final transition = _versionTransition(item);
                                final summaries =
                                    _changeSummaryRows(item['changes']);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _selectSnapshot(item),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? cs.primaryContainer
                                              .withValues(alpha: 0.30)
                                          : cs.surfaceContainerHighest
                                              .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: selected
                                            ? cs.primary.withValues(alpha: 0.45)
                                            : cs.outlineVariant
                                                .withValues(alpha: 0.22),
                                        width: selected ? 1.4 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? cs.primary
                                                        .withValues(alpha: 0.18)
                                                    : cs.surfaceContainerHighest
                                                        .withValues(alpha: 0.6),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                transition,
                                                style: t.caption.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: selected
                                                      ? cs.primary
                                                      : cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                widget.isSpanish
                                                    ? 'Versión guardada'
                                                    : 'Saved version',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: t.caption.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 11,
                                              color: cs.onSurfaceVariant
                                                  .withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _dateLabel(item['changedAt']),
                                              style: t.caption.copyWith(
                                                color: cs.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (fields.isNotEmpty ||
                                                rowRefs.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              _historyMiniChip(
                                                context,
                                                [
                                                  if (fields.isNotEmpty)
                                                    fields.first,
                                                  ...rowRefs.take(2),
                                                ].join(' · '),
                                                rowRefs.isNotEmpty
                                                    ? cs.secondary
                                                    : cs.primary,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          userLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: t.caption.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (summaries.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          for (final summary
                                              in summaries.take(2))
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                summary,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: t.caption.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                        ],
                                        if (reason.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.notes_rounded,
                                                size: 11,
                                                color: cs.onSurfaceVariant
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  reason,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: t.caption.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              VerticalDivider(
                width: 1,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 10),
              Expanded(child: _snapshotDetails(context)),
            ],
          );
        },
      ),
    );
    if (widget.embedded) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 10),
            Expanded(child: content),
          ],
        ),
      );
    }
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.isSpanish ? 'Cerrar' : 'Close'),
        ),
      ],
    );
  }

  Widget _snapshotDetails(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final id = _selectedSnapshotId;
    if (id == null) {
      return Center(
        child: Text(
          widget.isSpanish
              ? 'Selecciona una version para ver sus datos guardados.'
              : 'Select a version to view its saved data.',
          textAlign: TextAlign.center,
          style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: _snapshotFutures[id],
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString().replaceFirst('Exception: ', ''),
              style: TextStyle(color: cs.error),
              textAlign: TextAlign.center,
            ),
          );
        }
        final data = snapshot.data ?? const <String, dynamic>{};
        final source = _snapshotSource(data);
        final blocks = _snapshotBlocks(source);
        final changed = source['changedFields'];
        final changes = data['changes'] ?? source['changes'];
        _rememberSnapshotRowRefs(id, changes);
        return ListView(
          children: [
            _historyHeader(context, source),
            const SizedBox(height: 12),
            _historySummary(context, source),
            const SizedBox(height: 12),
            _historyLinesTable(context, blocks, changes),
            const SizedBox(height: 12),
            _historyChangesSection(context, changed, changes),
          ],
        );
        // ignore: dead_code
        return ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.preview_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSpanish
                              ? 'Versión guardada antes del cambio'
                              : 'Saved version before the change',
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.isSpanish
                              ? 'Datos cargados desde el snapshot histórico.'
                              : 'Data loaded from the historical snapshot.',
                          style: t.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _historyValue(
                    context,
                    widget.isSpanish ? 'Número' : 'Number',
                    source['version'],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _historyValue(
                    context,
                    widget.isSpanish ? 'Fecha emisión' : 'Issue date',
                    _dateLabel(source['changedAt']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if ((source['reason']?.toString().trim() ?? '').isNotEmpty) ...[
              _historyValue(
                context,
                widget.isSpanish ? 'Motivo' : 'Reason',
                source['reason'],
              ),
              const SizedBox(height: 10),
            ],
            _historyChangedFields(context, changed),
            const SizedBox(height: 10),
            _historyBlocksPreview(context, blocks, source['totals']),
            const SizedBox(height: 10),
            _historyJsonSection(context,
                title: 'notes', value: source['notes']),
            _historyJsonSection(
              context,
              title: 'clientSnapshot',
              value: source['clientSnapshot'],
            ),
            _historyJsonSection(
              context,
              title: 'issuerSnapshot',
              value: source['issuerSnapshot'],
            ),
            _historyJsonSection(
              context,
              title: 'raw blocks',
              value: source['blocks'] ?? source['lines'],
            ),
            _historyJsonSection(
              context,
              title: 'raw totals',
              value: source['totals'],
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _snapshotSource(Map<String, dynamic> data) {
    if (data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    if (data['snapshot'] is Map) {
      final snapshot = Map<String, dynamic>.from(data['snapshot'] as Map);
      if (snapshot['data'] is Map) {
        final source = Map<String, dynamic>.from(snapshot['data'] as Map);
        if (!source.containsKey('reason')) {
          source['reason'] = snapshot['reason'];
        }
        if (!source.containsKey('version')) {
          source['version'] = snapshot['version'];
        }
        if (!source.containsKey('changedAt')) {
          source['changedAt'] = snapshot['changedAt'];
        }
        if (!source.containsKey('changes')) {
          source['changes'] = snapshot['changes'];
        }
        if (!source.containsKey('changedFields')) {
          source['changedFields'] = snapshot['changedFields'];
        }
        return source;
      }
      return snapshot;
    }
    if (data['version'] is Map) {
      return Map<String, dynamic>.from(data['version'] as Map);
    }
    return data;
  }

  List<Map<String, dynamic>> _snapshotBlocks(Map<String, dynamic> source) {
    final raw = source['blocks'] ?? source['lines'] ?? source['draftLines'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Widget _historyHeader(BuildContext context, Map<String, dynamic> source) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final reason = source['reason']?.toString().trim() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.history_edu_rounded, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isSpanish
                      ? 'Versión guardada antes del cambio'
                      : 'Saved version before the change',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                ),
                if (reason.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    reason,
                    style: t.caption.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconChip(
                context,
                Icons.tag_rounded,
                _displayValue(source['version']),
              ),
              const SizedBox(width: 6),
              _iconChip(
                context,
                Icons.schedule_rounded,
                _dateLabel(source['changedAt']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconChip(BuildContext context, IconData icon, String value) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(value, style: t.caption.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _historyMiniChip(BuildContext context, String value, Color color) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _historySummary(BuildContext context, Map<String, dynamic> source) {
    final totals = source['totals'] is Map
        ? Map<String, dynamic>.from(source['totals'])
        : {};
    final client = source['clientSnapshot'] is Map
        ? Map<String, dynamic>.from(source['clientSnapshot'])
        : const <String, dynamic>{};
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _historyValue(
                context,
                widget.isSpanish ? 'Número' : 'Number',
                source['presupuestoNumber'] ?? source['budgetNumber'],
                icon: Icons.tag_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _historyValue(
                context,
                widget.isSpanish ? 'Fecha emisión' : 'Issue date',
                _dateLabel(source['issueDate']),
                icon: Icons.calendar_month_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _historyValue(
                context,
                widget.isSpanish ? 'Cliente' : 'Client',
                client['billingName'] ?? client['name'] ?? source['clientName'],
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _historyMoneyValue(
                context,
                widget.isSpanish ? 'Subtotal' : 'Subtotal',
                totals['subtotal'] ?? totals['base'] ?? totals['taxableBase'],
                icon: Icons.receipt_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _historyMoneyValue(
                context,
                widget.isSpanish ? 'IVA' : 'Tax',
                totals['taxTotal'] ?? totals['tax'] ?? totals['iva'],
                icon: Icons.percent_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _historyMoneyValue(
                context,
                'Total',
                totals['total'] ?? totals['grandTotal'] ?? totals['amount'],
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
        if ((source['notes']?.toString().trim() ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          _historyValue(
            context,
            widget.isSpanish ? 'Notas' : 'Notes',
            source['notes'],
            icon: Icons.notes_rounded,
          ),
        ],
      ],
    );
  }

  Widget _historyMoneyValue(
    BuildContext context,
    String label,
    Object? value, {
    IconData? icon,
  }) {
    final parsed = _numValue(value);
    return _historyValue(
      context,
      label,
      value == null
          ? null
          : NumberFormat.currency(locale: widget.localeName, symbol: '€')
              .format(parsed),
      icon: icon,
    );
  }

  num _numValue(Object? value, [num fallback = 0]) {
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }

  Widget _historyLinesTable(
    BuildContext context,
    List<Map<String, dynamic>> blocks,
    Object? changes,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final money = NumberFormat.currency(locale: widget.localeName, symbol: '€');
    final compact = NumberFormat.compact(locale: widget.localeName);
    final changedRows = _changedBlockIndexes(blocks, changes);
    final changedRefs = changedRows.toList()..sort();

    Map<String, num> calc(Map<String, dynamic> block) {
      final qty = _numValue(block['qty'] ?? block['quantity'], 1);
      final unit = _numValue(block['unitPrice'] ?? block['price']);
      final discountRate =
          _numValue(block['discountRate'] ?? block['discountPercent'])
              .clamp(0, 100);
      final taxRate =
          _numValue(block['taxRate'] ?? block['tax'] ?? block['iva']);
      final grossBase = qty * unit;
      final discountAmount = grossBase * discountRate / 100;
      final base = _numValue(block['lineSubtotal'], grossBase - discountAmount);
      final tax = _numValue(block['lineTax'], base * taxRate / 100);
      final total = _numValue(block['lineTotal'], base + tax);
      return {
        'qty': qty,
        'unit': unit,
        'discountRate': discountRate,
        'base': base,
        'tax': tax,
        'total': total,
      };
    }

    String label(Map<String, dynamic> block) {
      final text = (block['description'] ?? block['title'] ?? block['text'])
          ?.toString()
          .trim();
      return (text == null || text.isEmpty) ? 'Sin datos' : text;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.table_rows_outlined,
                    size: 18, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isSpanish ? 'Líneas' : 'Lines',
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      changedRows.isEmpty
                          ? (widget.isSpanish
                              ? 'Sin filas modificadas detectadas'
                              : 'No modified rows detected')
                          : (widget.isSpanish
                              ? '${changedRows.length} fila(s) modificada(s): ${changedRefs.map((i) => '#${i + 1}').join(', ')}'
                              : '${changedRows.length} modified row(s): ${changedRefs.map((i) => '#${i + 1}').join(', ')}'),
                      style: t.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (changedRows.isNotEmpty)
                Chip(
                  avatar: Icon(Icons.auto_awesome_rounded,
                      size: 14, color: cs.secondary),
                  label: Text(
                      changedRefs.take(4).map((i) => '#${i + 1}').join(', ')),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: cs.secondary.withValues(alpha: 0.12),
                  side: BorderSide(color: cs.secondary.withValues(alpha: 0.22)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (blocks.isEmpty)
            Text(
              'Sin datos',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 34,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 58,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Precio unitario')),
                  DataColumn(label: Text('Descuento %')),
                  DataColumn(label: Text('Base')),
                  DataColumn(label: Text('IVA')),
                  DataColumn(label: Text('Total')),
                ],
                rows: [
                  for (final entry in blocks.asMap().entries)
                    if ((entry.value['type'] ?? 'item').toString() == 'item')
                      DataRow(
                        color: WidgetStateProperty.resolveWith((states) {
                          if (changedRows.contains(entry.key)) {
                            return cs.secondaryContainer
                                .withValues(alpha: 0.22);
                          }
                          return null;
                        }),
                        cells: [
                          DataCell(
                            Text(
                              '#${entry.key + 1}',
                              style: TextStyle(
                                color: changedRows.contains(entry.key)
                                    ? cs.secondary
                                    : cs.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          DataCell(SizedBox(
                            width: 230,
                            child: Row(
                              children: [
                                if (changedRows.contains(entry.key)) ...[
                                  Tooltip(
                                    message: widget.isSpanish
                                        ? 'Fila modificada'
                                        : 'Modified row',
                                    child: Icon(Icons.change_circle_outlined,
                                        size: 17, color: cs.secondary),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    label(entry.value),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight:
                                          changedRows.contains(entry.key)
                                              ? FontWeight.w900
                                              : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          DataCell(
                              Text(compact.format(calc(entry.value)['qty']))),
                          DataCell(
                              Text(money.format(calc(entry.value)['unit']))),
                          DataCell(Text(
                              '${compact.format(calc(entry.value)['discountRate'])}%')),
                          DataCell(
                              Text(money.format(calc(entry.value)['base']))),
                          DataCell(
                              Text(money.format(calc(entry.value)['tax']))),
                          DataCell(Text(
                            money.format(calc(entry.value)['total']),
                            style: TextStyle(
                              fontWeight: changedRows.contains(entry.key)
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                            ),
                          )),
                        ],
                      )
                    else
                      DataRow(
                        color: WidgetStateProperty.all(
                          cs.surfaceContainerHighest.withValues(alpha: 0.18),
                        ),
                        cells: [
                          DataCell(
                            Text(
                              '#${entry.key + 1}',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ),
                          DataCell(SizedBox(
                            width: 230,
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 15, color: cs.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label(entry.value),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          const DataCell(Text('')),
                          DataCell(
                              Text((entry.value['type'] ?? '').toString())),
                        ],
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _changedBlockReferences(Object? changes) {
    if (changes is! List) return const <String>[];

    String stableRow(Map<String, dynamic> row) {
      String text(Object? value) => (value ?? '').toString().trim();
      String number(Object? value, [num fallback = 0]) {
        final parsed = value is num
            ? value
            : num.tryParse(value?.toString().replaceAll(',', '.') ?? '');
        return (parsed ?? fallback).toStringAsFixed(4);
      }

      final type = text(row['type']).isEmpty ? 'item' : text(row['type']);
      final meaningful = <String, String>{
        'type': type,
        'description': text(row['description']),
        'title': text(row['title']),
        'text': text(row['text']),
      };
      if (type == 'item') {
        meaningful.addAll({
          'qty': number(row['qty'] ?? row['quantity'], 1),
          'unit': text(row['unit']),
          'unitPrice': number(row['unitPrice'] ?? row['price']),
          'discountRate': number(row['discountRate'] ?? row['discountPercent']),
          'taxRate': number(row['taxRate'] ?? row['tax'] ?? row['iva']),
        });
      }
      return jsonEncode(meaningful);
    }

    final indexes = <int>{};
    for (final raw in changes.whereType<Map>()) {
      final change = Map<String, dynamic>.from(raw);
      final field = (change['field'] ?? change['path'] ?? '').toString();
      final bracketMatch = RegExp(r'blocks\[(\d+)\]').firstMatch(field);
      final dottedMatch = RegExp(r'blocks\.(\d+)').firstMatch(field);
      final matchedIndex = bracketMatch?.group(1) ?? dottedMatch?.group(1);
      if (matchedIndex != null) {
        final index = int.tryParse(matchedIndex);
        if (index != null) {
          final oldValue = change['oldValue'];
          final newValue = change['newValue'];
          if (oldValue is Map && newValue is Map) {
            final oldRow = Map<String, dynamic>.from(oldValue);
            final newRow = Map<String, dynamic>.from(newValue);
            if (stableRow(oldRow) != stableRow(newRow)) {
              indexes.add(index);
            }
          } else if (_isMeaningfulBlockField(field)) {
            indexes.add(index);
          }
        }
      }

      if (field == 'blocks' || field.startsWith('blocks')) {
        final oldValue = change['oldValue'];
        final newValue = change['newValue'];
        if (oldValue is List && newValue is List) {
          final maxLength = oldValue.length > newValue.length
              ? oldValue.length
              : newValue.length;
          for (var i = 0; i < maxLength; i++) {
            if (oldValue.length <= i ||
                newValue.length <= i ||
                oldValue[i] is! Map ||
                newValue[i] is! Map) {
              continue;
            }
            final oldRow = Map<String, dynamic>.from(oldValue[i] as Map);
            final newRow = Map<String, dynamic>.from(newValue[i] as Map);
            if (stableRow(oldRow) != stableRow(newRow)) {
              indexes.add(i);
            }
          }
        }
      }
    }
    final sorted = indexes.toList()..sort();
    return sorted.map((index) => 'Fila #${index + 1}').toList(growable: false);
  }

  void _rememberSnapshotRowRefs(String id, Object? changes) {
    final refs = _changedBlockReferences(changes);
    if (refs.isEmpty || _snapshotRowRefs[id]?.join('|') == refs.join('|')) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _snapshotRowRefs[id] = refs);
    });
  }

  Set<int> _changedBlockIndexes(
    List<Map<String, dynamic>> blocks,
    Object? changes,
  ) {
    final indexes = <int>{};
    if (changes is! List) return indexes;

    String stableRow(Map<String, dynamic> row) {
      String text(Object? value) => (value ?? '').toString().trim();
      String number(Object? value, [num fallback = 0]) {
        final parsed = value is num
            ? value
            : num.tryParse(value?.toString().replaceAll(',', '.') ?? '');
        return (parsed ?? fallback).toStringAsFixed(4);
      }

      final type = text(row['type']).isEmpty ? 'item' : text(row['type']);
      final meaningful = <String, String>{
        'type': type,
        'description': text(row['description']),
        'title': text(row['title']),
        'text': text(row['text']),
      };
      if (type == 'item') {
        meaningful.addAll({
          'qty': number(row['qty'] ?? row['quantity'], 1),
          'unit': text(row['unit']),
          'unitPrice': number(row['unitPrice'] ?? row['price']),
          'discountRate': number(row['discountRate'] ?? row['discountPercent']),
          'taxRate': number(row['taxRate'] ?? row['tax'] ?? row['iva']),
        });
      }
      return jsonEncode(meaningful);
    }

    for (final raw in changes.whereType<Map>()) {
      final change = Map<String, dynamic>.from(raw);
      final field = (change['field'] ?? change['path'] ?? '').toString();
      final bracketMatch = RegExp(r'blocks\[(\d+)\]').firstMatch(field);
      final dottedMatch = RegExp(r'blocks\.(\d+)').firstMatch(field);
      final matchedIndex = bracketMatch?.group(1) ?? dottedMatch?.group(1);
      if (matchedIndex != null) {
        final index = int.tryParse(matchedIndex);
        if (index != null && index >= 0 && index < blocks.length) {
          final oldValue = change['oldValue'];
          final newValue = change['newValue'];
          if (oldValue is Map && newValue is Map) {
            final oldRow = Map<String, dynamic>.from(oldValue);
            final newRow = Map<String, dynamic>.from(newValue);
            if (stableRow(oldRow) != stableRow(newRow)) {
              indexes.add(index);
            }
          } else if (_isMeaningfulBlockField(field)) {
            indexes.add(index);
          }
        }
      }

      if (field == 'blocks' || field.startsWith('blocks')) {
        final oldValue = change['oldValue'];
        final newValue = change['newValue'];
        if (oldValue is List && newValue is List) {
          final maxLength = oldValue.length > newValue.length
              ? oldValue.length
              : newValue.length;
          for (var i = 0; i < maxLength && i < blocks.length; i++) {
            if (oldValue.length <= i ||
                newValue.length <= i ||
                oldValue[i] is! Map ||
                newValue[i] is! Map) {
              continue;
            }
            final oldRow = Map<String, dynamic>.from(oldValue[i] as Map);
            final newRow = Map<String, dynamic>.from(newValue[i] as Map);
            if (stableRow(oldRow) != stableRow(newRow)) {
              indexes.add(i);
            }
          }
        }
      }
    }
    return indexes;
  }

  bool _isMeaningfulBlockField(String field) {
    final normalized = field.replaceAll(RegExp(r'blocks\[\d+\]'), 'blocks.0');
    final parts = normalized.split('.');
    if (parts.length < 3 || parts.first != 'blocks') return false;
    const meaningfulFields = {
      'type',
      'description',
      'title',
      'text',
      'qty',
      'quantity',
      'unit',
      'unitPrice',
      'price',
      'discountRate',
      'discountPercent',
      'taxRate',
      'tax',
      'iva',
    };
    return meaningfulFields.contains(parts[2]);
  }

  Widget _historyChangesSection(
    BuildContext context,
    Object? changedFields,
    Object? changes,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final changeRows = changes is List
        ? changes
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
        : const Iterable<Map<String, dynamic>>.empty();
    final rows = changeRows.toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isSpanish ? 'Cambios' : 'Changes',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _historyChangedFields(context, changedFields),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final summary in _changeSummaryRows(rows))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  summary,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(
                    () => _showRawHistoryChanges = !_showRawHistoryChanges),
                icon: Icon(
                  _showRawHistoryChanges
                      ? Icons.visibility_off_outlined
                      : Icons.code_rounded,
                  size: 16,
                ),
                label: Text(
                  _showRawHistoryChanges
                      ? (widget.isSpanish
                          ? 'Ocultar detalle técnico'
                          : 'Hide technical detail')
                      : (widget.isSpanish
                          ? 'Ver detalle técnico'
                          : 'View technical detail'),
                ),
              ),
            ),
          ],
          if (_showRawHistoryChanges && rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        _friendlyField((row['field'] ?? '').toString()),
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_displayValue(row['oldValue'])} → ${_displayValue(row['newValue'])}',
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _historyValue(
    BuildContext context,
    String label,
    Object? value, {
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: t.caption.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SelectableText(
            value?.toString().trim().isNotEmpty == true
                ? value.toString()
                : '-',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _historyChangedFields(BuildContext context, Object? value) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final fields = value is List
        ? value.map((item) => item.toString()).where((s) => s.trim().isNotEmpty)
        : value == null
            ? const Iterable<String>.empty()
            : [value.toString()];
    final list = fields.toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isSpanish ? 'Campos modificados' : 'Changed fields',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Text(
              '-',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final field in list)
                  Chip(
                    label: Text(field),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: cs.primary.withValues(alpha: 0.22),
                    ),
                    backgroundColor: cs.primary.withValues(alpha: 0.08),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _historyBlocksPreview(
    BuildContext context,
    List<Map<String, dynamic>> blocks,
    Object? totals,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final nf = NumberFormat.currency(locale: widget.localeName, symbol: '€');
    num parse(Object? value, [num fallback = 0]) {
      if (value is num) return value;
      return num.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
          fallback;
    }

    num totalFor(Map<String, dynamic> item) {
      final explicit = item['lineTotal'] ?? item['total'];
      if (explicit is num) return explicit;
      final qty = parse(item['qty'] ?? item['quantity'], 1);
      final unit = parse(item['unitPrice'] ?? item['price']);
      final discount =
          parse(item['discountRate'] ?? item['discountPercent']).clamp(0, 100);
      final tax = parse(item['taxRate'] ?? item['tax'] ?? item['iva'] ?? 0);
      final grossBase = qty * unit;
      final base = grossBase - (grossBase * discount / 100);
      return base + (base * tax / 100);
    }

    String labelFor(Map<String, dynamic> item) {
      final value = item['description'] ?? item['title'] ?? item['text'] ?? '-';
      final label = value.toString().trim();
      return label.isEmpty ? '-' : label;
    }

    final totalsMap =
        totals is Map ? Map<String, dynamic>.from(totals) : const {};
    final totalValue = totalsMap['total'] ??
        totalsMap['grandTotal'] ??
        totalsMap['amount'] ??
        blocks.fold<num>(0, (sum, item) => sum + totalFor(item));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.isSpanish ? 'Lineas guardadas' : 'Saved lines',
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                nf.format(parse(totalValue)),
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (blocks.isEmpty)
            Text(
              widget.isSpanish ? 'Sin lineas guardadas.' : 'No saved lines.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ...blocks.take(8).map((item) {
              final qty = parse(item['qty'] ?? item['quantity'], 1);
              final unit = parse(item['unitPrice'] ?? item['price']);
              final discount =
                  parse(item['discountRate'] ?? item['discountPercent']);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelFor(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${NumberFormat.compact(locale: widget.localeName).format(qty)} x ${nf.format(unit)}'
                            '${discount > 0 ? ' · Dto. ${NumberFormat.compact(locale: widget.localeName).format(discount)}%' : ''}',
                            style: t.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      nf.format(totalFor(item)),
                      style: t.bodySmall.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              );
            }),
          if (blocks.length > 8)
            Text(
              '+${blocks.length - 8}',
              style: t.caption.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _historyJsonSection(
    BuildContext context, {
    required String title,
    required Object? value,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final pretty = const JsonEncoder.withIndent('  ').convert(value);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.bodySmall.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SelectableText(
            pretty,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSortButton extends StatelessWidget {
  const _BudgetSortButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.ascending,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool ascending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dirIcon =
        ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: active
              ? cs.secondary.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: active
                  ? cs.secondary
                  : cs.onSurfaceVariant.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? cs.secondary
                    : cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(dirIcon,
                  size: 11, color: cs.secondary.withValues(alpha: 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetInlineErrorCard extends StatelessWidget {
  const _BudgetInlineErrorCard({
    required this.message,
    required this.visibleStep,
    required this.isSpanishLocale,
  });

  final String message;
  final int visibleStep;
  final bool isSpanishLocale;

  String get _title {
    if (visibleStep == 2) {
      return isSpanishLocale ? 'Falta completar una línea' : 'Complete a line';
    }
    if (visibleStep == 3) {
      return isSpanishLocale ? 'Confirma la revisión' : 'Confirm the review';
    }
    return isSpanishLocale ? 'Revisa este paso' : 'Review this step';
  }

  String get _hint {
    if (visibleStep == 2) {
      return isSpanishLocale
          ? 'Añade un concepto de trabajo y un precio unitario mayor que 0. Si no indicas vivienda/unidad, usaremos "Unit".'
          : 'Add a work concept and a unit price greater than 0. If unit/title is empty, we will use "Unit".';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: cs.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: t.bodyMedium?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _hint,
                  style: t.bodySmall?.copyWith(
                    color: cs.onErrorContainer.withValues(alpha: 0.82),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
