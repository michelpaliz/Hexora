import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';
import 'package:hexora/b-backend/invoicing/models/manual_editor_capabilities.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/sections/invoice_editor_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_editor/blocks_table_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'invoice_content_section/json_import_unavailable_panel.dart';
import 'invoice_content_section/photo_extract_panel.dart';

class InvoiceContentDiscountConfig {
  const InvoiceContentDiscountConfig({
    required this.readOnly,
    required this.usePercent,
    required this.amountCtrl,
    required this.percentCtrl,
    required this.effectiveDiscountAmount,
    required this.total,
    required this.onModePercentChanged,
    required this.onAmountChanged,
    required this.onPercentChanged,
  });

  final bool readOnly;
  final bool usePercent;
  final TextEditingController amountCtrl;
  final TextEditingController percentCtrl;
  final num effectiveDiscountAmount;
  final num total;
  final ValueChanged<bool> onModePercentChanged;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String> onPercentChanged;
}

class InvoiceContentSection extends StatefulWidget {
  final List<InvoiceBlockDraft> blocks;
  final VoidCallback onChanged;
  final num total;
  final InvoiceEditorController? controller;
  final InvoiceContentDiscountConfig? discountConfig;
  final Future<void> Function()? onSaveDraft;
  final String? saveDraftLabel;
  final bool savingDraft;
  final bool showSaveDraftButton;
  final bool jsonImportLoading;
  final bool jsonPromptLoading;
  final bool jsonImportDisabled;
  final String? jsonImportFileName;
  final String? jsonImportErrorText;
  final Future<void> Function()? onPickJsonImportFile;
  final VoidCallback? onClearJsonImportFile;
  final VoidCallback? onClearJsonImportError;
  final JsonImportFromText? onImportJsonFromText;
  final JsonImportFromFile? onImportJsonFromFile;
  final Future<void> Function()? onCopyJsonPrompt;
  final String? Function(String rawText)? jsonTextValidator;
  final dynamic ocrState;
  final Future<void> Function()? onPickImageForLineExtraction;
  final VoidCallback? onApplyExtractedLines;
  final VoidCallback? onClearExtractedLines;

  const InvoiceContentSection({
    super.key,
    required this.blocks,
    required this.onChanged,
    required this.total,
    this.controller,
    this.discountConfig,
    this.onSaveDraft,
    this.saveDraftLabel,
    this.savingDraft = false,
    this.showSaveDraftButton = true,
    this.jsonImportLoading = false,
    this.jsonPromptLoading = false,
    this.jsonImportDisabled = false,
    this.jsonImportFileName,
    this.jsonImportErrorText,
    this.onPickJsonImportFile,
    this.onClearJsonImportFile,
    this.onClearJsonImportError,
    this.onImportJsonFromText,
    this.onImportJsonFromFile,
    this.onCopyJsonPrompt,
    this.jsonTextValidator,
    // Legacy props kept for call-site compatibility — not used in this widget.
    bool useBlocks = true,
    ValueChanged<bool>? onModeChanged,
    List<dynamic>? lines,
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
  String _contentMode = 'manual';
  final ScrollController _toolSectionsScrollController = ScrollController();

  ManualEditorCapabilities? _capabilities;
  bool _loadingCapabilities = false;
  final Map<String, bool> _toolSectionExpanded = {
    'billable': true,
    'discount': false,
    'content': true,
    'structure': true,
    'other': false,
  };

  @override
  void initState() {
    super.initState();
    _syncSelectionWithBlocks();
    _fetchCapabilities();
  }

  @override
  void dispose() {
    _toolSectionsScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCapabilities() async {
    if (_loadingCapabilities) return;
    setState(() => _loadingCapabilities = true);
    try {
      final lang =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      debugPrint(
          '[ManualEditorCaps] fetching: lang=$lang groupId=${widget.controller?.group.id}');
      final caps = await InvoicesApi().getManualEditorCapabilities(
        lang: lang,
        groupId: widget.controller?.group.id,
      );
      debugPrint(
          '[ManualEditorCaps] OK: ${caps.blockTypes.length} block types → ${caps.blockTypes.map((t) => t.id).join(', ')}');
      if (mounted) setState(() => _capabilities = caps);
    } catch (e, st) {
      debugPrint('[ManualEditorCaps] FAILED: $e');
      if (kDebugMode) {
        debugPrintStack(label: '[ManualEditorCaps] stack', stackTrace: st);
      }
    } finally {
      if (mounted) setState(() => _loadingCapabilities = false);
    }
  }

  void _syncSelectionWithBlocks() {
    if (widget.blocks.isEmpty) {
      _selectedIndex = null;
      return;
    }
    _selectedIndex ??= widget.blocks.length - 1;
    if (_selectedIndex != null && _selectedIndex! >= widget.blocks.length) {
      _selectedIndex = widget.blocks.length - 1;
    }
  }

  bool _isToolSectionExpanded(String id) => _toolSectionExpanded[id] ?? true;

  void _toggleToolSection(String id) {
    setState(() {
      _toolSectionExpanded[id] = !(_toolSectionExpanded[id] ?? true);
    });
  }

  Future<void> _saveDraftFromManualLines() async {
    final customSave = widget.onSaveDraft;
    if (customSave != null) {
      await customSave();
      return;
    }
    final controller = widget.controller;
    if (controller == null) {
      widget.onChanged();
      return;
    }
    try {
      await controller.handleSaveDraft(context, confirmIfEditing: false);
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final raw = e.toString().trim();
      final message = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length).trim()
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? l.somethingWentWrong : message),
        ),
      );
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
    final currentLang = Localizations.localeOf(context).languageCode;

    // ── Block type helpers ────────────────────────────────────────────────────
    bool isWrapperType(String type) =>
        type == InvoiceBlockType.date ||
        type == InvoiceBlockType.section ||
        type == InvoiceBlockType.subsection;

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

    // ── Available block types (server-driven) ─────────────────────────────────
    // Use exactly what the server returns — no hardcoded merging.
    final availableBlockTypes = [
      ...(_capabilities ?? ManualEditorCapabilities.fallback())
          .enabledBlockTypes(lang: currentLang),
    ]..sort((a, b) {
        int score(ManualEditorBlockTypeCapability c) {
          if (c.recommended && c.billable) return 3;
          if (c.billable) return 2;
          if (c.recommended) return 1;
          return 0;
        }

        final scoreCompare = score(b) - score(a);
        if (scoreCompare != 0) return scoreCompare;
        return a.sortOrder.compareTo(b.sortOrder);
      });

    String toolSectionId(ManualEditorBlockTypeCapability cap) {
      if (cap.billable || cap.id == InvoiceBlockType.checklist) {
        return 'billable';
      }
      switch (cap.id) {
        case InvoiceBlockType.note:
          return 'content';
        case InvoiceBlockType.date:
        case InvoiceBlockType.section:
        case InvoiceBlockType.subsection:
        case InvoiceBlockType.divider:
          return 'structure';
      }
      return 'other';
    }

    String toolSectionLabel(String id) {
      final isEs = currentLang.startsWith('es');
      switch (id) {
        case 'billable':
          return isEs ? 'Facturable' : 'Billable';
        case 'discount':
          return isEs ? 'Descuento' : 'Discount';
        case 'content':
          return isEs ? 'Contenido' : 'Content';
        case 'structure':
          return isEs ? 'Estructura' : 'Structure';
        default:
          return isEs ? 'Otros' : 'Other';
      }
    }

    IconData toolSectionIcon(String id) {
      switch (id) {
        case 'billable':
          return Icons.euro_rounded;
        case 'discount':
          return Icons.percent_rounded;
        case 'content':
          return Icons.notes_rounded;
        case 'structure':
          return Icons.account_tree_outlined;
        default:
          return Icons.widgets_outlined;
      }
    }

    final groupedBlockTypes = <String, List<ManualEditorBlockTypeCapability>>{
      'billable': [],
      'content': [],
      'structure': [],
      'other': [],
    };
    for (final cap in availableBlockTypes) {
      groupedBlockTypes[toolSectionId(cap)]!.add(cap);
    }

    // ── Insert block ──────────────────────────────────────────────────────────
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
          final bt = widget.blocks[i].type;
          if (bt == InvoiceBlockType.subsection) return 2;
          if (bt == InvoiceBlockType.section) return 1;
          if (bt == InvoiceBlockType.date) return 1;
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
      final isWrapper = isWrapperType(type);
      if (!isWrapper && level != null && draft.levelCtrl.text.trim().isEmpty) {
        draft.levelCtrl.text = '$level';
      }

      widget.blocks.insert(insertAt, draft);
      _selectedIndex = insertAt;
      widget.onChanged();
      setState(() {});
    }

    // ── "Add block" popup ─────────────────────────────────────────────────────
    Widget blockTypeTile(ManualEditorBlockTypeCapability cap) {
      final recommended = cap.recommended;
      final billable = cap.billable;
      final billableLabel =
          currentLang.startsWith('es') ? 'Facturable' : 'Billable';
      final description = cap.description.resolve(currentLang).trim();
      final label = cap.label.resolve(currentLang, fallback: cap.id);
      final tooltip = cap.tooltip.resolve(currentLang).trim();
      final example = cap.example.resolve(currentLang).trim();

      Future<void> showDetails() {
        return showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(label),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style:
                            t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (tooltip.isNotEmpty) ...[
                      Text(
                        currentLang.startsWith('es') ? 'Informacion' : 'Info',
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tooltip,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (example.isNotEmpty) ...[
                      Text(
                        currentLang.startsWith('es') ? 'Ejemplo' : 'Example',
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          example,
                          style: t.bodySmall.copyWith(
                            color: cs.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child:
                      Text(MaterialLocalizations.of(context).closeButtonLabel),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    insertBlock(cap.id);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l.invoiceAddBlock),
                ),
              ],
            );
          },
        );
      }

      final hasInfo =
          description.isNotEmpty || tooltip.isNotEmpty || example.isNotEmpty;

      // Two-zone row: left = tap to add, right = ⓘ info
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: recommended
                  ? cs.primary.withValues(alpha: 0.4)
                  : cs.outlineVariant.withValues(alpha: 0.5),
            ),
            color: recommended
                ? cs.primaryContainer.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Add zone ──────────────────────────────────────────
                Expanded(
                  child: InkWell(
                    onTap: () => insertBlock(cap.id),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recommended)
                            Tooltip(
                              message: l.invoiceAddBlockRecommended,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.star_outline_rounded,
                                  size: 12,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          if (billable)
                            Tooltip(
                              message: billableLabel,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.euro_outlined,
                                  size: 12,
                                  color: cs.tertiary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(Icons.add, size: 13, color: cs.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Info zone ─────────────────────────────────────────
                if (hasInfo) ...[
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                  InkWell(
                    onTap: showDetails,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget toolSection(String id, List<ManualEditorBlockTypeCapability> caps) {
      if (caps.isEmpty) return const SizedBox.shrink();
      final expanded = _isToolSectionExpanded(id);

      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _toggleToolSection(id),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      toolSectionIcon(id),
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        toolSectionLabel(id),
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.expand_more,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: Column(
                  children: [
                    for (int i = 0; i < caps.length; i++) ...[
                      blockTypeTile(caps[i]),
                      if (i != caps.length - 1) const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget discountSection() {
      final controller = widget.controller;
      final config = widget.discountConfig;
      if (controller == null && config == null) return const SizedBox.shrink();

      final expanded = _isToolSectionExpanded('discount');
      final readOnly = controller?.discountReadOnly ?? config!.readOnly;
      final usePercent = controller?.useDiscountPercent ?? config!.usePercent;
      final discountAmountCtrl =
          controller?.discountAmountCtrl ?? config!.amountCtrl;
      final discountPercentCtrl =
          controller?.discountPercentCtrl ?? config!.percentCtrl;
      final effectiveDiscountAmount = controller?.effectiveDiscountAmount ??
          config!.effectiveDiscountAmount;
      final discountTotal = controller?.total ?? config!.total;
      final moneyFmt = NumberFormat.simpleCurrency(name: '');
      final isSpanish = currentLang.startsWith('es');

      Future<void> showDiscountInfo() {
        return showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(isSpanish ? 'Descuento' : 'Discount'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isSpanish
                    ? 'Usa EUR para restar un importe fijo o % para calcular el descuento sobre la base antes de impuestos.'
                    : 'Use Amount for a fixed deduction or % to calculate the discount from the pre-tax base.',
                style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
              ),
            ],
          ),
        );
      }

      String? validateDiscount(String? raw) {
        final text = (raw ?? '').trim();
        if (text.isEmpty) return null;
        final parsed = num.tryParse(text.replaceAll(',', '.'));
        if (parsed == null) {
          return usePercent
              ? (currentLang.startsWith('es')
                  ? 'Porcentaje invalido'
                  : 'Invalid percent')
              : (currentLang.startsWith('es')
                  ? 'Importe invalido'
                  : 'Invalid amount');
        }
        if (parsed < 0) {
          return currentLang.startsWith('es')
              ? 'Debe ser >= 0'
              : 'Must be >= 0';
        }
        if (usePercent && parsed > 100) return '0 - 100';
        return null;
      }

      Widget modeButton({
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
        return Expanded(
          child: InkWell(
            onTap: readOnly ? null : onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primaryContainer.withValues(alpha: 0.75)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _toggleToolSection('discount'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      toolSectionIcon('discount'),
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        toolSectionLabel('discount'),
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (effectiveDiscountAmount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '-${moneyFmt.format(effectiveDiscountAmount)}',
                        style: t.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: isSpanish ? 'Informacion' : 'Information',
                      onPressed: showDiscountInfo,
                      icon: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.78),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.expand_more,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          modeButton(
                            label:
                                currentLang.startsWith('es') ? 'EUR' : 'Amount',
                            selected: !usePercent,
                            onTap: () => (controller?.setDiscountModePercent ??
                                config!.onModePercentChanged)(false),
                          ),
                          modeButton(
                            label: '%',
                            selected: usePercent,
                            onTap: () => (controller?.setDiscountModePercent ??
                                config!.onModePercentChanged)(true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller:
                          usePercent ? discountPercentCtrl : discountAmountCtrl,
                      enabled: !readOnly,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: validateDiscount,
                      decoration: InputDecoration(
                        labelText: usePercent
                            ? (currentLang.startsWith('es')
                                ? 'Porcentaje'
                                : 'Percent')
                            : (currentLang.startsWith('es')
                                ? 'Importe'
                                : 'Amount'),
                        suffixText: usePercent ? '%' : 'EUR',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                      ),
                      onChanged: usePercent
                          ? (controller?.setDiscountPercentText ??
                              config!.onPercentChanged)
                          : (controller?.setDiscountAmountText ??
                              config!.onAmountChanged),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentLang.startsWith('es') ? 'Total' : 'Total',
                            style: t.bodySmall.copyWith(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          moneyFmt.format(discountTotal),
                          style: t.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget modeTab({
      required String id,
      required String label,
      required bool selected,
    }) {
      return InkWell(
        onTap: () => setState(() => _contentMode = id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    Widget buildJsonPanel() {
      final controller = widget.controller;
      if (controller != null) {
        return LinesJsonImportPanel(
          loading: controller.importingJsonLines,
          loadingPrompt: controller.loadingJsonPromptTemplate,
          disabled: false,
          fileName: controller.jsonImportFileName,
          errorText: controller.jsonImportError,
          onPickFile: () => controller.pickJsonImportFile(context),
          onClearFile: controller.clearJsonImportFile,
          onClearError: controller.clearJsonImportError,
          onImportFromText: (rawText,
                  {required bool overwrite, required double defaultTaxRate}) =>
              controller.importLinesFromJsonText(
            context,
            rawText: rawText,
            overwrite: overwrite,
            defaultTaxRate: defaultTaxRate,
          ),
          onImportFromFile: (
                  {required bool overwrite, required double defaultTaxRate}) =>
              controller.importLinesFromJsonFile(
            context,
            overwrite: overwrite,
            defaultTaxRate: defaultTaxRate,
          ),
          onCopyPrompt: () => controller.copyJsonImportPromptTemplate(context),
        );
      }

      if (widget.onPickJsonImportFile != null &&
          widget.onClearJsonImportFile != null &&
          widget.onImportJsonFromText != null &&
          widget.onImportJsonFromFile != null &&
          widget.onCopyJsonPrompt != null) {
        return LinesJsonImportPanel(
          loading: widget.jsonImportLoading,
          loadingPrompt: widget.jsonPromptLoading,
          disabled: widget.jsonImportDisabled,
          fileName: widget.jsonImportFileName,
          errorText: widget.jsonImportErrorText,
          onPickFile: widget.onPickJsonImportFile!,
          onClearFile: widget.onClearJsonImportFile!,
          onClearError: widget.onClearJsonImportError,
          onImportFromText: widget.onImportJsonFromText!,
          onImportFromFile: widget.onImportJsonFromFile!,
          onCopyPrompt: widget.onCopyJsonPrompt!,
          textValidator: widget.jsonTextValidator,
        );
      }

      return const InvoiceJsonImportUnavailablePanel();
    }

    Widget buildContentBody() {
      if (_contentMode == 'photo') {
        return InvoicePhotoExtractPanel(
          state: widget.ocrState,
          controller: widget.controller,
          hasImagePreview: widget.controller?.hasLastOcrImagePreview ?? false,
          onPreviewImage: null,
          onPickImage: widget.onPickImageForLineExtraction,
          onApply: widget.onApplyExtractedLines,
          onClear: widget.onClearExtractedLines,
        );
      }
      if (_contentMode == 'json') {
        return buildJsonPanel();
      }

      final blocksPanel = Column(
        children: [
          BlocksTableEditor(
            blocks: widget.blocks,
            onChanged: widget.onChanged,
            selectedIndex: _selectedIndex,
            onSelectionChanged: (index) =>
                setState(() => _selectedIndex = index),
            availableBlockTypes: availableBlockTypes,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.showSaveDraftButton)
                FilledButton.tonalIcon(
                  onPressed:
                      (widget.controller?.saving == true || widget.savingDraft)
                          ? null
                          : _saveDraftFromManualLines,
                  icon:
                      (widget.controller?.saving == true || widget.savingDraft)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                  label: Text(
                    (widget.controller?.saving == true || widget.savingDraft)
                        ? l.savingLabel
                        : (widget.saveDraftLabel ?? l.invoiceSaveDraftCta),
                  ),
                ),
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
      );

      final actionsPanel = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   l.invoiceAddBlock,
            //   style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
            // ),
            // const SizedBox(height: 8),
            // Text(
            //   currentLang.startsWith('es')
            //       ? 'Inserta bloques facturables o estructurales sin ocupar todo el ancho.'
            //       : 'Insert billable or structural blocks without using the full width.',
            //   style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            // ),
            // const SizedBox(height: 16),
            if (_loadingCapabilities)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              for (final sectionId in const [
                'billable',
              ]) ...[
                if ((groupedBlockTypes[sectionId] ?? const []).isNotEmpty) ...[
                  toolSection(sectionId, groupedBlockTypes[sectionId]!),
                  const SizedBox(height: 8),
                ],
              ],
              discountSection(),
              const SizedBox(height: 8),
              for (final sectionId in const [
                'content',
                'structure',
                'other',
              ]) ...[
                if ((groupedBlockTypes[sectionId] ?? const []).isNotEmpty) ...[
                  toolSection(sectionId, groupedBlockTypes[sectionId]!),
                  const SizedBox(height: 8),
                ],
              ],
              if (availableBlockTypes.isEmpty)
                blockTypeTile(
                  ManualEditorCapabilities.fallback()
                      .enabledBlockTypes(
                        lang: currentLang,
                      )
                      .first,
                ),
            ],
          ],
        ),
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 980) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  actionsPanel,
                  const SizedBox(height: 16),
                  blocksPanel,
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 176,
                  maxWidth: 196,
                ),
                child: Scrollbar(
                  controller: _toolSectionsScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _toolSectionsScrollController,
                    padding: const EdgeInsets.only(right: 4),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: actionsPanel,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 9,
                child: SingleChildScrollView(
                  child: blocksPanel,
                ),
              ),
            ],
          );
        },
      );
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                modeTab(
                  id: 'manual',
                  label: 'Manual',
                  selected: _contentMode == 'manual',
                ),
                modeTab(
                  id: 'photo',
                  label: 'Foto',
                  selected: _contentMode == 'photo',
                ),
                modeTab(
                  id: 'json',
                  label: 'JSON',
                  selected: _contentMode == 'json',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: buildContentBody()),
        ],
      ),
    );
  }
}
