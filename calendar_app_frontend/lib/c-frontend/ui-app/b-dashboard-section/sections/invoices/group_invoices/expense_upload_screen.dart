import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/providers/providers_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/expense_operations.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/form_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/provider_operations.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_sections.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'expense_upload/screen_sections/expense_upload_import_actions_section.dart';
part 'expense_upload/screen_sections/expense_upload_import_tabs_section.dart';

class ExpenseUploadScreen extends StatefulWidget {
  const ExpenseUploadScreen({
    super.key,
    this.embedded = false,
    this.onUploaded,
    this.initialTabIndex = 0,
    this.providersOnly = false,
    this.providerFormOnly = false,
    this.listOnly = false,
    this.uploadOnly = false,
    required this.groupId,
    required this.groupName,
  });

  final bool embedded;
  final VoidCallback? onUploaded;
  final int initialTabIndex;
  final bool providersOnly;
  final bool providerFormOnly;
  final bool listOnly;
  final bool uploadOnly;
  final String groupId;
  final String groupName;

  @override
  State<ExpenseUploadScreen> createState() => ExpenseUploadScreenState();
}

abstract class _ExpenseUploadScreenStateBase extends State<ExpenseUploadScreen>
    with
        TickerProviderStateMixin,
        ProviderOperationsMixin,
        ExpenseOperationsMixin {
  final _api = ExpensesApi();
  final _providersApi = ProvidersApi();

  // Form controllers
  final _vendorController = TextEditingController();
  final _issueDateController = TextEditingController();
  final _totalController = TextEditingController();
  final _vendorTaxIdController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _taxTotalController = TextEditingController();
  final _currencyController = TextEditingController(text: 'EUR');
  final _notesController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _jsonPayloadController = TextEditingController();
  final _jsonProviderIdOverrideController = TextEditingController();
  final _jsonGroupIdOverrideController = TextEditingController();
  final _jsonStatementEntryController = TextEditingController();
  final _jsonClientController = TextEditingController();
  final _batchJsonController = TextEditingController();

  // Provider form controllers
  final _providerNameController = TextEditingController();
  final _providerTaxIdController = TextEditingController();
  final _providerEmailController = TextEditingController();
  final _providerPhoneController = TextEditingController();
  final _providerNotesController = TextEditingController();
  final _providerStreetController = TextEditingController();
  final _providerExtraController = TextEditingController();
  final _providerCityController = TextEditingController();
  final _providerProvinceController = TextEditingController();
  final _providerPostalCodeController = TextEditingController();
  final _providerCountryController = TextEditingController();

  // State variables
  String? _fileName;
  Uint8List? _fileBytes;
  String? _error;
  bool _submitting = false;
  final List<Map<String, String>> _recentUploads = [];
  late TabController _tabs;
  late TabController _importTabs;

  // Provider state
  List<Map<String, dynamic>> _providers = [];
  bool _loadingProviders = false;
  String? _providersError;
  bool _savingProvider = false;
  String? _editingProviderId;
  String? _selectedProviderId;
  String? _selectedProviderSummaryId;

  // Expense state
  final List<ExpenseLineDraft> _lines = [];
  List<Map<String, dynamic>>? _vatBreakdown;
  Map<String, String>? _selectedRecentExpense;
  bool _loadingPreview = false;
  String? _previewError;
  Uint8List? _jsonInvoiceFileBytes;
  String? _jsonInvoiceFileName;
  Uint8List? _jsonFileBytes;
  String? _jsonFileName;
  bool _jsonSubmitting = false;
  bool _jsonPromptLoading = false;
  String? _jsonError;
  bool _jsonAdvancedExpanded = false;
  String? _jsonPromptMessage;
  String? _jsonPromptText;
  List<Uint8List> _batchDocumentBytes = [];
  List<String> _batchDocumentNames = [];
  bool _batchSubmitting = false;
  bool _batchGeneratingJson = false;
  String? _batchError;
  String? _batchVerifyMessage;
  int _batchDetectedInvoices = 0;

  static const int _maxBatchDocuments = 100;
  static const int _maxBatchFileSizeBytes = 10 * 1024 * 1024;

  // Mixin implementations for ProviderOperationsMixin
  @override
  ProvidersApi get providersApi => _providersApi;
  @override
  List<Map<String, dynamic>> get providers => _providers;
  @override
  set providers(List<Map<String, dynamic>> value) => _providers = value;
  @override
  bool get loadingProviders => _loadingProviders;
  @override
  set loadingProviders(bool value) => _loadingProviders = value;
  @override
  String? get providersError => _providersError;
  @override
  set providersError(String? value) => _providersError = value;
  @override
  bool get savingProvider => _savingProvider;
  @override
  set savingProvider(bool value) => _savingProvider = value;
  @override
  String? get editingProviderId => _editingProviderId;
  @override
  set editingProviderId(String? value) => _editingProviderId = value;
  @override
  String? get selectedProviderId => _selectedProviderId;
  @override
  set selectedProviderId(String? value) => _selectedProviderId = value;
  @override
  String? get selectedProviderSummaryId => _selectedProviderSummaryId;
  @override
  set selectedProviderSummaryId(String? value) =>
      _selectedProviderSummaryId = value;
  @override
  TextEditingController get providerNameController => _providerNameController;
  @override
  TextEditingController get providerTaxIdController => _providerTaxIdController;
  @override
  TextEditingController get providerEmailController => _providerEmailController;
  @override
  TextEditingController get providerPhoneController => _providerPhoneController;
  @override
  TextEditingController get providerNotesController => _providerNotesController;
  @override
  TextEditingController get providerStreetController =>
      _providerStreetController;
  @override
  TextEditingController get providerExtraController => _providerExtraController;
  @override
  TextEditingController get providerCityController => _providerCityController;
  @override
  TextEditingController get providerProvinceController =>
      _providerProvinceController;
  @override
  TextEditingController get providerPostalCodeController =>
      _providerPostalCodeController;
  @override
  TextEditingController get providerCountryController =>
      _providerCountryController;
  @override
  TextEditingController get vendorController => _vendorController;
  @override
  TextEditingController get vendorTaxIdController => _vendorTaxIdController;

  // Mixin implementations for ExpenseOperationsMixin
  @override
  ExpensesApi get expensesApi => _api;
  @override
  List<Map<String, String>> get recentUploads => _recentUploads;
  @override
  Map<String, String>? get selectedRecentExpense => _selectedRecentExpense;
  @override
  set selectedRecentExpense(Map<String, String>? value) =>
      _selectedRecentExpense = value;
  @override
  bool get loadingPreview => _loadingPreview;
  @override
  set loadingPreview(bool value) => _loadingPreview = value;
  @override
  String? get previewError => _previewError;
  @override
  set previewError(String? value) => _previewError = value;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
          '[ExpenseUploadScreen] init providersOnly=${widget.providersOnly}');
    }
    final idx = widget.listOnly
        ? 0
        : widget.uploadOnly
            ? 1
            : widget.initialTabIndex.clamp(0, 1);
    _createTabsController(initialIndex: idx);
    _createImportTabsController(initialIndex: 0);
    loadProviders();
    loadRecentUploads();
  }

  static const Set<String> _allowedInvoiceExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  static const Set<String> _allowedInvoiceMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  String _inferMimeTypeFromFileName(String fileName) {
    final lc = fileName.toLowerCase();
    if (lc.endsWith('.pdf')) return 'application/pdf';
    if (lc.endsWith('.jpg') || lc.endsWith('.jpeg')) return 'image/jpeg';
    if (lc.endsWith('.png')) return 'image/png';
    if (lc.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  bool _isAllowedInvoiceFileName(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    if (parts.length < 2) return false;
    return _allowedInvoiceExtensions.contains(parts.last);
  }

  String? _validateInvoiceUploadFile({
    required String fileName,
    required Uint8List fileBytes,
    int? maxSizeBytes,
    String emptyMessage =
        'Invoice file/photo is required and must be linked to the expense.',
    String unsupportedTypeMessage =
        'Unsupported file type. Use PDF, JPG, PNG, or WEBP.',
    String Function(String fileName, int fileSize, int maxSize)?
        tooLargeMessageBuilder,
  }) {
    if (fileBytes.isEmpty) return emptyMessage;
    if (maxSizeBytes != null && fileBytes.length > maxSizeBytes) {
      if (tooLargeMessageBuilder != null) {
        return tooLargeMessageBuilder(fileName, fileBytes.length, maxSizeBytes);
      }
      return 'File "$fileName" is too large.';
    }
    final mime = _inferMimeTypeFromFileName(fileName);
    final allowed = _isAllowedInvoiceFileName(fileName) &&
        _allowedInvoiceMimeTypes.contains(mime);
    if (!allowed) return unsupportedTypeMessage;
    return null;
  }

  String _newImportAttemptId() =>
      'expimp_${DateTime.now().microsecondsSinceEpoch}';

  String _requiredGroupMessage() =>
      'Debes seleccionar un grupo antes de guardar/importar el gasto.';

  void _logImportEvent(
    String stage,
    String attemptId, {
    String? providerMode,
    bool? hadMultipartFile,
    bool? hadBlobName,
    bool? fileLinked,
    String? detail,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[ExpenseJsonImport] attempt=$attemptId stage=$stage '
      'providerMode=${providerMode ?? '-'} '
      'hadMultipartFile=${hadMultipartFile?.toString() ?? '-'} '
      'hadBlobName=${hadBlobName?.toString() ?? '-'} '
      'fileLinked=${fileLinked?.toString() ?? '-'} '
      '${detail == null ? '' : 'detail=$detail'}',
    );
  }

  void _logExpenseAttempt({
    required String route,
    required String attemptId,
    required bool hasGroupId,
    required String groupId,
    required bool blockedByValidation,
    String? detail,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[ExpenseAttempt] attemptId=$attemptId route=$route '
      'hasGroupId=$hasGroupId groupId=$groupId '
      'blockedByValidation=$blockedByValidation '
      '${detail == null ? '' : 'detail=$detail'}',
    );
  }

  void _createTabsController({required int initialIndex}) {
    _tabs = TabController(length: 2, vsync: this);
    _tabs.index = initialIndex.clamp(0, 1);
  }

  void _createImportTabsController({required int initialIndex}) {
    _importTabs = TabController(length: 3, vsync: this);
    _importTabs.index = initialIndex.clamp(0, 2);
  }

  @override
  void reassemble() {
    super.reassemble();
    final currentIndex = _tabs.index;
    final currentImportIndex = _importTabs.index;
    _tabs.dispose();
    _importTabs.dispose();
    _createTabsController(initialIndex: currentIndex);
    _createImportTabsController(initialIndex: currentImportIndex);
  }

  @override
  void didUpdateWidget(covariant ExpenseUploadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final desiredTabIndex = widget.listOnly
        ? 0
        : widget.uploadOnly
            ? 1
            : widget.initialTabIndex.clamp(0, 1);
    if (_tabs.index != desiredTabIndex) {
      _tabs.index = desiredTabIndex;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _importTabs.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    _vendorController.dispose();
    _issueDateController.dispose();
    _totalController.dispose();
    _vendorTaxIdController.dispose();
    _invoiceNumberController.dispose();
    _dueDateController.dispose();
    _taxTotalController.dispose();
    _currencyController.dispose();
    _notesController.dispose();
    _clientIdController.dispose();
    _jsonPayloadController.dispose();
    _jsonProviderIdOverrideController.dispose();
    _jsonGroupIdOverrideController.dispose();
    _jsonStatementEntryController.dispose();
    _jsonClientController.dispose();
    _batchJsonController.dispose();
    _providerNameController.dispose();
    _providerTaxIdController.dispose();
    _providerEmailController.dispose();
    _providerPhoneController.dispose();
    _providerNotesController.dispose();
    _providerStreetController.dispose();
    _providerExtraController.dispose();
    _providerCityController.dispose();
    _providerProvinceController.dispose();
    _providerPostalCodeController.dispose();
    _providerCountryController.dispose();
    super.dispose();
  }

  @override
  String resolveGroupId() {
    final explicit = widget.groupId.trim();
    if (explicit.isNotEmpty) return explicit;
    try {
      final gm = context.read<GroupDomain>();
      final fallback = gm.currentGroup?.id;
      if (fallback != null && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    } catch (_) {}
    return '';
  }

  String _resolveGroupName() {
    final explicit = widget.groupName.trim();
    if (explicit.isNotEmpty) return explicit;
    try {
      final gm = context.read<GroupDomain>();
      final fallback = gm.currentGroup?.name;
      if (fallback != null && fallback.trim().isNotEmpty) {
        return fallback.trim();
      }
    } catch (_) {}
    return '';
  }

  void _addLine() {
    setState(() => _lines.add(ExpenseLineDraft()));
  }

  void _removeLine(int index) {
    final line = _lines.removeAt(index);
    line.dispose();
    setState(() {});
  }

  String _computeTotalFromLines() {
    final total = _lines.fold<double>(0, (sum, line) => sum + line.total);
    return total.toStringAsFixed(2);
  }

  double _linesSubtotal() =>
      _lines.fold<double>(0, (sum, line) => sum + line.subtotal);

  double _linesTax() =>
      _lines.fold<double>(0, (sum, line) => sum + line.taxAmount);

  Future<void> _pickFile() async {
    final result = await ExpenseFormHelpers.pickFile();
    if (result == null) return;
    final validationError = _validateInvoiceUploadFile(
      fileName: result.fileName,
      fileBytes: result.fileBytes,
    );
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _fileName = result.fileName;
      _fileBytes = result.fileBytes;
      _error = null;
    });
  }

  Future<void> _previewSelectedPdf() async {
    final bytes = _fileBytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) return;
    final success = await ExpenseFormHelpers.previewPdf(
      context,
      bytes,
      fileName,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.invoicePdfPreviewFailedSnack),
        ),
      );
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await ExpenseFormHelpers.pickDate(
      context,
      controller.text,
    );
    if (picked == null) return;
    setState(() {
      controller.text = picked;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final attemptId = 'expcreate_${DateTime.now().microsecondsSinceEpoch}';
    final groupId = resolveGroupId();
    if (groupId.isEmpty) {
      _logExpenseAttempt(
        route: 'create',
        attemptId: attemptId,
        hasGroupId: false,
        groupId: '',
        blockedByValidation: true,
        detail: 'missing_group_id',
      );
      setState(() => _error = _requiredGroupMessage());
      return;
    }
    if (_fileBytes == null || _fileName == null) {
      setState(
        () =>
            _error = AppLocalizations.of(context)!.expenseUploadSelectFileError,
      );
      return;
    }
    if (_vendorController.text.trim().isEmpty ||
        _issueDateController.text.trim().isEmpty) {
      setState(
        () => _error =
            AppLocalizations.of(context)!.expenseUploadRequiredFieldsError,
      );
      return;
    }
    if (_lines.isEmpty) {
      setState(
        () => _error =
            AppLocalizations.of(context)!.expenseUploadLinesRequiredError,
      );
      return;
    }
    for (final line in _lines) {
      if (line.descriptionController.text.trim().isEmpty ||
          line.quantity <= 0 ||
          line.unitPrice <= 0 ||
          line.taxRate < 0) {
        setState(
          () => _error =
              AppLocalizations.of(context)!.expenseUploadLinesInvalidError,
        );
        return;
      }
    }
    setState(() {
      _submitting = true;
      _error = null;
      _vatBreakdown = null;
    });
    _logExpenseAttempt(
      route: 'create',
      attemptId: attemptId,
      hasGroupId: true,
      groupId: groupId,
      blockedByValidation: false,
    );
    try {
      final issueDate = DateTime.tryParse(_issueDateController.text.trim());
      final dueDate = DateTime.tryParse(_dueDateController.text.trim());
      if (issueDate == null) {
        throw Exception(
          AppLocalizations.of(context)!.expenseUploadInvalidIssueDateError,
        );
      }
      final response = await _api.uploadExpense(
        bytes: _fileBytes!,
        filename: _fileName!,
        vendorName: _vendorController.text.trim(),
        issueDate: DateFormat('yyyy-MM-dd').format(issueDate),
        total: _totalController.text.trim(),
        groupId: groupId,
        vendorTaxId: _vendorTaxIdController.text.trim().isEmpty
            ? null
            : _vendorTaxIdController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim().isEmpty
            ? null
            : _invoiceNumberController.text.trim(),
        dueDate:
            dueDate == null ? null : DateFormat('yyyy-MM-dd').format(dueDate),
        taxTotal: _taxTotalController.text.trim().isEmpty
            ? null
            : _taxTotalController.text.trim(),
        currency: _currencyController.text.trim().isEmpty
            ? null
            : _currencyController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        clientId: _clientIdController.text.trim().isEmpty
            ? null
            : _clientIdController.text.trim(),
        lines: ExpenseFormHelpers.buildLinesPayload(_lines),
        providerId: _selectedProviderId,
      );
      if (!mounted) return;
      final breakdown = response['vatBreakdown'];
      if (breakdown is List) {
        setState(() {
          _vatBreakdown = breakdown
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.expenseUploadSuccessSnack),
        ),
      );
      final newId = (response['id'] ?? response['_id'] ?? response['expenseId'])
          ?.toString()
          .trim();
      final selectedProvider = _providers.firstWhere(
        (p) =>
            (p['id'] ?? p['_id'] ?? p['providerId'])?.toString() ==
            _selectedProviderId,
        orElse: () => const <String, dynamic>{},
      );
      final providerNameValue =
          selectedProvider['name']?.toString().trim() ?? '';
      setState(() {
        _recentUploads.insert(0, {
          if (newId != null && newId.isNotEmpty) 'id': newId,
          'vendor': _vendorController.text.trim(),
          'total': _totalController.text.trim(),
          'date': _issueDateController.text.trim(),
          'file': _fileName ?? '',
          'providerId': _selectedProviderId ?? '',
          if (providerNameValue.isNotEmpty) 'providerName': providerNameValue,
          if (_invoiceNumberController.text.trim().isNotEmpty)
            'invoice': _invoiceNumberController.text.trim(),
          if (_currencyController.text.trim().isNotEmpty)
            'currency': _currencyController.text.trim(),
          if (_taxTotalController.text.trim().isNotEmpty)
            'tax': _taxTotalController.text.trim(),
          if (_dueDateController.text.trim().isNotEmpty)
            'due': _dueDateController.text.trim(),
        });
        _selectedRecentExpense = _recentUploads.first;
      });
      widget.onUploaded?.call();
      if (!widget.embedded) {
        Navigator.of(context).pop();
      }
    } on ExpensesApiException catch (e) {
      var message = e.message;
      if (e.statusCode == 400) {
        final lower = e.message.toLowerCase();
        if (lower.contains('groupid is required') ||
            lower.contains('groupid')) {
          message = _requiredGroupMessage();
        }
      }
      setState(() => _error = message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildJsonImportTab(AppLocalizations l);
  Widget _buildBatchImportTab(AppLocalizations l);
  Future<void> pickBatchDocuments();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final filePicker = ExpenseFilePickerCard(
      fileName: _fileName,
      fileBytes: _fileBytes,
      submitting: _submitting,
      onPick: _pickFile,
      dropZoneHeight: 240,
      onPreviewPdf: (_fileName?.toLowerCase().endsWith('.pdf') ?? false)
          ? _previewSelectedPdf
          : null,
    );
    final providerPicker = ExpenseProviderPicker(
      providers: _providers,
      selectedProviderId: _selectedProviderId,
      providersError: _providersError,
      loading: _loadingProviders,
      onSelectProvider: selectProvider,
    );
    final linesEditor = ExpenseLinesEditor(
      lines: _lines,
      onAddLine: _addLine,
      onRemoveLine: _removeLine,
      onLinesChanged: () => setState(() {}),
    );
    final hasLines = _lines.isNotEmpty;
    final computedTotal = hasLines ? _computeTotalFromLines() : '';
    if (hasLines && computedTotal != _totalController.text) {
      _totalController.text = computedTotal;
    }
    if (hasLines) {
      final computedTax = _linesTax().toStringAsFixed(2);
      if (computedTax != _taxTotalController.text) {
        _taxTotalController.text = computedTax;
      }
    }
    final summarySubtotal = hasLines
        ? ExpenseFormHelpers.formatAmount(_linesSubtotal())
        : (() {
            final total = ExpenseFormHelpers.parseAmount(_totalController.text);
            final tax =
                ExpenseFormHelpers.parseAmount(_taxTotalController.text);
            if (total == null) return '-';
            if (tax == null) return ExpenseFormHelpers.formatAmount(total);
            return ExpenseFormHelpers.formatAmount(
                (total - tax).clamp(0, double.infinity));
          })();
    final summaryTax = hasLines
        ? ExpenseFormHelpers.formatAmount(_linesTax())
        : ExpenseFormHelpers.formatAmount(
            ExpenseFormHelpers.parseAmount(_taxTotalController.text));
    final summaryTotal = hasLines
        ? ExpenseFormHelpers.formatAmount(_linesSubtotal() + _linesTax())
        : ExpenseFormHelpers.formatAmount(
            ExpenseFormHelpers.parseAmount(_totalController.text));
    final vatBreakdown = ExpenseVatBreakdownCard(
      breakdown: _vatBreakdown,
    );
    final summaryBar = ExpenseTotalsSummaryBar(
      subtotal: summarySubtotal,
      tax: summaryTax,
      total: summaryTotal,
    );
    final displayGroupId = resolveGroupId();
    final hasGroupSelected = displayGroupId.trim().isNotEmpty;
    final displayGroupName = _resolveGroupName();
    final formFields = ExpenseFormFields(
      groupName: displayGroupName,
      groupId: displayGroupId,
      providerPicker: providerPicker,
      vendorController: _vendorController,
      issueDateController: _issueDateController,
      totalController: _totalController,
      vendorTaxIdController: _vendorTaxIdController,
      invoiceNumberController: _invoiceNumberController,
      dueDateController: _dueDateController,
      taxTotalController: _taxTotalController,
      currencyController: _currencyController,
      notesController: _notesController,
      clientIdController: _clientIdController,
      linesEditor: linesEditor,
      vatBreakdown: vatBreakdown,
      summaryBar: summaryBar,
      hasLines: hasLines,
      submitting: _submitting,
      onPickDate: _pickDate,
    );
    final errorsAndSubmit = ExpenseErrorsAndSubmit(
      error: _error,
      submitting: _submitting,
      onSubmit: _submit,
      canSubmit: hasGroupSelected,
    );
    final uploadWorkspace = AnimatedBuilder(
      animation: _importTabs,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          Widget centeredLeftPanel({
            required Widget picker,
            String? helperText,
            List<String>? chips,
          }) {
            return LayoutBuilder(
              builder: (context, leftConstraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: leftConstraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            picker,
                            if ((helperText ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                helperText!,
                                textAlign: TextAlign.center,
                              ),
                            ],
                            if ((chips ?? const <String>[]).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: (chips ?? const <String>[])
                                    .map((name) => Chip(label: Text(name)))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          final importTabsHeader = TabBar(
            controller: _importTabs,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: cs.primary.withValues(alpha: 0.14),
            ),
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            labelPadding: EdgeInsets.zero,
            tabs: const [
              Tab(height: 34, text: 'Manual'),
              Tab(height: 34, text: 'JSON'),
              Tab(height: 34, text: 'Batch'),
            ],
          );
          final manualWideTab = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: formFields),
              errorsAndSubmit,
            ],
          );
          final batchLeftPicker = centeredLeftPanel(
            picker: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpenseFilePickerCard(
                  fileName: _batchDocumentNames.isNotEmpty
                      ? _batchDocumentNames.first
                      : null,
                  fileBytes: _batchDocumentBytes.isNotEmpty
                      ? _batchDocumentBytes.first
                      : null,
                  submitting: _batchSubmitting || _batchGeneratingJson,
                  onPick: pickBatchDocuments,
                  dropZoneHeight: 240,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: (_batchSubmitting || _batchGeneratingJson)
                      ? null
                      : pickBatchDocuments,
                  icon:
                      const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text('Seleccionar documentos'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Los archivos cargados se muestran en el panel derecho.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
          final defaultLeftPicker = centeredLeftPanel(picker: filePicker);
          final manualCompactTab = SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                filePicker,
                const SizedBox(height: 8),
                formFields,
                errorsAndSubmit,
              ],
            ),
          );
          final editorPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              importTabsHeader,
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _importTabs,
                  children: [
                    manualWideTab,
                    _buildJsonImportTab(l),
                    _buildBatchImportTab(l),
                  ],
                ),
              ),
            ],
          );
          if (!isWide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                importTabsHeader,
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _importTabs,
                    children: [
                      manualCompactTab,
                      _buildJsonImportTab(l),
                      _buildBatchImportTab(l),
                    ],
                  ),
                ),
              ],
            );
          }
          final isBatchTab = _importTabs.index == 2;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: isBatchTab ? batchLeftPicker : defaultLeftPicker,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 7,
                child: editorPanel,
              ),
            ],
          );
        },
      ),
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.embedded)
          if (widget.providersOnly)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ExpenseProvidersManagementView(
                  groupName: _resolveGroupName(),
                  groupId: resolveGroupId(),
                  providers: _providers,
                  recentUploads: _recentUploads,
                  loadingProviders: _loadingProviders,
                  savingProvider: _savingProvider,
                  editingProviderId: _editingProviderId,
                  selectedProviderId: _selectedProviderSummaryId,
                  providerId: providerId,
                  providerName: providerName,
                  providerNameController: _providerNameController,
                  providerTaxIdController: _providerTaxIdController,
                  providerEmailController: _providerEmailController,
                  providerPhoneController: _providerPhoneController,
                  providerNotesController: _providerNotesController,
                  providerStreetController: _providerStreetController,
                  providerExtraController: _providerExtraController,
                  providerCityController: _providerCityController,
                  providerProvinceController: _providerProvinceController,
                  providerPostalCodeController: _providerPostalCodeController,
                  providerCountryController: _providerCountryController,
                  onSelectProvider: (provider) {
                    final id = providerId(provider);
                    if (id != null) {
                      setState(() => _selectedProviderSummaryId = id);
                    }
                    editProvider(provider);
                  },
                  onPreviewExpense: previewExpenseFromProviders,
                  onSaveProvider: saveProvider,
                  onResetProviderForm: resetProviderForm,
                  onDeleteProvider: deleteProvider,
                ),
              ),
            )
          else if (widget.providerFormOnly)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ProviderFormView(
                  editingProviderId: _editingProviderId,
                  savingProvider: _savingProvider,
                  nameController: _providerNameController,
                  taxIdController: _providerTaxIdController,
                  emailController: _providerEmailController,
                  phoneController: _providerPhoneController,
                  notesController: _providerNotesController,
                  streetController: _providerStreetController,
                  extraController: _providerExtraController,
                  cityController: _providerCityController,
                  provinceController: _providerProvinceController,
                  postalCodeController: _providerPostalCodeController,
                  countryController: _providerCountryController,
                  onSave: saveProvider,
                  onReset: resetProviderForm,
                ),
              ),
            )
          else if (widget.listOnly)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ExpenseRecentUploadsTab(
                  recentUploads: _recentUploads,
                  onDeleteExpense: deleteRecentExpense,
                  selectedExpense: _selectedRecentExpense,
                  previewLoading: _loadingPreview,
                  previewError: _previewError,
                  groupId: displayGroupId,
                  onSelectExpense: selectRecentExpense,
                ),
              ),
            )
          else if (widget.uploadOnly)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: uploadWorkspace,
              ),
            )
          else ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cs.primary.withValues(alpha: 0.16),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.55),
                  ),
                ),
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                labelPadding: EdgeInsets.zero,
                tabs: [
                  Tab(height: 34, text: l.expenseUploadTabList),
                  Tab(height: 34, text: l.expenseUploadTabUpload),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    ExpenseRecentUploadsTab(
                      recentUploads: _recentUploads,
                      onDeleteExpense: deleteRecentExpense,
                      selectedExpense: _selectedRecentExpense,
                      previewLoading: _loadingPreview,
                      previewError: _previewError,
                      groupId: displayGroupId,
                      onSelectExpense: selectRecentExpense,
                    ),
                    uploadWorkspace,
                  ],
                ),
              ),
            ),
          ],
      ],
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.expenseUploadTitle),
      ),
      body: body,
    );
  }
}

class ExpenseUploadScreenState extends _ExpenseUploadScreenStateBase
    with ExpenseUploadImportActionsSection, ExpenseUploadImportTabsSection {
  @override
  bool get jsonSubmitting => _jsonSubmitting;
  @override
  bool get jsonPromptLoading => _jsonPromptLoading;
  @override
  String? get jsonPromptMessage => _jsonPromptMessage;
  @override
  String? get jsonPromptText => _jsonPromptText;
  @override
  String? get jsonFileName => _jsonFileName;
  @override
  String? get jsonInvoiceFileName => _jsonInvoiceFileName;
  @override
  String? get selectedFileName => _fileName;
  @override
  TextEditingController get jsonPayloadController => _jsonPayloadController;
  @override
  bool get jsonAdvancedExpanded => _jsonAdvancedExpanded;
  @override
  set jsonAdvancedExpanded(bool value) => _jsonAdvancedExpanded = value;
  @override
  TextEditingController get jsonProviderIdOverrideController =>
      _jsonProviderIdOverrideController;
  @override
  TextEditingController get jsonGroupIdOverrideController =>
      _jsonGroupIdOverrideController;
  @override
  TextEditingController get jsonStatementEntryController =>
      _jsonStatementEntryController;
  @override
  TextEditingController get jsonClientController => _jsonClientController;
  @override
  String? get jsonError => _jsonError;
  @override
  bool get batchSubmitting => _batchSubmitting;
  @override
  bool get batchGeneratingJson => _batchGeneratingJson;
  @override
  TextEditingController get batchJsonController => _batchJsonController;
  @override
  int get batchDetectedInvoices => _batchDetectedInvoices;
  @override
  set batchDetectedInvoices(int value) => _batchDetectedInvoices = value;
  @override
  List<Uint8List> get batchDocumentBytes => _batchDocumentBytes;
  @override
  List<String> get batchDocumentNames => _batchDocumentNames;
  @override
  String? get batchError => _batchError;
  @override
  String? get batchVerifyMessage => _batchVerifyMessage;
  @override
  Future<void> pickJsonPayloadFile() => _pickJsonPayloadFile();
  @override
  Future<void> pickJsonInvoiceFile() => _pickJsonInvoiceFile();
  @override
  Future<void> fetchExpenseJsonPrompt() => _fetchExpenseJsonPrompt();
  @override
  Future<void> copyPromptToClipboard() => _copyPromptToClipboard();
  @override
  Future<void> submitExpenseJsonImport() => _submitExpenseJsonImport();
  @override
  Future<void> pickBatchJsonFile() => _pickBatchJsonFile();
  @override
  Future<void> pickBatchDocuments() => _pickBatchDocuments();
  @override
  Future<void> generateBatchJsonWithAi() => _generateBatchJsonWithAi();
  @override
  Future<void> submitBatchImport() => _submitBatchImport();
  @override
  List<Map<String, dynamic>> extractBatchInvoices(
          Map<String, dynamic> payload) =>
      _extractBatchInvoices(payload);
}
