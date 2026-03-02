import 'dart:async';

import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_models.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_normalizer.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_service.dart';

enum OcrExtractionStage {
  idle,
  extracting,
  extracted,
  saving,
  saved,
  error,
}

class InvoiceLinesOcrFlowState {
  final OcrExtractionStage stage;
  final List<OcrExtractedLineDraft> extractedLines;
  final String rawText;
  final double? confidence;
  final List<String> warnings;
  final String? methodUsed;
  final List<String> diagnostics;
  final String? extractionError;
  final OcrBulkSaveResult? saveResults;
  final OcrSaveSummary? saveSummary;

  const InvoiceLinesOcrFlowState({
    required this.stage,
    required this.extractedLines,
    required this.rawText,
    required this.confidence,
    required this.warnings,
    required this.methodUsed,
    required this.diagnostics,
    required this.extractionError,
    required this.saveResults,
    required this.saveSummary,
  });

  factory InvoiceLinesOcrFlowState.initial() {
    return const InvoiceLinesOcrFlowState(
      stage: OcrExtractionStage.idle,
      extractedLines: <OcrExtractedLineDraft>[],
      rawText: '',
      confidence: null,
      warnings: <String>[],
      methodUsed: null,
      diagnostics: <String>[],
      extractionError: null,
      saveResults: null,
      saveSummary: null,
    );
  }

  InvoiceLinesOcrFlowState copyWith({
    OcrExtractionStage? stage,
    List<OcrExtractedLineDraft>? extractedLines,
    String? rawText,
    double? confidence,
    List<String>? warnings,
    String? methodUsed,
    List<String>? diagnostics,
    String? extractionError,
    bool clearExtractionError = false,
    OcrBulkSaveResult? saveResults,
    bool clearSaveResults = false,
    OcrSaveSummary? saveSummary,
    bool clearSaveSummary = false,
  }) {
    return InvoiceLinesOcrFlowState(
      stage: stage ?? this.stage,
      extractedLines: extractedLines ?? this.extractedLines,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
      methodUsed: methodUsed ?? this.methodUsed,
      diagnostics: diagnostics ?? this.diagnostics,
      extractionError:
          clearExtractionError ? null : extractionError ?? this.extractionError,
      saveResults: clearSaveResults ? null : saveResults ?? this.saveResults,
      saveSummary: clearSaveSummary ? null : saveSummary ?? this.saveSummary,
    );
  }
}

class InvoiceLinesOcrFlowController {
  InvoiceLinesOcrFlowController({
    required InvoiceLinesOcrService service,
    OcrTelemetryHook? telemetry,
  })  : _service = service,
        _telemetry = telemetry;

  final InvoiceLinesOcrService _service;
  final OcrTelemetryHook? _telemetry;
  final StreamController<InvoiceLinesOcrFlowState> _stateController =
      StreamController<InvoiceLinesOcrFlowState>.broadcast();

  InvoiceLinesOcrFlowState _state = InvoiceLinesOcrFlowState.initial();

  InvoiceLinesOcrFlowState get state => _state;
  Stream<InvoiceLinesOcrFlowState> get stream => _stateController.stream;

  void _emit(InvoiceLinesOcrFlowState next) {
    _state = next;
    _stateController.add(_state);
  }

  Future<void> startExtraction(
    OcrImageFile file,
    String invoiceId, {
    double? taxRate,
  }) async {
    _emit(_state.copyWith(
      stage: OcrExtractionStage.extracting,
      clearExtractionError: true,
      clearSaveResults: true,
      clearSaveSummary: true,
    ));

    try {
      final response = await _service.extractInvoiceLinesFromImage(
        invoiceId: invoiceId,
        file: file,
        defaultTaxRate: taxRate,
      );
      _emit(_state.copyWith(
        stage: OcrExtractionStage.extracted,
        extractedLines: response.draftLines,
        rawText: response.rawText,
        confidence: response.confidence,
        warnings: response.warnings,
        methodUsed: response.methodUsed,
        diagnostics: response.diagnostics,
        clearExtractionError: true,
      ));
    } on OcrExtractionException catch (e) {
      _telemetry?.call('extraction_failed', {
        'invoiceId': invoiceId,
        'statusCode': e.statusCode,
        'debugMessage': e.debugMessage,
      });
      _emit(_state.copyWith(
        stage: OcrExtractionStage.error,
        extractionError: e.userMessage,
      ));
    } catch (e) {
      _telemetry?.call('extraction_failed', {
        'invoiceId': invoiceId,
        'error': e.toString(),
      });
      _emit(_state.copyWith(
        stage: OcrExtractionStage.error,
        extractionError: 'No se pudo procesar la imagen.',
      ));
    }
  }

  void updateExtractedLine(int index, Map<String, dynamic> patch) {
    if (index < 0 || index >= _state.extractedLines.length) return;
    final lines = List<OcrExtractedLineDraft>.from(_state.extractedLines);
    final current = lines[index].toJson();
    current.addAll(patch);
    lines[index] = normalizeExtractedLine(current, index);
    _emit(_state.copyWith(
      extractedLines: lines,
      stage: OcrExtractionStage.extracted,
    ));
  }

  void removeExtractedLine(int index) {
    if (index < 0 || index >= _state.extractedLines.length) return;
    final lines = List<OcrExtractedLineDraft>.from(_state.extractedLines)
      ..removeAt(index);
    final normalized = <OcrExtractedLineDraft>[];
    for (var i = 0; i < lines.length; i++) {
      normalized.add(normalizeExtractedLine(lines[i].toJson(), i));
    }
    _emit(_state.copyWith(
      extractedLines: normalized,
      stage: OcrExtractionStage.extracted,
    ));
  }

  void addExtractedLine() {
    final lines = List<OcrExtractedLineDraft>.from(_state.extractedLines);
    final nextIndex = lines.length;
    lines.add(normalizeExtractedLine(const <String, dynamic>{}, nextIndex));
    _emit(_state.copyWith(
      extractedLines: lines,
      stage: OcrExtractionStage.extracted,
    ));
  }

  Future<OcrBulkSaveResult> saveAllLines(String invoiceId) async {
    _emit(_state.copyWith(
      stage: OcrExtractionStage.saving,
      clearExtractionError: true,
      clearSaveResults: true,
      clearSaveSummary: true,
    ));

    final editedNormalized = <OcrExtractedLineDraft>[];
    for (var i = 0; i < _state.extractedLines.length; i++) {
      editedNormalized
          .add(normalizeExtractedLine(_state.extractedLines[i].toJson(), i));
    }

    final result = await _service.createInvoiceLinesBulk(
      invoiceId,
      editedNormalized,
    );

    final summary = OcrSaveSummary(
      total: result.total,
      savedCount: result.savedCount,
      failedCount: result.failedCount,
      failedReasons: result.failedReasons,
    );

    _emit(_state.copyWith(
      stage: OcrExtractionStage.saved,
      extractedLines: editedNormalized,
      saveResults: result,
      saveSummary: summary,
    ));

    return result;
  }

  void resetExtraction() {
    _emit(InvoiceLinesOcrFlowState.initial());
  }

  Future<void> dispose() async {
    await _stateController.close();
  }
}
