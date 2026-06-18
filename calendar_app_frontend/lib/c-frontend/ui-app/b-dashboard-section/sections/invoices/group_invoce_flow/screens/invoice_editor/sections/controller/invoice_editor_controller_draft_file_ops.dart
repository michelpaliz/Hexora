part of '../invoice_editor_controller.dart';

extension InvoiceEditorControllerDraftFileOps on InvoiceEditorController {
  Future<Invoice> loadDraftForEdit(Invoice draft) async {
    if (draft.id.trim().isEmpty) {
      throw Exception('Draft is missing an id');
    }
    var full = await _invoicesApi.getById(draft.id);
    if (full.lines.isEmpty) {
      final lines = await _linesApi.list(draft.id);
      if (lines.isNotEmpty) {
        full = full.copyWith(lines: lines);
      }
    }
    return full;
  }

  Future<void> editDraftFromList(BuildContext context, Invoice draft) async {
    try {
      final draftId = draft.id.trim();
      if (draftId.isNotEmpty) {
        _editingDraftId = draftId;
        _savedInvoice = draft;
        _editingDraftMode = true;
        notifyListeners();
      }
      final full = await loadDraftForEdit(draft);
      _applyInitialInvoice(full);
      _previewedPdf = false;
      _previewPdfBytes = null;
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(context, e, fallback: 'Could not open draft'),
          ),
        ),
      );
    }
  }

  String _fileNameFromHeaders(Map<String, String> headers, Invoice invoice) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name;
      }
      final match = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
          .firstMatch(raw);
      if (match != null) {
        final name = match.group(1);
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    }
    final number = invoice.invoiceNumber.trim();
    if (number.isEmpty) return 'BORRADOR.pdf';
    return 'invoice-$number.pdf';
  }

  Future<void> downloadDraftPdf(BuildContext context, Invoice draft) async {
    try {
      final r = await _invoicesApi.downloadPdf(draft.id);
      final fileName = _fileNameFromHeaders(r.headers, draft);
      await launchFileDownload(
        r.bodyBytes,
        fileName: fileName,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _safeErrorMessage(
              context,
              e,
              fallback: 'Could not download PDF',
            ),
          ),
        ),
      );
    }
  }
}
