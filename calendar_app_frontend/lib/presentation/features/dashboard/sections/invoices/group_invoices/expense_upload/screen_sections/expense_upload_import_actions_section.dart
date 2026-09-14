part of '../../expense_upload_screen.dart';

mixin _ExpenseUploadImportActionsSection on _ExpenseUploadScreenStateBase {
  List<String> _duplicateBatchNames(List<String> names) {
    final counts = <String, int>{};
    final originals = <String, String>{};
    for (final raw in names) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
      originals.putIfAbsent(key, () => trimmed);
    }
    return counts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => originals[entry.key] ?? entry.key)
        .toList()
      ..sort();
  }

  String _friendlyNetworkError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    final explicitCors = lower.contains('blocked by cors') ||
        lower.contains('access-control-allow-origin') ||
        lower.contains('cors');
    final looksLikeFetchFailure = lower.contains('failed to fetch') ||
        lower.contains('xmlhttprequest error');
    final gatewayFailure = lower.contains('502') ||
        lower.contains('bad gateway') ||
        lower.contains('504') ||
        lower.contains('gateway timeout');
    if (explicitCors) {
      return 'La peticiÃ³n fue bloqueada por CORS. El backend debe permitir este origen y responder OPTIONS para /api/expenses/import-json-batch/*.';
    }
    if (gatewayFailure) {
      return 'El servidor o proxy devolviÃƒÂ³ un 502/504 mientras procesaba el lote. Esto suele indicar que la generaciÃƒÂ³n AI tarda demasiado para este volumen. Prueba con lotes mÃƒÂ¡s pequeÃƒÂ±os (20-30 archivos) o aumenta el timeout del gateway.';
    }
    if (looksLikeFetchFailure) {
      return 'La peticiÃƒÂ³n no devolviÃƒÂ³ una respuesta utilizable. Puede ser CORS, un corte de red o un timeout del proxy/backend durante la generaciÃƒÂ³n AI del lote.';
    }
    return raw;
  }

  Future<void> _acceptJsonInvoiceFile(
    String fileName,
    Uint8List fileBytes,
  ) async {
    final validationError = _validateInvoiceUploadFile(
      fileName: fileName,
      fileBytes: fileBytes,
    );
    if (validationError != null) {
      if (!mounted) return;
      setState(() => _jsonError = validationError);
      return;
    }
    if (!mounted) return;
    setState(() {
      _jsonInvoiceFileBytes = fileBytes;
      _jsonInvoiceFileName = fileName;
      _jsonError = null;
    });
  }

  Future<void> _acceptJsonPayloadFile(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final text = utf8.decode(fileBytes);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('Invalid JSON');
      }
      _tryLoadJsonDocumentDiscountFromPayload(
        Map<String, dynamic>.from(decoded),
      );
      _tryLoadJsonSummaryControllersFromPayload(text);
      if (!mounted) return;
      setState(() {
        _jsonFileBytes = fileBytes;
        _jsonFileName = fileName;
        _jsonPayloadController.text = text;
        _jsonError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _jsonError = 'Invalid JSON');
    }
  }

  Future<void> _pickJsonInvoiceFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'jpe', 'png', 'webp'],
    );
    final file =
        (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    if (file == null || file.bytes == null) {
      setState(
        () => _jsonError =
            'Invoice file/photo is required and must be linked to the expense.',
      );
      return;
    }
    await _acceptJsonInvoiceFile(file.name, file.bytes!);
  }

  Future<void> _pickJsonPayloadFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final file =
        (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    if (file == null || file.bytes == null || file.bytes!.isEmpty) return;
    await _acceptJsonPayloadFile(file.name, file.bytes!);
  }

  Future<void> _fetchExpenseJsonPrompt() async {
    if (_jsonPromptLoading) return;
    setState(() {
      _jsonPromptLoading = true;
      _jsonError = null;
    });
    try {
      final response = await _api.getImportJsonPromptTemplate();
      final prompt = (response['promptTemplate'] ??
              response['prompt'] ??
              response['template'] ??
              response['text'] ??
              '')
          .toString();
      final message = (response['message'] ?? '').toString().trim();
      setState(() {
        _jsonPromptMessage = message;
        _jsonPromptText = prompt.isEmpty ? jsonEncode(response) : prompt;
      });
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      showSafeSnackBar(context, SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      showSafeSnackBar(context, SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _jsonPromptLoading = false);
      }
    }
  }

  Future<void> _pickBatchJsonFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final file =
        (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    if (file == null || file.bytes == null || file.bytes!.isEmpty) return;
    try {
      final text = utf8.decode(file.bytes!);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _batchError = 'Invalid JSON');
        return;
      }
      final invoices =
          _extractBatchInvoices(Map<String, dynamic>.from(decoded));
      setState(() {
        _batchJsonController.text = text;
        _batchDetectedInvoices = invoices.length;
        _batchError = null;
      });
    } catch (_) {
      setState(() => _batchError = 'Invalid JSON');
    }
  }

  Future<void> _pickBatchDocuments() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'jpe', 'png', 'webp'],
    );
    final files = picked?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    await _applyBatchDocuments(
      [
        for (final file in files)
          if (file.bytes != null)
            (
              fileName: file.name,
              fileBytes: file.bytes!,
            ),
      ],
      selectedCount: files.length,
    );
  }

  Future<void> _applyBatchDocuments(
    List<({String fileName, Uint8List fileBytes})> files, {
    required int selectedCount,
  }) async {
    if (files.isEmpty) return;
    _resetBatchJobTracking(clearResult: true, clearCache: true);

    const maxDocs = _ExpenseUploadScreenStateBase._maxBatchDocuments;
    final selectedTooMany = selectedCount > maxDocs;
    final filesToProcess =
        selectedTooMany ? files.take(maxDocs).toList() : files;

    final bytes = <Uint8List>[];
    final names = <String>[];
    final skippedDetails = <String>[];
    var skippedCount = 0;

    if (selectedTooMany) {
      final overflowCount = selectedCount - maxDocs;
      skippedDetails.add(
        'Se ignoraron $overflowCount archivo(s) por exceder el lÃ­mite de $maxDocs.',
      );
      for (final extra in files.skip(maxDocs).take(6)) {
        skippedDetails
            .add('${extra.fileName} â€” excede el lÃ­mite de selecciÃ³n.');
      }
    }

    for (final file in filesToProcess) {
      final validationError = _validateInvoiceUploadFile(
        fileName: file.fileName,
        fileBytes: file.fileBytes,
        maxSizeBytes: _ExpenseUploadScreenStateBase._maxBatchFileSizeBytes,
        emptyMessage: 'Falta archivo/documento para una o mas facturas.',
        unsupportedTypeMessage:
            'Formato de archivo no soportado (PDF/JPG/JPEG/JPE/PNG/WEBP).',
        tooLargeMessageBuilder: (fileName, _, __) =>
            'File "$fileName" exceeds 10MB. Max file size is 10MB.',
      );
      if (validationError != null) {
        skippedCount++;
        skippedDetails.add('${file.fileName} â€” $validationError');
        continue;
      }
      bytes.add(file.fileBytes);
      names.add(file.fileName);
    }

    final duplicateNames = _duplicateBatchNames(names);
    if (duplicateNames.isNotEmpty) {
      skippedDetails.add(
        'Nombres duplicados detectados: ${duplicateNames.take(6).join(', ')}'
        '${duplicateNames.length > 6 ? 'â€¦' : ''}. RenÃ³mbralos para evitar cruces al enlazar.',
      );
    }

    if (bytes.isEmpty) {
      if (!mounted) return;
      setState(() {
        _batchSkippedDetails = skippedDetails;
        _batchError =
            'No valid files were loaded. Verify type/size and try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _batchDocumentBytes = bytes;
      _batchDocumentNames = names;
      _batchSkippedDetails = skippedDetails;
      if (selectedTooMany || skippedCount > 0) {
        final warnings = <String>[
          if (selectedTooMany)
            'Selected $selectedCount; only first $maxDocs were loaded.',
          if (skippedCount > 0) '$skippedCount file(s) were skipped.',
        ];
        _batchError = warnings.join(' ');
      } else {
        _batchError = null;
      }
      _batchVerifyMessage = null;
    });
  }

  Future<void> _generateBatchJsonWithAi() async {
    await _submitBatchImport();
  }

  List<Map<String, dynamic>> _extractBatchInvoices(
      Map<String, dynamic> payload) {
    if (payload['invoices'] is List) {
      return (payload['invoices'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (payload['expenses'] is List) {
      return (payload['expenses'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (payload['items'] is List) {
      return (payload['items'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String? _invoiceSourceFileName(Map<String, dynamic> invoice) {
    final candidates = <dynamic>[
      invoice['fileName'],
      invoice['sourceFileName'],
      invoice['source_file_name'],
      if (invoice['expense'] is Map) (invoice['expense'] as Map)['fileName'],
      if (invoice['expense'] is Map)
        (invoice['expense'] as Map)['sourceFileName'],
    ];
    for (final c in candidates) {
      final text = c?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  bool _verifyBatchLinking({
    required List<Map<String, dynamic>> invoices,
    required List<String> uploadedFileNames,
  }) {
    if (invoices.isEmpty) {
      _batchVerifyMessage = 'No se detectaron facturas en el JSON.';
      return false;
    }
    if (uploadedFileNames.isEmpty) {
      _batchVerifyMessage = 'Falta archivo/documento para una o mÃ¡s facturas.';
      return false;
    }

    final expectedNames = invoices
        .map(_invoiceSourceFileName)
        .whereType<String>()
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final hasNamesForAll = expectedNames.length == invoices.length;
    final uploaded = uploadedFileNames
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final duplicateNames = _duplicateBatchNames(uploadedFileNames);
    if (duplicateNames.isNotEmpty) {
      _batchVerifyMessage =
          'Hay nombres de archivo duplicados en la selecciÃ³n: '
          '${duplicateNames.take(6).join(', ')}${duplicateNames.length > 6 ? 'â€¦' : ''}. '
          'RenÃ³mbralos antes de importar para enlazar cada gasto correctamente.';
      return false;
    }

    if (hasNamesForAll) {
      final missing =
          expectedNames.where((n) => !uploaded.contains(n)).toList();
      if (missing.isNotEmpty) {
        _batchVerifyMessage =
            'No se pudo enlazar todos los documentos con las facturas del JSON. '
            'Faltan coincidencias para: ${missing.take(6).join(', ')}'
            '${missing.length > 6 ? 'â€¦' : ''}.';
        return false;
      }
      _batchVerifyMessage = 'Enlace verificado por nombre.';
      return true;
    }

    if (uploadedFileNames.length == invoices.length) {
      _batchVerifyMessage =
          'Enlace verificado por orden (fallback: mismo nÃºmero de archivos y facturas).';
      return true;
    }

    _batchVerifyMessage =
        'No se pudo enlazar todos los documentos con las facturas del JSON.';
    return false;
  }

  bool _validateBatchSuccess(Map<String, dynamic> response) {
    final status = (response['_statusCode'] is num)
        ? (response['_statusCode'] as num).toInt()
        : 0;
    if (status != 201) return false;

    final itemsRaw =
        response['items'] ?? response['results'] ?? response['data'];
    if (itemsRaw is! List || itemsRaw.isEmpty) return false;
    for (final item in itemsRaw) {
      if (item is! Map) return false;
      final expenseId = (item['expenseId'] ?? item['id'] ?? item['_id'] ?? '')
          .toString()
          .trim();
      final blob = (item['invoiceBlobName'] ?? '').toString().trim();
      final linked = item['fileLinked'] == true;
      if (expenseId.isEmpty || blob.isEmpty || !linked) return false;
    }
    return true;
  }

  // ignore: unused_element
  Future<void> _submitBatchImportLegacy() async {
    if (_batchSubmitting || _batchGeneratingJson) return;
    final attemptId = 'expbatch_${DateTime.now().microsecondsSinceEpoch}';
    final groupId = resolveGroupId().trim();
    if (groupId.isEmpty) {
      _logExpenseAttempt(
        route: 'import_batch',
        attemptId: attemptId,
        hasGroupId: false,
        groupId: '',
        blockedByValidation: true,
        detail: 'missing_group_id',
      );
      setState(
          () => _batchError = 'Debes seleccionar un grupo antes de importar.');
      return;
    }

    if (_batchDocumentBytes.isEmpty || _batchDocumentNames.isEmpty) {
      setState(() => _batchError = 'Upload at least 1 document first.');
      return;
    }

    Map<String, dynamic> payload;
    final raw = _batchJsonController.text.trim();
    if (raw.isEmpty) {
      setState(() => _batchGeneratingJson = true);
      try {
        final generated = await _api.generateBatchJsonWithAi(
          documentFilesBytes: _batchDocumentBytes,
          documentFileNames: _batchDocumentNames,
          groupId: groupId,
        );
        final payloadRaw = generated['payload'] ??
            generated['json'] ??
            generated['data'] ??
            generated['result'];
        if (payloadRaw == null) {
          if (!mounted) return;
          setState(
              () => _batchError = 'AI did not return a valid JSON payload.');
          return;
        }
        final generatedText = payloadRaw is String
            ? payloadRaw
            : const JsonEncoder.withIndent('  ').convert(payloadRaw);
        final decoded = jsonDecode(generatedText);
        if (decoded is! Map) {
          if (!mounted) return;
          setState(() => _batchError = 'AI output must be a JSON object.');
          return;
        }
        payload = Map<String, dynamic>.from(decoded);
        final invoices = _extractBatchInvoices(payload);
        _batchJsonController.text = generatedText;
        _batchDetectedInvoices = invoices.length;
      } on ExpensesApiException catch (e) {
        if (!mounted) return;
        setState(() => _batchError = e.message);
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() => _batchError = _friendlyNetworkError(e));
        return;
      } finally {
        if (mounted) {
          setState(() => _batchGeneratingJson = false);
        }
      }
    } else {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          setState(() => _batchError = 'Invalid JSON');
          return;
        }
        payload = Map<String, dynamic>.from(decoded);
      } catch (_) {
        setState(() => _batchError = 'Invalid JSON');
        return;
      }
    }

    final invoices = _extractBatchInvoices(payload);
    final okLinking = _verifyBatchLinking(
      invoices: invoices,
      uploadedFileNames: _batchDocumentNames,
    );
    if (!okLinking) {
      _logExpenseAttempt(
        route: 'import_batch',
        attemptId: attemptId,
        hasGroupId: true,
        groupId: groupId,
        blockedByValidation: true,
        detail: 'link_verification_failed',
      );
      setState(() => _batchError = _batchVerifyMessage);
      return;
    }

    payload['groupId'] = groupId;

    setState(() {
      _batchSubmitting = true;
      _batchError = null;
    });
    _logExpenseAttempt(
      route: 'import_batch',
      attemptId: attemptId,
      hasGroupId: true,
      groupId: groupId,
      blockedByValidation: false,
    );
    try {
      final response = await _api.importJsonBatch(
        payload: payload,
        documentFilesBytes: _batchDocumentBytes,
        documentFileNames: _batchDocumentNames,
        groupId: groupId,
      );
      if (!_validateBatchSuccess(response)) {
        setState(
          () => _batchError =
              'No se pudo enlazar todos los documentos con las facturas del JSON.',
        );
        return;
      }

      if (!mounted) return;
      showSafeSnackBar(
        context,
        const SnackBar(content: Text('ImportaciÃ³n batch completada.')),
      );
      await loadRecentUploads();
      if (!mounted) return;
      final importedFilesCountBeforeRefresh = _batchDocumentNames.length;
      setState(() {
        _batchJsonController.clear();
        _batchDocumentBytes = [];
        _batchDocumentNames = [];
        _batchDetectedInvoices = 0;
        _batchVerifyMessage = 'ImportaciÃ³n completada. Recargando resumen...';
      });
      widget.onUploaded?.call();
      if (!mounted) return;
      final importedFilesCount = importedFilesCountBeforeRefresh;
      setState(() {
        _batchVerifyMessage =
            'Ãšltima importaciÃ³n completada correctamente ($importedFilesCount archivo${importedFilesCount == 1 ? '' : 's'}).';
        _batchSkippedDetails = [];
        _batchError = null;
        _batchFileFilterIndex = 0;
        _batchErrorsExpanded = false;
      });
    } on ExpensesApiException catch (e) {
      var message = e.message;
      if (e.statusCode == 400) {
        final lower = e.message.toLowerCase();
        if (lower.contains('groupid')) {
          message = 'Debes seleccionar un grupo antes de importar.';
        } else if (lower.contains('unexpected file field')) {
          message = 'El servidor rechazÃ³ el formato del lote: ${e.message} '
              'Archivos seleccionados: ${_batchDocumentNames.length}.';
        }
      } else if (e.statusCode == 413) {
        message =
            'Upload is too large for the server limit (413). Reduce total files/size or contact support to increase upload limit.';
      } else if (e.statusCode == 502 || e.statusCode == 504) {
        message =
            'El servidor devolviÃƒÂ³ un ${e.statusCode} durante la importaciÃƒÂ³n batch. Esto suele significar que el lote tardÃƒÂ³ demasiado para el proxy/gateway. Prueba con lotes mÃƒÂ¡s pequeÃƒÂ±os (20-30 archivos).';
      } else if (e.statusCode == 500) {
        message = 'Error al importar. Intenta de nuevo.';
      }
      if (!mounted) return;
      setState(() {
        _batchError = message;
        if (_batchSkippedDetails.isEmpty && _batchDocumentNames.isNotEmpty) {
          _batchSkippedDetails = [
            'Archivos seleccionados en el lote: ${_batchDocumentNames.length}.',
            'Primeros archivos: ${_batchDocumentNames.take(6).join(', ')}'
                '${_batchDocumentNames.length > 6 ? 'â€¦' : ''}.',
          ];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _batchError = _friendlyNetworkError(e));
    } finally {
      if (mounted) setState(() => _batchSubmitting = false);
    }
  }

  String _describeBatchJobState(Map<String, dynamic>? payload) {
    return _expenseBatchJobUiMessage(payload);
  }

  void _syncBatchIssues({
    Map<String, dynamic>? statusPayload,
    Map<String, dynamic>? resultPayload,
  }) {
    _batchSkippedDetails = <String>{
      ...batchSkippedDetails,
      ..._expenseBatchIssuesFromPayload(statusPayload),
      ..._expenseBatchIssuesFromPayload(resultPayload),
    }.toList();
  }

  void _stopBatchJobPolling() {
    _batchJobPollTimer?.cancel();
    _batchJobPollTimer = null;
    _batchPollingInFlight = false;
  }

  void _startBatchJobPolling() {
    if ((_batchJobId ?? '').trim().isEmpty) return;
    _stopBatchJobPolling();
    _pollBatchJobStatus();
    _batchJobPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollBatchJobStatus();
    });
  }

  Future<void> _fetchBatchJobResult({bool silent = false}) async {
    final jobId = (_batchJobId ?? '').trim();
    if (jobId.isEmpty || _batchResultLoading) return;
    _batchResultLoading = true;
    try {
      final result = await _api.getBatchExpensePreviewJobResult(jobId);
      if (!mounted) return;
      setState(() {
        _batchJobResult = result;
        _batchPreviewItems = _expenseBatchPreviewItemsFromPayload(result);
        _syncBatchIssues(resultPayload: result);
        _batchErrorsExpanded = false;
      });
      _cacheBatchJobSnapshot();
    } on ExpensesApiException catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _batchError =
            'El analisis termino, pero no se pudieron cargar los detalles. ${e.message}';
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _batchError =
            'El analisis termino, pero no se pudieron cargar los detalles. ${_friendlyNetworkError(e)}';
      });
    } finally {
      _batchResultLoading = false;
    }
  }

  Future<void> _handleCompletedBatchJob(
      Map<String, dynamic> statusPayload) async {
    await _fetchBatchJobResult(silent: true);
    if (!mounted) return;

    final readyCount = _batchJobInt(statusPayload['readyCount']);
    final warningCount = _batchJobInt(statusPayload['warningCount']);
    final duplicateCount = _batchJobInt(statusPayload['duplicateCount']);
    final failedCount = _batchJobInt(statusPayload['failedCount']);
    final message = _batchJobFirstText([
      statusPayload['message'],
      'Previsualizacion lista. Revisa y confirma los gastos seleccionados.',
    ]);

    setState(() {
      _batchSubmitting = false;
      _batchStartingJob = false;
      _batchError = null;
      _batchVerifyMessage = message;
      _syncBatchIssues(
        statusPayload: statusPayload,
        resultPayload: _batchJobResult,
      );
      _batchErrorsExpanded = false;
    });
    _cacheBatchJobSnapshot();

    if (mounted) {
      showSafeSnackBar(
        context,
        SnackBar(
          content: Text(
            'Analisis listo. Preparados: $readyCount · Revision: $warningCount · Duplicados: $duplicateCount · Fallidos: $failedCount',
          ),
        ),
      );
    }
  }

  Future<void> _handleFailedBatchJob(Map<String, dynamic> statusPayload) async {
    await _fetchBatchJobResult(silent: true);
    if (!mounted) return;

    final issues = <String>{
      ..._expenseBatchIssuesFromPayload(statusPayload),
      ..._expenseBatchIssuesFromPayload(_batchJobResult),
    }.toList();
    final fallbackMessage = _describeBatchJobState(statusPayload);
    final errorMessage = issues.isNotEmpty ? issues.first : fallbackMessage;

    setState(() {
      _batchSubmitting = false;
      _batchStartingJob = false;
      _batchError = errorMessage;
      _batchVerifyMessage = fallbackMessage;
      _batchSkippedDetails = issues;
      _batchErrorsExpanded = false;
    });
    _cacheBatchJobSnapshot();
  }

  Future<void> _pollBatchJobStatus() async {
    final jobId = (_batchJobId ?? '').trim();
    if (jobId.isEmpty || _batchPollingInFlight) return;

    _batchPollingInFlight = true;
    try {
      final statusPayload = await _api.getBatchExpensePreviewJobStatus(jobId);
      if (!mounted) return;

      final normalizedStatus = _expenseBatchJobStatusFromPayload(statusPayload);
      final message = _describeBatchJobState(statusPayload);

      setState(() {
        _batchJobStatus = statusPayload;
        _batchVerifyMessage = message;
        _syncBatchIssues(statusPayload: statusPayload);
        if (!_isExpenseBatchJobTerminal(normalizedStatus)) {
          _batchError = null;
        }
      });
      _cacheBatchJobSnapshot();

      if (_isExpenseBatchJobTerminal(normalizedStatus)) {
        _stopBatchJobPolling();
        if (normalizedStatus == 'completed') {
          await _handleCompletedBatchJob(statusPayload);
        } else {
          await _handleFailedBatchJob(statusPayload);
        }
      }
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      final activeStatus = _expenseBatchJobStatusFromPayload(_batchJobStatus);
      if (_isExpenseBatchJobTerminal(activeStatus)) return;
      setState(() {
        _batchError =
            'No se pudo actualizar el progreso del lote. ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      final activeStatus = _expenseBatchJobStatusFromPayload(_batchJobStatus);
      if (_isExpenseBatchJobTerminal(activeStatus)) return;
      setState(() {
        _batchError =
            'No se pudo actualizar el progreso del lote. ${_friendlyNetworkError(e)}';
      });
    } finally {
      _batchPollingInFlight = false;
    }
  }

  Future<void> _resumeCachedBatchJobIfNeeded() async {
    if (_hasTrackedBatchJob) {
      if (_hasRunningBatchJob) {
        _startBatchJobPolling();
      }
      return;
    }
    final restored = _restoreCachedBatchJobSnapshot();
    if (!restored) {
      final persisted = await _restorePersistedBatchJobMapping();
      if (!persisted || !mounted) return;
    }
    final restoredStatus = _expenseBatchJobStatusFromPayload(_batchJobStatus);
    _batchVerifyMessage = _describeBatchJobState(_batchJobStatus);
    _syncBatchIssues(
      statusPayload: _batchJobStatus,
      resultPayload: _batchJobResult,
    );
    if (_isExpenseBatchJobTerminal(restoredStatus)) return;
    _startBatchJobPolling();
  }

  Future<void> _submitBatchImport() async {
    if (_batchSubmitting || _batchGeneratingJson || _batchStartingJob) return;
    final attemptId = 'expbatch_${DateTime.now().microsecondsSinceEpoch}';
    final groupId = resolveGroupId().trim();
    if (groupId.isEmpty) {
      _logExpenseAttempt(
        route: 'import_batch',
        attemptId: attemptId,
        hasGroupId: false,
        groupId: '',
        blockedByValidation: true,
        detail: 'missing_group_id',
      );
      setState(
          () => _batchError = 'Debes seleccionar un grupo antes de importar.');
      return;
    }

    if (_batchDocumentBytes.isEmpty || _batchDocumentNames.isEmpty) {
      setState(() => _batchError = 'Upload at least 1 document first.');
      return;
    }

    if (_hasRunningBatchJob) {
      setState(() {
        _batchError =
            'Ya hay un lote en proceso. Puedes salir de esta pantalla mientras se completa el analisis.';
      });
      return;
    }

    _resetBatchJobTracking(clearResult: true, clearCache: true);
    setState(() {
      _batchSubmitting = true;
      _batchStartingJob = true;
      _batchError = null;
      _batchVerifyMessage = 'Subiendo documentos...';
      _batchErrorsExpanded = false;
    });
    _logExpenseAttempt(
      route: 'import_batch',
      attemptId: attemptId,
      hasGroupId: true,
      groupId: groupId,
      blockedByValidation: false,
    );
    try {
      final currency = _currencyController.text.trim();
      final response = await _api.startBatchExpensePreviewJob(
        documentFilesBytes: _batchDocumentBytes,
        documentFileNames: _batchDocumentNames,
        groupId: groupId,
        currency: currency.isEmpty ? null : currency,
      );
      final jobId = _batchJobText(response['jobId']);
      final backgroundJobId = _batchJobText(response['backgroundJobId']);
      if (jobId.isEmpty) {
        throw Exception('El backend no devolvio un jobId valido.');
      }

      if (!mounted) return;
      setState(() {
        _batchJobId = jobId;
        _batchBackgroundJobId =
            backgroundJobId.isEmpty ? _batchBackgroundJobId : backgroundJobId;
        _batchJobStatus = Map<String, dynamic>.from(response);
        _batchVerifyMessage =
            'Procesando en segundo plano. Puedes salir de esta pantalla.';
        _batchSubmitting = false;
        _batchStartingJob = false;
      });
      _cacheBatchJobSnapshot();
      await _persistBatchJobMapping();
      if (backgroundJobId.isNotEmpty) {
        OcrImportJobsStore.instance.trackStartedJob(
          backgroundJobId: backgroundJobId,
          totalFiles: _batchDocumentNames.length,
        );
      }
      _startBatchJobPolling();
      if (!mounted) return;
      showSafeSnackBar(
        context,
        const SnackBar(
          content: Text(
            'Tus documentos se estan procesando en segundo plano. Puedes salir de esta pantalla y te avisaremos cuando esten listos.',
          ),
        ),
      );
    } on ExpensesApiException catch (e) {
      var message = e.message;
      if (e.statusCode == 400) {
        final lower = e.message.toLowerCase();
        if (lower.contains('groupid')) {
          message = 'Debes seleccionar un grupo antes de importar.';
        }
      } else if (e.statusCode == 413) {
        message =
            'Upload is too large for the server limit (413). Reduce total files/size or contact support to increase upload limit.';
      } else if (e.statusCode == 502 || e.statusCode == 504) {
        message =
            'El servidor devolvio un ${e.statusCode} al iniciar el lote. Prueba con menos archivos o revisa el timeout del gateway.';
      } else if (e.statusCode == 500) {
        message = 'Error al iniciar el analisis. Intenta de nuevo.';
      }
      if (!mounted) return;
      setState(() {
        _batchError = message;
        _batchVerifyMessage = 'No se pudo iniciar el analisis del lote.';
        if (_batchSkippedDetails.isEmpty && _batchDocumentNames.isNotEmpty) {
          _batchSkippedDetails = [
            'Archivos seleccionados en el lote: ${_batchDocumentNames.length}.',
            'Primeros archivos: ${_batchDocumentNames.take(6).join(', ')}'
                '${_batchDocumentNames.length > 6 ? '...' : ''}.',
          ];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _batchError = _friendlyNetworkError(e);
        _batchVerifyMessage = 'No se pudo iniciar el analisis del lote.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _batchSubmitting = false;
          _batchStartingJob = false;
        });
      }
    }
  }

  Future<void> confirmBatchPreviewImport() async {
    if (_batchSubmitting || _batchGeneratingJson || _batchStartingJob) return;
    final groupId = resolveGroupId().trim();
    if (groupId.isEmpty) {
      setState(
          () => _batchError = 'Debes seleccionar un grupo antes de importar.');
      return;
    }

    final selected = _batchPreviewItems
        .where((item) => item.selected && item.canSelect)
        .toList(growable: false);
    if (selected.isEmpty) {
      setState(() {
        _batchError =
            'Selecciona al menos un gasto listo para importar. Los duplicados y fallidos se omiten por seguridad.';
      });
      return;
    }

    setState(() {
      _batchSubmitting = true;
      _batchError = null;
      _batchVerifyMessage = 'Importando gastos seleccionados...';
    });

    try {
      final response = await _api.confirmBatchExpenseImports(
        groupId: groupId,
        items: [
          for (final item in selected)
            {
              'tempId': item.tempId,
              'fileName': item.fileName,
              'prediction': Map<String, dynamic>.from(item.prediction),
              'confirm': true,
            },
        ],
      );
      if (!mounted) return;
      final importedCount = _batchJobInt(response['importedCount']);
      final skippedCount = _batchJobInt(response['skippedCount']);
      final duplicateCount = _batchJobInt(response['duplicateCount']);
      setState(() {
        _batchSubmitting = false;
        _batchConfirmResult = response;
        _batchVerifyMessage =
            'Importacion confirmada. Importados: $importedCount Â· Omitidos: $skippedCount Â· Duplicados: $duplicateCount';
      });
      await loadRecentUploads();
      if (!mounted) return;
      widget.onUploaded?.call();
      showSafeSnackBar(
        context,
        SnackBar(
          content:
              Text('Importados: $importedCount Â· Omitidos: $skippedCount'),
        ),
      );
    } on ExpensesApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _batchSubmitting = false;
        _batchError = e.message;
        _batchVerifyMessage = 'No se pudieron importar los seleccionados.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _batchSubmitting = false;
        _batchError = _friendlyNetworkError(e);
        _batchVerifyMessage = 'No se pudieron importar los seleccionados.';
      });
    }
  }

  Future<void> exportBatchIncidentExcel() async {
    final batchId = (_batchJobId ?? '').trim();
    if (_batchExportingIncidents || batchId.isEmpty) return;
    setState(() {
      _batchExportingIncidents = true;
      _batchError = null;
    });
    try {
      final export = await _api.downloadBatchIncidentExport(batchId);
      await launchFileDownload(
        export.bytes,
        fileName: export.fileName,
        mimeType: export.contentType,
      );
      if (!mounted) return;
      showSafeSnackBar(
        context,
        const SnackBar(content: Text('Excel de incidencias descargado.')),
      );
    } catch (_) {
      if (!mounted) return;
      showSafeSnackBar(
        context,
        const SnackBar(
          content: Text('No se pudo generar el Excel de incidencias.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _batchExportingIncidents = false;
        });
      }
    }
  }

  Future<void> _copyPromptToClipboard() async {
    final text = (_jsonPromptText ?? '').trim();
    if (text.isEmpty) return;
    await copyTextWithManualFallbackDialog(
      context,
      text: text,
      successMessage: 'Prompt copied',
    );
  }

  Future<void> _submitExpenseJsonImport() async {
    if (_jsonSubmitting) return;
    final attemptId = _newImportAttemptId();
    final resolvedGroupIdAtStart = resolveGroupId().trim();
    if (resolvedGroupIdAtStart.isEmpty) {
      _logExpenseAttempt(
        route: 'import',
        attemptId: attemptId,
        hasGroupId: false,
        groupId: '',
        blockedByValidation: true,
        detail: 'missing_group_id',
      );
      setState(() => _jsonError = _requiredGroupMessage());
      return;
    }
    final raw = _jsonPayloadController.text.trim();
    if (raw.isEmpty && (_jsonFileBytes == null || _jsonFileBytes!.isEmpty)) {
      _logImportEvent('validation', attemptId, detail: 'missing_json');
      setState(() => _jsonError = 'Missing JSON');
      return;
    }

    dynamic decoded;
    if (raw.isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        _logImportEvent('validation', attemptId, detail: 'invalid_json_text');
        setState(() => _jsonError = 'Invalid JSON');
        return;
      }
    } else {
      try {
        decoded = jsonDecode(utf8.decode(_jsonFileBytes!));
      } catch (_) {
        _logImportEvent('validation', attemptId, detail: 'invalid_json_file');
        setState(() => _jsonError = 'Invalid JSON');
        return;
      }
    }

    if (decoded is! Map) {
      _logImportEvent('validation', attemptId, detail: 'json_not_object');
      setState(() => _jsonError = 'JSON payload must be an object.');
      return;
    }

    final payload = Map<String, dynamic>.from(decoded);
    final expense = payload['expense'] is Map
        ? Map<String, dynamic>.from(payload['expense'] as Map)
        : <String, dynamic>{};
    final invoice = payload['invoice'] is Map
        ? Map<String, dynamic>.from(payload['invoice'] as Map)
        : <String, dynamic>{};
    final store = payload['store'] is Map
        ? Map<String, dynamic>.from(payload['store'] as Map)
        : <String, dynamic>{};
    final client = payload['client'] is Map
        ? Map<String, dynamic>.from(payload['client'] as Map)
        : <String, dynamic>{};
    final totals = payload['totals'] is Map
        ? Map<String, dynamic>.from(payload['totals'] as Map)
        : <String, dynamic>{};

    // Compat mapping for OCR/LLM JSON shapes that come without `expense`.
    expense['issueDate'] ??= invoice['date'] ?? invoice['issueDate'];
    expense['invoiceNumber'] ??=
        invoice['invoiceNumber'] ?? invoice['invoice_number'];
    expense['vendorName'] ??=
        store['name'] ?? store['company'] ?? client['company_name'];
    expense['vendorTaxId'] ??= store['cif_nif'] ?? client['cif'];
    expense['currency'] ??= 'EUR';
    expense['total'] ??= totals['total'] ?? totals['total_eur'];
    if (expense['taxTotal'] == null && totals['tax'] is Map) {
      final tax = Map<String, dynamic>.from(totals['tax'] as Map);
      expense['taxTotal'] = tax['vat_amount'] ?? tax['taxTotal'];
    }
    if (expense['lines'] == null && payload['items'] is List) {
      final lines = <Map<String, dynamic>>[];
      for (final rawItem in (payload['items'] as List)) {
        if (rawItem is! Map) continue;
        final item = Map<String, dynamic>.from(rawItem);
        lines.add({
          'description': item['description']?.toString() ?? '',
          'quantity': item['quantity'] ?? 1,
          'baseUnitPrice': item['baseUnitPrice'] ??
              item['base_unit_price'] ??
              item['unitPrice'] ??
              item['unit_price'] ??
              item['price'] ??
              item['total'] ??
              0,
          'discountAmount':
              item['discountAmount'] ?? item['discount_amount'] ?? 0,
          'discountPercent':
              item['discountPercent'] ?? item['discount_percent'] ?? 0,
          'taxRate':
              item['taxRate'] ?? item['vatRate'] ?? item['tax_rate'] ?? 21,
          if (item['lineSubtotal'] != null)
            'lineSubtotal': item['lineSubtotal'],
          if (item['lineTax'] != null) 'lineTax': item['lineTax'],
          if (item['total'] != null) 'lineTotal': item['total'],
          if (item['lineTotal'] != null) 'lineTotal': item['lineTotal'],
        });
      }
      if (lines.isNotEmpty) {
        expense['lines'] = lines;
      }
    }

    _jsonSettlement.applyToExpensePayload(expense);
    final settlementError = _jsonSettlement.validate();
    if (settlementError != null) {
      setState(() => _jsonError = settlementError);
      return;
    }
    if (_jsonUseSummaryTotals) {
      final summaryBase = _parseControllerAmount(_jsonBaseController);
      final summaryTax = _parseControllerAmount(_jsonTaxController);
      final summaryTotal = _parseControllerAmount(_jsonTotalController);
      final summaryValidation = ExpenseFormHelpers.validateSummaryTotals(
        base: summaryBase,
        tax: summaryTax,
        total: summaryTotal,
      );
      if (summaryValidation != null) {
        setState(() => _jsonError = summaryValidation);
        return;
      }
      if (summaryBase != null) {
        expense['subtotal'] = double.parse(summaryBase.toStringAsFixed(2));
      }
      if (summaryTax != null) {
        expense['taxTotal'] = double.parse(summaryTax.toStringAsFixed(2));
      }
      if (summaryTotal != null) {
        expense['total'] = double.parse(summaryTotal.toStringAsFixed(2));
      }
      final summaryVatBreakdown = ExpenseFormHelpers.buildSummaryVatBreakdown(
        base: summaryBase,
        tax: summaryTax,
      );
      if (summaryVatBreakdown != null) {
        expense['vatBreakdown'] = summaryVatBreakdown;
      }
      expense['useSummaryTotals'] = true;
      expense['taxSource'] = 'summary';
      expense.remove('lines');
    }
    final discountPreview = _jsonDiscountPreview();
    final discountValidationBase = discountPreview?.subtotalBeforeDiscount ??
        (() {
          final total = ExpenseFormHelpers.parseNum(expense['total']);
          final tax = ExpenseFormHelpers.parseNum(
            expense['taxTotal'] ?? expense['vatTotal'] ?? expense['tax'],
          );
          if (total == null) return 0.0;
          return (total - (tax ?? 0)).clamp(0, double.infinity).toDouble();
        })();
    final discountError =
        _jsonDocumentDiscount.validate(discountValidationBase);
    if (discountError != null) {
      setState(() => _jsonError = discountError);
      return;
    }
    _jsonDocumentDiscount.applyToExpensePayload(expense);

    if ((payload['providerMode']?.toString().trim().isEmpty ?? true) &&
        (payload['providerId']?.toString().trim().isEmpty ?? true)) {
      payload['providerMode'] = 'create';
      payload['provider'] = {
        'name': (store['name'] ??
                store['company'] ??
                client['company_name'] ??
                expense['vendorName'] ??
                'Proveedor')
            .toString(),
        if ((store['cif_nif']?.toString().trim().isNotEmpty ?? false))
          'taxId': store['cif_nif'].toString().trim(),
      };
    }

    payload['expense'] = expense;

    dynamic firstValue(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final normalizedIssueDate = _normalizeImportDate(
      firstValue(expense, [
            'issueDate',
            'issue_date',
            'fechaEmision',
            'fecha_emision',
            'fecha',
          ]) ??
          firstValue(payload, [
            'issueDate',
            'issue_date',
            'fechaEmision',
            'fecha_emision',
            'fecha',
          ]),
    );
    if (normalizedIssueDate == null) {
      _logImportEvent('validation', attemptId, detail: 'invalid_issue_date');
      setState(
        () => _jsonError =
            'issueDate is required and must use YYYY-MM-DD or DD/MM/YYYY',
      );
      return;
    }
    expense['issueDate'] = normalizedIssueDate;

    final rawDueDate = firstValue(expense, [
          'dueDate',
          'due_date',
          'fechaVencimiento',
          'fecha_vencimiento',
        ]) ??
        firstValue(payload, [
          'dueDate',
          'due_date',
          'fechaVencimiento',
          'fecha_vencimiento',
        ]);
    final dueDateText = rawDueDate?.toString().trim() ?? '';
    if (dueDateText.isNotEmpty) {
      final normalizedDueDate = _normalizeImportDate(rawDueDate);
      if (normalizedDueDate == null) {
        _logImportEvent('validation', attemptId, detail: 'invalid_due_date');
        setState(
          () => _jsonError =
              'dueDate must use YYYY-MM-DD or DD/MM/YYYY when provided',
        );
        return;
      }
      expense['dueDate'] = normalizedDueDate;
    }

    final providerIdOverride = _jsonProviderIdOverrideController.text.trim();
    final groupIdOverride = _jsonGroupIdOverrideController.text.trim();
    final statementEntryId = _jsonStatementEntryController.text.trim();
    final clientId = _jsonClientController.text.trim();
    final resolvedGroupId = resolveGroupId().trim();

    if (providerIdOverride.isNotEmpty) {
      payload['providerMode'] = 'existing';
      payload['providerId'] = providerIdOverride;
      payload.remove('provider');
    }
    if (groupIdOverride.isNotEmpty && groupIdOverride != resolvedGroupId) {
      _logImportEvent(
        'validation',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        detail: 'group_override_ignored',
      );
    }
    if (resolvedGroupId.isEmpty) {
      _logImportEvent(
        'validation',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        detail: 'missing_group_id',
      );
      _logExpenseAttempt(
        route: 'import',
        attemptId: attemptId,
        hasGroupId: false,
        groupId: '',
        blockedByValidation: true,
        detail: 'missing_group_id',
      );
      setState(() => _jsonError = _requiredGroupMessage());
      return;
    }
    payload['groupId'] = resolvedGroupId;
    if ((expense['groupId']?.toString().trim().isEmpty ?? true)) {
      expense['groupId'] = payload['groupId'];
    }
    if (statementEntryId.isNotEmpty) {
      payload['statementEntryId'] = statementEntryId;
    }
    if (clientId.isNotEmpty) {
      payload['clientId'] = clientId;
    }

    final hasJsonFile =
        _jsonInvoiceFileBytes != null && _jsonInvoiceFileBytes!.isNotEmpty;
    final hasSharedFile = _fileBytes != null && _fileBytes!.isNotEmpty;
    final hasFile = hasJsonFile || hasSharedFile;
    final selectedInvoiceFileBytes = _jsonInvoiceFileBytes ?? _fileBytes;
    final selectedInvoiceFileName = _jsonInvoiceFileName ?? _fileName;
    final hasBlob =
        (expense['invoiceBlobName']?.toString().trim().isNotEmpty ?? false);
    if (!hasFile && !hasBlob) {
      _logExpenseAttempt(
        route: 'import',
        attemptId: attemptId,
        hasGroupId: true,
        groupId: payload['groupId']?.toString().trim() ?? '',
        blockedByValidation: true,
        detail: 'missing_file_or_blob',
      );
      _logImportEvent(
        'validation',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        hadMultipartFile: hasFile,
        hadBlobName: hasBlob,
        detail: 'missing_file_or_blob',
      );
      setState(
        () => _jsonError =
            'Invoice file/photo is required and must be linked to the expense.',
      );
      return;
    }

    // File takes precedence over any provided blobName.
    if (hasFile) {
      expense.remove('invoiceBlobName');
      expense.remove('invoiceBlobUrl');
    }

    setState(() {
      _jsonSubmitting = true;
      _jsonError = null;
    });
    _logExpenseAttempt(
      route: 'import',
      attemptId: attemptId,
      hasGroupId: true,
      groupId: payload['groupId']?.toString().trim() ?? '',
      blockedByValidation: false,
    );
    try {
      _logImportEvent(
        'upload',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        hadMultipartFile: hasFile,
        hadBlobName: hasBlob,
      );
      final response = await _api.importJson(
        payload: payload,
        invoiceFileBytes: selectedInvoiceFileBytes,
        invoiceFileName: selectedInvoiceFileName,
      );
      if (!mounted) return;

      final importedId = (response['expenseId'] ?? '').toString().trim();
      final statusCode = (response['_statusCode'] is num)
          ? (response['_statusCode'] as num).toInt()
          : 0;
      final responseBlobName =
          (response['invoiceBlobName'] ?? '').toString().trim();
      final responseBlobUrl =
          (response['invoiceBlobUrl'] ?? '').toString().trim();
      final responseFileLinked = response['fileLinked'] == true;

      if (statusCode != 201 ||
          importedId.isEmpty ||
          responseBlobName.isEmpty ||
          !responseFileLinked) {
        _logImportEvent(
          'response_validation',
          attemptId,
          providerMode: payload['providerMode']?.toString(),
          hadMultipartFile: hasFile,
          hadBlobName: hasBlob,
          fileLinked: responseFileLinked,
          detail:
              'status=$statusCode importedIdEmpty=${importedId.isEmpty} blobEmpty=${responseBlobName.isEmpty}',
        );
        setState(
          () => _jsonError =
              'Invoice file/photo is required and must be linked to the expense.',
        );
        return;
      }

      if (importedId.isEmpty) {
        setState(
          () => _jsonError =
              'El gasto se importo pero no se pudo validar el archivo enlazado.',
        );
        return;
      }

      bool linked = hasBlob;
      try {
        final fileInfo = await _api.fetchExpenseFile(importedId);
        final linkedUrl = (fileInfo['url'] ?? '').toString().trim();
        final linkedName = (fileInfo['fileName'] ?? '').toString().trim();
        linked = linked || linkedUrl.isNotEmpty || linkedName.isNotEmpty;
      } catch (_) {
        linked = false;
      }

      if (!linked) {
        _logImportEvent(
          'link',
          attemptId,
          providerMode: payload['providerMode']?.toString(),
          hadMultipartFile: hasFile,
          hadBlobName: hasBlob,
          fileLinked: false,
          detail: 'post_fetch_link_check_failed',
        );
        try {
          await _api.deleteExpense(importedId);
        } catch (_) {}
        if (!mounted) return;
        setState(
          () => _jsonError =
              'No se pudo enlazar la foto/PDF al gasto. No se registro.',
        );
        return;
      }

      if (!mounted) return;
      _logImportEvent(
        'persist',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        hadMultipartFile: hasFile,
        hadBlobName: hasBlob,
        fileLinked: true,
      );
      showSafeSnackBar(
        context,
        SnackBar(
          content: Text(
            'Gasto importado: $importedId',
          ),
        ),
      );
      await loadRecentUploads();
      if (!mounted) return;
      widget.onUploaded?.call();
      setState(() {
        selectedRecentExpense =
            recentUploads.cast<Map<String, String>?>().firstWhere(
                      (item) => (item?['id'] ?? '').trim() == importedId,
                      orElse: () => null,
                    ) ??
                <String, String>{
                  'id': importedId,
                  'invoiceBlobName': responseBlobName,
                  'fileLinked': responseFileLinked.toString(),
                  if (responseBlobUrl.isNotEmpty)
                    'invoiceBlobUrl': responseBlobUrl,
                };
        _jsonPayloadController.clear();
        _jsonInvoiceFileBytes = null;
        _jsonInvoiceFileName = null;
        _jsonFileBytes = null;
        _jsonFileName = null;
        _jsonProviderIdOverrideController.clear();
        _jsonGroupIdOverrideController.clear();
        _jsonStatementEntryController.clear();
        _jsonClientController.clear();
        _jsonBaseController.clear();
        _jsonTaxController.clear();
        _jsonTotalController.clear();
        _jsonUseSummaryTotals = false;
        _jsonAdvancedExpanded = false;
        _jsonSettlement.setExpenseType(ExpenseDocumentType.standard);
        _jsonSettlement.advancePercentController.clear();
        _jsonSettlement.projectBaseAmountController.clear();
        _jsonSettlement.advanceTaxRateController.clear();
        _jsonSettlement.selectedAdvanceExpenseId = null;
        _jsonDocumentDiscount.clear();
      });
      _tabs.index = 0;
    } on ExpensesApiException catch (e) {
      String message = e.message;
      if (e.statusCode == 404) {
        message = 'Provider not found';
      } else if (e.statusCode == 400) {
        final lower = e.message.toLowerCase();
        if (lower.contains('groupid is required') ||
            lower.contains('groupid')) {
          message = _requiredGroupMessage();
        } else if (lower.contains('blob')) {
          message =
              'Linked invoice file is invalid or inaccessible. Re-upload.';
        } else {
          message =
              'Invoice file/photo is required and must be linked to the expense.';
        }
      } else if (e.statusCode == 409) {
        final body = e.responseBody ?? '';
        try {
          final decodedBody = jsonDecode(body);
          if (decodedBody is Map && decodedBody['existingExpenseId'] != null) {
            message =
                '${decodedBody['error'] ?? 'Duplicate invoice'} (${decodedBody['existingExpenseId']})';
          }
        } catch (_) {}
      } else if (e.statusCode == 500) {
        message = 'Server error while importing expense.';
      }
      _logImportEvent(
        e.statusCode == 400
            ? 'validation'
            : e.statusCode == 500
                ? 'persist'
                : 'upload',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        hadMultipartFile: hasFile,
        hadBlobName: hasBlob,
        fileLinked: false,
        detail: 'api_${e.statusCode}',
      );
      if (!mounted) return;
      setState(() => _jsonError = message);
    } catch (e) {
      _logImportEvent(
        'upload',
        attemptId,
        providerMode: payload['providerMode']?.toString(),
        hadMultipartFile: hasFile,
        hadBlobName: hasBlob,
        fileLinked: false,
        detail: e.toString(),
      );
      if (!mounted) return;
      setState(() => _jsonError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _jsonSubmitting = false);
      }
    }
  }

  String? _normalizeImportDate(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(text)) return text;
    for (final pattern in const ['dd/MM/yyyy', 'dd-MM-yyyy']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(text);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {}
    }
    final parsedIsoDateTime = DateTime.tryParse(text);
    if (parsedIsoDateTime != null) {
      return DateFormat('yyyy-MM-dd').format(parsedIsoDateTime);
    }
    return null;
  }
}
