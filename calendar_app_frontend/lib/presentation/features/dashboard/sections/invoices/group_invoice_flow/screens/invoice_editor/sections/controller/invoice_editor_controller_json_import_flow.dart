part of '../invoice_editor_controller.dart';

extension InvoiceEditorControllerJsonImportFlow on InvoiceEditorController {
  static const double _jsonDefaultTaxRate = 21;

  bool get hasJsonImportFile =>
      _jsonImportFileBytes != null &&
      (_jsonImportFileName ?? '').trim().isNotEmpty;

  Future<void> pickJsonImportFile(BuildContext context) async {
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

    _jsonImportFileBytes = bytes;
    _jsonImportFileName =
        file.name.trim().isEmpty ? 'draft-lines.json' : file.name;
    _jsonImportError = null;
    notifyListeners();
  }

  void clearJsonImportFile() {
    _jsonImportFileBytes = null;
    _jsonImportFileName = null;
    _jsonImportError = null;
    notifyListeners();
  }

  void clearJsonImportError() {
    _jsonImportError = null;
    notifyListeners();
  }

  Future<void> importLinesFromJsonText(
    BuildContext context, {
    required String rawText,
    required bool overwrite,
    double defaultTaxRate = _jsonDefaultTaxRate,
  }) async {
    final payload = JsonImportService.buildImportPayload(
      entity: JsonImportEntityType.invoice,
      sourceText: rawText,
      overwrite: overwrite,
      defaultTaxRate: defaultTaxRate,
    );

    await _runJsonImport(
      context,
      seedPayload: payload,
      execute: (invoiceId) =>
          _linesApi.importLinesFromJsonBody(invoiceId, payload: payload),
    );
  }

  Future<void> importLinesFromJsonFile(
    BuildContext context, {
    required bool overwrite,
    double defaultTaxRate = _jsonDefaultTaxRate,
  }) async {
    final bytes = _jsonImportFileBytes;
    final fileName = (_jsonImportFileName ?? '').trim();
    if (bytes == null || bytes.isEmpty || fileName.isEmpty) {
      _setJsonImportError('No JSON file selected');
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showInfoSnack(context, l.invoiceLinesJsonImportNoFile);
      return;
    }

    await _runJsonImport(
      context,
      seedPayload: utf8.decode(bytes, allowMalformed: true).trim().isEmpty
          ? null
          : JsonImportService.buildImportPayload(
              entity: JsonImportEntityType.invoice,
              sourceText: utf8.decode(bytes, allowMalformed: true),
              overwrite: overwrite,
              defaultTaxRate: defaultTaxRate,
            ),
      execute: (invoiceId) => _linesApi.importLinesFromJsonFile(
        invoiceId,
        bytes: bytes,
        fileName: fileName,
        overwrite: overwrite,
        defaultTaxRate: defaultTaxRate,
      ),
    );
  }

  Future<void> copyJsonImportPromptTemplate(BuildContext context) async {
    if (_loadingJsonPromptTemplate) return;

    final draftId = await _ensureDraftIdForOcr(context);
    if (!context.mounted) return;
    if (draftId == null || draftId.isEmpty) {
      final l = AppLocalizations.of(context)!;
      showErrorSnack(context, l.invoiceDraftSaveFailedSnack);
      return;
    }

    _loadingJsonPromptTemplate = true;
    _jsonImportError = null;
    notifyListeners();

    try {
      final template = await _linesApi.getImportJsonPromptTemplate(draftId);
      final text = JsonImportService.extractPromptText(template.raw).isEmpty
          ? jsonEncode(template.raw)
          : JsonImportService.extractPromptText(template.raw);
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      await copyTextWithManualFallbackDialog(
        context,
        text: text,
        successMessage: l.invoiceLinesJsonImportPromptCopied,
      );
    } on line_ev.InvoiceLinesJsonImportException catch (e) {
      _setJsonImportError(e.debugMessage);
      if (!context.mounted) return;
      showErrorSnack(context, e.userMessage);
    } catch (e) {
      _setJsonImportError(e.toString());
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showErrorSnack(context, l.invoiceLinesJsonImportGenericError);
    } finally {
      _loadingJsonPromptTemplate = false;
      notifyListeners();
    }
  }

  Future<void> _runJsonImport(
    BuildContext context, {
    Map<String, dynamic>? seedPayload,
    required Future<line_ev.InvoiceLinesJsonImportResult> Function(String)
        execute,
  }) async {
    if (_importingJsonLines) return;

    if ((_savedInvoice?.id ?? '').trim().isEmpty && !hasBillableEntries) {
      final seededLines = _seedLineDraftsFromJsonPayload(seedPayload);
      if (seededLines.isEmpty) {
        final l = AppLocalizations.of(context)!;
        _setJsonImportError(l.invoiceLinesRequired);
        if (!context.mounted) return;
        showInfoSnack(context, l.invoiceLinesRequired);
        return;
      }
      _resetDraftLines();
      lines.addAll(seededLines);
      _useBlocks = false;
      notifyUi();
    }

    final draftId = await _ensureDraftIdForOcr(context);
    if (!context.mounted) return;
    if (draftId == null || draftId.isEmpty) {
      final l = AppLocalizations.of(context)!;
      showErrorSnack(context, l.invoiceDraftSaveFailedSnack);
      return;
    }

    _importingJsonLines = true;
    _jsonImportError = null;
    notifyListeners();

    try {
      final result = await execute(draftId);
      await _reloadDraftLinesFromApi(draftId);
      _useBlocks = false;
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showSuccessSnack(
        context,
        l.invoiceLinesJsonImportSuccess(result.importedCount.toString()),
      );
      if (JsonImportService.extractRepairApplied(result.raw)) {
        showInfoSnack(context, l.jsonAutoRepairAppliedSnack);
      }
    } on line_ev.InvoiceLinesJsonImportException catch (e) {
      final l = AppLocalizations.of(context)!;
      final mapped = JsonImportService.mapErrorMessage(
        l: l,
        entity: JsonImportEntityType.invoice,
        statusCode: e.statusCode,
        backendMessage: e.debugMessage,
      );
      _setJsonImportError(mapped);
      if (!context.mounted) return;
      showErrorSnack(context, mapped);
    } catch (e) {
      _setJsonImportError(e.toString());
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      showErrorSnack(context, l.invoiceLinesJsonImportGenericError);
    } finally {
      _importingJsonLines = false;
      notifyListeners();
    }
  }

  Future<void> _reloadDraftLinesFromApi(String invoiceId) async {
    final fetched = await _linesApi.list(invoiceId);
    final sorted = [...fetched]
      ..sort((a, b) => a.position.compareTo(b.position));

    _resetDraftLines();
    for (final line in sorted) {
      lines.add(_draftFromLine(line));
    }
    if (lines.isEmpty) {
      lines.add(LineDraft(position: 1));
    }
    if (_savedInvoice != null) {
      _savedInvoice = _savedInvoice!.copyWith(lines: sorted);
    }
    _previewedPdf = false;
    _previewPdfBytes = null;
    _confirmSaveDraft = false;
  }

  void _setJsonImportError(String value) {
    _jsonImportError = value.trim().isEmpty ? null : value.trim();
    notifyListeners();
  }

  List<LineDraft> _seedLineDraftsFromJsonPayload(
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) return const <LineDraft>[];
    final rawLines = payload['draftLines'] ?? payload['lines'];
    if (rawLines is! List) return const <LineDraft>[];

    num parseNum(dynamic value, num fallback) {
      if (value is num) return value;
      final parsed = num.tryParse(value.toString().trim().replaceAll(',', '.'));
      return parsed ?? fallback;
    }

    final defaultTaxRate = parseNum(
      payload['defaultTaxRate'],
      _jsonDefaultTaxRate,
    );
    final seeded = <LineDraft>[];
    for (var i = 0; i < rawLines.length; i++) {
      final raw = rawLines[i];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final description = (map['description'] ?? '').toString().trim();
      final quantity = parseNum(map['quantity'], 1);
      final unitPrice = parseNum(map['unitPrice'], 0);
      final taxRate = parseNum(map['taxRate'], defaultTaxRate);
      final rawConceptItems = map['conceptItems'];
      final conceptItems = rawConceptItems is List
          ? rawConceptItems
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
          : null;
      final sku = cleanInvoiceText(map['sku']?.toString());
      final items = cleanInvoiceConceptItems(conceptItems, staleSku: sku);
      final conceptTitle = invoiceConceptTitleFrom(
        conceptTitle: map['conceptTitle']?.toString(),
        sku: sku,
      );
      final hasConcept =
          description.isNotEmpty || conceptTitle != null || items != null;
      if (!hasConcept || unitPrice <= 0) continue;

      final draft = LineDraft(
        position: seeded.length + 1,
        sku: isInvoiceUnitCode(sku) ? sku : null,
        conceptItems: items,
        conceptTitle: conceptTitle,
        serviceDate: cleanInvoiceServiceDate(map['serviceDate']),
        isCompositeConcept: map['isCompositeConcept'] is bool
            ? map['isCompositeConcept'] as bool
            : (items?.length ?? 0) > 1
                ? true
                : null,
        parseMethod: map['parseMethod']?.toString(),
      );
      draft.description.text = description;
      draft.quantityCtrl.text = quantity <= 0 ? '1' : quantity.toString();
      draft.unitPriceCtrl.text = unitPrice.toString();
      draft.taxRateCtrl.text = taxRate < 0 ? '0' : taxRate.toString();
      seeded.add(draft);
    }
    return seeded;
  }
}
