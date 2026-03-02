part of '../receipt_editor_wizard_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _ReceiptEditorWizardFlowSection on _ReceiptEditorWizardScreenState {
  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) {
      setState(() => _issueDate = picked);
    }
  }

  void _close({required bool changed}) {
    final isEmbedded = widget.embedded == true;
    if (isEmbedded) {
      widget.onClose?.call(changed);
      return;
    }
    Navigator.of(context).pop(changed);
  }

  bool _validateCurrentStep() {
    final l = AppLocalizations.of(context)!;
    if (_step == 0 && !_hasClient) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.receiptClientRequired)));
      return false;
    }
    if (_step == 1 && !_hasLines) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.receiptLinesRequired)));
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

  Future<Receipt?> _saveDraft({bool showSavedSnack = true}) async {
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
        clientId: _clientId!,
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
      });
      if (showSavedSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.receiptDraftSavedSnack)),
        );
      }
      return saved;
    } catch (e) {
      if (!mounted) return null;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? l.failedWithReason('') : msg)),
      );
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
      setState(() => _step = targetStep);
      return;
    }
    if (targetStep > _step + 1) return;
    if (!_validateCurrentStep()) return;
    if (targetStep == 3) {
      await _preparePreviewStep();
      if (!mounted) return;
    }
    setState(() => _step = targetStep);
  }

  void _finishFlow() {
    final l = AppLocalizations.of(context)!;
    if (!_hasClient || !_hasLines) {
      _validateCurrentStep();
      return;
    }

    () async {
      if (_issuing) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l.receiptIssueConfirmTitle),
          content: Text(l.receiptIssueConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.receiptIssueCta),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      setState(() => _issuing = true);
      try {
        final draft = await _saveDraft(showSavedSnack: false);
        if (draft == null || !mounted) return;
        final issued = await _receiptsApi.issue(draft.id);
        if (!mounted) return;
        setState(() {
          _draftReceipt = issued;
          _didPersist = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l.receiptIssueSuccessSnack(issued.receiptNumber ?? '')),
          ),
        );
        _close(changed: true);
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().replaceFirst('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.isEmpty ? l.receiptIssueFailed : msg)),
        );
      } finally {
        if (mounted) setState(() => _issuing = false);
      }
    }();
  }

}



