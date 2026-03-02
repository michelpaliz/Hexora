part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewFlowSection on _GroupInvoicesBudgetsViewState {
  Map<String, dynamic>? _pickBestDraft(List<Map<String, dynamic>> items) {
    final drafts = items
        .where((item) =>
            ((item['status'] ?? '').toString().toLowerCase().contains('draft')))
        .toList(growable: false);
    if (drafts.isEmpty) return null;
    final sorted = [...drafts]..sort((a, b) {
        final aTs = DateTime.tryParse(
                (a['updatedAt'] ?? a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTs = DateTime.tryParse(
                (b['updatedAt'] ?? b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTs.compareTo(aTs);
      });
    return sorted.first;
  }

  Future<String> _ensureDraftCreated({bool forceRebuild = false}) async {
    if (forceRebuild) {
      _draftId = null;
      _draftCreateInFlight = null;
    }
    final existing = (_draftId ?? '').trim();
    if (existing.isNotEmpty) {
      return existing;
    }
    if (_draftCreateInFlight != null) return _draftCreateInFlight!;

    final creation = () async {
      final linesPayload = _buildLinesPayload();
      final fallbackLinesFromBlocks = _buildLinesFromBlocksPayload();
      try {
        Future<Map<String, dynamic>> createDraft({
          required bool withContent,
        }) {
          // Only send clientId OR clientName, never both
          final bool useExisting = _clientSource == _ClientSource.existing;
          final String? clientId = useExisting &&
                  (_selectedClientId ?? '').trim().isNotEmpty
              ? _selectedClientId!.trim()
              : null;
          final String? clientName = !useExisting &&
                  _clientNameCtrl.text.trim().isNotEmpty
              ? _clientNameCtrl.text.trim()
              : null;

          return _presupuestosApi.createDraft(
            groupId: widget.groupId.trim(),
            clientId: clientId,
            clientName: clientName,
            lines: withContent
                ? (linesPayload.isNotEmpty
                    ? linesPayload
                    : fallbackLinesFromBlocks)
                : null,
            blocks: withContent ? _buildBlocksPayload() : null,
          );
        }

        final created = await createDraft(withContent: true);
        final id = _extractIdFromPayload(created);
        if (id.isEmpty) {
          throw Exception('Missing presupuesto draft id');
        }
        _draftId = id;
        return id;
      } on PresupuestosApiException catch (e) {
        if (e.statusCode != 409) rethrow;
        final itemsForClient = await _presupuestosApi.listByGroup(
          groupId: widget.groupId.trim(),
          clientId: (_selectedClientId ?? '').trim().isEmpty
              ? null
              : _selectedClientId!.trim(),
        );
        var draft = _pickBestDraft(itemsForClient);
        if (draft == null) {
          final itemsAnyClient = await _presupuestosApi.listByGroup(
            groupId: widget.groupId.trim(),
          );
          draft = _pickBestDraft(itemsAnyClient);
        }
        final reusedId = draft == null ? '' : _extractIdFromPayload(draft);
        if (reusedId.isNotEmpty) {
          _draftId = reusedId;
          return reusedId;
        }

        // If no reusable draft exists, try one minimal create without content.
        final bool useExisting = _clientSource == _ClientSource.existing;
        final String? clientId = useExisting &&
                (_selectedClientId ?? '').trim().isNotEmpty
            ? _selectedClientId!.trim()
            : null;
        final String? clientName = !useExisting &&
                _clientNameCtrl.text.trim().isNotEmpty
            ? _clientNameCtrl.text.trim()
            : null;

        final minimal = await _presupuestosApi.createDraft(
          groupId: widget.groupId.trim(),
          clientId: clientId,
          clientName: clientName,
        );
        final minimalId = _extractIdFromPayload(minimal);
        if (minimalId.isNotEmpty) {
          _draftId = minimalId;
          return minimalId;
        }

        if (reusedId.isEmpty) rethrow;
        return reusedId;
      } finally {
        _draftCreateInFlight = null;
      }
    }();

    _draftCreateInFlight = creation;
    return creation;
  }

  Future<void> _createDraftAndPreparePreview(
      {bool forceRebuild = false}) async {
    final l = AppLocalizations.of(context)!;
    if (widget.groupId.trim().isEmpty) {
      setState(() => _error = l.budgetValidationGroupRequired);
      return;
    }
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      final id = await _ensureDraftCreated(forceRebuild: forceRebuild);
      if (!mounted) return;
      setState(() {
        _draftId = id;
      });
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
      return;
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
    await _loadPreviewPdf(force: true);
  }

  Future<void> _issueBudgetAndPreparePreview(
      {bool forceRebuild = false}) async {
    final l = AppLocalizations.of(context)!;
    if (widget.groupId.trim().isEmpty) {
      setState(() => _error = l.budgetValidationGroupRequired);
      return;
    }
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      final id = await _ensureDraftCreated(forceRebuild: forceRebuild);
      final issued = await _presupuestosApi.issue(id);
      final issuedNumber = _extractNumberFromPayload(issued);
      final issuedId = _extractIdFromPayload(issued);
      if (!mounted) return;
      setState(() {
        _draftId = issuedId.isEmpty ? id : issuedId;
        _issuedPresupuestoNumber = issuedNumber;
      });
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      final conflict = e.statusCode == 409;
      setState(() {
        _error = conflict ? l.budgetIssueConflict : e.message;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
      return;
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
    await _loadPreviewPdf(force: true);
  }

  Future<void> _loadPreviewPdf({bool force = false}) async {
    final id = (_draftId ?? '').trim();
    if (id.isEmpty) {
      setState(() => _previewError = 'Missing presupuesto id');
      return;
    }
    if (!force && _previewForId == id && _previewPdfBytes != null) return;
    if (_loadingPreview) return;
    setState(() {
      _loadingPreview = true;
      _previewError = null;
      _previewPdfBytes = null;
    });
    try {
      final r = await _presupuestosApi.previewPdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      if (!mounted) return;
      setState(() {
        _previewPdfBytes = bytes;
        _previewForId = id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingPreview = false);
      }
    }
  }

  Future<void> _loadDetailPreviewPdf(String budgetId) async {
    final id = budgetId.trim();
    if (id.isEmpty) {
      setState(() => _detailPreviewError = 'Missing presupuesto id');
      return;
    }
    if (_detailPreviewForId == id && _detailPreviewPdfBytes != null) return;
    if (_loadingDetailPreview) return;
    setState(() {
      _loadingDetailPreview = true;
      _detailPreviewError = null;
      _detailPreviewPdfBytes = null;
    });
    try {
      final r = await _presupuestosApi.previewPdf(id);
      final bytes = InvoiceEditorPdf.validatePdf(r);
      if (!mounted) return;
      setState(() {
        _detailPreviewPdfBytes = bytes;
        _detailPreviewForId = id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailPreviewError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _loadingDetailPreview = false);
      }
    }
  }

  bool _validateCurrentStep() {
    final l = AppLocalizations.of(context)!;
    if (_visibleStep == 0 && !_hasClientInfo) {
      setState(() {
        _error = l.budgetValidationClientRequired;
      });
      return false;
    }
    if (_visibleStep == 2 && !_hasLineContent) {
      setState(() {
        _error = l.budgetValidationLineItemsRequired;
      });
      return false;
    }
    if (_visibleStep == 3 && !_confirmPreview) {
      setState(() {
        _error = l.budgetPreviewAcceptRequired;
      });
      return false;
    }
    return true;
  }

  Future<void> _saveDraftOnly() async {
    final l = AppLocalizations.of(context)!;
    if (!_hasClientInfo) {
      setState(() {
        _error = l.budgetValidationClientRequired;
      });
      return;
    }
    if (!_hasLineContent) {
      setState(() {
        _error = l.budgetValidationLineItemsRequired;
      });
      return;
    }
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      final id = await _ensureDraftCreated(forceRebuild: true);
      if (!mounted) return;
      setState(() => _draftId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Borrador guardado: $id'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  Future<void> _validateAndSave() async {
    final l = AppLocalizations.of(context)!;
    if (!_hasClientInfo) {
      setState(() {
        _error = l.budgetValidationClientRequired;
      });
      return;
    }
    if (!_hasLineContent) {
      setState(() {
        _error = l.budgetValidationLineItemsRequired;
      });
      return;
    }
    await _issueBudgetAndPreparePreview(forceRebuild: true);
    if (!mounted || _error != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.budgetIssuedSnack(
            _issuedPresupuestoNumber ?? '-',
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _previewRows() {
    if (_useBlocks) {
      return _budgetBlocks.where((b) => b.hasBillableContent).map((b) {
        final qty = b.qty ?? 1;
        final unitPrice = b.unitPrice ?? 0;
        final taxRate = b.taxRate ?? 21;
        final subtotal = qty * unitPrice;
        final total = subtotal + (subtotal * (taxRate / 100));
        final label = b.description.text.trim().isNotEmpty
            ? b.description.text.trim()
            : (b.title.text.trim().isNotEmpty ? b.title.text.trim() : '-');
        return <String, dynamic>{
          'label': label,
          'qty': qty,
          'unitPrice': unitPrice,
          'taxRate': taxRate,
          'total': total,
        };
      }).toList(growable: false);
    }
    return _budgetLines
        .where((line) =>
            line.description.text.trim().isNotEmpty && (line.quantity ?? 0) > 0)
        .map((line) {
      final qty = line.quantity ?? 1;
      final unitPrice = line.unitPrice ?? 0;
      final taxRate = line.taxRate ?? 21;
      final subtotal = qty * unitPrice;
      final total = subtotal + (subtotal * (taxRate / 100));
      return <String, dynamic>{
        'label': line.description.text.trim(),
        'qty': qty,
        'unitPrice': unitPrice,
        'taxRate': taxRate,
        'total': total,
      };
    }).toList(growable: false);
  }

  num _previewTotal() {
    return _useBlocks
        ? InvoiceEditorFormatters.totalBlocks(_budgetBlocks)
        : InvoiceEditorFormatters.total(_budgetLines);
  }

  Widget _budgetPreviewWidget(AppLocalizations l) {
    final cs = Theme.of(context).colorScheme;
    final rows = _previewRows();
    final nf = NumberFormat.simpleCurrency(name: '');
    final previewTotal = _previewTotal();

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(
          l.budgetPreviewEmpty,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.budgetPreviewInlineTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...rows.take(5).map((row) {
            final label = row['label']?.toString() ?? '-';
            final qty = row['qty'];
            final unitPrice = row['unitPrice'];
            final total = row['total'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$qty x ${nf.format(unitPrice)}'),
                  const SizedBox(width: 10),
                  Text(
                    nf.format(total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
          if (rows.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+${rows.length - 5}',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              const Spacer(),
              Text(
                '${l.invoiceTotalLabel}: ${nf.format(previewTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

