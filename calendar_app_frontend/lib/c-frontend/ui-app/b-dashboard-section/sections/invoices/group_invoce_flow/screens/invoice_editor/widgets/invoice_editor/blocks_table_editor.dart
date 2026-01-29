import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class BlocksTableEditor extends StatefulWidget {
  final List<InvoiceBlockDraft> blocks;
  final VoidCallback onChanged;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectionChanged;

  const BlocksTableEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  State<BlocksTableEditor> createState() => _BlocksTableEditorState();
}

class _BlocksTableEditorState extends State<BlocksTableEditor> {
  static const _wrapperIndent = 16.0;

  void _scheduleRebuild() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  bool _isWrapperType(String type) {
    return type == InvoiceBlockType.date ||
        type == InvoiceBlockType.section ||
        type == InvoiceBlockType.subsection;
  }

  int _wrapperPriority(String type) {
    switch (type) {
      case InvoiceBlockType.date:
        return 0;
      case InvoiceBlockType.section:
        return 1;
      case InvoiceBlockType.subsection:
        return 2;
    }
    return 999;
  }

  int _wrapperLevel(String type) {
    switch (type) {
      case InvoiceBlockType.date:
        return 1;
      case InvoiceBlockType.section:
        return 1;
      case InvoiceBlockType.subsection:
        return 2;
    }
    return 0;
  }

  void _applyAutoLevels() {
    int? activeLevel;

    for (final block in widget.blocks) {
      if (_isWrapperType(block.type)) {
        activeLevel = _wrapperLevel(block.type);
        continue;
      }

      if (activeLevel == null) continue;
      if (block.levelCtrl.text.trim().isNotEmpty) continue;
      block.levelCtrl.text = '$activeLevel';
    }
  }

  void _moveBlock(int from, int to) {
    if (to < 0 || to >= widget.blocks.length) return;
    final item = widget.blocks.removeAt(from);
    widget.blocks.insert(to, item);
    widget.onChanged();
    if (widget.selectedIndex == from) {
      widget.onSelectionChanged(to);
    } else if (widget.selectedIndex != null) {
      final idx = widget.selectedIndex!;
      if (from < idx && to >= idx) {
        widget.onSelectionChanged(idx - 1);
      } else if (from > idx && to <= idx) {
        widget.onSelectionChanged(idx + 1);
      }
    }
    _applyAutoLevels();
    _scheduleRebuild();
  }

  void _removeBlockAt(int index) {
    if (index < 0 || index >= widget.blocks.length) return;
    widget.blocks.removeAt(index).dispose();
    widget.onChanged();
    _applyAutoLevels();
    if (widget.blocks.isEmpty) {
      widget.onSelectionChanged(null);
    } else if (widget.selectedIndex == index) {
      final next = index == 0 ? 0 : index - 1;
      widget.onSelectionChanged(next);
    } else if (widget.selectedIndex != null &&
        widget.selectedIndex! > index) {
      widget.onSelectionChanged(widget.selectedIndex! - 1);
    }
    _scheduleRebuild();
  }

  int _indexOfBlock(InvoiceBlockDraft block) {
    return widget.blocks.indexOf(block);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    int findWrapperEnd(int start, int max) {
      final current = widget.blocks[start];
      if (!_isWrapperType(current.type)) return start + 1;
      final priority = _wrapperPriority(current.type);
      for (int i = start + 1; i < max; i++) {
        final next = widget.blocks[i];
        if (_isWrapperType(next.type) &&
            _wrapperPriority(next.type) <= priority) {
          return i;
        }
      }
      return max;
    }

    void insertInside(InvoiceBlockDraft wrapperBlock, String type) {
      final wrapperStart = _indexOfBlock(wrapperBlock);
      if (wrapperStart < 0 || wrapperStart >= widget.blocks.length) return;
      final wrapperEnd = findWrapperEnd(wrapperStart, widget.blocks.length);
      final insertAt =
          wrapperEnd.clamp(wrapperStart + 1, widget.blocks.length);
      final draft = InvoiceBlockDraft.ofType(type);
      final wrapperType = widget.blocks[wrapperStart].type;
      draft.levelCtrl.text = '${_wrapperLevel(wrapperType)}';
      widget.blocks.insert(insertAt, draft);
      widget.onSelectionChanged(insertAt);
      widget.onChanged();
      _applyAutoLevels();
      _scheduleRebuild();
    }

    List<Widget> buildRange(int start, int end, int depth) {
      final widgets = <Widget>[];
      int i = start;
      while (i < end) {
        final block = widget.blocks[i];
        if (!_isWrapperType(block.type)) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(left: depth * _wrapperIndent),
              child: _BlockCard(
                key: ValueKey(block),
                index: _indexOfBlock(block),
                total: widget.blocks.length,
                block: block,
                selected: widget.selectedIndex == _indexOfBlock(block),
                onSelect: () {
                  final idx = _indexOfBlock(block);
                  if (idx < 0) return;
                  widget.onSelectionChanged(idx);
                },
                onDelete: () {
                  final idx = _indexOfBlock(block);
                  _removeBlockAt(idx);
                },
                onMoveUp: () {
                  final idx = _indexOfBlock(block);
                  if (idx < 0) return;
                  _moveBlock(idx, idx - 1);
                },
                onMoveDown: () {
                  final idx = _indexOfBlock(block);
                  if (idx < 0) return;
                  _moveBlock(idx, idx + 1);
                },
                onChanged: () {
                  widget.onChanged();
                  _scheduleRebuild();
                },
                onAddChecklistItem: () {
                  final idx = _indexOfBlock(block);
                  if (idx < 0) return;
                  widget.blocks[idx].checklistItems
                      .add(InvoiceChecklistItemDraft());
                  widget.onChanged();
                  _scheduleRebuild();
                },
                onRemoveChecklistItem: (idx) {
                  final blockIdx = _indexOfBlock(block);
                  if (blockIdx < 0) return;
                  if (idx < 0 ||
                      idx >= widget.blocks[blockIdx].checklistItems.length) {
                    return;
                  }
                  widget.blocks[blockIdx].checklistItems.removeAt(idx).dispose();
                  widget.onChanged();
                  _scheduleRebuild();
                },
              ),
            ),
          );
          i += 1;
          continue;
        }

        final wrapperEnd = findWrapperEnd(i, end);
        final headerBlock = widget.blocks[i];
        final header = _BlockCard(
          key: ValueKey(headerBlock),
          index: _indexOfBlock(headerBlock),
          total: widget.blocks.length,
          block: headerBlock,
          selected: widget.selectedIndex == _indexOfBlock(headerBlock),
          onSelect: () {
            final idx = _indexOfBlock(headerBlock);
            if (idx < 0) return;
            widget.onSelectionChanged(idx);
          },
          onDelete: () {
            final idx = _indexOfBlock(headerBlock);
            _removeBlockAt(idx);
          },
          onMoveUp: () {
            final idx = _indexOfBlock(headerBlock);
            if (idx < 0) return;
            _moveBlock(idx, idx - 1);
          },
          onMoveDown: () {
            final idx = _indexOfBlock(headerBlock);
            if (idx < 0) return;
            _moveBlock(idx, idx + 1);
          },
          onChanged: () {
            widget.onChanged();
            _scheduleRebuild();
          },
          onAddChecklistItem: () {
            final idx = _indexOfBlock(headerBlock);
            if (idx < 0) return;
            widget.blocks[idx].checklistItems
                .add(InvoiceChecklistItemDraft());
            widget.onChanged();
            _scheduleRebuild();
          },
          onRemoveChecklistItem: (idx) {
            final blockIdx = _indexOfBlock(headerBlock);
            if (blockIdx < 0) return;
            if (idx < 0 ||
                idx >= widget.blocks[blockIdx].checklistItems.length) {
              return;
            }
            widget.blocks[blockIdx].checklistItems.removeAt(idx).dispose();
            widget.onChanged();
            _scheduleRebuild();
          },
        );

        final children = buildRange(i + 1, wrapperEnd, depth + 1);
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: depth * _wrapperIndent),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  const SizedBox(height: 8),
                  if (children.isNotEmpty) ...children,
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 420;
                      if (compact) {
                        return Row(
                          children: [
                            Text(
                              l.invoiceWrapperAddInsideLabel,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: l.invoiceBlocksQuickItem,
                              onPressed: () =>
                                  insertInside(headerBlock, InvoiceBlockType.item),
                              icon: const Icon(Icons.add),
                            ),
                            IconButton(
                              tooltip: l.invoiceBlockTypeNote,
                              onPressed: () =>
                                  insertInside(headerBlock, InvoiceBlockType.note),
                              icon: const Icon(Icons.sticky_note_2_outlined),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Text(
                            l.invoiceWrapperAddInsideLabel,
                            style: t.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: l.invoiceBlocksQuickItem,
                            onPressed: () =>
                                insertInside(headerBlock, InvoiceBlockType.item),
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            tooltip: l.invoiceBlockTypeNote,
                            onPressed: () =>
                                insertInside(headerBlock, InvoiceBlockType.note),
                            icon: const Icon(Icons.sticky_note_2_outlined),
                          ),
                          IconButton(
                            tooltip: l.invoiceBlockTypeChecklist,
                            onPressed: () => insertInside(
                                headerBlock, InvoiceBlockType.checklist),
                            icon: const Icon(Icons.checklist_outlined),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        i = wrapperEnd;
      }
      return widgets;
    }

    if (widget.blocks.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.invoiceBlocksEmptyMessage,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      widget.blocks.add(
                          InvoiceBlockDraft.ofType(InvoiceBlockType.item));
                      widget.onChanged();
                      _scheduleRebuild();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l.invoiceBlocksQuickItem),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.blocks.add(
                          InvoiceBlockDraft.ofType(InvoiceBlockType.date));
                      widget.onChanged();
                      _scheduleRebuild();
                    },
                    icon: const Icon(Icons.today_outlined),
                    label: Text(l.invoiceBlocksQuickDate),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: buildRange(0, widget.blocks.length, 0),
    );
  }
}

class _BlockCard extends StatefulWidget {
  final int index;
  final int total;
  final InvoiceBlockDraft block;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onChanged;
  final VoidCallback onAddChecklistItem;
  final ValueChanged<int> onRemoveChecklistItem;

  const _BlockCard({
    super.key,
    required this.index,
    required this.total,
    required this.block,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onChanged,
    required this.onAddChecklistItem,
    required this.onRemoveChecklistItem,
  });

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard> {
  bool _hovered = false;
  bool _expanded = false;
  bool _showAdvanced = false;
  static const _unitOptions = <String>['ud', 'h', 'kg', 'm', 'm2', 'm3', 'l'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final block = widget.block;
    final numFmt = NumberFormat('#,##0.##');
    final moneyFmt = NumberFormat.simpleCurrency(name: '');

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );

    InputDecoration fieldDec({required String label, String? suffixText}) {
      return InputDecoration(
        labelText: label,
        suffixText: suffixText,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        isDense: true,
      );
    }

    String typeLabel(String type) {
      switch (type) {
        case InvoiceBlockType.item:
          return l.invoiceBlockTypeItem;
        case InvoiceBlockType.date:
          return l.invoiceBlockTypeDate;
        case InvoiceBlockType.section:
          return l.invoiceBlockTypeSection;
        case InvoiceBlockType.subsection:
          return l.invoiceBlockTypeSubsection;
        case InvoiceBlockType.divider:
          return l.invoiceBlockTypeDivider;
        case InvoiceBlockType.note:
          return l.invoiceBlockTypeNote;
        case InvoiceBlockType.checklist:
          return l.invoiceBlockTypeChecklist;
      }
      return type;
    }

    IconData typeIcon(String type) {
      switch (type) {
        case InvoiceBlockType.item:
          return Icons.receipt_long_outlined;
        case InvoiceBlockType.date:
          return Icons.event_outlined;
        case InvoiceBlockType.section:
          return Icons.segment_outlined;
        case InvoiceBlockType.subsection:
          return Icons.subdirectory_arrow_right_outlined;
        case InvoiceBlockType.divider:
          return Icons.horizontal_rule;
        case InvoiceBlockType.note:
          return Icons.sticky_note_2_outlined;
        case InvoiceBlockType.checklist:
          return Icons.checklist_outlined;
      }
      return Icons.more_horiz;
    }

    String? nonNegativeValidator(String? v) {
      final parsed = num.tryParse((v ?? '').trim());
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0) return l.invoiceValidationNonNegative;
      return null;
    }

    String? taxValidator(String? v) {
      final parsed = num.tryParse((v ?? '').trim());
      if (parsed == null) return l.fieldIsRequired;
      if (parsed < 0 || parsed > 100) return l.invoiceValidationTaxRate;
      return null;
    }

    Widget headerActions() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l.invoiceBlockMoveUp,
            onPressed: widget.index == 0 ? null : widget.onMoveUp,
            icon: const Icon(Icons.keyboard_arrow_up),
          ),
          IconButton(
            tooltip: l.invoiceBlockMoveDown,
            onPressed:
                widget.index == widget.total - 1 ? null : widget.onMoveDown,
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          IconButton(
            tooltip: l.remove,
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete_outline, color: cs.error),
          ),
        ],
      );
    }

    Widget typePicker() {
      final items = [
        InvoiceBlockType.item,
        InvoiceBlockType.date,
        InvoiceBlockType.section,
        InvoiceBlockType.subsection,
        InvoiceBlockType.divider,
        InvoiceBlockType.note,
        InvoiceBlockType.checklist,
      ];

      return PopupMenuButton<String>(
        tooltip: l.invoiceBlockTypeLabel,
        onSelected: (value) {
          setState(() {
            block.type = value;
            _expanded = true;
          });
          widget.onSelect();
          widget.onChanged();
        },
        itemBuilder: (_) => items
            .map((type) => PopupMenuItem<String>(
                  value: type,
                  child: Text(typeLabel(type)),
                ))
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(typeIcon(block.type), size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              typeLabel(block.type),
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      );
    }

    String summaryText() {
      switch (block.type) {
        case InvoiceBlockType.item:
          final sku = block.sku.text.trim();
          final desc = block.description.text.trim();
          final label = desc.isEmpty ? l.lineDescription : desc;
          return sku.isEmpty ? label : '$sku $label';
        case InvoiceBlockType.date:
        case InvoiceBlockType.section:
        case InvoiceBlockType.subsection:
          return block.title.text.trim().isEmpty
              ? typeLabel(block.type)
              : block.title.text.trim();
        case InvoiceBlockType.note:
          return block.text.text.trim().isEmpty
              ? typeLabel(block.type)
              : block.text.text.trim();
        case InvoiceBlockType.checklist:
          if (block.checklistItems.isEmpty) return typeLabel(block.type);
          final first = block.checklistItems.first.text.text.trim();
          return first.isEmpty ? typeLabel(block.type) : first;
        case InvoiceBlockType.divider:
          return typeLabel(block.type);
      }
      return typeLabel(block.type);
    }

    String? itemMeta() {
      if (block.type != InvoiceBlockType.item) return null;
      final qty = block.qty ?? 1;
      final price = block.unitPrice ?? 0;
      final unit = block.unitCtrl.text.trim();
      final qtyText = unit.isEmpty
          ? numFmt.format(qty)
          : '${numFmt.format(qty)} $unit';
      return '$qtyText × ${moneyFmt.format(price)}';
    }

    String? itemTotalText() {
      if (block.type != InvoiceBlockType.item) return null;
      final qty = block.qty ?? 1;
      final price = block.unitPrice ?? 0;
      final taxRate = block.taxRate ?? 21;
      final subtotal = qty * price;
      final tax = subtotal * (taxRate / 100);
      final total = subtotal + tax;
      return moneyFmt.format(total);
    }

    bool shouldShowLevel() {
      return _showAdvanced || block.levelCtrl.text.trim().isNotEmpty;
    }

    Widget advancedToggle() {
      return TextButton.icon(
        onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
        icon: Icon(_showAdvanced ? Icons.expand_less : Icons.more_horiz),
        label: Text(
          _showAdvanced
              ? l.invoiceBlockAdvancedHideCta
              : l.invoiceBlockAdvancedShowCta,
        ),
      );
    }

    Widget itemFields() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: block.description,
            decoration: fieldDec(label: l.lineDescription),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            onChanged: (_) => widget.onChanged(),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: TextFormField(
                  controller: block.sku,
                  decoration: fieldDec(label: l.invoiceBlockSkuLabel),
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              SizedBox(
                width: 220,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: block.qtyCtrl,
                        decoration: fieldDec(label: l.lineQuantity),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: nonNegativeValidator,
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: block.unitCtrl,
                        decoration: fieldDec(label: l.invoiceBlockUnitLabel)
                            .copyWith(
                          suffixIcon: PopupMenuButton<String>(
                            tooltip: l.invoiceBlockUnitLabel,
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (value) {
                              block.unitCtrl.text = value;
                              block.unitCtrl.selection =
                                  TextSelection.collapsed(
                                offset: value.length,
                              );
                              widget.onChanged();
                            },
                            itemBuilder: (_) => [
                              for (final unit in _unitOptions)
                                PopupMenuItem<String>(
                                  value: unit,
                                  child: Text(unit),
                                ),
                            ],
                          ),
                        ),
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 140,
                child: TextFormField(
                  controller: block.unitPriceCtrl,
                  decoration: fieldDec(label: l.lineUnitPrice),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: nonNegativeValidator,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: block.taxRateCtrl,
                  decoration: fieldDec(label: '${l.taxRateShort}%'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: taxValidator,
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
              if (shouldShowLevel())
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: block.levelCtrl,
                    decoration: fieldDec(label: l.invoiceBlockLevelLabel),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                    onChanged: (_) => widget.onChanged(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          advancedToggle(),
          Row(
            children: [
              Switch(
                value: block.isBillable,
                onChanged: (v) {
                  setState(() => block.isBillable = v);
                  widget.onChanged();
                },
              ),
              Text(
                l.invoiceBlockBillableLabel,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      );
    }

    Widget titleField({required String label}) {
      return TextFormField(
        controller: block.title,
        decoration: fieldDec(label: label),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        onChanged: (_) => widget.onChanged(),
      );
    }

    Widget dateField() {
      final locale = Localizations.localeOf(context);
      final isEnUs = locale.languageCode == 'en' && locale.countryCode == 'US';
      final pattern = isEnUs ? 'MM/dd/yyyy' : 'dd/MM/yyyy';
      final placeholder = pattern.toLowerCase();
      final formatter = DateFormat(pattern, locale.toString());

      Future<void> pickDate() async {
        final initial = block.dateValue == null
            ? DateTime.now()
            : DateTime.tryParse(block.dateValue!);
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: initial ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 5),
        );
        if (selected == null) return;
        final iso = DateFormat('yyyy-MM-dd').format(selected);
        block.dateValue = iso;
        if (block.title.text.trim().isEmpty) {
          block.title.text = formatter.format(selected);
        }
        widget.onChanged();
        setState(() {});
      }

      void applyAutoFormat() {
        if (block.dateValue == null || block.dateValue!.trim().isEmpty) {
          pickDate();
          return;
        }
        final parsed = DateTime.tryParse(block.dateValue!);
        if (parsed == null) return;
        block.title.text = formatter.format(parsed);
        widget.onChanged();
        setState(() {});
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: block.title,
            decoration: fieldDec(label: l.invoiceBlockTitleLabelDate)
                .copyWith(hintText: placeholder),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
            onChanged: (_) => widget.onChanged(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(l.invoiceBlocksQuickDate),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: applyAutoFormat,
                child: Text(l.invoiceBlockDateAutoFormatCta),
              ),
            ],
          ),
        ],
      );
    }

    Widget textField({required String label}) {
      return TextFormField(
        controller: block.text,
        decoration: fieldDec(label: label),
        maxLines: 3,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? l.fieldIsRequired : null,
        onChanged: (_) => widget.onChanged(),
      );
    }

    Widget levelField() {
      return SizedBox(
        width: 120,
        child: TextFormField(
          controller: block.levelCtrl,
          decoration: fieldDec(label: l.invoiceBlockLevelLabel),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          onChanged: (_) => widget.onChanged(),
        ),
      );
    }

    Widget checklistFields() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < block.checklistItems.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: block.checklistItems[i].checked,
                    onChanged: (v) {
                      setState(() => block.checklistItems[i].checked = v ?? false);
                      widget.onChanged();
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: block.checklistItems[i].text,
                      decoration:
                          fieldDec(label: l.invoiceBlockChecklistItemLabel),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.fieldIsRequired
                          : null,
                      onChanged: (_) => widget.onChanged(),
                    ),
                  ),
                  IconButton(
                    tooltip: l.remove,
                    onPressed: () => widget.onRemoveChecklistItem(i),
                    icon: Icon(Icons.delete_outline, color: cs.error),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: widget.onAddChecklistItem,
            icon: const Icon(Icons.add),
            label: Text(l.invoiceBlockAddChecklistItem),
          ),
        ],
      );
    }

    Widget body() {
      switch (block.type) {
        case InvoiceBlockType.item:
          return itemFields();
        case InvoiceBlockType.date:
          return dateField();
        case InvoiceBlockType.section:
          return titleField(label: l.invoiceBlockTitleLabelSection);
        case InvoiceBlockType.subsection:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleField(label: l.invoiceBlockTitleLabelSubsection),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
              advancedToggle(),
            ],
          );
        case InvoiceBlockType.divider:
          return Text(
            l.invoiceBlockTypeDivider,
            style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
          );
        case InvoiceBlockType.note:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textField(label: l.invoiceBlockNoteLabel),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
              advancedToggle(),
            ],
          );
        case InvoiceBlockType.checklist:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              checklistFields(),
              const SizedBox(height: 12),
              if (shouldShowLevel()) levelField(),
              advancedToggle(),
            ],
          );
      }
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.selected
              ? cs.primaryContainer.withValues(alpha: 0.25)
              : _hovered
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.35)
                  : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.selected
                ? cs.primary.withValues(alpha: 0.6)
                : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      widget.onSelect();
                      setState(() => _expanded = !_expanded);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      child: Row(
                        children: [
                          typePicker(),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              summaryText(),
                              style:
                                  t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                              maxLines: _expanded ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (itemMeta() != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              itemMeta()!,
                              style: t.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (itemTotalText() != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    itemTotalText()!,
                    style: t.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                headerActions(),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              body(),
            ],
          ],
        ),
      ),
    );
  }
}
