import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'blocks_table/block_card.dart';

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
    } else if (widget.selectedIndex != null && widget.selectedIndex! > index) {
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
      final insertAt = wrapperEnd.clamp(wrapperStart + 1, widget.blocks.length);
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
              child: BlockCard(
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
                  widget.blocks[blockIdx].checklistItems
                      .removeAt(idx)
                      .dispose();
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
        final header = BlockCard(
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
            widget.blocks[idx].checklistItems.add(InvoiceChecklistItemDraft());
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
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
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
                              onPressed: () => insertInside(
                                  headerBlock, InvoiceBlockType.item),
                              icon: const Icon(Icons.add),
                            ),
                            IconButton(
                              tooltip: l.invoiceBlockTypeNote,
                              onPressed: () => insertInside(
                                  headerBlock, InvoiceBlockType.note),
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
                            onPressed: () => insertInside(
                                headerBlock, InvoiceBlockType.item),
                            icon: const Icon(Icons.add),
                          ),
                          IconButton(
                            tooltip: l.invoiceBlockTypeNote,
                            onPressed: () => insertInside(
                                headerBlock, InvoiceBlockType.note),
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
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
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
                      widget.blocks
                          .add(InvoiceBlockDraft.ofType(InvoiceBlockType.item));
                      widget.onChanged();
                      _scheduleRebuild();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l.invoiceBlocksQuickItem),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      widget.blocks
                          .add(InvoiceBlockDraft.ofType(InvoiceBlockType.date));
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
