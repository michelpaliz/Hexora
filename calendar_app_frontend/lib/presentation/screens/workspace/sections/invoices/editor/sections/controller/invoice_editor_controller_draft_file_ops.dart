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

  Future<void> downloadDraftPdf(BuildContext context, Invoice draft) async {
    final pdfPrefix = Localizations.localeOf(context).languageCode == 'es' ? 'factura' : 'invoice';
    try {
      final r = await _invoicesApi.downloadPdf(draft.id);
      final invoiceNumber = draft.invoiceNumber.trim();
      final fileName = invoiceNumber.isEmpty
          ? '$pdfPrefix-draft-${draft.id}.pdf'
          : '$pdfPrefix-$invoiceNumber.pdf';
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
