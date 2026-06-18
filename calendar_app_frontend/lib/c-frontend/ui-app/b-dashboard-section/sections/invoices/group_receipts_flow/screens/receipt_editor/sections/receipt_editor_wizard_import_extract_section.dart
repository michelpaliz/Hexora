part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardImportExtractSection
    on _ReceiptEditorWizardScreenState {
  void _applyReceiptLinesFromReceipt(Receipt receipt) {
    for (final line in _lines) {
      line.dispose();
    }
    _lines.clear();
    if (receipt.lines.isEmpty) {
      _lines.add(ReceiptLineDraft.empty());
      return;
    }
    for (final line in receipt.lines) {
      _lines.add(ReceiptLineDraft.fromLine(line));
    }
  }

  Future<Receipt?> _ensureDraftForImport() async {
    if (_draftReceipt != null && _draftReceipt!.id.trim().isNotEmpty) {
      return _draftReceipt;
    }
    return _saveDraft(showSavedSnack: false);
  }

  Future<void> _pickJsonImportFile() async {
    final l = AppLocalizations.of(context)!;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _jsonImportFileName = file.name;
        _jsonImportFileContent = null;
        _jsonImportError = l.invoiceLinesJsonImportInvalidPayload;
      });
      return;
    }
    setState(() {
      _jsonImportFileName = file.name;
      _jsonImportFileContent = utf8.decode(bytes, allowMalformed: true);
      _jsonImportError = null;
    });
  }

  void _clearJsonImportFile() {
    setState(() {
      _jsonImportFileName = null;
      _jsonImportFileContent = null;
      _jsonImportError = null;
    });
  }

  Future<void> _copyJsonPromptTemplate() async {
    final l = AppLocalizations.of(context)!;
    if (_jsonPromptLoading || _jsonImporting) return;
    final draft = await _ensureDraftForImport();
    if (draft == null || !mounted) return;
    setState(() => _jsonPromptLoading = true);
    try {
      final response = await _receiptsApi.getImportJsonPromptTemplate(draft.id);
      final prompt = JsonImportService.extractPromptText(response);
      if (prompt.isEmpty) {
        throw Exception(l.invoiceLinesJsonImportGenericError);
      }
      await copyTextWithManualFallbackDialog(
        context,
        text: prompt,
        successMessage: l.invoiceLinesJsonImportPromptCopied,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      showErrorSnack(
          context, msg.isEmpty ? l.invoiceLinesJsonImportGenericError : msg);
    } finally {
      if (mounted) setState(() => _jsonPromptLoading = false);
    }
  }

  Future<void> _importLinesFromJson({
    required String sourceText,
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (_jsonImporting) return;
    if (sourceText.trim().isEmpty) {
      setState(() => _jsonImportError = l.invoiceLinesJsonImportInvalidPayload);
      return;
    }

    final payload = JsonImportService.buildImportPayload(
      entity: JsonImportEntityType.receipt,
      sourceText: sourceText,
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );
    final draft = await _ensureDraftForImport();
    if (draft == null || !mounted) return;

    setState(() {
      _jsonImporting = true;
      _jsonImportError = null;
    });
    try {
      final response = await _receiptsApi.importJson(draft.id, payload);
      final refreshed = await _receiptsApi.getById(draft.id);
      if (!mounted) return;
      setState(() {
        _draftReceipt = refreshed;
        _didPersist = true;
        _applyReceiptLinesFromReceipt(refreshed);
        _markDraftSynced();
      });
      final importedCount = (response['importedCount'] is num)
          ? (response['importedCount'] as num).toInt()
          : refreshed.lines.length;
      showSuccessSnack(
          context, l.invoiceLinesJsonImportSuccess('$importedCount'));
      if (JsonImportService.extractRepairApplied(response)) {
        showInfoSnack(context, l.jsonAutoRepairAppliedSnack);
      }
    } catch (e) {
      if (!mounted) return;
      final backend = e.toString().replaceFirst('Exception: ', '').trim();
      String msg = backend;
      if (e is ReceiptsApiException) {
        msg = JsonImportService.mapErrorMessage(
          l: l,
          entity: JsonImportEntityType.receipt,
          statusCode: e.statusCode,
          backendMessage: backend,
        );
      }
      setState(
        () => _jsonImportError =
            msg.isEmpty ? l.invoiceLinesJsonImportGenericError : msg,
      );
    } finally {
      if (mounted) setState(() => _jsonImporting = false);
    }
  }

  Future<void> _importLinesFromJsonText(
    String rawText, {
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    await _importLinesFromJson(
      sourceText: rawText,
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );
  }

  Future<void> _importLinesFromJsonFile({
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    await _importLinesFromJson(
      sourceText: _jsonImportFileContent ?? '',
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );
  }

  Future<void> _pickExtractFile() async {
    if (_extractingLines) return;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'jpe', 'webp', 'pdf'],
      withData: true,
    );
    final file =
        (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) return;
    setState(() {
      _extractFileName = file.name;
      _extractFileBytes = bytes;
      _extractError = null;
    });
  }

  void _clearExtractedLines() {
    setState(() {
      _extractFileName = null;
      _extractFileBytes = null;
      _extractError = null;
      _extractedDraftLines = const [];
      _extractMethodUsed = null;
      _extractDiagnostics = const [];
    });
  }

  Future<void> _extractLinesWithOpenAi() async {
    final l = AppLocalizations.of(context)!;
    if (_extractingLines) return;
    final bytes = _extractFileBytes;
    final name = (_extractFileName ?? '').trim();
    if (bytes == null || bytes.isEmpty || name.isEmpty) {
      setState(() => _extractError = l.invoiceLinesJsonImportNoFile);
      return;
    }
    final draft = await _ensureDraftForImport();
    if (!mounted || draft == null) return;

    setState(() {
      _extractingLines = true;
      _extractError = null;
    });
    try {
      final response = await _receiptsApi.extractImageOpenAi(
        id: draft.id,
        bytes: bytes,
        fileName: name,
      );
      final raw = (response['lines'] ?? response['draftLines']);
      final rows = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false)
          : const <Map<String, dynamic>>[];
      final diagnosticsRaw = response['diagnostics'];
      final diagnostics = <String>[
        if (diagnosticsRaw is List)
          ...diagnosticsRaw
              .where((e) => e != null)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty),
        if (diagnosticsRaw is Map)
          ...diagnosticsRaw.entries.map((e) => '${e.key}: ${e.value}'),
        if (diagnosticsRaw is String && diagnosticsRaw.trim().isNotEmpty)
          diagnosticsRaw.trim(),
      ];
      setState(() {
        _extractedDraftLines = rows;
        _extractMethodUsed =
            (response['methodUsed'] ?? response['method'])?.toString().trim();
        _extractDiagnostics = diagnostics;
      });
    } on ReceiptsApiException catch (e) {
      if (!mounted) return;
      setState(() => _extractError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _extractError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _extractingLines = false);
    }
  }

  void _updateExtractedLineField(int index, String key, String value) {
    if (index < 0 || index >= _extractedDraftLines.length) return;
    final next = _extractedDraftLines
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: true);
    final current = Map<String, dynamic>.from(next[index]);
    if (key == 'description') {
      current[key] = value;
    } else {
      current[key] = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    next[index] = current;
    setState(() => _extractedDraftLines = next);
  }

  void _removeExtractedLine(int index) {
    if (index < 0 || index >= _extractedDraftLines.length) return;
    final next = _extractedDraftLines.toList(growable: true)..removeAt(index);
    setState(() => _extractedDraftLines = next);
  }

  void _addExtractedLine() {
    final next = _extractedDraftLines.toList(growable: true)
      ..add({
        'description': '',
        'quantity': 1,
        'unitPrice': 0,
        'taxRate': 21,
      });
    setState(() => _extractedDraftLines = next);
  }

  Future<void> _importExtractedLines({
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    if (_extractingLines || _jsonImporting) return;
    if (_extractedDraftLines.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final draft = await _ensureDraftForImport();
    if (!mounted || draft == null) return;

    setState(() {
      _jsonImporting = true;
      _jsonImportError = null;
    });
    try {
      final payload = <String, dynamic>{
        'lines': _extractedDraftLines,
        'overwrite': overwrite,
        'defaultTaxRate': defaultTaxRate,
      };
      final response = await _receiptsApi.importJson(draft.id, payload);
      final refreshed = await _receiptsApi.getById(draft.id);
      if (!mounted) return;
      setState(() {
        _draftReceipt = refreshed;
        _didPersist = true;
        _applyReceiptLinesFromReceipt(refreshed);
        _markDraftSynced();
      });
      final importedCount = JsonImportService.extractImportedCount(response);
      showSuccessSnack(
        context,
        l.invoiceLinesJsonImportSuccess(
          '${importedCount > 0 ? importedCount : _extractedDraftLines.length}',
        ),
      );
    } on ReceiptsApiException catch (e) {
      if (!mounted) return;
      setState(() => _jsonImportError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _jsonImportError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _jsonImporting = false);
    }
  }

  String _receiptNumber(AppLocalizations l) {
    final existing = _draftReceipt?.receiptNumber?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    return l.receiptDraftNumberPlaceholder;
  }
}
