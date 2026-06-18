import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/b-backend/invoicing/models/manual_editor_capabilities.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'blocks_table/block_card.dart';

class BlocksTableEditor extends StatefulWidget {
  final List<InvoiceBlockDraft> blocks;
  final VoidCallback onChanged;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectionChanged;
  final List<ManualEditorBlockTypeCapability> availableBlockTypes;

  const BlocksTableEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    required this.selectedIndex,
    required this.onSelectionChanged,
    required this.availableBlockTypes,
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
    debugPrint('[BlocksTableEditor] move from=$from to=$to total=${widget.blocks.length}');
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
    debugPrint('[BlocksTableEditor] remove index=$index total=${widget.blocks.length}');
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

  // Action buttons are now embedded directly inside BlockCard's header row.
  // This wrapper is kept only for the Padding indentation used by wrappers.
  Widget _cardWithActions({
    required BuildContext context,
    required BlockCard card,
    required int index,
    required VoidCallback onMoveUp,
    required VoidCallback onMoveDown,
    required VoidCallback onDelete,
  }) {
    return card;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;

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
          final blockIdx = _indexOfBlock(block);
          final card = BlockCard(
            key: ValueKey(block),
            index: blockIdx,
            total: widget.blocks.length,
            block: block,
            selected: widget.selectedIndex == blockIdx,
            availableBlockTypes: widget.availableBlockTypes,
            onSelect: () {
              final idx = _indexOfBlock(block);
              if (idx < 0) return;
              widget.onSelectionChanged(idx);
            },
            onDelete: () => _removeBlockAt(_indexOfBlock(block)),
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
              final bIdx = _indexOfBlock(block);
              if (bIdx < 0) return;
              if (idx < 0 ||
                  idx >= widget.blocks[bIdx].checklistItems.length) {
                return;
              }
              widget.blocks[bIdx].checklistItems.removeAt(idx).dispose();
              widget.onChanged();
              _scheduleRebuild();
            },
          );
          widgets.add(
            Padding(
              padding: EdgeInsets.only(left: depth * _wrapperIndent),
              child: _cardWithActions(
                context: context,
                card: card,
                index: blockIdx,
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
                onDelete: () => _removeBlockAt(_indexOfBlock(block)),
              ),
            ),
          );
          i += 1;
          continue;
        }

        final wrapperEnd = findWrapperEnd(i, end);
        final headerBlock = widget.blocks[i];
        final headerIdx = _indexOfBlock(headerBlock);
        final headerCard = BlockCard(
          key: ValueKey(headerBlock),
          index: headerIdx,
          total: widget.blocks.length,
          block: headerBlock,
          selected: widget.selectedIndex == headerIdx,
          availableBlockTypes: widget.availableBlockTypes,
          onSelect: () {
            final idx = _indexOfBlock(headerBlock);
            if (idx < 0) return;
            widget.onSelectionChanged(idx);
          },
          onDelete: () => _removeBlockAt(_indexOfBlock(headerBlock)),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cardWithActions(
                    context: context,
                    card: headerCard,
                    index: headerIdx,
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
                    onDelete: () =>
                        _removeBlockAt(_indexOfBlock(headerBlock)),
                  ),
                  const SizedBox(height: 8),
                  if (children.isNotEmpty) ...children,
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      final addButton = PopupMenuButton<String>(
                        tooltip: l.invoiceAddBlock,
                        onSelected: (type) => insertInside(headerBlock, type),
                        itemBuilder: (_) {
                          final insertable = widget.availableBlockTypes
                              .where((t) => !_isWrapperType(t.id))
                              .toList();
                          if (insertable.isEmpty) {
                            return [
                              PopupMenuItem<String>(
                                value: InvoiceBlockType.item,
                                child: Text(l.invoiceBlockTypeItem),
                              ),
                            ];
                          }
                          return insertable
                              .map((t) => PopupMenuItem<String>(
                                    value: t.id,
                                    child: Text(
                                      t.label.resolve(lang, fallback: t.id),
                                    ),
                                  ))
                              .toList();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, size: 18),
                        ),
                      );

                      final label = Text(
                        l.invoiceWrapperAddInsideLabel,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            label,
                            const SizedBox(height: 8),
                            addButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          addButton,
                          const SizedBox(width: 8),
                          Expanded(child: label),
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_box_outlined,
                size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l.invoiceBlocksEmptyMessage,
                style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buildRange(0, widget.blocks.length, 0),
    );
  }
}
