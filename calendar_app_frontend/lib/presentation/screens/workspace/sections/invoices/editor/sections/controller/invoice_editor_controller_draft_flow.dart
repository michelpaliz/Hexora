part of '../invoice_editor_controller.dart';

extension InvoiceEditorControllerDraftFlow on InvoiceEditorController {
  Future<Invoice> saveDraft(BuildContext context) async {
    return _saveDraftInternal(context, allowEmptyLines: false);
  }

  Future<Invoice> saveAiDraft(BuildContext context) async {
    return _saveDraftInternal(context, allowEmptyLines: true);
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
    } else if (!allowEmptyLines && !hasBillableEntries) {
      throw Exception(l.invoiceLinesRequired);
    }
    if (_clientId == null) {
      throw Exception(l.selectClientFirst);
    }
    await _ensureInvoiceLanguage(context);
    // A newly created or unchanged draft already has the backend default
    // payment state. Do not make a second payment-endpoint request unless the
    // user actually changed payment details; that request used to turn an
    // otherwise successful draft save into a failed Continue action.
    if (_draftPaymentPayloadInvalid) {
      buildDraftPaymentPayload(context);
    }
    final paymentPayload =
        _draftPaymentPayload == null ? null : buildDraftPaymentPayload(context);

    _saving = true;
    notifyListeners();
    try {
      if (editingIssued) {
        final id = (_savedInvoice?.id ?? initialInvoice?.id ?? '').trim();
        final reason = (_issuedChangeReason ?? '').trim();
        if (id.isEmpty) throw Exception('Factura no encontrada.');
        if (reason.isEmpty) {
          throw Exception('El motivo del cambio es obligatorio.');
        }
        final blocksPayload =
            _useBlocks ? _sanitizeBlocks(blocks) : _blocksFromLines(lines);
        final payload = _buildIssuedUpdatePayload(blocksPayload, reason);
        final updated = await _invoicesApi.updateIssued(id, payload);
        _applyInitialInvoice(updated);
        _draftDirty = false;
        _draftSaveFailed = false;
        _issuedChangeReason = null;
        _dataRevision++;
        await refreshIssuedHistory();
        if (context.mounted) {
          await _refreshPreviewAfterIssuedUpdate(context);
        }
        notifyListeners();
        return updated;
      }
      if (_editingDraftId != null && _editingDraftId!.trim().isNotEmpty) {
        final blocksPayload =
            _useBlocks ? _sanitizeBlocks(blocks) : _blocksFromLines(lines);
        final payload = _buildDraftUpdatePayload(blocksPayload);
        final updated =
            await _invoicesApi.updateDraft(_editingDraftId!, payload);

        // updateDraft already receives `draftLines` in its payload. Calling the
        // legacy /lines endpoint again can return 404 on deployments where
        // line persistence is handled by the draft endpoint itself.
        final updatedLines = updated.lines.isNotEmpty
            ? updated.lines
            : _draftLinesForInvoice(_editingDraftId!);
        _savedInvoice = updated.copyWith(
          lines: updatedLines,
          blocks: blocksPayload,
        );
        if (paymentPayload != null) {
          _savedInvoice =
              await _applyDraftPayment(_savedInvoice!, paymentPayload);
        }
        _pendingDrafts = [
          _savedInvoice!,
          ..._pendingDrafts.where((inv) => inv.id != _savedInvoice!.id),
        ];
        _pendingDraftsCount = _pendingDrafts.length;
        _draftDirty = false;
        _draftSaveFailed = false;
        notifyListeners();
        return _savedInvoice!;
      }
      final sanitizedBlocks =
          _useBlocks ? _sanitizeBlocks(blocks) : _blocksFromLines(lines);
      final draftLines = _useBlocks
          ? const <InvoiceLine>[]
          : _billableLineDrafts()
              .map((d) => d.toLine())
              .toList(growable: false);
      final invoice = Invoice(
        id: '',
        invoiceNumber: '',
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
        lines: draftLines,
        documentLanguage: _documentLanguage,
      );

      final payload = invoice.toCreatePayload();
      debugPrint('[InvoiceDraft] create payload: $payload');
      final created = await _invoicesApi.create(invoice);
      debugPrint('[InvoiceDraft] create response: ${created.toJson()}');
      // The creation payload includes `draftLines` (or `blocks`). The server
      // persists them with the draft, so avoid a second legacy /lines request.
      // Some API versions omit lines from the create response; retain the local
      // draft lines in that case so the editor stays coherent.
      final createdLines = created.lines.isNotEmpty
          ? created.lines
          : _draftLinesForInvoice(created.id);
      _savedInvoice = created.copyWith(
        lines: createdLines,
        blocks: sanitizedBlocks,
      );
      if (paymentPayload != null) {
        _savedInvoice =
            await _applyDraftPayment(_savedInvoice!, paymentPayload);
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
      _draftDirty = false;
      _draftSaveFailed = false;
      notifyListeners();
      return _savedInvoice!;
    } catch (_) {
      _draftSaveFailed = true;
      notifyListeners();
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
