part of '../group_invoices_budgets_view.dart';

// ignore_for_file: invalid_use_of_protected_member

extension _GroupInvoicesBudgetsViewPayloadSection on _GroupInvoicesBudgetsViewState {
  List<Map<String, dynamic>> _buildLinesPayload() {
    return _budgetLines
        .where((line) =>
            line.description.text.trim().isNotEmpty && (line.quantity ?? 0) > 0)
        .map((line) => line.toLine().toJson()
          ..removeWhere((key, value) =>
              key == 'id' || key == 'invoiceId' || value == null))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _buildLinesFromBlocksPayload() {
    final rows = <Map<String, dynamic>>[];
    var position = 1;
    for (final block in _budgetBlocks) {
      if (!block.hasBillableContent) continue;
      final label = block.description.text.trim().isNotEmpty
          ? block.description.text.trim()
          : block.title.text.trim();
      final qty = (block.qty ?? 1).toDouble();
      final unitPrice = (block.unitPrice ?? 0).toDouble();
      final taxRate = (block.taxRate ?? 21).toDouble();
      if (label.isEmpty || unitPrice <= 0) continue;
      rows.add(<String, dynamic>{
        'position': position++,
        'description': label,
        'quantity': qty,
        'unitPrice': unitPrice,
        'taxRate': taxRate,
      });
    }
    return rows;
  }

  List<Map<String, dynamic>> _buildBlocksPayload() {
    return _budgetBlocks
        .where((b) => b.hasBillableContent)
        .map((b) => b.toBlock().toJson())
        .toList(growable: false);
  }

  String _extractIdFromPayload(Map<String, dynamic> payload) {
    return (payload['_id'] ?? payload['id'] ?? '').toString();
  }

  String? _extractNumberFromPayload(Map<String, dynamic> payload) {
    final value = payload['presupuestoNumber'] ?? payload['budgetNumber'];
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  void _markDraftDirty() {
    _issuedPresupuestoNumber = null;
    _previewPdfBytes = null;
    _previewForId = null;
  }

  bool _isDraftPresupuesto(Map<String, dynamic> payload) {
    final status = (payload['status'] ?? '').toString().toLowerCase();
    return status.isEmpty || status.contains('draft');
  }

  InvoiceBlockDraft _blockDraftFromMap(Map<String, dynamic> map) {
    final type = (map['type'] ?? InvoiceBlockType.item).toString().trim();
    final draft = InvoiceBlockDraft.ofType(type);
    draft.description.text = (map['description'] ?? '').toString();
    draft.qtyCtrl.text = (map['qty'] ?? map['quantity'] ?? 1).toString();
    draft.unitPriceCtrl.text = (map['unitPrice'] ?? 0).toString();
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
    draft.taxRateCtrl.text = (map['taxRate'] ?? 21).toString();
    return draft;
  }

  void _applyPresupuestoPayload(Map<String, dynamic> payload) {
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

}

