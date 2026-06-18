part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewPayloadSection
    on _GroupInvoicesBudgetsViewState {
  String _formatBudgetIssueDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Map<String, dynamic> _buildBudgetDraftUpdatePayload() {
    final useManualClient = _clientSource == _ClientSource.manual;
    final manualClientSnapshot = _buildManualClientSnapshotPayload();
    final linesPayload = _buildLinesPayload();
    return <String, dynamic>{
      if (!useManualClient && (_selectedClientId ?? '').trim().isNotEmpty)
        'clientId': _selectedClientId!.trim(),
      if (useManualClient && _clientNameCtrl.text.trim().isNotEmpty)
        'clientName': _clientNameCtrl.text.trim(),
      if (useManualClient && _clientAddressCtrl.text.trim().isNotEmpty)
        'addressStreet': _clientAddressCtrl.text.trim(),
      if (useManualClient && _clientCityCtrl.text.trim().isNotEmpty)
        'addressCity': _clientCityCtrl.text.trim(),
      if (useManualClient && _clientPostalCodeCtrl.text.trim().isNotEmpty)
        'addressPostalCode': _clientPostalCodeCtrl.text.trim(),
      if (manualClientSnapshot != null) 'clientSnapshot': manualClientSnapshot,
      if (_formatBudgetIssueDate(_budgetIssueDate).isNotEmpty)
        'issueDate': _formatBudgetIssueDate(_budgetIssueDate),
      'notes': _budgetNotesCtrl.text,
      'currency': (_budgetCurrencyCtrl.text.trim().isEmpty
          ? 'EUR'
          : _budgetCurrencyCtrl.text.trim().toUpperCase()),
      'lines': linesPayload.isNotEmpty
          ? linesPayload
          : _buildLinesFromBlocksPayload(),
      'blocks': _buildBlocksPayload(),
      'totals': _buildBudgetDiscountTotalsPayload(),
    };
  }

  Map<String, dynamic>? _buildManualClientSnapshotPayload() {
    if (_clientSource != _ClientSource.manual) return null;
    final name = _clientNameCtrl.text.trim();
    final address = _clientAddressCtrl.text.trim();
    final city = _clientCityCtrl.text.trim();
    final postalCode = _clientPostalCodeCtrl.text.trim();
    if (name.isEmpty && address.isEmpty && city.isEmpty && postalCode.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      if (name.isNotEmpty) 'name': name,
      if (name.isNotEmpty) 'billingName': name,
      if (name.isNotEmpty) 'legalName': name,
      if (address.isNotEmpty) 'addressStreet': address,
      if (address.isNotEmpty) 'address': address,
      if (address.isNotEmpty) 'street': address,
      if (city.isNotEmpty) 'addressCity': city,
      if (city.isNotEmpty) 'city': city,
      if (postalCode.isNotEmpty) 'addressPostalCode': postalCode,
      if (postalCode.isNotEmpty) 'postalCode': postalCode,
      if (postalCode.isNotEmpty) 'cp': postalCode,
      'documentType': 'presupuesto',
    };
  }

  bool _budgetLineHasBillableContent(LineDraft line) {
    final invoiceLine = line.toLine();
    return (invoiceLine.quantity) > 0 &&
        _budgetLineBillableDescription(line).isNotEmpty;
  }

  List<String> _budgetLineConceptItems(LineDraft line) {
    return line.conceptItemsCtrl.text
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _budgetLineBillableDescription(LineDraft line) {
    final detail = line.description.text.trim();
    if (detail.isNotEmpty) return detail;

    final conceptItems = _budgetLineConceptItems(line);
    if (conceptItems.isNotEmpty) return conceptItems.first;

    return line.conceptTitleCtrl.text.trim();
  }

  String _budgetDefaultConceptTitle(LineDraft line) {
    final invoiceLine = line.toLine();
    final conceptTitle = (invoiceLine.conceptTitle ?? '').trim();
    if (conceptTitle.isNotEmpty) return conceptTitle;

    return _budgetLineBillableDescription(line).isNotEmpty ? 'Unit' : '';
  }

  String _budgetLinePreviewLabel(LineDraft line) {
    final conceptTitle = _budgetDefaultConceptTitle(line);
    final conceptItems = _budgetLineConceptItems(line);
    final firstConcept = conceptItems.isEmpty ? '' : conceptItems.first;
    final detail = line.description.text.trim();
    if (conceptTitle.isNotEmpty && firstConcept.isNotEmpty) {
      return '$conceptTitle - $firstConcept';
    }
    if (firstConcept.isNotEmpty) return firstConcept;
    if (conceptTitle.isNotEmpty) return conceptTitle;
    if (detail.isNotEmpty) return detail;
    final fallback = _budgetLineBillableDescription(line);
    return fallback.isEmpty ? '-' : fallback;
  }

  List<Map<String, dynamic>> _buildLinesPayload() {
    return _budgetLines.where(_budgetLineHasBillableContent).map((line) {
      final payload = line.toLine().toJson()
        ..removeWhere(
            (key, value) => key == 'id' || key == 'invoiceId' || value == null);
      final conceptTitle = (payload['conceptTitle'] ?? '').toString().trim();
      if (conceptTitle.isEmpty) {
        payload['conceptTitle'] = _budgetDefaultConceptTitle(line);
      }
      final description = (payload['description'] ?? '').toString().trim();
      if (description.isEmpty) {
        payload['description'] = _budgetLineBillableDescription(line);
      }
      if ((payload['conceptTitle'] ?? '').toString().trim().isEmpty) {
        payload.remove('conceptTitle');
      }
      return payload;
    }).toList(growable: false);
  }

  List<Map<String, dynamic>> _buildLinesFromBlocksPayload() {
    final rows = <Map<String, dynamic>>[];
    var position = 1;
    for (final block in _budgetBlocks) {
      if (!block.hasBillableContent) continue;
      final label = _budgetBlockBillableDescription(block);
      final qty = (block.qty ?? 1).toDouble();
      final unitPrice = (block.unitPrice ?? 0).toDouble();
      final discountRate = (block.discountRate ?? 0).toDouble().clamp(0, 100);
      final taxRate = (block.taxRate ?? 21).toDouble();
      if (label.isEmpty || unitPrice <= 0) continue;
      rows.add(<String, dynamic>{
        'position': position++,
        'description': label,
        'quantity': qty,
        'unitPrice': unitPrice,
        'discountRate': discountRate,
        'taxRate': taxRate,
      });
    }
    return rows;
  }

  String _budgetBlockBillableDescription(InvoiceBlockDraft block) {
    if (block.isChecklist) {
      final title = block.title.text.trim();
      final items = block.checklistItems
          .map((item) => item.text.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (items.isEmpty) return title;
      return <String>[
        if (title.isNotEmpty) title,
        ...items.map((item) => '- $item'),
      ].join('\n');
    }
    if (block.isSection) return block.title.text.trim();
    return _budgetBlockItemDescription(block);
  }

  List<String> _budgetBlockConceptItems(InvoiceBlockDraft block) {
    return block.conceptItemsCtrl.text
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _budgetBlockItemDescription(InvoiceBlockDraft block) {
    final detail = block.description.text.trim();
    if (detail.isNotEmpty) return detail;

    final conceptItems = _budgetBlockConceptItems(block);
    if (conceptItems.isNotEmpty) return conceptItems.first;

    return block.conceptTitleCtrl.text.trim();
  }

  String _budgetBlockConceptTitle(InvoiceBlockDraft block) {
    final title = block.conceptTitleCtrl.text.trim();
    if (title.isNotEmpty) return title;
    return _budgetBlockItemDescription(block).isNotEmpty ? 'Unit' : '';
  }

  String _budgetBlockPreviewLabel(InvoiceBlockDraft block) {
    if (!block.isBillableItem) return _budgetBlockBillableDescription(block);

    final conceptTitle = _budgetBlockConceptTitle(block);
    final conceptItems = _budgetBlockConceptItems(block);
    final firstConcept = conceptItems.isEmpty ? '' : conceptItems.first;
    final detail = block.description.text.trim();
    if (conceptTitle.isNotEmpty && firstConcept.isNotEmpty) {
      return '$conceptTitle - $firstConcept';
    }
    if (firstConcept.isNotEmpty) return firstConcept;
    if (conceptTitle.isNotEmpty) return conceptTitle;
    if (detail.isNotEmpty) return detail;
    final fallback = _budgetBlockItemDescription(block);
    return fallback.isEmpty ? '-' : fallback;
  }

  Map<String, dynamic> _sanitizedBudgetBlockPayload(InvoiceBlockDraft block) {
    final raw = block.toBlock();
    final type = raw.type.trim();
    if (type == InvoiceBlockType.checklist ||
        type == InvoiceBlockType.section) {
      return <String, dynamic>{
        'type': InvoiceBlockType.item,
        'description': _budgetBlockBillableDescription(block),
        'qty': raw.qty,
        if ((raw.unit ?? '').trim().isNotEmpty) 'unit': raw.unit,
        'unitPrice': raw.unitPrice,
        'discountRate': raw.discountRate ?? 0,
        'taxRate': raw.taxRate ?? 21,
        'isBillable': true,
      }..removeWhere((_, value) => value == null);
    }
    final payload = raw.toJson();
    if (block.isBillableItem) {
      final description = (payload['description'] ?? '').toString().trim();
      if (description.isEmpty) {
        payload['description'] = _budgetBlockItemDescription(block);
      }
      final conceptTitle = (payload['conceptTitle'] ?? '').toString().trim();
      if (conceptTitle.isEmpty) {
        payload['conceptTitle'] = _budgetBlockConceptTitle(block);
      }
      if ((payload['conceptTitle'] ?? '').toString().trim().isEmpty) {
        payload.remove('conceptTitle');
      }
    }
    return payload;
  }

  List<Map<String, dynamic>> _buildBlocksPayload() {
    return _budgetBlocks
        .where((b) => b.hasBillableContent)
        .map(_sanitizedBudgetBlockPayload)
        .toList(growable: false);
  }

  Map<String, dynamic> _budgetPayloadData(Map<String, dynamic> payload) {
    for (final key in const ['presupuesto', 'budget', 'data', 'item']) {
      final value = payload[key];
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        if (map.containsKey('_id') ||
            map.containsKey('id') ||
            map.containsKey('status') ||
            map.containsKey('clientSnapshot') ||
            map.containsKey('blocks') ||
            map.containsKey('lines')) {
          return map;
        }
      }
    }
    return payload;
  }

  String _payloadText(
    Map<String, dynamic> payload,
    Map<String, dynamic> snapshot,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    for (final key in keys) {
      final value = snapshot[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _extractIdFromPayload(Map<String, dynamic> payload) {
    payload = _budgetPayloadData(payload);
    return (payload['_id'] ?? payload['id'] ?? '').toString();
  }

  String? _extractNumberFromPayload(Map<String, dynamic> payload) {
    payload = _budgetPayloadData(payload);
    final value = payload['presupuestoNumber'] ?? payload['budgetNumber'];
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  void _markDraftDirty() {
    _editableBudgetDirty = true;
    _budgetAutoSaveFailed = false;
    widget.onUnsavedStateChanged?.call(true);
    _issuedPresupuestoNumber = null;
    _previewPdfBytes = null;
    _previewForId = null;
    _scheduleBudgetAutoSave();
  }

  void _scheduleBudgetAutoSave() {
    if (widget.mode != GroupInvoicesBudgetsMode.create) return;
    _budgetAutoSaveTimer?.cancel();
    _budgetAutoSaveTimer =
        Timer(const Duration(seconds: 3), _autoSaveBudgetDraftIfReady);
  }

  Future<void> _autoSaveBudgetDraftIfReady() async {
    if (!mounted ||
        _budgetAutoSaving ||
        _issuing ||
        !_editableBudgetDirty ||
        !_hasClientInfo ||
        !_hasLineContent ||
        (!_isDraftEditable && !_isIssuedEditable)) {
      return;
    }
    if (_isIssuedEditable && _issuedEditReasonCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _budgetAutoSaving = true;
      _budgetAutoSaveFailed = false;
    });
    try {
      final id = _isIssuedEditable
          ? await _persistIssuedChanges()
          : await _persistDraftChanges();
      if (!mounted) return;
      setState(() {
        _draftId = id;
        _editableBudgetDirty = false;
        _budgetAutoSaveFailed = false;
        widget.onUnsavedStateChanged?.call(false);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _budgetAutoSaveFailed = true);
        _scheduleBudgetAutoSave();
      }
    } finally {
      _budgetAutoSaving = false;
      if (mounted) setState(() {});
    }
  }

  bool _isDraftPresupuesto(Map<String, dynamic> payload) {
    final status = (payload['status'] ?? '').toString().toLowerCase();
    return status.isEmpty || status.contains('draft');
  }

  InvoiceBlockDraft? _checklistDraftFromSanitizedItem(
    Map<String, dynamic> map,
  ) {
    final type = (map['type'] ?? '').toString().trim();
    if (type != InvoiceBlockType.item) return null;

    final description = (map['description'] ?? '').toString().trim();
    if (!description.contains('\n- ')) return null;

    final lines = description
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length < 2 ||
        !lines.skip(1).every((line) => line.startsWith('- '))) {
      return null;
    }

    return InvoiceBlockDraft(
      type: InvoiceBlockType.checklist,
      title: lines.first,
      qty: (map['qty'] ?? map['quantity'] ?? 1).toString(),
      unit: (map['unit'] ?? '').toString(),
      unitPrice: (map['unitPrice'] ?? 0).toString(),
      discountRate:
          (map['discountRate'] ?? map['discountPercent'] ?? 0).toString(),
      taxRate: (map['taxRate'] ?? 21).toString(),
      isBillable: map['isBillable'] != false,
      checklistItems: lines
          .skip(1)
          .map((line) => InvoiceChecklistItemDraft(
                initialText: line.replaceFirst(RegExp(r'^-\s*'), ''),
                checked: true,
              ))
          .toList(),
    );
  }

  InvoiceBlockDraft _blockDraftFromMap(Map<String, dynamic> map) {
    final restoredChecklist = _checklistDraftFromSanitizedItem(map);
    if (restoredChecklist != null) return restoredChecklist;

    final type = (map['type'] ?? InvoiceBlockType.item).toString().trim();
    final draft = InvoiceBlockDraft.ofType(type);
    draft.description.text = (map['description'] ?? '').toString();
    draft.qtyCtrl.text = (map['qty'] ?? map['quantity'] ?? 1).toString();
    draft.unitPriceCtrl.text = (map['unitPrice'] ?? 0).toString();
    draft.discountRateCtrl.text =
        (map['discountRate'] ?? map['discountPercent'] ?? 0).toString();
    draft.taxRateCtrl.text = (map['taxRate'] ?? 21).toString();
    draft.title.text = (map['title'] ?? '').toString();
    draft.text.text = (map['text'] ?? '').toString();
    draft.isBillable = map['isBillable'] != false;
    final itemsRaw = map['items'];
    if (itemsRaw is List) {
      draft.checklistItems.clear();
      for (final item in itemsRaw) {
        if (item is Map) {
          draft.checklistItems.add(
            InvoiceChecklistItemDraft(
              initialText: (item['text'] ?? '').toString(),
              checked: item['checked'] == true,
            ),
          );
        }
      }
      if (type == InvoiceBlockType.checklist && draft.checklistItems.isEmpty) {
        draft.checklistItems.add(InvoiceChecklistItemDraft());
      }
    }
    return draft;
  }

  LineDraft _lineDraftFromMap(Map<String, dynamic> map, int position) {
    final draft = LineDraft(position: position);
    draft.description.text = (map['description'] ?? '').toString();
    draft.quantityCtrl.text = (map['quantity'] ?? map['qty'] ?? 1).toString();
    draft.unitPriceCtrl.text = (map['unitPrice'] ?? 0).toString();
    draft.discountRateCtrl.text =
        (map['discountRate'] ?? map['discountPercent'] ?? 0).toString();
    draft.taxRateCtrl.text = (map['taxRate'] ?? 21).toString();
    return draft;
  }

  void _applyPresupuestoPayload(Map<String, dynamic> payload) {
    payload = _budgetPayloadData(payload);
    _applyBudgetDiscountPayload(payload);

    final id = _extractIdFromPayload(payload);
    if (id.isNotEmpty) _draftId = id;
    final number = _extractNumberFromPayload(payload);
    if (number != null && number.isNotEmpty) {
      _issuedPresupuestoNumber = number;
    }
    final blocksRaw = payload['blocks'];
    final linesRaw = payload['lines'];
    for (final line in _budgetLines) {
      line.dispose();
    }
    _budgetLines.clear();
    for (final block in _budgetBlocks) {
      block.dispose();
    }
    _budgetBlocks.clear();

    if (blocksRaw is List && blocksRaw.isNotEmpty) {
      _useBlocks = true;
      for (final block in blocksRaw) {
        if (block is Map) {
          _budgetBlocks.add(
            _blockDraftFromMap(Map<String, dynamic>.from(block)),
          );
        }
      }
      if (_budgetBlocks.isEmpty) {
        _budgetBlocks.add(InvoiceBlockDraft.item());
      }
      _budgetLines.add(LineDraft(position: 1));
      return;
    }

    if (linesRaw is List && linesRaw.isNotEmpty) {
      _useBlocks = false;
      var pos = 1;
      for (final line in linesRaw) {
        if (line is Map) {
          _budgetLines
              .add(_lineDraftFromMap(Map<String, dynamic>.from(line), pos));
          pos += 1;
        }
      }
      if (_budgetLines.isEmpty) {
        _budgetLines.add(LineDraft(position: 1));
      }
      _budgetBlocks.add(InvoiceBlockDraft.item());
      return;
    }

    _budgetBlocks.add(InvoiceBlockDraft.item());
    _budgetLines.add(LineDraft(position: 1));
  }

  void _applyEditableBudgetPayload(
    Map<String, dynamic> payload, {
    bool resetWizard = true,
  }) {
    final previousStep = _visibleStep;
    final previousConfirmPreview = _confirmPreview;
    payload = _budgetPayloadData(payload);
    _draftId = _extractIdFromPayload(payload);
    _editableBudgetStatus = (payload['status'] ?? 'draft').toString().trim();
    _editableBudgetVersion = int.tryParse(
      (payload['currentVersion'] ?? payload['version'] ?? '').toString(),
    );
    _issuedPresupuestoNumber = _extractNumberFromPayload(payload);
    _budgetIssueDate = DateTime.tryParse(
      (payload['issueDate'] ?? payload['createdAt'] ?? '').toString(),
    );
    _budgetCurrencyCtrl.text =
        (payload['currency'] ?? 'EUR').toString().trim().isEmpty
            ? 'EUR'
            : (payload['currency'] ?? 'EUR').toString().trim().toUpperCase();
    _budgetNotesCtrl.text = (payload['notes'] ?? '').toString();
    final clientId = (payload['clientId'] ?? '').toString().trim();
    final clientName = (payload['clientName'] ?? '').toString().trim();
    final clientSnapshot = payload['clientSnapshot'] is Map
        ? Map<String, dynamic>.from(payload['clientSnapshot'] as Map)
        : const <String, dynamic>{};
    if (clientId.isNotEmpty &&
        widget.clients.any((client) => client.id.trim() == clientId)) {
      _clientSource = _ClientSource.existing;
      _selectedClientId = clientId;
      _clientNameCtrl.clear();
      _clientAddressCtrl.clear();
      _clientCityCtrl.clear();
      _clientPostalCodeCtrl.clear();
    } else {
      _clientSource = _ClientSource.manual;
      _selectedClientId = null;
      _clientNameCtrl.text = clientName.isNotEmpty
          ? clientName
          : _payloadText(payload, clientSnapshot, const [
              'billingName',
              'legalName',
              'name',
            ]);
      _clientAddressCtrl.text = _payloadText(payload, clientSnapshot, const [
        'addressStreet',
        'address',
        'street',
      ]);
      _clientCityCtrl.text = _payloadText(payload, clientSnapshot, const [
        'addressCity',
        'city',
      ]);
      _clientPostalCodeCtrl.text = _payloadText(payload, clientSnapshot, const [
        'addressPostalCode',
        'postalCode',
        'cp',
      ]);
    }
    if (resetWizard) {
      _confirmPreview = false;
    }
    _issuedEditReasonCtrl.clear();
    _editableBudgetDirty = false;
    widget.onUnsavedStateChanged?.call(false);
    _applyPresupuestoPayload(payload);
    if (resetWizard) {
      _visibleStep = 1;
    } else {
      _visibleStep = previousStep;
      _confirmPreview = previousConfirmPreview;
    }
  }
}
