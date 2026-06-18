part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewFlowSection
    on _GroupInvoicesBudgetsViewState {
  String _savedManualClientValue(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    final data = _budgetPayloadData(payload);
    final snapshot = data['clientSnapshot'] is Map
        ? Map<String, dynamic>.from(data['clientSnapshot'] as Map)
        : const <String, dynamic>{};
    return _payloadText(data, snapshot, keys);
  }

  void _assertManualClientFieldsPersisted(
    Map<String, dynamic> submitted,
    Map<String, dynamic> saved,
  ) {
    if (_clientSource != _ClientSource.manual) return;

    final expected = <String, List<String>>{
      'clientName': const ['clientName', 'billingName', 'legalName', 'name'],
      'addressStreet': const ['addressStreet', 'address', 'street'],
      'addressCity': const ['addressCity', 'city'],
      'addressPostalCode': const ['addressPostalCode', 'postalCode', 'cp'],
    };

    for (final entry in expected.entries) {
      final submittedValue = (submitted[entry.key] ?? '').toString().trim();
      if (submittedValue.isEmpty) continue;
      final savedValue = _savedManualClientValue(saved, entry.value);
      if (savedValue == submittedValue) continue;
      throw PresupuestosApiException(
        statusCode: 200,
        message: _isSpanishLocale
            ? 'El servidor ha respondido correctamente, pero no ha guardado los datos manuales del cliente. Revisa que el endpoint de presupuestos persista clientSnapshot, direccion, ciudad y CP.'
            : 'The server returned success, but did not persist the manual client data. Check that the presupuesto endpoint saves clientSnapshot, address, city, and postal code.',
      );
    }
  }

  Future<String> _persistDraftChanges() async {
    final existingId = (_draftId ?? '').trim();
    final payload = _buildBudgetDraftUpdatePayload();
    if (existingId.isNotEmpty) {
      final updated = await _presupuestosApi.updateDraft(
        id: existingId,
        clientId: payload['clientId']?.toString(),
        clientName: payload['clientName']?.toString(),
        addressStreet: payload['addressStreet']?.toString(),
        addressCity: payload['addressCity']?.toString(),
        addressPostalCode: payload['addressPostalCode']?.toString(),
        clientSnapshot:
            (payload['clientSnapshot'] as Map?)?.cast<String, dynamic>(),
        issueDate: payload['issueDate']?.toString(),
        notes: payload['notes']?.toString(),
        currency: payload['currency']?.toString(),
        lines: (payload['lines'] as List?)?.cast<Map<String, dynamic>>(),
        blocks: (payload['blocks'] as List?)?.cast<Map<String, dynamic>>(),
        totals: (payload['totals'] as Map?)?.cast<String, dynamic>(),
      );
      _assertManualClientFieldsPersisted(payload, updated);
      _applyEditableBudgetPayload(updated, resetWizard: false);
      return _draftId ?? existingId;
    }

    final createdId = await _ensureDraftCreated(forceRebuild: true);
    final updated = await _presupuestosApi.updateDraft(
      id: createdId,
      clientId: payload['clientId']?.toString(),
      clientName: payload['clientName']?.toString(),
      addressStreet: payload['addressStreet']?.toString(),
      addressCity: payload['addressCity']?.toString(),
      addressPostalCode: payload['addressPostalCode']?.toString(),
      clientSnapshot:
          (payload['clientSnapshot'] as Map?)?.cast<String, dynamic>(),
      issueDate: payload['issueDate']?.toString(),
      notes: payload['notes']?.toString(),
      currency: payload['currency']?.toString(),
      lines: (payload['lines'] as List?)?.cast<Map<String, dynamic>>(),
      blocks: (payload['blocks'] as List?)?.cast<Map<String, dynamic>>(),
      totals: (payload['totals'] as Map?)?.cast<String, dynamic>(),
    );
    _assertManualClientFieldsPersisted(payload, updated);
    _applyEditableBudgetPayload(updated, resetWizard: false);
    return _draftId ?? createdId;
  }

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
          final String? clientId =
              useExisting && (_selectedClientId ?? '').trim().isNotEmpty
                  ? _selectedClientId!.trim()
                  : null;
          final String? clientName =
              !useExisting && _clientNameCtrl.text.trim().isNotEmpty
                  ? _clientNameCtrl.text.trim()
                  : null;
          final clientSnapshot = _buildManualClientSnapshotPayload();

          return _presupuestosApi.createDraft(
            groupId: widget.groupId.trim(),
            clientId: clientId,
            clientName: clientName,
            addressStreet: _clientAddressCtrl.text.trim(),
            addressCity: _clientCityCtrl.text.trim(),
            addressPostalCode: _clientPostalCodeCtrl.text.trim(),
            clientSnapshot: clientSnapshot,
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
        final String? clientId =
            useExisting && (_selectedClientId ?? '').trim().isNotEmpty
                ? _selectedClientId!.trim()
                : null;
        final String? clientName =
            !useExisting && _clientNameCtrl.text.trim().isNotEmpty
                ? _clientNameCtrl.text.trim()
                : null;
        final clientSnapshot = _buildManualClientSnapshotPayload();

        final minimal = await _presupuestosApi.createDraft(
          groupId: widget.groupId.trim(),
          clientId: clientId,
          clientName: clientName,
          addressStreet: _clientAddressCtrl.text.trim(),
          addressCity: _clientCityCtrl.text.trim(),
          addressPostalCode: _clientPostalCodeCtrl.text.trim(),
          clientSnapshot: clientSnapshot,
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
      if (forceRebuild) {
        _draftCreateInFlight = null;
      }
      final id = await _persistDraftChanges();
      if (!mounted) return;
      setState(() {
        _draftId = id;
        _visibleStep = 4;
        _confirmPreview = true;
      });
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      final msg = _translateApiError(e.message, isSpanish: _isSpanishLocale);
      setState(() {
        _error = msg;
      });
      showErrorSnack(context, msg);
      return;
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = _translateApiError(raw, isSpanish: _isSpanishLocale);
      setState(() {
        _error = msg;
      });
      showErrorSnack(context, msg);
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
        _detailPreviewError =
            e.toString().replaceFirst('Exception: ', '').trim();
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
    if (_visibleStep == 1 &&
        _isIssuedEditable &&
        _issuedEditReasonCtrl.text.trim().isEmpty) {
      setState(() {
        _error = _isSpanishLocale
            ? 'Indica el motivo del cambio para continuar.'
            : 'Add the change reason before continuing.';
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
      final msg = l.budgetValidationClientRequired;
      setState(() {
        _error = msg;
      });
      showErrorSnack(context, msg);
      return;
    }
    if (!_hasLineContent) {
      final msg = l.budgetValidationLineItemsRequired;
      setState(() {
        _error = msg;
      });
      showErrorSnack(context, msg);
      return;
    }
    if (!_isDraftEditable && !_isIssuedEditable) {
      showInfoSnack(context, l.budgetDraftNotEditableSnack);
      return;
    }
    if (_isIssuedEditable && _issuedEditReasonCtrl.text.trim().isEmpty) {
      final msg = _isSpanishLocale
          ? 'Indica el motivo del cambio para guardar una version.'
          : 'Add a reason before saving a new version.';
      setState(() => _error = msg);
      showErrorSnack(context, msg);
      return;
    }
    setState(() {
      _issuing = true;
      _error = null;
    });
    try {
      final id = (_isIssuedEditable)
          ? await _persistIssuedChanges()
          : await _persistDraftChanges();
      if (!mounted) return;
      setState(() {
        _draftId = id;
        _editableBudgetDirty = false;
        widget.onUnsavedStateChanged?.call(false);
      });
      await _loadPreviewPdf(force: true);
      if (_isIssuedEditable) {
        await _loadEditableBudget(id);
        await _loadBudgets();
      }
      if (!mounted) return;
      showSuccessSnack(
        context,
        l.budgetDraftUpdatedSnackMessage,
        title: l.budgetDraftUpdatedSnackTitle,
        actionLabel: l.invoiceDraftSnackDismiss,
      );
    } on PresupuestosApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 409
          ? l.budgetDraftNotEditableSnack
          : _translateApiError(e.message, isSpanish: _isSpanishLocale);
      setState(() => _error = msg);
      showErrorSnack(context, msg);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = _translateApiError(raw, isSpanish: _isSpanishLocale);
      setState(() {
        _error = msg;
      });
      showErrorSnack(context, msg);
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  static String _translateApiError(String raw, {required bool isSpanish}) {
    final lower = raw.toLowerCase();
    if (lower.contains('item description is required') ||
        lower.contains('description is required')) {
      return isSpanish
          ? 'Añade un concepto de trabajo para la línea. Si no indicas vivienda/unidad, usaremos "Unit".'
          : 'Add a work concept for the line. If unit/title is empty, we will use "Unit".';
    }
    if (lower.contains('not found')) {
      return isSpanish ? 'No encontrado.' : 'Not found.';
    }
    if (lower.contains('unauthorized') || lower.contains('unauthenticated')) {
      return isSpanish
          ? 'Sin autorización. Vuelve a iniciar sesión.'
          : 'Not authorized. Please sign in again.';
    }
    if (lower.contains('forbidden')) {
      return isSpanish ? 'Acceso denegado.' : 'Access denied.';
    }
    if (lower.contains('internal server error') ||
        lower.contains('server error')) {
      return isSpanish
          ? 'Error interno del servidor. Inténtalo de nuevo.'
          : 'Server error. Please try again.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return isSpanish
          ? 'Error de red. Comprueba tu conexión.'
          : 'Network error. Check your connection.';
    }
    if (lower.contains('item description is required') ||
        lower.contains('description is required')) {
      return 'La descripción del artículo es requerida.';
    }
    if (lower.contains('not found')) return 'No encontrado.';
    if (lower.contains('unauthorized') || lower.contains('unauthenticated')) {
      return 'Sin autorización. Vuelve a iniciar sesión.';
    }
    if (lower.contains('forbidden')) return 'Acceso denegado.';
    if (lower.contains('internal server error') ||
        lower.contains('server error')) {
      return 'Error interno del servidor. Inténtalo de nuevo.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Error de red. Comprueba tu conexión.';
    }
    return raw;
  }

  Future<String> _persistIssuedChanges() async {
    final existingId = (_draftId ?? '').trim();
    if (existingId.isEmpty) throw Exception('Missing presupuesto id');
    final payload = _buildBudgetDraftUpdatePayload();
    final updated = await _presupuestosApi.updateIssued(
      id: existingId,
      notes: payload['notes']?.toString(),
      currency: payload['currency']?.toString(),
      blocks: (payload['blocks'] as List?)?.cast<Map<String, dynamic>>(),
      clientSnapshot:
          (payload['clientSnapshot'] as Map?)?.cast<String, dynamic>(),
      reason: _issuedEditReasonCtrl.text.trim(),
    );
    _applyEditableBudgetPayload(updated, resetWizard: false);
    return _draftId ?? existingId;
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
    await _createDraftAndPreparePreview(forceRebuild: true);
    if (!mounted || _error != null) return;
    showSuccessSnack(
      context,
      l.budgetDraftSavedSnackMessage,
      title: l.budgetDraftSavedSnackTitle,
      actionLabel: l.invoiceDraftSnackDismiss,
    );
  }

  List<Map<String, dynamic>> _previewRows() {
    if (_useBlocks) {
      return _budgetBlocks.where((b) => b.hasBillableContent).map((b) {
        final qty = b.qty ?? 1;
        final unitPrice = b.unitPrice ?? 0;
        final discountRate = b.discountRate ?? 0;
        final taxRate = b.taxRate ?? 21;
        final grossBase = qty * unitPrice;
        final base = grossBase - (grossBase * discountRate / 100);
        final total = base + (base * (taxRate / 100));
        final label = _budgetBlockPreviewLabel(b);
        return <String, dynamic>{
          'label': label,
          'qty': qty,
          'unitPrice': unitPrice,
          'discountRate': discountRate,
          'taxRate': taxRate,
          'base': base,
          'total': total,
        };
      }).toList(growable: false);
    }
    return _budgetLines.where(_budgetLineHasBillableContent).map((line) {
      final qty = line.quantity ?? 1;
      final unitPrice = line.unitPrice ?? 0;
      final discountRate = line.discountRate ?? 0;
      final taxRate = line.taxRate ?? 21;
      final grossBase = qty * unitPrice;
      final base = grossBase - (grossBase * discountRate / 100);
      final total = base + (base * (taxRate / 100));
      return <String, dynamic>{
        'label': _budgetLinePreviewLabel(line),
        'qty': qty,
        'unitPrice': unitPrice,
        'discountRate': discountRate,
        'taxRate': taxRate,
        'base': base,
        'total': total,
      };
    }).toList(growable: false);
  }

  num _previewTotal() {
    return _budgetTotalAfterDiscount;
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
            final discountRate = (row['discountRate'] as num?) ?? 0;
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
                  if (discountRate > 0) ...[
                    const SizedBox(width: 8),
                    Text('Dto. ${nf.format(discountRate)}%'),
                  ],
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
