part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewImportExtractSection on _GroupInvoicesBudgetsViewState {
  static const Set<String> _supportedOcrExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  bool get _hasIssuedPresupuesto =>
      (_issuedPresupuestoNumber ?? '').trim().isNotEmpty;

  String _friendlyPresupuestoImportError(
    String raw, {
    String? code,
  }) {
    final normalizedCode = (code ?? '').trim().toUpperCase();
    if (normalizedCode == 'PRESUPUESTO_NOT_DRAFT') {
      return 'Este presupuesto ya no esta en borrador.';
    }
    if (normalizedCode == 'INVALID_IMPORT_PAYLOAD') {
      return 'El JSON de importacion no tiene formato valido (usa lines, draftLines o blocks).';
    }
    if (normalizedCode == 'PRESUPUESTO_NOT_FOUND') {
      return 'No se encontro el presupuesto.';
    }
    final m = raw.trim();
    if (m.isEmpty) return m;
    final lower = m.toLowerCase();
    if (lower.contains('only draft presupuestos can be updated via json import')) {
      return 'Este presupuesto ya no esta en borrador.';
    }
    if (lower.contains('invalid_import_payload') ||
        lower.contains('invalid import payload')) {
      return 'El JSON de importacion no tiene formato valido (usa lines, draftLines o blocks).';
    }
    if (lower.contains('presupuesto_not_found') ||
        lower.contains('presupuesto not found')) {
      return 'No se encontro el presupuesto.';
    }
    if (lower.contains('presupuesto number already exists')) {
      return 'Ya existe un presupuesto con ese numero en este grupo.';
    }
    return m;
  }

  bool _isDraftOnlyImportError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('only draft presupuestos can be updated') ||
        lower.contains('solo se pueden importar lineas en presupuestos en borrador');
  }

  bool _isDraftOnlyImportCode(String? code) {
    return (code ?? '').trim().toUpperCase() == 'PRESUPUESTO_NOT_DRAFT';
  }

  bool _isValidJsonPayload(String sourceText) {
    final raw = sourceText.trim();
    if (raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return true;
      if (decoded is Map<String, dynamic>) return true;
      if (decoded is Map) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  bool _looksLikeBudgetLineObject(Map<dynamic, dynamic> map) {
    final keys = map.keys.map((e) => e.toString().trim().toLowerCase()).toSet();
    return keys.contains('description') ||
        keys.contains('qty') ||
        keys.contains('quantity') ||
        keys.contains('unitprice') ||
        keys.contains('price') ||
        keys.contains('taxrate') ||
        keys.contains('iva') ||
        keys.contains('type');
  }

  String? _validateBudgetJsonShape(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return null;
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return 'JSON invalido. Revisa llaves, comas y estructura.';
    }
    if (decoded is List) return null;
    if (decoded is! Map) {
      return 'Estructura no valida. Usa {"lines":[...]} o una lista de lineas.';
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['lines'] is List || map['draftLines'] is List || map['blocks'] is List) {
      return null;
    }
    if (_looksLikeBudgetLineObject(map)) return null;
    return 'Estructura no valida. Incluye "lines", "draftLines", "blocks" o una linea.';
  }

  String _normalizeBudgetJsonSource(String sourceText) {
    final trimmed = sourceText.trim();
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } catch (_) {
      return sourceText;
    }
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['lines'] is List || map['draftLines'] is List || map['blocks'] is List) {
        return sourceText;
      }
      if (_looksLikeBudgetLineObject(map)) {
        return jsonEncode({
          'lines': [map],
        });
      }
    }
    return sourceText;
  }

  Future<String> _ensureWritableDraftForImport() async {
    final currentId = (_draftId ?? '').trim();
    if (currentId.isEmpty) {
      return _ensureDraftCreated(forceRebuild: false);
    }

    var requiresNewDraft = _hasIssuedPresupuesto;
    if (!requiresNewDraft) {
      try {
        final current = await _presupuestosApi.getById(currentId);
        if (!_isDraftPresupuesto(current)) {
          requiresNewDraft = true;
        }
      } catch (_) {
        // If status cannot be resolved, force a new draft to avoid importing into
        // a potentially issued/non-editable presupuesto.
        requiresNewDraft = true;
      }
    }

    if (!requiresNewDraft) return currentId;

    _markDraftDirty();
    return _ensureDraftCreated(forceRebuild: true);
  }

  bool _isSupportedOcrFile(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return false;
    final ext = fileName.substring(dot + 1).toLowerCase().trim();
    return _supportedOcrExtensions.contains(ext);
  }

  num _coerceNum(
    dynamic value, {
    num fallback = 0,
    int decimals = 4,
  }) {
    final parsed = value is num
        ? value
        : num.tryParse((value ?? '').toString().replaceAll(',', '.'));
    final normalized = parsed ?? fallback;
    return num.parse(normalized.toStringAsFixed(decimals));
  }

  List<Map<String, dynamic>> _normalizedExtractedLinesForImport() {
    final normalized = <Map<String, dynamic>>[];
    for (final raw in _extractedBlocks) {
      final description =
          (raw['description'] ?? raw['title'] ?? '').toString().trim();
      final quantity = _coerceNum(
        raw['quantity'] ?? raw['qty'] ?? raw['q'] ?? 1,
        fallback: 1,
      );
      final unitPrice = _coerceNum(raw['unitPrice'] ?? raw['price'] ?? 0);
      final taxRate =
          _coerceNum(raw['taxRate'] ?? raw['vat'] ?? raw['iva'] ?? 21);
      if (description.isEmpty) continue;
      if (quantity <= 0) continue;
      if (unitPrice < 0) continue;
      normalized.add({
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'taxRate': taxRate,
      });
    }
    return normalized;
  }

  Future<void> _pickBudgetJsonFile() async {
    if (_jsonImportLoading) return;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final file =
        (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) return;
    final text = utf8.decode(bytes, allowMalformed: true);
    setState(() {
      _jsonImportFileName = file.name;
      _jsonImportFileContent = text;
      _jsonImportError = null;
    });
  }

  void _clearBudgetJsonFile() {
    setState(() {
      _jsonImportFileName = null;
      _jsonImportFileContent = null;
      _jsonImportError = null;
    });
  }

  Future<void> _copyBudgetPromptTemplate() async {
    if (_jsonPromptLoading) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      _jsonPromptLoading = true;
      _jsonImportError = null;
    });
    try {
      final id = await _ensureDraftCreated(forceRebuild: false);
      final response = await _presupuestosApi.getImportJsonPromptTemplate(id);
      final prompt = JsonImportService.extractPromptText(response);
      await Clipboard.setData(
        ClipboardData(text: prompt.isEmpty ? jsonEncode(response) : prompt),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLinesJsonImportPromptCopied)),
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _jsonImportError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _jsonImportError = l.failedWithReason('');
      });
    } finally {
      if (mounted) {
        setState(() => _jsonPromptLoading = false);
      }
    }
  }

  Future<void> _importBudgetJson({
    required String sourceText,
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    if (_jsonImportLoading) return;
    final l = AppLocalizations.of(context)!;
    final raw = sourceText.trim();
    if (raw.isEmpty) {
      setState(() => _jsonImportError = l.invoiceLinesJsonImportInvalidPayload);
      return;
    }
    if (!_isValidJsonPayload(raw)) {
      setState(() {
        _jsonImportError =
            'JSON invalido. Revisa llaves, comas y estructura antes de importar.';
      });
      return;
    }
    final shapeError = _validateBudgetJsonShape(raw);
    if (shapeError != null && shapeError.trim().isNotEmpty) {
      setState(() => _jsonImportError = shapeError);
      return;
    }
    final normalizedSource = _normalizeBudgetJsonSource(sourceText);
    final payload = JsonImportService.buildImportPayload(
      entity: JsonImportEntityType.presupuesto,
      sourceText: normalizedSource,
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );
    setState(() {
      _jsonImportLoading = true;
      _jsonImportError = null;
    });
    try {
      Future<Map<String, dynamic>> runImport(String id) {
        return _presupuestosApi.importJson(id, payload);
      }

      var id = await _ensureWritableDraftForImport();
      Map<String, dynamic> response;
      try {
        response = await runImport(id);
      } on PresupuestosApiException catch (e) {
        if (!_isDraftOnlyImportCode(e.code) && !_isDraftOnlyImportError(e.message)) {
          rethrow;
        }
        _markDraftDirty();
        id = await _ensureDraftCreated(forceRebuild: true);
        response = await runImport(id);
      }
      final refreshed = await _presupuestosApi.getById(id);
      if (!mounted) return;
      if (!_isDraftPresupuesto(refreshed)) {
        setState(() {
          _jsonImportError = 'Este presupuesto ya no esta en borrador.';
        });
        return;
      }
      _applyPresupuestoPayload(refreshed);
      final imported = (refreshed['importedCount'] ??
              refreshed['lineCount'] ??
              refreshed['createdCount'] ??
              refreshed['count'] ??
              0)
          .toString();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLinesJsonImportSuccess(imported))),
      );
      if (JsonImportService.extractRepairApplied(response)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON auto-corrected before import.')),
        );
      }
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      var msg = JsonImportService.mapErrorMessage(
        l: l,
        entity: JsonImportEntityType.presupuesto,
        statusCode: e.statusCode,
        backendMessage: e.message,
      );
      msg = _friendlyPresupuestoImportError(msg, code: e.code);
      setState(() => _jsonImportError = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _jsonImportError = l.invoiceLinesJsonImportGenericError);
    } finally {
      if (mounted) {
        setState(() => _jsonImportLoading = false);
      }
    }
  }

  Future<void> _importBudgetJsonFromText(
    String rawText, {
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    await _importBudgetJson(
      sourceText: rawText,
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );
  }

  Future<void> _importBudgetJsonFromFile({
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    await _importBudgetJson(
      sourceText: _jsonImportFileContent ?? '',
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );
  }

  Future<void> _pickBudgetExtractFile() async {
    if (_extractingBlocks) return;
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      withData: true,
    );
    final file =
        (picked?.files.isNotEmpty ?? false) ? picked!.files.first : null;
    final bytes = file?.bytes;
    if (file == null || bytes == null || bytes.isEmpty) return;
    if (!_isSupportedOcrFile(file.name)) {
      setState(() {
        _extractError =
            'Tipo de archivo no soportado. Usa: pdf, jpg, jpeg, png o webp.';
      });
      return;
    }
    setState(() {
      _extractFileName = file.name;
      _extractFileBytes = bytes;
      _extractError = null;
    });
  }

  void _clearBudgetExtractedBlocks() {
    setState(() {
      _extractFileName = null;
      _extractFileBytes = null;
      _extractError = null;
      _extractedBlocks = const [];
      _extractMethodUsed = null;
      _extractDiagnostics = const [];
    });
  }

  Future<void> _extractBudgetBlocksWithOpenAi() async {
    if (_extractingBlocks) return;
    final l = AppLocalizations.of(context)!;
    final bytes = _extractFileBytes;
    final name = (_extractFileName ?? '').trim();
    if (bytes == null || bytes.isEmpty || name.isEmpty) {
      setState(() => _extractError = l.invoiceLinesJsonImportNoFile);
      return;
    }
    setState(() {
      _extractingBlocks = true;
      _extractError = null;
    });
    try {
      final id = await _ensureWritableDraftForImport();
      Map<String, dynamic> response;
      try {
        response = await _presupuestosApi.extractLinesOcr(
          id: id,
          bytes: bytes,
          fileName: name,
          preview: true,
        );
      } on PresupuestosApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          response = await _presupuestosApi.extractImageOpenAi(
            id: id,
            bytes: bytes,
            fileName: name,
          );
        } else {
          rethrow;
        }
      }
      var raw = response['draftLines'] ?? response['blocks'] ?? response['lines'];
      if (raw is! List || raw.isEmpty) {
        try {
          final full = await _presupuestosApi.extractLinesOcr(
            id: id,
            bytes: bytes,
            fileName: name,
            preview: false,
          );
          response = full;
          raw = response['draftLines'] ?? response['blocks'] ?? response['lines'];
        } catch (_) {
          // Keep preview response/errors as source of truth.
        }
      }
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
        _extractedBlocks = rows;
        _extractMethodUsed = (response['methodUsed'] ?? response['method'])
            ?.toString()
            .trim();
        _extractDiagnostics = diagnostics;
        if (rows.isEmpty) {
          _extractError =
              'No se detectaron conceptos. Prueba con otra imagen o ajusta manualmente.';
        }
      });
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() => _extractError =
          _friendlyPresupuestoImportError(e.message, code: e.code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _extractError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _extractingBlocks = false);
    }
  }

  void _updateExtractedBlockField(int index, String key, String value) {
    if (index < 0 || index >= _extractedBlocks.length) return;
    final next = _extractedBlocks
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: true);
    final current = Map<String, dynamic>.from(next[index]);
    if (key == 'description' || key == 'title' || key == 'type') {
      current[key] = value;
    } else {
      current[key] = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    next[index] = current;
    setState(() => _extractedBlocks = next);
  }

  void _removeExtractedBlock(int index) {
    if (index < 0 || index >= _extractedBlocks.length) return;
    final next = _extractedBlocks.toList(growable: true)..removeAt(index);
    setState(() => _extractedBlocks = next);
  }

  void _addExtractedBlock() {
    final next = _extractedBlocks.toList(growable: true)
      ..add({
        'type': 'item',
        'description': '',
        'qty': 1,
        'unitPrice': 0,
        'taxRate': 21,
      });
    setState(() => _extractedBlocks = next);
  }

  Future<void> _importExtractedBudgetBlocks({
    required bool overwrite,
    required double defaultTaxRate,
  }) async {
    if (_extractingBlocks || _jsonImportLoading) return;
    if (_extractedBlocks.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final normalizedLines = _normalizedExtractedLinesForImport();
    if (normalizedLines.isEmpty) {
      setState(() {
        _jsonImportError =
            'No hay líneas válidas para importar. Revisa descripción, cantidad y precio.';
      });
      return;
    }
    setState(() {
      _jsonImportLoading = true;
      _jsonImportError = null;
    });
    try {
      var id = await _ensureWritableDraftForImport();
      final payload = <String, dynamic>{
        'lines': normalizedLines,
        'overwrite': overwrite,
        'defaultTaxRate': defaultTaxRate,
      };
      Map<String, dynamic> response;
      try {
        response = await _presupuestosApi.importLinesMultipart(
          id: id,
          payload: payload,
        );
      } on PresupuestosApiException catch (e) {
        if (_isDraftOnlyImportCode(e.code) || _isDraftOnlyImportError(e.message)) {
          _markDraftDirty();
          id = await _ensureDraftCreated(forceRebuild: true);
          response = await _presupuestosApi.importLinesMultipart(
            id: id,
            payload: payload,
          );
        } else if (e.statusCode == 404 || e.statusCode == 405) {
          response = await _presupuestosApi.importJson(id, payload);
        } else {
          rethrow;
        }
      }
      try {
        if (response.isEmpty) {
          response = await _presupuestosApi.importJson(id, payload);
        }
      } on PresupuestosApiException catch (e) {
        if (_isDraftOnlyImportCode(e.code) || _isDraftOnlyImportError(e.message)) {
          _markDraftDirty();
          id = await _ensureDraftCreated(forceRebuild: true);
          response = await _presupuestosApi.importJson(id, payload);
        } else if (e.statusCode == 404 || e.statusCode == 405) {
          response = await _presupuestosApi.importJson(id, payload);
        } else {
          rethrow;
        }
      }
      final refreshed = await _presupuestosApi.getById(id);
      if (!mounted) return;
      _applyPresupuestoPayload(refreshed);
      final imported = JsonImportService.extractImportedCount(response);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.invoiceLinesJsonImportSuccess(
              '${imported > 0 ? imported : normalizedLines.length}',
            ),
          ),
        ),
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() => _jsonImportError =
          _friendlyPresupuestoImportError(e.message, code: e.code));
    } catch (e) {
      if (!mounted) return;
      setState(() => _jsonImportError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _jsonImportLoading = false);
    }
  }

  Widget _buildBudgetOpenAiExtractPanel(
    BuildContext context,
  ) {
    final l = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    Widget smallNumField(
      String label,
      String value,
      ValueChanged<String> onChanged,
    ) {
      return SizedBox(
        width: 100,
        child: TextField(
          controller: TextEditingController(text: value),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Importar lineas por foto/PDF',
            style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: _extractingBlocks ? null : _pickBudgetExtractFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  (_extractFileName ?? '').trim().isEmpty
                      ? 'Seleccionar archivo'
                      : _extractFileName!,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _extractingBlocks ? null : _extractBudgetBlocksWithOpenAi,
                icon: _extractingBlocks
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(
                  _extractingBlocks ? 'Extrayendo...' : 'Extraer lineas',
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _extractedBlocks.isEmpty ? null : _clearBudgetExtractedBlocks,
                icon: const Icon(Icons.clear_all),
                label: Text(l.invoiceLinesPhotoClear),
              ),
            ],
          ),
          if ((_extractError ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _extractError!,
              style: t.bodySmall?.copyWith(color: cs.error),
            ),
          ],
          if ((_extractMethodUsed ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'methodUsed: ${_extractMethodUsed!.trim()}',
              style: t.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_extractDiagnostics.isNotEmpty) ...[
            const SizedBox(height: 4),
            ..._extractDiagnostics.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('- $d', style: t.bodySmall),
                )),
          ],
          if (_extractedBlocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  l.invoiceLinesPhotoExtractedCount('${_extractedBlocks.length}'),
                  style: t.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(onPressed: _addExtractedBlock, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                itemCount: _extractedBlocks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final row = _extractedBlocks[i];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: TextEditingController(
                            text: (row['description'] ?? row['title'] ?? '').toString(),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Descripcion',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _updateExtractedBlockField(i, 'description', v),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            smallNumField(
                              'Cantidad',
                              (row['qty'] ?? row['quantity'] ?? 1).toString(),
                              (v) => _updateExtractedBlockField(i, 'qty', v),
                            ),
                            const SizedBox(width: 6),
                            smallNumField(
                              'Precio unitario',
                              (row['unitPrice'] ?? 0).toString(),
                              (v) => _updateExtractedBlockField(i, 'unitPrice', v),
                            ),
                            const SizedBox(width: 6),
                            smallNumField(
                              'Impuesto',
                              (row['taxRate'] ?? 21).toString(),
                              (v) => _updateExtractedBlockField(i, 'taxRate', v),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _removeExtractedBlock(i),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _jsonImportLoading
                  ? null
                  : () => _importExtractedBudgetBlocks(
                        overwrite: false,
                        defaultTaxRate: 21,
                      ),
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              label: const Text('Importar al presupuesto'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No se detectaron conceptos. Prueba con otra imagen o ajusta manualmente.',
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

}
