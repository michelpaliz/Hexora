part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardFlowSection on _ReceiptEditorWizardScreenState {
  bool get _shouldRefreshReceiptList =>
      _didPersist ||
      (_draftReceipt?.id.trim().isNotEmpty ?? false) ||
      (_existingUnnumberedReceiptId?.trim().isNotEmpty ?? false) ||
      _existingUnnumberedReceipt != null;

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
      _close(changed: _shouldRefreshReceiptList);
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
    _close(changed: _shouldRefreshReceiptList);
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
            unit: line.unit,
            unitLabel: line.unitLabel,
            unitPrice: line.unitPrice,
            total: line.total,
          ),
        )
        .toList(growable: false);
  }

  bool _validateReceiptLineValues() {
    final active = _lines.where((line) => line.hasAnyValue).toList();
    for (final line in active) {
      if (line.description.trim().isEmpty) {
        showInfoSnack(context, 'La descripcion es obligatoria.');
        return false;
      }
      if (line.quantity < 0) {
        showInfoSnack(context, 'La cantidad debe ser mayor o igual que 0.');
        return false;
      }
      if (line.unitPrice < 0) {
        showInfoSnack(context, 'El precio debe ser mayor o igual que 0.');
        return false;
      }
      if (line.unit == 'other' && (line.unitLabel ?? '').trim().length > 20) {
        showInfoSnack(context, 'La unidad personalizada maximo 20 caracteres.');
        return false;
      }
    }
    return true;
  }

  Future<void> _openExistingUnnumberedDraft({
    String? receiptId,
    Receipt? receipt,
  }) async {
    Receipt? existing = receipt;
    final id = receiptId ?? receipt?.id;
    if (existing == null && id != null && id.trim().isNotEmpty) {
      try {
        existing = await _receiptsApi.getById(id.trim());
      } catch (e) {
        if (!mounted) return;
        showErrorSnack(
          context,
          e.toString().replaceFirst('Exception: ', '').trim(),
        );
        return;
      }
    }
    if (existing == null || !mounted) return;
    setState(() {
      _applyReceiptDraft(existing!);
      _step = 1;
      _releasePreviewSurface();
    });
    if (_clientId != null) {
      await _loadClientReceiptStats(_clientId);
    }
  }

  void _showDraftsList() {
    _close(changed: _shouldRefreshReceiptList);
  }

  Future<void> _showExistingUnnumberedDraftDialog(
    ReceiptsApiException error,
  ) async {
    final isEs =
        Localizations.localeOf(context).languageCode.toLowerCase().startsWith(
              'es',
            );
    final receipt = error.receipt;
    final receiptId = error.existingReceiptId ?? receipt?.id;
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Borrador existente' : 'Existing draft'),
        content: Text(
          isEs
              ? 'Ya existe un recibo borrador sin numerar para este grupo.'
              : 'An unnumbered receipt draft already exists for this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('list'),
            child: Text(isEs ? 'Ver lista de borradores' : 'View drafts list'),
          ),
          FilledButton(
            onPressed: (receiptId ?? '').trim().isEmpty && receipt == null
                ? null
                : () => Navigator.of(dialogContext).pop('open'),
            child: Text(
              isEs ? 'Abrir borrador existente' : 'Open existing draft',
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'open') {
      await _openExistingUnnumberedDraft(
        receiptId: receiptId,
        receipt: receipt,
      );
    } else if (action == 'list') {
      _showDraftsList();
    }
  }

  Future<Receipt?> _saveDraft({
    bool showSavedSnack = true,
    String? successSnackMessage,
    String? genericErrorMessage,
    bool emitErrorSnack = true,
    bool allowEmptyLines = false,
  }) async {
    final l = AppLocalizations.of(context)!;
    if (!_hasClient || (!allowEmptyLines && !_hasLines)) {
      if (allowEmptyLines && !_hasClient) {
        showInfoSnack(context, l.receiptClientRequired);
      } else {
        _validateCurrentStep();
      }
      return null;
    }
    if (!allowEmptyLines && !_validateReceiptLineValues()) return null;
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
      if (e is ReceiptsApiException &&
          e.statusCode == 409 &&
          e.code == 'RECEIPT_UNNUMBERED_DRAFT_EXISTS') {
        setState(() {
          _existingUnnumberedReceiptId = e.existingReceiptId ?? e.receipt?.id;
          _existingUnnumberedReceipt = e.receipt;
          _draftSaveFailed = true;
        });
        await _showExistingUnnumberedDraftDialog(e);
        return null;
      }
      var msg = e.toString().replaceFirst('Exception: ', '').trim();
      if (msg.toLowerCase().contains('e11000 duplicate key error')) {
        msg = l.somethingWentWrong;
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

  Future<void> _tryGoToStep(int targetStep) async {
    if (targetStep == _step) return;
    if (targetStep < _step) {
      setState(() {
        if (_step == 2) {
          _releasePreviewSurface();
        }
        _step = targetStep;
      });
      return;
    }
    if (targetStep > _step + 1) return;
    if (!_validateCurrentStep()) return;
    if (targetStep == 2) {
      await _preparePreviewStep();
      if (!mounted) return;
    }
    setState(() {
      if (targetStep != 2) {
        _releasePreviewSurface();
      }
      _step = targetStep;
    });
  }
}
