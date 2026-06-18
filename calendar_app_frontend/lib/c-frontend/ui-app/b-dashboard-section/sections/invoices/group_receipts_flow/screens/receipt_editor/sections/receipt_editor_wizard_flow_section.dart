part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardFlowSection on _ReceiptEditorWizardScreenState {
  void _releasePreviewSurface() {
    _previewPdfBytes = null;
    _previewError = null;
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) {
      setState(() {
        _issueDate = picked;
        _markDraftDirty();
      });
    }
  }

  void _close({required bool changed}) {
    _releasePreviewSurface();
    final isEmbedded = widget.embedded == true;
    if (isEmbedded) {
      widget.onClose?.call(changed);
      return;
    }
    Navigator.of(context).pop(changed);
  }

  Future<void> _requestClose() async {
    if (!_draftDirty || _savingDraft) {
      _close(changed: _didPersist);
      return;
    }
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Tienes cambios sin guardar' : 'Unsaved changes'),
        content: Text(
          isEs
              ? 'Puedes quedarte, salir sin guardar o guardar el borrador antes de salir.'
              : 'You can stay, leave without saving, or save the draft before leaving.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('stay'),
            child: Text(isEs ? 'Quedarme' : 'Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('leave'),
            child: Text(isEs ? 'Salir sin guardar' : 'Leave without saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(isEs ? 'Guardar y salir' : 'Save & leave'),
          ),
        ],
      ),
    );
    if (!mounted || result == null || result == 'stay') return;
    if (result == 'save') {
      await _saveDraft(showSavedSnack: false);
      if (!mounted || _draftDirty) return;
    }
    _close(changed: _didPersist);
  }

  bool _validateCurrentStep() {
    final l = AppLocalizations.of(context)!;
    if (widget.group.id.trim().isEmpty) {
      showInfoSnack(context, l.fieldIsRequired);
      return false;
    }
    if (_step == 0 && !_hasClient) {
      showInfoSnack(context, l.receiptClientRequired);
      return false;
    }
    if (_step == 1 && !_hasLines) {
      showInfoSnack(context, l.receiptLinesRequired);
      return false;
    }
    return true;
  }

  List<ReceiptLine> _payloadLines() {
    final active = _lines.where((line) => line.hasAnyValue).toList();
    return active
        .map(
          (line) => ReceiptLine(
            description:
                line.description.trim().isEmpty ? '-' : line.description.trim(),
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            total: line.total,
          ),
        )
        .toList(growable: false);
  }

  Future<Receipt?> _saveDraft({
    bool showSavedSnack = true,
    String? successSnackMessage,
    String? genericErrorMessage,
    bool emitErrorSnack = true,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (!_hasClient || !_hasLines) {
      _validateCurrentStep();
      return null;
    }
    if (_savingDraft) return _draftReceipt;

    setState(() => _savingDraft = true);
    try {
      final payloadReceipt = Receipt(
        id: _draftReceipt?.id ?? '',
        groupId: widget.group.id,
        clientId: _useManualClient ? '' : _clientId!,
        clientName: _useManualClient ? _clientNameCtrl.text.trim() : null,
        status: 'draft',
        issueDate: _issueDate,
        notes: _notesCtrl.text.trim(),
        lines: _payloadLines(),
      );
      final saved = (_draftReceipt == null || _draftReceipt!.id.trim().isEmpty)
          ? await _receiptsApi.create(payloadReceipt)
          : await _receiptsApi.update(
              _draftReceipt!.id,
              payloadReceipt.toUpdatePayload(),
            );
      if (!mounted) return null;
      setState(() {
        _draftReceipt = saved;
        _didPersist = true;
        _markDraftSynced();
      });
      if (showSavedSnack) {
        showSuccessSnack(
          context,
          successSnackMessage ?? l.receiptDraftSavedSnackMessage,
          title: l.receiptDraftSavedSnackTitle,
          actionLabel: l.invoiceDraftSnackDismiss,
        );
      }
      return saved;
    } catch (e) {
      if (!mounted) return null;
      var msg = e.toString().replaceFirst('Exception: ', '').trim();
      final lowerMsg = msg.toLowerCase();
      if (lowerMsg.contains('e11000 duplicate key error') &&
          lowerMsg.contains('receiptnumber') &&
          lowerMsg.contains('null')) {
        final isEs = Localizations.localeOf(context)
            .languageCode
            .toLowerCase()
            .startsWith('es');
        msg = isEs
            ? 'Ya existe un recibo borrador sin numerar para este grupo. Revisa la lista de borradores de recibos.'
            : 'An unnumbered draft receipt already exists for this group. Check the receipts drafts list.';
      }
      if (emitErrorSnack) {
        showErrorSnack(
          context,
          msg.isEmpty ? (genericErrorMessage ?? l.failedWithReason('')) : msg,
        );
      }
      setState(() => _draftSaveFailed = true);
      return null;
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _loadDraftPreview({required String receiptId}) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _loadingPreview = true;
      _previewError = null;
    });
    try {
      final r = await _receiptsApi.previewPdf(receiptId);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      if (!mounted) return;
      setState(() => _previewPdfBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _previewPdfBytes = null;
        _previewError = msg.isEmpty ? l.receiptPreviewFailed : msg;
      });
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _preparePreviewStep() async {
    final draft = await _saveDraft(showSavedSnack: false);
    if (draft == null || !mounted) return;
    await _loadDraftPreview(receiptId: draft.id);
  }

  Future<void> _syncDraftForPreviewFromSummary() async {
    final isSpanish =
        Localizations.localeOf(context).languageCode.startsWith('es');
    final successMessage = isSpanish
        ? 'Resumen actualizado. La vista previa usara los datos mas recientes.'
        : 'Summary updated. Preview will use the latest data.';
    final errorMessage = isSpanish
        ? 'No se pudo actualizar el borrador para la vista previa.'
        : 'Could not update the draft for preview.';

    await _saveDraft(
      showSavedSnack: true,
      successSnackMessage: successMessage,
      genericErrorMessage: errorMessage,
      emitErrorSnack: true,
    );
  }

  Future<void> _tryGoToStep(int targetStep) async {
    if (targetStep == _step) return;
    if (targetStep < _step) {
      setState(() {
        if (_step == 3) {
          _releasePreviewSurface();
        }
        _step = targetStep;
      });
      return;
    }
    if (targetStep > _step + 1) return;
    if (!_validateCurrentStep()) return;
    if (targetStep == 3) {
      await _preparePreviewStep();
      if (!mounted) return;
    }
    setState(() {
      if (targetStep != 3) {
        _releasePreviewSurface();
      }
      _step = targetStep;
    });
  }
}
