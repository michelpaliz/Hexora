import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/b-backend/invoicing/invoice_lines_ocr_flow.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/blocks_table_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section/json_import_unavailable_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/invoice_editor_form/invoice_content_section/photo_extract_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/lines_table_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/section_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class InvoiceContentSection extends StatefulWidget {
  final bool useBlocks;
  final ValueChanged<bool> onModeChanged;
  final List<InvoiceBlockDraft> blocks;
  final List<LineDraft> lines;
  final VoidCallback onChanged;
  final num total;
  final InvoiceEditorController? controller;
  final InvoiceLinesOcrFlowState? ocrState;
  final Future<void> Function()? onPickImageForLineExtraction;
  final VoidCallback? onApplyExtractedLines;
  final VoidCallback? onClearExtractedLines;

  const InvoiceContentSection({
    super.key,
    required this.useBlocks,
    required this.onModeChanged,
    required this.blocks,
    required this.lines,
    required this.onChanged,
    required this.total,
    this.controller,
    this.ocrState,
    this.onPickImageForLineExtraction,
    this.onApplyExtractedLines,
    this.onClearExtractedLines,
  });

  @override
  State<InvoiceContentSection> createState() => _InvoiceContentSectionState();
}

class _InvoiceContentSectionState extends State<InvoiceContentSection> {
  int? _selectedIndex;
  int _lineEntryTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _syncSelectionWithBlocks();
  }

  void _syncSelectionWithBlocks() {
    if (!widget.useBlocks) {
      _selectedIndex = null;
      return;
    }
    if (widget.blocks.isEmpty) {
      _selectedIndex = null;
      return;
    }
    _selectedIndex ??= widget.blocks.length - 1;
    if (_selectedIndex != null && _selectedIndex! >= widget.blocks.length) {
      _selectedIndex = widget.blocks.length - 1;
    }
  }

  @override
  void didUpdateWidget(covariant InvoiceContentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectionWithBlocks();
  }

  @override
  Widget build(BuildContext context) {
    _syncSelectionWithBlocks();
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = widget.useBlocks ? l.invoiceBlocksTitle : l.invoiceLinesTitle;
    final supportsPhotoImport = widget.onPickImageForLineExtraction != null &&
        widget.onApplyExtractedLines != null;
    final supportsLineImportTabs = supportsPhotoImport;
    final isPhotoTabActive = supportsLineImportTabs && _lineEntryTabIndex == 1;
    final isJsonTabActive = supportsLineImportTabs && _lineEntryTabIndex == 2;
    final isManualTabActive =
        supportsLineImportTabs && !isPhotoTabActive && !isJsonTabActive;

    bool isWrapperType(String type) {
      return type == InvoiceBlockType.date ||
          type == InvoiceBlockType.section ||
          type == InvoiceBlockType.subsection;
    }

    int wrapperPriority(String type) {
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

    int findWrapperEnd(int start, int max) {
      if (start < 0 || start >= max) return max;
      final current = widget.blocks[start];
      if (!isWrapperType(current.type)) return start + 1;
      final priority = wrapperPriority(current.type);
      for (int i = start + 1; i < max; i++) {
        final next = widget.blocks[i];
        if (isWrapperType(next.type) &&
            wrapperPriority(next.type) <= priority) {
          return i;
        }
      }
      return max;
    }

    int? findContainingWrapper(int index) {
      if (index < 0 || index >= widget.blocks.length) return null;
      for (int i = index; i >= 0; i--) {
        final candidate = widget.blocks[i];
        if (!isWrapperType(candidate.type)) continue;
        final end = findWrapperEnd(i, widget.blocks.length);
        if (index < end) return i;
      }
      return null;
    }

    Widget modeToggle() {
      return Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(l.invoiceBlocksModeBlocks),
            selected: widget.useBlocks,
            onSelected: (_) => widget.onModeChanged(true),
          ),
          ChoiceChip(
            label: Text(l.invoiceBlocksModeLines),
            selected: !widget.useBlocks,
            onSelected: (_) => widget.onModeChanged(false),
          ),
        ],
      );
    }

    Widget addButton() {
      if (!widget.useBlocks) {
        return FilledButton.tonalIcon(
          onPressed: isPhotoTabActive
              ? null
              : () {
                  final nextPos = widget.lines.length + 1;
                  widget.lines.add(LineDraft(position: nextPos));
                  widget.onChanged();
                  setState(() {});
                },
          icon: const Icon(Icons.add),
          label: Text(l.invoiceAddLine),
        );
      }

      final selectedType =
          (_selectedIndex != null && _selectedIndex! < widget.blocks.length)
              ? widget.blocks[_selectedIndex!].type
              : null;
      final selectedWrapper = _selectedIndex == null
          ? null
          : findContainingWrapper(_selectedIndex!);
      final selectionInsideWrapper =
          selectedWrapper != null && selectedWrapper != _selectedIndex;

      void insertBlock(String type) {
        int insertAt = widget.blocks.length;
        if (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.blocks.length) {
          final wrapperStart = findContainingWrapper(_selectedIndex!);
          if (wrapperStart != null) {
            insertAt = findWrapperEnd(wrapperStart, widget.blocks.length);
          } else {
            insertAt = _selectedIndex! + 1;
          }
        }
        final draft = InvoiceBlockDraft.ofType(type);

        int? inferLevel(int index) {
          for (int i = index - 1; i >= 0; i--) {
            final t = widget.blocks[i].type;
            if (t == InvoiceBlockType.subsection) return 2;
            if (t == InvoiceBlockType.section) return 1;
            if (t == InvoiceBlockType.date) return 1;
          }
          return null;
        }

        final containingWrapper = findContainingWrapper(insertAt);
        final wrapperEnd = containingWrapper == null
            ? null
            : findWrapperEnd(containingWrapper, widget.blocks.length);
        final isInsideWrapper = containingWrapper != null &&
            wrapperEnd != null &&
            insertAt < wrapperEnd;
        final level = isInsideWrapper ? inferLevel(insertAt) : null;
        final isWrapper = type == InvoiceBlockType.date ||
            type == InvoiceBlockType.section ||
            type == InvoiceBlockType.subsection;
        if (!isWrapper &&
            level != null &&
            draft.levelCtrl.text.trim().isEmpty) {
          draft.levelCtrl.text = '$level';
        }

        widget.blocks.insert(insertAt, draft);
        _selectedIndex = insertAt;
        widget.onChanged();
        setState(() {});
      }

      List<Map<String, dynamic>> buildOptions() {
        final recommended = <String>{};
        final order = <String>[];

        if (widget.blocks.isEmpty) {
          recommended.addAll([InvoiceBlockType.item, InvoiceBlockType.date]);
          order.addAll([
            InvoiceBlockType.item,
            InvoiceBlockType.date,
            InvoiceBlockType.section,
            InvoiceBlockType.note,
            InvoiceBlockType.checklist,
            InvoiceBlockType.divider,
            InvoiceBlockType.subsection,
          ]);
        } else if (selectedType == InvoiceBlockType.date) {
          recommended.add(InvoiceBlockType.item);
          order.addAll([
            InvoiceBlockType.item,
            InvoiceBlockType.note,
            InvoiceBlockType.checklist,
            InvoiceBlockType.date,
            InvoiceBlockType.section,
            InvoiceBlockType.subsection,
            InvoiceBlockType.divider,
          ]);
        } else if (selectedType == InvoiceBlockType.section) {
          recommended
              .addAll([InvoiceBlockType.item, InvoiceBlockType.subsection]);
          order.addAll([
            InvoiceBlockType.item,
            InvoiceBlockType.subsection,
            InvoiceBlockType.note,
            InvoiceBlockType.checklist,
            InvoiceBlockType.section,
            InvoiceBlockType.divider,
            InvoiceBlockType.date,
          ]);
        } else if (selectedType == InvoiceBlockType.item) {
          recommended.addAll([InvoiceBlockType.item, InvoiceBlockType.note]);
          order.addAll([
            InvoiceBlockType.item,
            InvoiceBlockType.note,
            InvoiceBlockType.checklist,
            InvoiceBlockType.date,
            InvoiceBlockType.section,
            InvoiceBlockType.subsection,
            InvoiceBlockType.divider,
          ]);
        } else {
          order.addAll([
            InvoiceBlockType.item,
            InvoiceBlockType.date,
            InvoiceBlockType.section,
            InvoiceBlockType.subsection,
            InvoiceBlockType.note,
            InvoiceBlockType.checklist,
            InvoiceBlockType.divider,
          ]);
        }

        String labelFor(String type) {
          switch (type) {
            case InvoiceBlockType.item:
              return l.invoiceBlockTypeItem;
            case InvoiceBlockType.date:
              return l.invoiceBlockTypeDate;
            case InvoiceBlockType.section:
              return l.invoiceBlockTypeSection;
            case InvoiceBlockType.subsection:
              return l.invoiceBlockTypeSubsection;
            case InvoiceBlockType.note:
              return l.invoiceBlockTypeNote;
            case InvoiceBlockType.checklist:
              return l.invoiceBlockTypeChecklist;
            case InvoiceBlockType.divider:
              return l.invoiceBlockTypeDivider;
          }
          return type;
        }

        return order
            .map((type) => {
                  'type': type,
                  'label': labelFor(type),
                  'recommended': recommended.contains(type),
                })
            .toList();
      }

      final options = buildOptions();

      Widget menuItem(Map<String, dynamic> option) {
        final recommended = option['recommended'] == true;
        return Row(
          children: [
            Expanded(child: Text(option['label'] as String)),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l.invoiceAddBlockRecommended,
                  style: t.bodySmall.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => insertBlock(InvoiceBlockType.item),
            icon: const Icon(Icons.add),
            label: Text(l.invoiceBlocksQuickItem),
          ),
          OutlinedButton.icon(
            onPressed: () => insertBlock(InvoiceBlockType.date),
            icon: const Icon(Icons.today_outlined),
            label: Text(l.invoiceBlocksQuickDate),
          ),
          PopupMenuButton<String>(
            tooltip: l.invoiceAddBlockMore,
            onSelected: insertBlock,
            itemBuilder: (_) => [
              for (final option in options)
                PopupMenuItem<String>(
                  value: option['type'] as String,
                  child: menuItem(option),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  selectionInsideWrapper
                      ? l.invoiceAddBlockFooterOutsideWrapper
                      : l.invoiceAddBlockFooterInsert,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_horiz,
                      size: 18, color: cs.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    l.invoiceAddBlockMore,
                    style: t.bodySmall.copyWith(
                      color: cs.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SectionCard(
      title: title,
      trailing: Wrap(
        spacing: 8,
        children: [
          modeToggle(),
          if (widget.useBlocks || !supportsLineImportTabs)
            Tooltip(
              message: l.invoiceBlocksInfoTooltip,
              child: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
            ),
          if (widget.useBlocks || !supportsLineImportTabs) addButton(),
        ],
      ),
      child: Column(
        children: [
          if (supportsLineImportTabs) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
                child: DefaultTabController(
                  length: 3,
                  initialIndex: _lineEntryTabIndex,
                  child: TabBar(
                    onTap: (index) {
                      setState(() => _lineEntryTabIndex = index);
                      if (index != 0 && widget.useBlocks) {
                        widget.onModeChanged(false);
                      }
                    },
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    unselectedLabelStyle: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: [
                      Tab(text: l.invoiceLinesModeManual),
                      Tab(text: l.invoiceLinesModePhoto),
                      Tab(text: l.invoiceLinesModeJson),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!widget.useBlocks && isManualTabActive) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Tooltip(
                    message: l.invoiceBlocksInfoTooltip,
                    child: Icon(
                      Icons.info_outline,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  addButton(),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (isPhotoTabActive)
            InvoicePhotoExtractPanel(
              state: widget.ocrState,
              controller: widget.controller,
              hasImagePreview:
                  widget.controller?.hasLastOcrImagePreview == true,
              onPreviewImage: widget.controller == null
                  ? null
                  : () => widget.controller!.previewLastOcrImage(context),
              onPickImage: widget.onPickImageForLineExtraction,
              onApply: widget.onApplyExtractedLines,
              onClear: widget.onClearExtractedLines,
            )
          else if (isJsonTabActive)
            widget.controller == null
                ? const InvoiceJsonImportUnavailablePanel()
                : LinesJsonImportPanel(
                    loading: widget.controller!.importingJsonLines,
                    loadingPrompt: widget.controller!.loadingJsonPromptTemplate,
                    disabled: widget.controller!.extractingLinesFromImage,
                    fileName: widget.controller!.jsonImportFileName,
                    errorText: widget.controller!.jsonImportError,
                    onPickFile: () =>
                        widget.controller!.pickJsonImportFile(context),
                    onClearFile: widget.controller!.clearJsonImportFile,
                    onImportFromText: (
                      rawText, {
                      required bool overwrite,
                      required double defaultTaxRate,
                    }) =>
                        widget.controller!.importLinesFromJsonText(
                      context,
                      rawText: rawText,
                      overwrite: overwrite,
                      defaultTaxRate: defaultTaxRate,
                    ),
                    onImportFromFile: ({
                      required bool overwrite,
                      required double defaultTaxRate,
                    }) =>
                        widget.controller!.importLinesFromJsonFile(
                      context,
                      overwrite: overwrite,
                      defaultTaxRate: defaultTaxRate,
                    ),
                    onCopyPrompt: () => widget.controller!
                        .copyJsonImportPromptTemplate(context),
                    onClearError: widget.controller!.clearJsonImportError,
                  )
          else if (widget.useBlocks)
            BlocksTableEditor(
              blocks: widget.blocks,
              onChanged: widget.onChanged,
              selectedIndex: _selectedIndex,
              onSelectionChanged: (index) =>
                  setState(() => _selectedIndex = index),
            )
          else
            LinesTableEditor(
              lines: widget.lines,
              onChanged: widget.onChanged,
              canAttachEvidence: widget.controller?.canAttachEvidenceForLine,
              evidenceBlobNameOf: widget.controller?.lineEvidenceBlobName,
              onAttachEvidence: widget.controller == null
                  ? null
                  : (line) =>
                      widget.controller!.attachEvidenceForLine(context, line),
              onOpenEvidence: widget.controller == null
                  ? null
                  : (line) =>
                      widget.controller!.openEvidenceForLine(context, line),
              onDeleteEvidence: widget.controller == null
                  ? null
                  : (line) =>
                      widget.controller!.deleteEvidenceForLine(context, line),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Text(
                l.invoiceTotalLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Text(
                NumberFormat.simpleCurrency(name: '').format(widget.total),
                style: t.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
