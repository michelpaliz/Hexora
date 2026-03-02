part of '../invoice_editor_controller.dart';
extension InvoiceEditorControllerDraftFlow on InvoiceEditorController {
  Future<Invoice> saveDraft(BuildContext context) async {
    return _saveDraftInternal(context, allowEmptyLines: false);
  }

  Future<Invoice> _saveDraftInternal(
    BuildContext context, {
    required bool allowEmptyLines,
  }) async {
    final l = AppLocalizations.of(context)!;

    if (!formKey.currentState!.validate()) {
      throw Exception(l.invoiceFillRequiredFieldsError);
    }
    if (_useBlocks) {
      if (!allowEmptyLines && !hasBillableEntries) {
        throw Exception(l.invoiceLinesRequired);
      }
      if (!allowEmptyLines || hasBillableEntries) {
        _validateBlocks(l);
      }
    } else if (!allowEmptyLines && !hasLines) {
      throw Exception(l.invoiceLinesRequired);
    }
    if (_clientId == null) {
      throw Exception(l.selectClientFirst);
    }

    _saving = true;
    notifyListeners();
    try {
      if (_editingDraftId != null && _editingDraftId!.trim().isNotEmpty) {
        final blocksPayload =
            _useBlocks ? _sanitizeBlocks(blocks) : _blocksFromLines(lines);
        final payload = _buildDraftUpdatePayload(blocksPayload);
        final updated =
            await _invoicesApi.updateDraft(_editingDraftId!, payload);

        if (!_useBlocks) {
          final existing = await _linesApi.list(_editingDraftId!);
          for (final line in existing) {
            final id = line.id;
            if (id != null && id.isNotEmpty) {
              await _linesApi.delete(_editingDraftId!, id);
            }
          }
          final updatedLines = <InvoiceLine>[];
          if (!allowEmptyLines) {
            for (var i = 0; i < lines.length; i++) {
              final d = lines[i];
              final saved =
                  await _linesApi.create(_editingDraftId!, d.toLine());
              updatedLines.add(saved);
              d.id = saved.id;
              d.evidenceBlobName = saved.evidenceBlobName;
            }
          }
          _savedInvoice = updated.copyWith(lines: updatedLines);
        } else {
          _savedInvoice = updated.copyWith(blocks: blocksPayload);
        }
        _pendingDrafts = [
          _savedInvoice!,
          ..._pendingDrafts.where((inv) => inv.id != _savedInvoice!.id),
        ];
        _pendingDraftsCount = _pendingDrafts.length;
        notifyListeners();
        return _savedInvoice!;
      }
      final sanitizedBlocks =
          _useBlocks ? _sanitizeBlocks(blocks) : const <InvoiceBlock>[];
      final invoice = Invoice(
        id: '',
        invoiceNumber: invoiceNumber,
        groupId: group.id,
        clientId: _clientId!,
        pdfUrl: pdfUrl.text.trim().isEmpty ? null : pdfUrl.text.trim(),
        currency: currency.text.trim().isEmpty ? 'EUR' : currency.text.trim(),
        issueDate: invoiceDate.value,
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        discountAmount: discountAmountValue != null && discountAmountValue! > 0
            ? discountAmountValue
            : null,
        discountPercent:
            discountPercentValue != null && discountPercentValue! > 0
                ? discountPercentValue
                : null,
        blocks: sanitizedBlocks,
      );

      final payload = invoice.toCreatePayload();
      debugPrint('[InvoiceDraft] create payload: $payload');
      final created = await _invoicesApi.create(invoice);
      debugPrint('[InvoiceDraft] create response: ${created.toJson()}');
      try {
        final fetched = await _invoicesApi.getById(created.id);
        debugPrint('[InvoiceDraft] fetched response: ${fetched.toJson()}');
      } catch (e) {
        debugPrint('[InvoiceDraft] fetch failed: $e');
      }

      final createdLines = <InvoiceLine>[];
      if (!_useBlocks) {
        if (!allowEmptyLines) {
          for (var i = 0; i < lines.length; i++) {
            final d = lines[i];
            final saved = await _linesApi.create(created.id, d.toLine());
            createdLines.add(saved);
            d.id = saved.id;
            d.evidenceBlobName = saved.evidenceBlobName;
          }
        }
        _savedInvoice = created.copyWith(lines: createdLines);
      } else {
        _savedInvoice = created.copyWith(blocks: sanitizedBlocks);
      }
      if (_savedInvoice?.status == 'draft') {
        final savedDraft = _savedInvoice!;
        _editingDraftId = savedDraft.id.trim().isEmpty ? null : savedDraft.id;
        _pendingDrafts = [
          savedDraft,
          ..._pendingDrafts.where((inv) => inv.id != savedDraft.id),
        ];
        _pendingDraftsCount = _pendingDrafts.length;
      }
      notifyListeners();
      return _savedInvoice!;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }


}
