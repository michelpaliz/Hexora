import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_formatters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/budget_sort_query.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/json_import_service.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/client_search_select.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/pdf_inline_preview.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/wizard_steps_header.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

part 'sections/group_invoices_budgets_view_payload_section.dart';
part 'sections/group_invoices_budgets_view_import_extract_section.dart';
part 'sections/group_invoices_budgets_view_flow_section.dart';
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
    this.onOpenInvoiceId,
  });

  final String groupId;
  final List<GroupClient> clients;
  final GroupInvoicesBudgetsMode mode;
  final ValueChanged<String>? onOpenInvoiceId;

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
  final Set<String> _convertingBudgetIds = <String>{};
  BudgetSortState? _budgetSortState;
  String? _budgetsError;
  List<Map<String, dynamic>> _budgets = const [];
  String? _selectedBudgetId;
  int _budgetsTabIndex = 0;
  String? _selectedClientId;
  final TextEditingController _clientNameCtrl = TextEditingController();
  _ClientSource _clientSource = _ClientSource.existing;
  final List<LineDraft> _budgetLines = <LineDraft>[LineDraft(position: 1)];
  final List<InvoiceBlockDraft> _budgetBlocks = <InvoiceBlockDraft>[
    InvoiceBlockDraft.item(),
  ];
  bool _useBlocks = true;
  int _visibleStep = 0;
  String? _error;
  bool _confirmPreview = false;
  bool _issuing = false;
  String? _draftId;
  Future<String>? _draftCreateInFlight;
  String? _issuedPresupuestoNumber;
  bool _loadingPreview = false;
  String? _previewError;
  List<int>? _previewPdfBytes;
  String? _previewForId;
  bool _loadingDetailPreview = false;
  String? _detailPreviewError;
  List<int>? _detailPreviewPdfBytes;
  String? _detailPreviewForId;
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
  BudgetSortState get _effectiveBudgetSortState =>
      _budgetSortState ??
      const BudgetSortState(by: BudgetSortBy.date, dir: BudgetSortDir.desc);

  @override
  void initState() {
    super.initState();
    if (widget.mode == GroupInvoicesBudgetsMode.list) {
      _loadBudgets();
    }
  }

  @override
  void didUpdateWidget(covariant GroupInvoicesBudgetsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modeChangedToList = oldWidget.mode != GroupInvoicesBudgetsMode.list &&
        widget.mode == GroupInvoicesBudgetsMode.list;
    final groupChanged = oldWidget.groupId != widget.groupId;
    if (modeChangedToList || groupChanged) {
      _loadBudgets();
    }
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
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

  bool get _hasLineItems => _budgetLines.any((line) =>
      line.description.text.trim().isNotEmpty && (line.quantity ?? 0) > 0);
  bool get _hasBillableBlocks => _budgetBlocks.any((b) => b.hasBillableContent);
  bool get _hasLineContent => _useBlocks ? _hasBillableBlocks : _hasLineItems;

  int get _billableItemsCount => _useBlocks
      ? _budgetBlocks.where((b) => b.hasBillableContent).length
      : _budgetLines
          .where((line) =>
              line.description.text.trim().isNotEmpty &&
              (line.quantity ?? 0) > 0)
          .length;

  int get _maxAllowedStep => !_hasClientInfo
      ? 0
      : !_hasLineContent
          ? 2
          : !_confirmPreview
              ? 3
              : 4;

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == GroupInvoicesBudgetsMode.create;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final selectedClient = widget.clients
        .where((c) => c.id == _selectedClientId)
        .cast<GroupClient?>()
        .firstWhere((_) => true, orElse: () => null);
    final selectedClientName = selectedClient?.name.trim().isNotEmpty == true
        ? selectedClient!.name.trim()
        : _clientNameCtrl.text.trim();
    if (_visibleStep > _maxAllowedStep) {
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
        title: Text(l.budgetStepBudget),
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
        title: Text(l.budgetStepConfirm),
        subtitle: const SizedBox.shrink(),
        content: const SizedBox.shrink(),
        isActive: _visibleStep == 3,
        state: _visibleStep > 3
            ? StepState.complete
            : (_visibleStep == 3 ? StepState.editing : StepState.indexed),
      ),
      Step(
        title: Text(l.budgetStepPreview),
        subtitle: const SizedBox.shrink(),
        content: const SizedBox.shrink(),
        isActive: _visibleStep == 4,
        state: _visibleStep == 4 ? StepState.editing : StepState.indexed,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isCreate) ...[
                _buildBudgetsListLayout(context),
              ] else ...[
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
                                  if (target <= _maxAllowedStep) {
                                    setState(() {
                                      _visibleStep = target;
                                      _error = null;
                                    });
                                    if (target == 4) {
                                      _issueBudgetAndPreparePreview();
                                    }
                                  }
                                },
                              ),
                            ),
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
                                      color: cs.primary.withValues(alpha: 0.45),
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
                  Text(
                    _error!,
                    style: TextStyle(color: cs.error),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_visibleStep > 0)
                      TextButton(
                        onPressed: _issuing
                            ? null
                            : () => setState(() {
                                  _visibleStep -= 1;
                                  _error = null;
                                }),
                        child: Text(l.budgetBackCta),
                      ),
                    const Spacer(),
                    if (_visibleStep < 4)
                      FilledButton(
                        onPressed: _issuing
                            ? null
                            : () async {
                                if (!_validateCurrentStep()) return;
                                final target = _visibleStep + 1;
                                setState(() {
                                  _visibleStep = target;
                                  _error = null;
                                });
                                if (target == 4) {
                                  await _createDraftAndPreparePreview();
                                }
                              },
                        child: Text(l.budgetNextCta),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${l.budgetShortLogicFlowTitle}:\n'
                '1. ${l.budgetShortLogicFlow1}\n'
                '2. ${l.budgetShortLogicFlow2}\n'
                '3. ${l.budgetShortLogicFlow3}\n'
                '4. ${l.budgetShortLogicFlow4}',
              ),
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

  bool _canConvertToInvoice(Map<String, dynamic> item) {
    if (_isDraftBudget(item) || _isConvertedToInvoice(item)) return false;
    final status = _budgetStatus(item);
    return status.contains('issued') || status.contains('accept');
  }

  String _convertDisabledReason(Map<String, dynamic> item) {
    if (_isConvertedToInvoice(item)) return 'Convertido previamente';
    if (_isDraftBudget(item)) return 'Solo presupuestos emitidos/aceptados';
    final status = _budgetStatus(item);
    if (!(status.contains('issued') || status.contains('accept'))) {
      return 'Estado no elegible para conversión';
    }
    return '';
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
        final tax = parseNum(
          line['taxRate'] ?? line['tax'] ?? line['vat'] ?? line['iva'] ?? 0,
        );
        final subtotal = qty * unit;
        sum += subtotal + (subtotal * (tax / 100));
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
        final tax = parseNum(
          block['taxRate'] ?? block['tax'] ?? block['vat'] ?? block['iva'] ?? 0,
        );
        final subtotal = qty * unit;
        sum += subtotal + (subtotal * (tax / 100));
      }
      if (sum > 0) return sum;
    }

    return 0;
  }

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
      );
      if (!mounted) return;
      setState(() {
        _budgets = list;
        final selected = (_selectedBudgetId ?? '').trim();
        if (selected.isEmpty ||
            !_budgets.any((e) => _budgetId(e).trim() == selected)) {
          _selectedBudgetId =
              _budgets.isEmpty ? null : _budgetId(_budgets.first);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
    } finally {
      if (mounted) setState(() => _downloadingBudgetsZip = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.budgetIssuedSnack(number.isEmpty ? '-' : number))),
      );
      await _loadBudgets();
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Presupuesto eliminado')),
      );
      await _loadBudgets();
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingBudgetIds.remove(id));
      }
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura creada desde presupuesto')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), action: action),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
    } finally {
      if (mounted) setState(() => _convertingBudgetIds.remove(id));
    }
  }

  Widget _buildBudgetsListLayout(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final drafts = _budgets.where(_isDraftBudget).toList(growable: false);
    final issued =
        _budgets.where((e) => !_isDraftBudget(e)).toList(growable: false);
    final activeList = _budgetsTabIndex == 0 ? drafts : issued;
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
      final isDeleting = _deletingBudgetIds.contains(id);
      final isConverted = _isConvertedToInvoice(item);

      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _selectedBudgetId = id);
          _loadDetailPreviewPdf(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selectedRow
                ? cs.primaryContainer.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedRow
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: cs.primary.withValues(alpha: 0.08),
                child: Icon(
                  Icons.request_quote_outlined,
                  size: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _budgetClientName(item, l),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          t.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
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
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDraft)
                        IconButton(
                          tooltip: 'Emitir',
                          onPressed: isIssuing
                              ? null
                              : () => _issueBudgetFromList(item),
                          icon: isIssuing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.publish_outlined, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                      IconButton(
                        tooltip: l.budgetPreviewOpenCta,
                        onPressed: () => _loadDetailPreviewPdf(id),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: l.download,
                        onPressed: () => _downloadBudgetPdf(item),
                        icon: const Icon(Icons.download_outlined, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (isDraft)
                        IconButton(
                          tooltip: l.delete,
                          onPressed: (isDeleting || isIssuing)
                              ? null
                              : () => _deleteDraftBudget(item),
                          icon: isDeleting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.delete_outline, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDraft
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
                          : cs.tertiaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isDraft ? l.statusDraft : l.statusIssued,
                      style: t.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: isDraft
                            ? cs.onSurfaceVariant
                            : cs.onTertiaryContainer,
                      ),
                    ),
                  ),
                  if (isConverted) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Convertido a factura',
                        style: t.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    totalLabel,
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
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
      final canConvert = _canConvertToInvoice(selected);
      final converting = _convertingBudgetIds.contains(budgetId);
      final convertedInvoiceId = _convertedInvoiceId(selected);
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
            Row(
              children: [
                Tooltip(
                  message: canConvert
                      ? 'Convertir a factura'
                      : _convertDisabledReason(selected),
                  child: FilledButton.tonalIcon(
                    onPressed: (!canConvert || converting)
                        ? null
                        : () => _convertBudgetToInvoice(selected),
                    icon: converting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.transform_outlined, size: 16),
                    label: const Text('Convertir a factura'),
                  ),
                ),
                if (convertedInvoiceId != null &&
                    convertedInvoiceId.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        widget.onOpenInvoiceId?.call(convertedInvoiceId.trim()),
                    icon: const Icon(Icons.open_in_new_outlined, size: 16),
                    label: const Text('Abrir factura'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
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

    return SizedBox(
      height: 580,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
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
                              color: cs.outlineVariant.withValues(alpha: 0.35),
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
                                    duration: const Duration(milliseconds: 160),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: _budgetsTabIndex == 0
                                          ? cs.primaryContainer
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        l.groupInvoicesTabDrafts(drafts.length),
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
                                    duration: const Duration(milliseconds: 160),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: _budgetsTabIndex == 1
                                          ? cs.primaryContainer
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Presupuestos (${issued.length})',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.folder_zip_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _BudgetSortButton(
                        label: l.date,
                        active: sortByDate,
                        ascending: isAsc,
                        enabled: !_loadingBudgets,
                        onTap: () async {
                          final next = nextBudgetSortState(
                            _effectiveBudgetSortState,
                            BudgetSortBy.date,
                          );
                          if (next.by == _effectiveBudgetSortState.by &&
                              next.dir == _effectiveBudgetSortState.dir) {
                            return;
                          }
                          setState(() => _budgetSortState = next);
                          await _loadBudgets();
                        },
                      ),
                      const SizedBox(width: 8),
                      _BudgetSortButton(
                        label: 'Número',
                        active: sortByNumber,
                        ascending: isAsc,
                        enabled: !_loadingBudgets,
                        onTap: () async {
                          final next = nextBudgetSortState(
                            _effectiveBudgetSortState,
                            BudgetSortBy.number,
                          );
                          if (next.by == _effectiveBudgetSortState.by &&
                              next.dir == _effectiveBudgetSortState.dir) {
                            return;
                          }
                          setState(() => _budgetSortState = next);
                          await _loadBudgets();
                        },
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
                                : ListView.separated(
                                    itemCount: activeList.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 4),
                                    itemBuilder: (_, i) =>
                                        budgetListCard(activeList[i]),
                                  ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: detailPanel(),
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
    required this.active,
    required this.ascending,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool ascending;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = ascending ? Icons.arrow_upward : Icons.arrow_downward;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(
            color: active
                ? cs.primary.withValues(alpha: 0.65)
                : cs.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
