import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_dropzone_platform_interface/flutter_dropzone_platform_interface.dart'
    show FlutterDropzonePlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/b-backend/expenses/expenses_api.dart';
import 'package:hexora/b-backend/group_mng_flow/group/domain/group_domain.dart';
import 'package:hexora/b-backend/providers/providers_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/expense_operations.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/form_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_ops/provider_operations.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload_sections.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/expense_upload/form_sections/expense_settlement_fields.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/prompt_clipboard_helper.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/ocr_import_job_mapping_store.dart';
import 'package:hexora/c-frontend/ui-app/shared/jobs/ocr_import_jobs_store.dart';
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

class _ExpenseBatchJobSnapshot {
  final String jobId;
  final String? backgroundJobId;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? result;

  const _ExpenseBatchJobSnapshot({
    required this.jobId,
    this.backgroundJobId,
    this.status,
    this.result,
  });
}

class _ExpenseBatchPreviewItem {
  final String id;
  final String tempId;
  final String fileName;
  String status;
  Map<String, dynamic> prediction;
  final Map<String, dynamic> confidence;
  final List<String> warnings;
  final Map<String, dynamic> duplicate;
  final String? error;
  bool selected;
  bool reviewed = false;

  _ExpenseBatchPreviewItem({
    required this.id,
    required this.tempId,
    required this.fileName,
    required this.status,
    required this.prediction,
    required this.confidence,
    required this.warnings,
    required this.duplicate,
    this.error,
    required this.selected,
  });

  bool get isDuplicate =>
      status == 'duplicate' || duplicate['isDuplicate'] == true;
  bool get isFailed => status == 'failed';
  bool get canSelect => !isDuplicate && !isFailed;
  bool get needsReview => status == 'needs_review';

  factory _ExpenseBatchPreviewItem.fromMap(
    Map<String, dynamic> raw,
    int index,
  ) {
    final status = _batchJobText(raw['status']).toLowerCase();
    final duplicate = raw['duplicate'] is Map
        ? Map<String, dynamic>.from(raw['duplicate'] as Map)
        : <String, dynamic>{};
    final tempId = _batchJobText(raw['tempId']);
    final fileName = _batchJobFirstText([
      raw['fileName'],
      raw['sourceDocument'] is Map
          ? (raw['sourceDocument'] as Map)['fileName']
          : null,
      'Documento ${index + 1}',
    ]);
    final isDuplicate =
        status == 'duplicate' || duplicate['isDuplicate'] == true;
    final isFailed = status == 'failed';
    return _ExpenseBatchPreviewItem(
      id: tempId.isNotEmpty ? tempId : '${fileName}_$index',
      tempId: tempId,
      fileName: fileName,
      status: status.isEmpty ? 'needs_review' : status,
      prediction: raw['prediction'] is Map
          ? Map<String, dynamic>.from(raw['prediction'] as Map)
          : <String, dynamic>{},
      confidence: raw['confidence'] is Map
          ? Map<String, dynamic>.from(raw['confidence'] as Map)
          : <String, dynamic>{},
      warnings: _expenseBatchStringList(raw['warnings']),
      duplicate: duplicate,
      error: _batchJobFirstText([raw['error'], raw['message'], raw['reason']]),
      selected: status == 'ready' && !isDuplicate && !isFailed,
    );
  }
}

enum _ExpenseDocumentTotalField {
  base,
  tax,
  total,
}

String _batchJobText(dynamic value) => value?.toString().trim() ?? '';

String _batchJobFirstText(Iterable<dynamic> values) {
  for (final value in values) {
    final text = _batchJobText(value);
    if (text.isNotEmpty) return text;
  }
  return '';
}

int _batchJobInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_batchJobText(value)) ?? 0;
}

double _batchJobDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(_batchJobText(value)) ?? 0;
}

bool _isIncidentStatus(String status) {
  return const {
    'failed',
    'needs_review',
    'duplicate',
    'duplicated',
    'skipped',
    'validation_error',
  }.contains(status.trim().toLowerCase());
}

bool _hasIncidentItems(
  Iterable<_ExpenseBatchPreviewItem> items, {
  int skippedCount = 0,
  int duplicateCount = 0,
  int failedCount = 0,
  int warningCount = 0,
}) {
  return items.any((item) => _isIncidentStatus(item.status)) ||
      skippedCount > 0 ||
      duplicateCount > 0 ||
      failedCount > 0 ||
      warningCount > 0;
}

List<String> _expenseBatchStringList(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => _batchJobText(entry))
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  final text = _batchJobText(value);
  return text.isEmpty ? <String>[] : <String>[text];
}

List<_ExpenseBatchPreviewItem> _expenseBatchPreviewItemsFromPayload(
  Map<String, dynamic>? payload,
) {
  final rawItems = payload?['items'];
  if (rawItems is! List) return <_ExpenseBatchPreviewItem>[];
  return [
    for (var index = 0; index < rawItems.length; index++)
      if (rawItems[index] is Map)
        _ExpenseBatchPreviewItem.fromMap(
          Map<String, dynamic>.from(rawItems[index] as Map),
          index,
        ),
  ];
}

String _expenseBatchJobStatusFromPayload(Map<String, dynamic>? payload) {
  final status = _batchJobText(payload?['status']).toLowerCase();
  if (status.isEmpty) return 'idle';
  return status;
}

bool _isExpenseBatchJobTerminal(String? status) =>
    status == 'completed' ||
    status == 'failed' ||
    status == 'needs_review' ||
    status == 'cancelled';

String _expenseBatchJobMessageFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return '';
  return _batchJobFirstText([
    payload['message'],
    payload['detail'],
    payload['currentStep'],
    payload['status'],
  ]);
}

String _expenseBatchJobUiMessage(Map<String, dynamic>? payload) {
  final status = _expenseBatchJobStatusFromPayload(payload);
  final backendMessage = _expenseBatchJobMessageFromPayload(payload);
  final processedFiles = _batchJobInt(payload?['processedFiles']);
  final totalFiles = _batchJobInt(payload?['totalFiles']);

  switch (status) {
    case 'queued':
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Importacion en cola. Puedes salir de esta pantalla mientras se procesa el lote.';
    case 'processing':
      final prefix = (processedFiles > 0 && totalFiles > 0)
          ? 'Procesando $processedFiles de $totalFiles archivos.'
          : 'Procesando lote de gastos.';
      if (backendMessage.isNotEmpty) {
        return '$prefix $backendMessage';
      }
      return '$prefix Puedes salir de esta pantalla mientras se completa la importacion.';
    case 'completed':
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Importacion completada.';
    case 'failed':
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Importacion fallida.';
    default:
      return backendMessage.isNotEmpty
          ? backendMessage
          : 'Esperando importacion...';
  }
}

List<String> _expenseBatchIssuesFromPayload(Map<String, dynamic>? payload) {
  if (payload == null) return const <String>[];
  final issues = <String>[];

  void append(dynamic entry, {String? fallbackReason}) {
    if (entry == null) return;
    if (entry is String) {
      final text = entry.trim();
      if (text.isNotEmpty) issues.add(text);
      return;
    }
    if (entry is Map) {
      final map = Map<String, dynamic>.from(entry);
      final fileName = _batchJobFirstText([
        map['fileName'],
        map['filename'],
        map['name'],
        map['documentName'],
        map['document'],
      ]);
      final reason = _batchJobFirstText([
        map['reason'],
        map['message'],
        map['error'],
        map['detail'],
        fallbackReason,
      ]);
      if (fileName.isNotEmpty && reason.isNotEmpty) {
        issues.add('$fileName - $reason');
      } else if (fileName.isNotEmpty) {
        issues.add(fileName);
      } else if (reason.isNotEmpty) {
        issues.add(reason);
      }
    }
  }

  void appendList(dynamic raw, {String? fallbackReason}) {
    if (raw is List) {
      for (final entry in raw) {
        append(entry, fallbackReason: fallbackReason);
      }
    }
  }

  appendList(payload['errors'], fallbackReason: 'Error');
  appendList(payload['issues'], fallbackReason: 'Incidencia');
  appendList(payload['warnings'], fallbackReason: 'Advertencia');
  appendList(payload['failedFiles'], fallbackReason: 'No se pudo importar');
  appendList(payload['skippedFiles'], fallbackReason: 'Se omitio del lote');
  appendList(payload['files']);

  return issues.toSet().toList();
}

Map<String, String> _expenseBatchFileIssueMapFromPayload(
  Map<String, dynamic>? payload,
) {
  if (payload == null) return const <String, String>{};
  final issuesByFile = <String, String>{};

  void append(dynamic entry, {String? fallbackReason}) {
    if (entry is! Map) return;
    final map = Map<String, dynamic>.from(entry);
    final fileName = _batchJobFirstText([
      map['fileName'],
      map['filename'],
      map['name'],
      map['documentName'],
      map['document'],
    ]);
    if (fileName.isEmpty) return;
    final reason = _batchJobFirstText([
      map['reason'],
      map['message'],
      map['error'],
      map['detail'],
      fallbackReason,
    ]);
    issuesByFile[fileName.toLowerCase().trim()] =
        reason.isEmpty ? 'Con incidencia' : reason;
  }

  void appendList(dynamic raw, {String? fallbackReason}) {
    if (raw is List) {
      for (final entry in raw) {
        append(entry, fallbackReason: fallbackReason);
      }
    }
  }

  appendList(payload['failedFiles'], fallbackReason: 'No se pudo importar');
  appendList(payload['skippedFiles'], fallbackReason: 'Se omitio del lote');
  appendList(payload['errors'], fallbackReason: 'Error');
  appendList(payload['issues'], fallbackReason: 'Incidencia');
  appendList(payload['files']);

  return issuesByFile;
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
  final _baseTotalController = TextEditingController();
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
  final _jsonBaseController = TextEditingController();
  final _jsonTaxController = TextEditingController();
  final _jsonTotalController = TextEditingController();
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
  final _manualSettlement = ExpenseSettlementDraft();
  final _manualDocumentDiscount = ExpenseDocumentDiscountDraft();
  final _manualWithholding = ExpenseWithholdingDraft();
  final _jsonSettlement = ExpenseSettlementDraft();
  final _jsonDocumentDiscount = ExpenseDocumentDiscountDraft();
  bool _manualUseSummaryTotals = false;
  bool _jsonUseSummaryTotals = false;
  bool _syncingManualSummaryTotals = false;
  bool _syncingJsonSummaryTotals = false;
  List<Map<String, dynamic>>? _vatBreakdown;
  Map<String, String>? _selectedRecentExpense;
  String? _pendingAutoEditExpenseId;
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
  int _jsonImportStep = 0;
  String? _jsonPromptMessage;
  String? _jsonPromptText;
  List<Uint8List> _batchDocumentBytes = [];
  List<String> _batchDocumentNames = [];
  bool _batchSubmitting = false;
  bool _batchGeneratingJson = false;
  bool _batchStartingJob = false;
  bool _batchExportingIncidents = false;
  bool _batchPollingInFlight = false;
  bool _batchResultLoading = false;
  String? _batchError;
  List<String> _batchSkippedDetails = [];
  String? _batchVerifyMessage;
  int _batchDetectedInvoices = 0;
  int _batchFileFilterIndex = 0;
  bool _batchErrorsExpanded = false;
  bool _batchSummaryCollapsed = true;
  String? _batchJobId;
  String? _batchBackgroundJobId;
  Map<String, dynamic>? _batchJobStatus;
  Map<String, dynamic>? _batchJobResult;
  Map<String, dynamic>? _batchConfirmResult;
  List<_ExpenseBatchPreviewItem> _batchPreviewItems = [];
  Timer? _batchJobPollTimer;

  static const int _maxBatchDocuments = 200;
  static const int _maxBatchFileSizeBytes = 10 * 1024 * 1024;
  static final Map<String, _ExpenseBatchJobSnapshot> _batchJobCacheByGroup =
      <String, _ExpenseBatchJobSnapshot>{};

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

  List<String> get batchSkippedDetails => _batchSkippedDetails;

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
    'jpe',
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
    if (lc.endsWith('.jpg') || lc.endsWith('.jpeg') || lc.endsWith('.jpe')) {
      return 'image/jpeg';
    }
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
        'Unsupported file type. Use PDF, JPG/JPEG/JPE, PNG, or WEBP.',
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

  String _batchJobCacheKey() {
    final resolved = resolveGroupId().trim();
    if (resolved.isNotEmpty) return resolved;
    return widget.groupId.trim();
  }

  bool get _hasTrackedBatchJob => (_batchJobId ?? '').trim().isNotEmpty;

  bool get _hasRunningBatchJob =>
      _hasTrackedBatchJob &&
      !_isExpenseBatchJobTerminal(
        _expenseBatchJobStatusFromPayload(_batchJobStatus),
      );

  void _cacheBatchJobSnapshot() {
    final key = _batchJobCacheKey();
    if (key.isEmpty) return;
    final jobId = (_batchJobId ?? '').trim();
    if (jobId.isEmpty) {
      _batchJobCacheByGroup.remove(key);
      return;
    }
    _batchJobCacheByGroup[key] = _ExpenseBatchJobSnapshot(
      jobId: jobId,
      backgroundJobId: (_batchBackgroundJobId ?? '').trim().isEmpty
          ? null
          : _batchBackgroundJobId!.trim(),
      status: _batchJobStatus == null
          ? null
          : Map<String, dynamic>.from(_batchJobStatus!),
      result: _batchJobResult == null
          ? null
          : Map<String, dynamic>.from(_batchJobResult!),
    );
  }

  bool _restoreCachedBatchJobSnapshot() {
    final key = _batchJobCacheKey();
    if (key.isEmpty) return false;
    final snapshot = _batchJobCacheByGroup[key];
    if (snapshot == null) return false;
    _batchJobId = snapshot.jobId;
    _batchBackgroundJobId = snapshot.backgroundJobId;
    _batchJobStatus = snapshot.status == null
        ? null
        : Map<String, dynamic>.from(snapshot.status!);
    _batchJobResult = snapshot.result == null
        ? null
        : Map<String, dynamic>.from(snapshot.result!);
    _batchPreviewItems = _expenseBatchPreviewItemsFromPayload(_batchJobResult);
    return true;
  }

  void _clearBatchJobSnapshotCache() {
    final key = _batchJobCacheKey();
    if (key.isEmpty) return;
    _batchJobCacheByGroup.remove(key);
  }

  Future<void> _persistBatchJobMapping() async {
    final previewJobId = (_batchJobId ?? '').trim();
    final backgroundJobId = (_batchBackgroundJobId ?? '').trim();
    if (previewJobId.isEmpty || backgroundJobId.isEmpty) return;
    await OcrImportJobMappingStore.instance.upsert(
      OcrImportJobMapping(
        previewJobId: previewJobId,
        backgroundJobId: backgroundJobId,
        startedAt: DateTime.now(),
        type: 'OCR_IMPORT',
      ),
    );
  }

  Future<bool> _restorePersistedBatchJobMapping() async {
    final jobs = await OcrImportJobMappingStore.instance.loadAll();
    if (jobs.isEmpty) return false;
    final latest = jobs.firstWhere(
      (entry) => entry.type == 'OCR_IMPORT',
      orElse: () => jobs.first,
    );
    _batchJobId = latest.previewJobId;
    _batchBackgroundJobId = latest.backgroundJobId;
    OcrImportJobsStore.instance.trackStartedJob(
      backgroundJobId: latest.backgroundJobId,
      totalFiles: _batchDocumentNames.length,
    );
    return true;
  }

  void _resetBatchJobTracking(
      {bool clearResult = true, bool clearCache = true}) {
    _batchJobPollTimer?.cancel();
    _batchJobPollTimer = null;
    _batchPollingInFlight = false;
    _batchStartingJob = false;
    _batchJobId = null;
    _batchBackgroundJobId = null;
    _batchJobStatus = null;
    if (clearResult) {
      _batchJobResult = null;
      _batchConfirmResult = null;
      _batchPreviewItems = [];
    }
    _batchResultLoading = false;
    if (clearCache) {
      _clearBatchJobSnapshotCache();
    }
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

  void openExpenseEditorById(String expenseId) {
    final trimmedId = expenseId.trim();
    if (trimmedId.isEmpty) return;

    _pendingAutoEditExpenseId = trimmedId;
    _selectedRecentExpense = <String, String>{'id': trimmedId};

    if (_tabs.index != 0) {
      _tabs.index = 0;
    }

    final matched = _recentUploads.cast<Map<String, String>?>().firstWhere(
          (item) => (item?['id'] ?? '').trim() == trimmedId,
          orElse: () => null,
        );

    if (matched != null) {
      selectRecentExpense(matched);
      return;
    }

    setState(() {});
    unawaited(loadRecentUploads());
  }

  @override
  void dispose() {
    _batchJobPollTimer?.cancel();
    _tabs.dispose();
    _importTabs.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    _vendorController.dispose();
    _issueDateController.dispose();
    _baseTotalController.dispose();
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
    _jsonBaseController.dispose();
    _jsonTaxController.dispose();
    _jsonTotalController.dispose();
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
    _manualSettlement.dispose();
    _manualDocumentDiscount.dispose();
    _manualWithholding.dispose();
    _jsonSettlement.dispose();
    _jsonDocumentDiscount.dispose();
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

  double _linesSubtotal() =>
      _lines.fold<double>(0, (sum, line) => sum + line.subtotal);

  double _linesTax() =>
      _lines.fold<double>(0, (sum, line) => sum + line.taxAmount);

  double? _parseControllerAmount(TextEditingController controller) {
    return ExpenseFormHelpers.parseAmount(controller.text);
  }

  void _setFormattedAmount(
    TextEditingController controller,
    double value,
  ) {
    final formatted = value.toStringAsFixed(2);
    if (controller.text != formatted) {
      controller.text = formatted;
    }
  }

  void _syncSummaryControllers({
    required TextEditingController baseController,
    required TextEditingController taxController,
    required TextEditingController totalController,
    required _ExpenseDocumentTotalField changedField,
    required bool Function() isSyncing,
    required void Function(bool value) setSyncing,
  }) {
    if (isSyncing()) return;
    final base = _parseControllerAmount(baseController);
    final tax = _parseControllerAmount(taxController) ?? 0;
    final total = _parseControllerAmount(totalController);

    setSyncing(true);
    if (changedField == _ExpenseDocumentTotalField.total ||
        (changedField == _ExpenseDocumentTotalField.tax &&
            (base == null || base < 0) &&
            total != null)) {
      if (total != null) {
        _setFormattedAmount(
          baseController,
          (total - tax).clamp(0, double.infinity).toDouble(),
        );
      }
    } else if (base != null) {
      _setFormattedAmount(
        totalController,
        (base + tax).clamp(0, double.infinity).toDouble(),
      );
    }
    setSyncing(false);
  }

  void _syncManualSummaryControllers(_ExpenseDocumentTotalField changedField) {
    if (!_manualUseSummaryTotals && _lines.isNotEmpty) return;
    _syncSummaryControllers(
      baseController: _baseTotalController,
      taxController: _taxTotalController,
      totalController: _totalController,
      changedField: changedField,
      isSyncing: () => _syncingManualSummaryTotals,
      setSyncing: (value) => _syncingManualSummaryTotals = value,
    );
  }

  void _syncJsonSummaryControllers(_ExpenseDocumentTotalField changedField) {
    _syncSummaryControllers(
      baseController: _jsonBaseController,
      taxController: _jsonTaxController,
      totalController: _jsonTotalController,
      changedField: changedField,
      isSyncing: () => _syncingJsonSummaryTotals,
      setSyncing: (value) => _syncingJsonSummaryTotals = value,
    );
  }

  ExpenseDocumentDiscountPreview? _previewDiscountFromSummaryControllers({
    required ExpenseDocumentDiscountDraft draft,
    required TextEditingController baseController,
    required TextEditingController taxController,
  }) {
    final finalBase = _parseControllerAmount(baseController);
    final finalTax = _parseControllerAmount(taxController) ?? 0;
    if (finalBase == null) return null;
    final grossBase = draft.grossBaseFromFinal(finalBase);
    final grossTax = draft.grossTaxFromFinal(
      finalBase: finalBase,
      finalTax: finalTax,
    );
    return _previewDocumentDiscount(
      draft: draft,
      subtotalBeforeDiscount: grossBase,
      taxBeforeDiscount: grossTax,
    );
  }

  void _applyManualSummaryControllersFromLines(
    ExpenseDocumentDiscountPreview preview,
  ) {
    _syncingManualSummaryTotals = true;
    _setFormattedAmount(
      _baseTotalController,
      preview.taxableBase,
    );
    _setFormattedAmount(
      _taxTotalController,
      preview.tax,
    );
    _setFormattedAmount(
      _totalController,
      preview.total,
    );
    _syncingManualSummaryTotals = false;
  }

  void _loadJsonSummaryControllersFromExpense(
    Map<String, dynamic> expense, {
    bool allowAutoMode = false,
  }) {
    final total = ExpenseFormHelpers.parseNum(expense['total']);
    final tax = ExpenseFormHelpers.parseNum(
          expense['taxTotal'] ?? expense['vatTotal'] ?? expense['tax'],
        ) ??
        0;
    final subtotal = ExpenseFormHelpers.parseNum(expense['subtotal']);
    final base = subtotal ??
        (total == null ? null : (total - tax).clamp(0, double.infinity));

    _syncingJsonSummaryTotals = true;
    if (base != null) {
      _setFormattedAmount(_jsonBaseController, base.toDouble());
    }
    if (ExpenseFormHelpers.parseNum(
          expense['taxTotal'] ?? expense['vatTotal'] ?? expense['tax'],
        ) !=
        null) {
      _setFormattedAmount(_jsonTaxController, tax.toDouble());
    }
    if (total != null) {
      _setFormattedAmount(_jsonTotalController, total.toDouble());
    }
    _syncingJsonSummaryTotals = false;

    if (!allowAutoMode) return;
    final rawLines = expense['lines'] is List
        ? expense['lines']
        : expense['items'] is List
            ? expense['items']
            : null;
    final lines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false)
        : null;
    final shouldUseSummary = ExpenseFormHelpers.shouldUseSummaryTotals(
      expense: expense,
      storedTotal: total?.toDouble(),
      storedTax: tax.toDouble(),
      lines: lines,
    );
    if (shouldUseSummary != _jsonUseSummaryTotals) {
      _jsonUseSummaryTotals = shouldUseSummary;
    }
  }

  void _tryLoadJsonSummaryControllersFromPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return;
      final payload = Map<String, dynamic>.from(decoded);
      final expense = payload['expense'] is Map
          ? Map<String, dynamic>.from(payload['expense'] as Map)
          : payload;
      _loadJsonSummaryControllersFromExpense(
        expense,
        allowAutoMode: true,
      );
    } catch (_) {
      // Ignore incomplete manual JSON while the user is still editing.
    }
  }

  ExpenseDocumentDiscountPreview _previewDocumentDiscount({
    required ExpenseDocumentDiscountDraft draft,
    required double subtotalBeforeDiscount,
    required double taxBeforeDiscount,
  }) {
    draft.syncDerivedFields(subtotalBeforeDiscount);
    return draft.buildPreview(
      subtotalBeforeDiscount: subtotalBeforeDiscount,
      taxBeforeDiscount: taxBeforeDiscount,
    );
  }

  ExpenseDocumentDiscountPreview? _manualDiscountPreview() {
    if (_manualUseSummaryTotals) {
      return _previewDiscountFromSummaryControllers(
        draft: _manualDocumentDiscount,
        baseController: _baseTotalController,
        taxController: _taxTotalController,
      );
    }
    if (_lines.isNotEmpty) {
      return _previewDocumentDiscount(
        draft: _manualDocumentDiscount,
        subtotalBeforeDiscount: _linesSubtotal(),
        taxBeforeDiscount: _linesTax(),
      );
    }
    final total = ExpenseFormHelpers.parseAmount(_totalController.text);
    final tax = ExpenseFormHelpers.parseAmount(_taxTotalController.text) ?? 0;
    if (total == null) return null;
    final finalBase = (total - tax).clamp(0, double.infinity).toDouble();
    final grossBase = _manualDocumentDiscount.grossBaseFromFinal(finalBase);
    final grossTax = _manualDocumentDiscount.grossTaxFromFinal(
      finalBase: finalBase,
      finalTax: tax,
    );
    return _previewDocumentDiscount(
      draft: _manualDocumentDiscount,
      subtotalBeforeDiscount: grossBase,
      taxBeforeDiscount: grossTax,
    );
  }

  ExpenseDocumentDiscountPreview? _jsonDiscountPreview() {
    if (_jsonUseSummaryTotals) {
      return _previewDiscountFromSummaryControllers(
        draft: _jsonDocumentDiscount,
        baseController: _jsonBaseController,
        taxController: _jsonTaxController,
      );
    }
    final raw = _jsonPayloadController.text.trim();
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final payload = Map<String, dynamic>.from(decoded);
      final expense = payload['expense'] is Map
          ? Map<String, dynamic>.from(payload['expense'] as Map)
          : payload;
      final rawLines = expense['lines'] is List
          ? expense['lines']
          : payload['items'] is List
              ? payload['items']
              : expense['items'] is List
                  ? expense['items']
                  : null;
      if (rawLines is List && rawLines.isNotEmpty) {
        final lines = rawLines
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
        final summary = ExpenseFormHelpers.summarizeLines(lines);
        final subtotal = (summary['subtotal'] as num?)?.toDouble() ?? 0;
        final tax = (summary['tax'] as num?)?.toDouble() ?? 0;
        return _previewDocumentDiscount(
          draft: _jsonDocumentDiscount,
          subtotalBeforeDiscount: subtotal,
          taxBeforeDiscount: tax,
        );
      }
      final total = ExpenseFormHelpers.parseNum(expense['total']);
      final tax = ExpenseFormHelpers.parseNum(
            expense['taxTotal'] ?? expense['vatTotal'] ?? expense['tax'],
          ) ??
          0;
      if (total == null) return null;
      final finalBase = (total - tax).clamp(0, double.infinity).toDouble();
      final grossBase = _jsonDocumentDiscount.grossBaseFromFinal(finalBase);
      final grossTax = _jsonDocumentDiscount.grossTaxFromFinal(
        finalBase: finalBase,
        finalTax: tax,
      );
      return _previewDocumentDiscount(
        draft: _jsonDocumentDiscount,
        subtotalBeforeDiscount: grossBase,
        taxBeforeDiscount: grossTax,
      );
    } catch (_) {
      return null;
    }
  }

  void _tryLoadJsonDocumentDiscountFromPayload(Map<String, dynamic> payload) {
    if (_jsonDocumentDiscount.hasDiscount) return;
    final expense = payload['expense'] is Map
        ? Map<String, dynamic>.from(payload['expense'] as Map)
        : payload;
    final rawLines = expense['lines'] is List
        ? expense['lines']
        : payload['items'] is List
            ? payload['items']
            : expense['items'] is List
                ? expense['items']
                : null;
    double? subtotalHint;
    if (rawLines is List && rawLines.isNotEmpty) {
      final lines = rawLines
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
      final summary = ExpenseFormHelpers.summarizeLines(lines);
      subtotalHint = (summary['subtotal'] as num?)?.toDouble();
    } else {
      final total = ExpenseFormHelpers.parseNum(expense['total']);
      final tax = ExpenseFormHelpers.parseNum(
        expense['taxTotal'] ?? expense['vatTotal'] ?? expense['tax'],
      );
      if (total != null) {
        final finalBase = (total - (tax ?? 0)).clamp(0, double.infinity);
        subtotalHint = finalBase.toDouble();
      }
    }
    _jsonDocumentDiscount.loadFromExpenseMap(
      expense,
      subtotalBeforeDiscountHint: subtotalHint,
    );
  }

  List<ExpenseAdvanceOption> _buildAdvanceOptions({
    String? providerId,
    String? vendorName,
    String? excludeExpenseId,
  }) {
    final normalizedProviderId = (providerId ?? '').trim().toLowerCase();
    final normalizedVendor = (vendorName ?? '').trim().toLowerCase();
    final excludedId = (excludeExpenseId ?? '').trim();
    final options = <ExpenseAdvanceOption>[];

    for (final item in _recentUploads) {
      final type = ExpenseDocumentTypeX.fromApi(item['expenseType']);
      if (!type.isAdvance) continue;

      final itemId = (item['id'] ?? '').trim();
      if (excludedId.isNotEmpty && itemId == excludedId) continue;

      final itemProviderId = (item['providerId'] ?? '').trim().toLowerCase();
      final itemVendor =
          ((item['vendor'] ?? item['providerName'] ?? '')).trim().toLowerCase();

      final matchesProvider = normalizedProviderId.isNotEmpty &&
          itemProviderId == normalizedProviderId;
      final matchesVendor = normalizedProviderId.isEmpty &&
          normalizedVendor.isNotEmpty &&
          itemVendor == normalizedVendor;

      final canUse = normalizedProviderId.isEmpty && normalizedVendor.isEmpty
          ? true
          : (matchesProvider || matchesVendor);
      if (!canUse) continue;

      options.add(ExpenseAdvanceOption.fromRecentMap(item));
    }

    options.sort((a, b) {
      final aDate = DateTime.tryParse(a.issueDate);
      final bDate = DateTime.tryParse(b.issueDate);
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      return b.issueDate.compareTo(a.issueDate);
    });
    return options;
  }

  Future<void> _pickFile() async {
    final result = await ExpenseFormHelpers.pickFile();
    if (result == null) return;
    await _acceptPickedExpenseFile(result.fileName, result.fileBytes);
  }

  Future<void> _acceptPickedExpenseFile(
    String fileName,
    Uint8List fileBytes,
  ) async {
    final validationError = _validateInvoiceUploadFile(
      fileName: fileName,
      fileBytes: fileBytes,
    );
    if (validationError != null) {
      if (!mounted) return;
      setState(() => _error = validationError);
      return;
    }
    if (!mounted) return;
    setState(() {
      _fileName = fileName;
      _fileBytes = fileBytes;
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
    if (_manualUseSummaryTotals) {
      final summaryValidation = ExpenseFormHelpers.validateSummaryTotals(
        base: _parseControllerAmount(_baseTotalController),
        tax: _parseControllerAmount(_taxTotalController),
        total: _parseControllerAmount(_totalController),
      );
      if (summaryValidation != null) {
        setState(() => _error = summaryValidation);
        return;
      }
    }
    final settlementError = _manualSettlement.validate();
    if (settlementError != null) {
      setState(() => _error = settlementError);
      return;
    }
    final discountPreview = _manualDiscountPreview();
    final discountValidationBase = discountPreview?.subtotalBeforeDiscount ??
        (() {
          final total = ExpenseFormHelpers.parseAmount(_totalController.text);
          final tax =
              ExpenseFormHelpers.parseAmount(_taxTotalController.text) ?? 0;
          if (total == null) return 0.0;
          return (total - tax).clamp(0, double.infinity).toDouble();
        })();
    final discountError =
        _manualDocumentDiscount.validate(discountValidationBase);
    if (discountError != null) {
      setState(() => _error = discountError);
      return;
    }
    for (final line in _lines) {
      if (line.descriptionController.text.trim().isEmpty ||
          line.quantity <= 0 ||
          line.baseUnitPrice <= 0 ||
          line.taxRate < 0 ||
          line.discountPercent < 0 ||
          line.discountPercent > 100 ||
          line.discountAmount < 0 ||
          line.discountAmount > line.grossSubtotal + 0.0001) {
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
      final expenseType = _manualSettlement.expenseType.apiValue;
      final advancePayment = _manualSettlement.buildAdvancePaymentPayload();
      final finalSettlement = _manualSettlement.buildFinalSettlementPayload();
      final effectiveDiscountPreview =
          discountPreview ?? _manualDiscountPreview();
      final summaryBase = _parseControllerAmount(_baseTotalController);
      final summaryTax = _parseControllerAmount(_taxTotalController);
      final summaryVatBreakdown = _manualUseSummaryTotals
          ? ExpenseFormHelpers.buildSummaryVatBreakdown(
              base: summaryBase,
              tax: summaryTax,
            )
          : null;
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
        lines: _manualUseSummaryTotals
            ? null
            : ExpenseFormHelpers.buildLinesPayload(_lines),
        providerId: _selectedProviderId,
        expenseType: expenseType,
        advancePayment: advancePayment,
        finalSettlement: finalSettlement,
        discountAmount: effectiveDiscountPreview == null
            ? (_manualDocumentDiscount.discountAmountController.text
                    .trim()
                    .isEmpty
                ? null
                : _manualDocumentDiscount.discountAmountController.text.trim())
            : effectiveDiscountPreview.discountAmount.toStringAsFixed(2),
        discountPercent: effectiveDiscountPreview == null
            ? (_manualDocumentDiscount.discountPercentController.text
                    .trim()
                    .isEmpty
                ? null
                : _manualDocumentDiscount.discountPercentController.text.trim())
            : effectiveDiscountPreview.discountPercent.toStringAsFixed(2),
        withholding: () {
          if (!_manualWithholding.enabled) return null;
          final buf = <String, dynamic>{};
          _manualWithholding.applyToExpensePayload(
            buf,
            taxableBase: double.tryParse(_baseTotalController.text.trim()) ?? 0,
            grossTotal: double.tryParse(_totalController.text.trim()) ?? 0,
          );
          return buf['withholding'] as Map<String, dynamic>?;
        }(),
        subtotal: _manualUseSummaryTotals && summaryBase != null
            ? summaryBase.toStringAsFixed(2)
            : null,
        vatBreakdown: summaryVatBreakdown,
        useSummaryTotals: _manualUseSummaryTotals ? true : null,
        taxSource: _manualUseSummaryTotals ? 'summary' : null,
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
      final createdLinesPayload = ExpenseFormHelpers.buildLinesPayload(
            _lines,
            useSummaryTotals: _manualUseSummaryTotals,
          ) ??
          const [];
      final createdLinesSummary =
          ExpenseFormHelpers.summarizeLines(createdLinesPayload);
      final responseUseSummaryTotals =
          ExpenseFormHelpers.shouldUseSummaryTotals(
        expense: response,
        storedTotal: ExpenseFormHelpers.parseNum(response['total'])?.toDouble(),
        storedTax: ExpenseFormHelpers.parseNum(
          response['taxTotal'] ?? response['vatTotal'] ?? response['tax'],
        )?.toDouble(),
        lines: response['lines'] is List
            ? (response['lines'] as List)
                .whereType<Map>()
                .map((entry) => Map<String, dynamic>.from(entry))
                .toList(growable: false)
            : response['items'] is List
                ? (response['items'] as List)
                    .whereType<Map>()
                    .map((entry) => Map<String, dynamic>.from(entry))
                    .toList(growable: false)
                : null,
      );
      setState(() {
        _recentUploads.insert(0, {
          if (newId != null && newId.isNotEmpty) 'id': newId,
          'vendor': _vendorController.text.trim(),
          'total': _totalController.text.trim(),
          'subtotal':
              (response['subtotal'] ?? _baseTotalController.text).toString(),
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
          'taxSource': (response['taxSource'] ?? response['totalsSource'] ?? '')
              .toString(),
          'discountAmount': (response['discountAmount'] ??
                  effectiveDiscountPreview?.discountAmount.toStringAsFixed(2) ??
                  '')
              .toString(),
          'discountPercent': (response['discountPercent'] ??
                  effectiveDiscountPreview?.discountPercent
                      .toStringAsFixed(2) ??
                  '')
              .toString(),
          'expenseType': (response['expenseType'] ?? expenseType).toString(),
          if (response['advancePayment'] is Map) ...{
            'advancePercent':
                ((response['advancePayment'] as Map)['percent'] ?? '')
                    .toString(),
            'advanceProjectBaseAmount':
                ((response['advancePayment'] as Map)['projectBaseAmount'] ?? '')
                    .toString(),
            'advanceTaxRate':
                ((response['advancePayment'] as Map)['taxRate'] ?? '')
                    .toString(),
          } else if (advancePayment != null) ...{
            'advancePercent': (advancePayment['percent'] ?? '').toString(),
            'advanceProjectBaseAmount':
                (advancePayment['projectBaseAmount'] ?? '').toString(),
            'advanceTaxRate': (advancePayment['taxRate'] ?? '').toString(),
          },
          if (response['finalSettlement'] is Map) ...{
            'finalAdvanceExpenseId':
                ((response['finalSettlement'] as Map)['advanceExpenseId'] ?? '')
                    .toString(),
            'finalAdvanceInvoiceNumber':
                ((response['finalSettlement'] as Map)['advanceInvoiceNumber'] ??
                        '')
                    .toString(),
            'settlementDeductedBase':
                ((response['finalSettlement'] as Map)['deductedBase'] ?? '')
                    .toString(),
            'settlementDeductedTax':
                ((response['finalSettlement'] as Map)['deductedTax'] ?? '')
                    .toString(),
            'settlementDeductedTotal':
                ((response['finalSettlement'] as Map)['deductedTotal'] ?? '')
                    .toString(),
            'settlementGrossBase':
                ((response['finalSettlement'] as Map)['grossBase'] ?? '')
                    .toString(),
            'settlementGrossTax':
                ((response['finalSettlement'] as Map)['grossTax'] ?? '')
                    .toString(),
            'settlementGrossTotal':
                ((response['finalSettlement'] as Map)['grossTotal'] ?? '')
                    .toString(),
            'settlementRemainingBase':
                ((response['finalSettlement'] as Map)['remainingBase'] ?? '')
                    .toString(),
            'settlementRemainingTax':
                ((response['finalSettlement'] as Map)['remainingTax'] ?? '')
                    .toString(),
            'settlementRemainingTotal':
                ((response['finalSettlement'] as Map)['remainingTotal'] ?? '')
                    .toString(),
          } else if (finalSettlement != null) ...{
            'finalAdvanceExpenseId':
                (finalSettlement['advanceExpenseId'] ?? '').toString(),
          },
          if (_dueDateController.text.trim().isNotEmpty)
            'due': _dueDateController.text.trim(),
          if ((createdLinesSummary['count'] as int? ?? 0) > 0)
            'linesCount': (createdLinesSummary['count'] as int).toString(),
          if ((createdLinesSummary['summary'] ?? '')
              .toString()
              .trim()
              .isNotEmpty)
            'linesSummary': (createdLinesSummary['summary'] ?? '').toString(),
          'useSummaryTotals': responseUseSummaryTotals ? 'true' : 'false',
          if (responseUseSummaryTotals)
            'linesSubtotal':
                (response['subtotal'] ?? _baseTotalController.text).toString()
          else if (createdLinesSummary['subtotal'] is num)
            'linesSubtotal':
                (createdLinesSummary['subtotal'] as num).toStringAsFixed(2),
          if (responseUseSummaryTotals)
            'linesTotal':
                (response['total'] ?? _totalController.text).toString()
          else if (createdLinesSummary['total'] is num)
            'linesTotal':
                (createdLinesSummary['total'] as num).toStringAsFixed(2),
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

  Future<void> _previewSelectedUploadedFile() async {
    final bytes = _fileBytes;
    final fileName = _fileName;
    if (bytes == null || fileName == null) return;
    final lowerName = fileName.toLowerCase();
    final isPdf = lowerName.endsWith('.pdf');
    final isImage = lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.jpe') ||
        lowerName.endsWith('.webp');
    if (isPdf) {
      await _previewSelectedPdf();
      return;
    }
    if (isImage) {
      await showExpenseImagePreviewDialog(
        context,
        fileName: fileName,
        fileBytes: bytes,
      );
    }
  }

  Widget _buildJsonImportTab(AppLocalizations l,
      {bool showInlineControls = true});
  Widget _buildBatchImportTab(AppLocalizations l,
      {bool showInlineControls = true});
  Widget _buildJsonStepRightContent(AppLocalizations l);
  Future<void> pickJsonPayloadFile();
  Future<void> pickJsonInvoiceFile();
  Future<void> fetchExpenseJsonPrompt();
  Future<void> copyPromptToClipboard();
  Future<void> submitExpenseJsonImport();
  Future<void> pickBatchDocuments();
  Future<void> applyBatchDocumentData(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  });
  Future<void> submitBatchImport();

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
    final manualDiscountPreview = _manualDiscountPreview();
    if (!_manualUseSummaryTotals) {
      if (hasLines && manualDiscountPreview != null) {
        _applyManualSummaryControllersFromLines(manualDiscountPreview);
      } else {
        _syncManualSummaryControllers(_ExpenseDocumentTotalField.total);
      }
    }
    final manualSummaryValidationError = _manualUseSummaryTotals
        ? ExpenseFormHelpers.validateSummaryTotals(
            base: _parseControllerAmount(_baseTotalController),
            tax: _parseControllerAmount(_taxTotalController),
            total: _parseControllerAmount(_totalController),
          )
        : null;
    final summarySubtotal = manualDiscountPreview != null
        ? ExpenseFormHelpers.formatAmount(
            manualDiscountPreview.subtotalBeforeDiscount,
          )
        : _manualUseSummaryTotals
            ? ExpenseFormHelpers.formatAmount(
                _parseControllerAmount(_baseTotalController),
              )
            : hasLines
                ? ExpenseFormHelpers.formatAmount(_linesSubtotal())
                : (() {
                    final total =
                        ExpenseFormHelpers.parseAmount(_totalController.text);
                    final tax = ExpenseFormHelpers.parseAmount(
                        _taxTotalController.text);
                    if (total == null) return '-';
                    if (tax == null) {
                      return ExpenseFormHelpers.formatAmount(total);
                    }
                    return ExpenseFormHelpers.formatAmount(
                      (total - tax).clamp(0, double.infinity),
                    );
                  })();
    final summaryDiscount = manualDiscountPreview != null &&
            manualDiscountPreview.discountAmount > 0.0001
        ? '${ExpenseFormHelpers.formatAmount(manualDiscountPreview.discountAmount)} · ${manualDiscountPreview.discountPercent.toStringAsFixed(2)}%'
        : null;
    final summaryDiscountedBase = manualDiscountPreview != null &&
            manualDiscountPreview.discountAmount > 0.0001
        ? ExpenseFormHelpers.formatAmount(manualDiscountPreview.taxableBase)
        : null;
    final summaryTax = manualDiscountPreview != null
        ? ExpenseFormHelpers.formatAmount(manualDiscountPreview.tax)
        : _manualUseSummaryTotals
            ? ExpenseFormHelpers.formatAmount(
                _parseControllerAmount(_taxTotalController),
              )
            : hasLines
                ? ExpenseFormHelpers.formatAmount(_linesTax())
                : ExpenseFormHelpers.formatAmount(
                    ExpenseFormHelpers.parseAmount(_taxTotalController.text),
                  );
    final summaryTotal = manualDiscountPreview != null
        ? ExpenseFormHelpers.formatAmount(manualDiscountPreview.total)
        : _manualUseSummaryTotals
            ? ExpenseFormHelpers.formatAmount(
                _parseControllerAmount(_totalController),
              )
            : hasLines
                ? ExpenseFormHelpers.formatAmount(
                    _linesSubtotal() + _linesTax())
                : ExpenseFormHelpers.formatAmount(
                    ExpenseFormHelpers.parseAmount(_totalController.text),
                  );
    final vatBreakdown = ExpenseVatBreakdownCard(
      breakdown: _vatBreakdown,
    );
    final summaryBar = ExpenseTotalsSummaryBar(
      subtotal: summarySubtotal,
      discount: summaryDiscount,
      discountedBase: summaryDiscountedBase,
      tax: summaryTax,
      total: summaryTotal,
    );
    final displayGroupId = resolveGroupId();
    final hasGroupSelected = displayGroupId.trim().isNotEmpty;
    final displayGroupName = _resolveGroupName();
    final manualAdvanceOptions = _buildAdvanceOptions(
      providerId: _selectedProviderId,
      vendorName: _vendorController.text.trim(),
    );
    final manualSettlementFields = ExpenseSettlementFields(
      settlement: _manualSettlement,
      advanceOptions: manualAdvanceOptions,
      enabled: !_submitting,
      onTypeChanged: (type) => setState(() {
        _manualSettlement.setExpenseType(type);
      }),
      onAdvanceExpenseChanged: (id) => setState(() {
        _manualSettlement.selectedAdvanceExpenseId = id;
      }),
      onChanged: () => setState(() {}),
    );
    final manualDiscountFields = ExpenseDocumentDiscountFields(
      discount: _manualDocumentDiscount,
      enabled: !_submitting,
      preview: manualDiscountPreview,
      onChanged: () => setState(() {}),
    );
    final manualWithholdingFields = ExpenseDocumentWithholdingFields(
      withholding: _manualWithholding,
      enabled: !_submitting,
      compactSummary: true,
      preview: _manualWithholding.buildPreview(
        taxableBase: double.tryParse(_baseTotalController.text.trim()) ?? 0,
        grossTotal: double.tryParse(_totalController.text.trim()) ?? 0,
      ),
      onChanged: () => setState(() {}),
    );
    final manualTotalsFields = ExpenseDocumentTotalsFields(
      baseController: _baseTotalController,
      taxController: _taxTotalController,
      totalController: _totalController,
      enabled: !_submitting,
      useSummaryTotals: _manualUseSummaryTotals,
      lockToLines: hasLines,
      validationError: manualSummaryValidationError,
      onSummaryModeChanged: (value) => setState(() {
        _manualUseSummaryTotals = value;
        if (!_manualUseSummaryTotals &&
            hasLines &&
            manualDiscountPreview != null) {
          _applyManualSummaryControllersFromLines(manualDiscountPreview);
        } else if (_manualUseSummaryTotals) {
          _syncManualSummaryControllers(_ExpenseDocumentTotalField.total);
        }
      }),
      onBaseChanged: (_) {
        _syncManualSummaryControllers(_ExpenseDocumentTotalField.base);
        setState(() {});
      },
      onTaxChanged: (_) {
        _syncManualSummaryControllers(_ExpenseDocumentTotalField.tax);
        setState(() {});
      },
      onTotalChanged: (_) {
        _syncManualSummaryControllers(_ExpenseDocumentTotalField.total);
        setState(() {});
      },
    );
    final formFields = ExpenseFormFields(
      groupName: displayGroupName,
      groupId: displayGroupId,
      providerPicker: providerPicker,
      vendorController: _vendorController,
      issueDateController: _issueDateController,
      vendorTaxIdController: _vendorTaxIdController,
      invoiceNumberController: _invoiceNumberController,
      dueDateController: _dueDateController,
      currencyController: _currencyController,
      notesController: _notesController,
      clientIdController: _clientIdController,
      settlementFields: manualSettlementFields,
      discountFields: manualDiscountFields,
      withholdingFields: manualWithholdingFields,
      totalsFields: manualTotalsFields,
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
      canSubmit: hasGroupSelected &&
          !(_manualSettlement.isFinal &&
              (_manualSettlement.selectedAdvanceExpenseId ?? '')
                  .trim()
                  .isEmpty),
    );
    final uploadWorkspace = AnimatedBuilder(
      animation: _importTabs,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          Widget buildImportTabsHeader() => TabBar(
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
                  Tab(height: 34, text: 'Lote'),
                ],
              );

          final importTabsHeader = buildImportTabsHeader();
          final manualWideTab = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: formFields),
              errorsAndSubmit,
            ],
          );
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
                      _buildJsonImportTab(
                        l,
                        showInlineControls: true,
                      ),
                      _buildBatchImportTab(
                        l,
                        showInlineControls: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          final currentTab = _importTabs.index;

          if (currentTab == 2) {
            final batchJobStatus =
                _expenseBatchJobStatusFromPayload(_batchJobStatus);
            final batchJobActive = _hasRunningBatchJob || _batchStartingJob;
            final batchJobCompleted =
                _isExpenseBatchJobTerminal(batchJobStatus) &&
                    batchJobStatus == 'completed';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildImportTabsHeader(),
                if (!batchJobCompleted) ...[
                  const SizedBox(height: 8),
                  _BatchCompactWorkflowIndicator(
                    selectedCount: (() {
                      final jobTotal =
                          _batchJobInt(_batchJobStatus?['totalFiles']);
                      if (jobTotal > 0) return jobTotal;
                      return _batchDocumentNames.length;
                    })(),
                    maxDocuments:
                        _ExpenseUploadScreenStateBase._maxBatchDocuments,
                    totalBytes: _batchDocumentBytes.fold<int>(
                      0,
                      (sum, bytes) => sum + bytes.length,
                    ),
                    submitting: _batchSubmitting ||
                        _batchGeneratingJson ||
                        batchJobActive,
                    hasGroupSelected: hasGroupSelected,
                    canImport: !batchJobActive &&
                        !_batchSubmitting &&
                        !_batchGeneratingJson &&
                        !batchJobCompleted &&
                        hasGroupSelected &&
                        _batchDocumentNames.isNotEmpty,
                    jobActive: batchJobActive,
                    jobCompleted: batchJobCompleted,
                    jobFailed: batchJobStatus == 'failed',
                    readyCount: _batchJobInt(_batchJobStatus?['readyCount']),
                    reviewCount: _batchJobInt(_batchJobStatus?['warningCount']),
                    duplicateCount:
                        _batchJobInt(_batchJobStatus?['duplicateCount']),
                    onPickDocuments: pickBatchDocuments,
                    onImport: submitBatchImport,
                    onClearSelection: _batchDocumentNames.isEmpty
                        ? null
                        : () => setState(() {
                              _resetBatchJobTracking(
                                clearResult: true,
                                clearCache: true,
                              );
                              _batchDocumentBytes.clear();
                              _batchDocumentNames.clear();
                              _batchSkippedDetails.clear();
                              _batchVerifyMessage = null;
                              _batchError = null;
                              _batchDetectedInvoices = 0;
                              _batchFileFilterIndex = 0;
                            }),
                  ),
                ],
                SizedBox(height: batchJobCompleted ? 6 : 10),
                Expanded(
                  child: _buildBatchImportTab(
                    l,
                    showInlineControls: false,
                  ),
                ),
              ],
            );
          }

          if (currentTab == 1) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildImportTabsHeader(),
                const SizedBox(height: 8),
                _JsonCompactWorkflowIndicator(
                  submitting: _jsonSubmitting || _jsonPromptLoading,
                  hasGroupSelected: hasGroupSelected,
                  activeStep: _jsonImportStep,
                  hasPayload: _jsonPayloadController.text.trim().isNotEmpty,
                  hasInvoiceFile:
                      (_jsonInvoiceFileName ?? '').trim().isNotEmpty,
                  onStepTapped: (step) =>
                      setState(() => _jsonImportStep = step),
                  onImport: submitExpenseJsonImport,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildJsonStepRightContent(l),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildImportTabsHeader(),
              const SizedBox(height: 8),
              _ManualCompactWorkflowIndicator(
                fileName: _fileName,
                fileBytes: _fileBytes,
                submitting: _submitting,
                hasGroupSelected: hasGroupSelected,
                onPickFile: _pickFile,
                onPreviewFile: (_fileName != null && _fileBytes != null)
                    ? _previewSelectedUploadedFile
                    : null,
                previewCtaLabel: (() {
                  final fileName = _fileName?.toLowerCase();
                  if (fileName == null) return null;
                  if (fileName.endsWith('.pdf')) return 'Abrir vista previa';
                  if (fileName.endsWith('.png') ||
                      fileName.endsWith('.jpg') ||
                      fileName.endsWith('.jpeg') ||
                      fileName.endsWith('.jpe') ||
                      fileName.endsWith('.webp')) {
                    return 'Ampliar imagen';
                  }
                  return null;
                })(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: manualWideTab,
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
                  autoEditExpenseId: _pendingAutoEditExpenseId,
                  onAutoEditHandled: (id) {
                    if (_pendingAutoEditExpenseId != id) return;
                    setState(() => _pendingAutoEditExpenseId = null);
                  },
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
                      autoEditExpenseId: _pendingAutoEditExpenseId,
                      onAutoEditHandled: (id) {
                        if (_pendingAutoEditExpenseId != id) return;
                        setState(() => _pendingAutoEditExpenseId = null);
                      },
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
    with _ExpenseUploadImportActionsSection, _ExpenseUploadImportTabsSection {
  @override
  void initState() {
    super.initState();
    unawaited(_resumeCachedBatchJobIfNeeded());
  }

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
  Future<void> applyBatchDocumentData(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  }) =>
      _applyBatchDocuments(files, selectedCount: selectedCount);
  @override
  Future<void> generateBatchJsonWithAi() => _generateBatchJsonWithAi();
  @override
  Future<void> submitBatchImport() => _submitBatchImport();
  @override
  List<Map<String, dynamic>> extractBatchInvoices(
          Map<String, dynamic> payload) =>
      _extractBatchInvoices(payload);
}
