part of '../../expense_upload_screen.dart';

mixin ExpenseUploadImportActionsSection on _ExpenseUploadScreenStateBase {
  String _friendlyNetworkError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();
    final looksLikeCors = lower.contains('failed to fetch') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('blocked by cors') ||
        lower.contains('access-control-allow-origin');
    if (looksLikeCors) {
      return 'La petición fue bloqueada por CORS. El backend debe permitir este origen y responder OPTIONS para /api/expenses/import-json-batch/*.';
    }
    return raw;
  }

  Future<void> _pickJsonInvoiceFile() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
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
    final validationError = _validateInvoiceUploadFile(
      fileName: file.name,
      fileBytes: file.bytes!,
    );
    if (validationError != null) {
      setState(() => _jsonError = validationError);
      return;
    }
    setState(() {
      _jsonInvoiceFileBytes = file.bytes!;
      _jsonInvoiceFileName = file.name;
      _jsonError = null;
    });
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
    try {
      final text = utf8.decode(file.bytes!);
      jsonDecode(text);
      setState(() {
        _jsonFileBytes = file.bytes!;
        _jsonFileName = file.name;
        _jsonPayloadController.text = text;
        _jsonError = null;
      });
    } catch (_) {
      setState(() => _jsonError = 'Invalid JSON');
    }
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    final files = picked?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;

    const maxDocs = _ExpenseUploadScreenStateBase._maxBatchDocuments;
    final selectedTooMany = files.length > maxDocs;
    final filesToProcess =
        selectedTooMany ? files.take(maxDocs).toList() : files;

    final bytes = <Uint8List>[];
    final names = <String>[];
    var skippedCount = 0;

    for (final f in filesToProcess) {
      final b = f.bytes;
      if (b == null) {
        skippedCount++;
        continue;
      }
      final validationError = _validateInvoiceUploadFile(
        fileName: f.name,
        fileBytes: b,
        maxSizeBytes: _ExpenseUploadScreenStateBase._maxBatchFileSizeBytes,
        emptyMessage: 'Falta archivo/documento para una o mas facturas.',
        unsupportedTypeMessage:
            'Formato de archivo no soportado (PDF/JPG/JPEG/PNG/WEBP).',
        tooLargeMessageBuilder: (fileName, _, __) =>
            'File "$fileName" exceeds 10MB. Max file size is 10MB.',
      );
      if (validationError != null) {
        skippedCount++;
        continue;
      }
      bytes.add(b);
      names.add(f.name);
    }

    if (bytes.isEmpty) {
      setState(
        () => _batchError =
            'No valid files were loaded. Verify type/size and try again.',
      );
      return;
    }

    setState(() {
      _batchDocumentBytes = bytes;
      _batchDocumentNames = names;
      if (selectedTooMany || skippedCount > 0) {
        final warnings = <String>[
          if (selectedTooMany)
            'Selected ${files.length}; only first $maxDocs were loaded.',
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
    if (_batchGeneratingJson || _batchSubmitting) return;
    final groupId = resolveGroupId().trim();
    if (groupId.isEmpty) {
      setState(
          () => _batchError = 'Debes seleccionar un grupo antes de importar.');
      return;
    }
    if (_batchDocumentBytes.isEmpty || _batchDocumentNames.isEmpty) {
      setState(() => _batchError = 'Upload at least 1 document first.');
      return;
    }
    if (_batchDocumentBytes.length >
        _ExpenseUploadScreenStateBase._maxBatchDocuments) {
      setState(
        () => _batchError =
            'Maximum ${_ExpenseUploadScreenStateBase._maxBatchDocuments} files.',
      );
      return;
    }

    setState(() {
      _batchGeneratingJson = true;
      _batchError = null;
    });

    try {
      final response = await _api.generateBatchJsonWithAi(
        documentFilesBytes: _batchDocumentBytes,
        documentFileNames: _batchDocumentNames,
        groupId: groupId,
      );
      final payload = response['payload'] ??
          response['json'] ??
          response['data'] ??
          response['result'];
      if (payload == null) {
        setState(() => _batchError = 'AI did not return a valid JSON payload.');
        return;
      }
      final text = payload is String
          ? payload
          : const JsonEncoder.withIndent('  ').convert(payload);
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _batchError = 'AI output must be a JSON object.');
        return;
      }
      final invoices =
          _extractBatchInvoices(Map<String, dynamic>.from(decoded));
      setState(() {
        _batchJsonController.text = text;
        _batchDetectedInvoices = invoices.length;
        _batchVerifyMessage = null;
      });
    } on ExpensesApiException catch (e) {
      var message = e.message;
      if (e.statusCode == 413) {
        message =
            'Upload is too large for the server limit (413). Reduce total files/size or contact support to increase upload limit.';
      }
      setState(() => _batchError = message);
    } catch (e) {
      setState(() => _batchError = _friendlyNetworkError(e));
    } finally {
      if (mounted) {
        setState(() => _batchGeneratingJson = false);
      }
    }
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
      _batchVerifyMessage = 'Falta archivo/documento para una o más facturas.';
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

    if (hasNamesForAll) {
      final missing =
          expectedNames.where((n) => !uploaded.contains(n)).toList();
      if (missing.isNotEmpty) {
        _batchVerifyMessage =
            'No se pudo enlazar todos los documentos con las facturas del JSON.';
        return false;
      }
      _batchVerifyMessage = 'Enlace verificado por nombre.';
      return true;
    }

    if (uploadedFileNames.length == invoices.length) {
      _batchVerifyMessage =
          'Enlace verificado por orden (fallback: mismo número de archivos y facturas).';
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

  Future<void> _submitBatchImport() async {
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
          setState(
              () => _batchError = 'AI did not return a valid JSON payload.');
          return;
        }
        final generatedText = payloadRaw is String
            ? payloadRaw
            : const JsonEncoder.withIndent('  ').convert(payloadRaw);
        final decoded = jsonDecode(generatedText);
        if (decoded is! Map) {
          setState(() => _batchError = 'AI output must be a JSON object.');
          return;
        }
        payload = Map<String, dynamic>.from(decoded);
        final invoices = _extractBatchInvoices(payload);
        _batchJsonController.text = generatedText;
        _batchDetectedInvoices = invoices.length;
      } on ExpensesApiException catch (e) {
        setState(() => _batchError = e.message);
        return;
      } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importación batch completada.')),
      );
      await loadRecentUploads();
      if (!mounted) return;
      widget.onUploaded?.call();
      setState(() {
        _batchJsonController.clear();
        _batchDocumentBytes = [];
        _batchDocumentNames = [];
        _batchDetectedInvoices = 0;
        _batchVerifyMessage = null;
      });
    } on ExpensesApiException catch (e) {
      var message = e.message;
      if (e.statusCode == 400) {
        final lower = e.message.toLowerCase();
        if (lower.contains('groupid')) {
          message = 'Debes seleccionar un grupo antes de importar.';
        } else {
          message =
              'No se pudo enlazar todos los documentos con las facturas del JSON.';
        }
      } else if (e.statusCode == 413) {
        message =
            'Upload is too large for the server limit (413). Reduce total files/size or contact support to increase upload limit.';
      } else if (e.statusCode == 500) {
        message = 'Error al importar. Intenta de nuevo.';
      }
      if (!mounted) return;
      setState(() => _batchError = message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _batchError = _friendlyNetworkError(e));
    } finally {
      if (mounted) setState(() => _batchSubmitting = false);
    }
  }

  Future<void> _copyPromptToClipboard() async {
    final text = (_jsonPromptText ?? '').trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Prompt copied')));
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
          'unitPrice': item['unitPrice'] ??
              item['unit_price'] ??
              item['price'] ??
              item['total'] ??
              0,
          'taxRate': item['taxRate'] ?? item['tax_rate'] ?? 21,
          if (item['total'] != null) 'lineTotal': item['total'],
        });
      }
      if (lines.isNotEmpty) {
        expense['lines'] = lines;
      }
    }

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
      ScaffoldMessenger.of(context).showSnackBar(
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
        final localState = <String, String>{
          'id': importedId,
          'invoiceBlobName': responseBlobName,
          'fileLinked': responseFileLinked.toString(),
        };
        if (responseBlobUrl.isNotEmpty) {
          localState['invoiceBlobUrl'] = responseBlobUrl;
        }
        selectedRecentExpense = localState;
        _jsonPayloadController.clear();
        _jsonInvoiceFileBytes = null;
        _jsonInvoiceFileName = null;
        _jsonFileBytes = null;
        _jsonFileName = null;
        _jsonProviderIdOverrideController.clear();
        _jsonGroupIdOverrideController.clear();
        _jsonStatementEntryController.clear();
        _jsonClientController.clear();
        _jsonAdvancedExpanded = false;
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
