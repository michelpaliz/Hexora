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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLinesJsonImportNoFile)),
      );
      return;
    }

    await _runJsonImport(
      context,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDraftSaveFailedSnack)),
      );
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
      await Clipboard.setData(ClipboardData(text: text));
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLinesJsonImportPromptCopied)),
      );
    } on line_ev.InvoiceLinesJsonImportException catch (e) {
      _setJsonImportError(e.debugMessage);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (e) {
      _setJsonImportError(e.toString());
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLinesJsonImportGenericError)),
      );
    } finally {
      _loadingJsonPromptTemplate = false;
      notifyListeners();
    }
  }

  Future<void> _runJsonImport(
    BuildContext context, {
    required Future<line_ev.InvoiceLinesJsonImportResult> Function(String)
        execute,
  }) async {
    if (_importingJsonLines) return;

    final draftId = await _ensureDraftIdForOcr(context);
    if (!context.mounted) return;
    if (draftId == null || draftId.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceDraftSaveFailedSnack)),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.invoiceLinesJsonImportSuccess(result.importedCount.toString()),
          ),
        ),
      );
      if (JsonImportService.extractRepairApplied(result.raw)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON auto-corrected before import.')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapped)),
      );
    } catch (e) {
      _setJsonImportError(e.toString());
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.invoiceLinesJsonImportGenericError)),
      );
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
}
