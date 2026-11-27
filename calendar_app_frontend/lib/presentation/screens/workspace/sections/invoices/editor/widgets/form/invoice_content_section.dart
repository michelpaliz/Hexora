import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hexora/models/invoice/invoice_block.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/invoicing/models/manual_editor_capabilities.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_payment_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/blocks_table_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/widgets/lines_json_import_panel.dart';
import 'package:hexora/presentation/shared/utils/formatting/money_format_utils.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  final Widget? photoExtractionPanel;
  final Future<void> Function()? onPickImageForLineExtraction;
  final VoidCallback? onApplyExtractedLines;
  final VoidCallback? onClearExtractedLines;
  final String? contentMode;
  final ValueChanged<String>? onContentModeChanged;
  final bool showModeTabs;

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
    this.photoExtractionPanel,
    this.onPickImageForLineExtraction,
    this.onApplyExtractedLines,
    this.onClearExtractedLines,
    this.contentMode,
    this.onContentModeChanged,
    this.showModeTabs = true,
  });

  @override
  State<InvoiceContentSection> createState() => _InvoiceContentSectionState();
}

class _InvoiceContentSectionState extends State<InvoiceContentSection> {
  int? _selectedIndex;
  String _contentMode = 'manual';

  ManualEditorCapabilities? _capabilities;
  bool _loadingCapabilities = false;

  /// Whether the inline discount strip is shown. Null = not toggled yet, in
  /// which case it opens automatically when a discount is already applied.
  bool? _discountOpen;

  @override
  void initState() {
    super.initState();
    _syncSelectionWithBlocks();
    _fetchCapabilities();
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

  String get _activeContentMode => widget.contentMode ?? _contentMode;

  void _selectContentMode(String mode) {
    if (widget.contentMode == null) {
      setState(() => _contentMode = mode);
    }
    widget.onContentModeChanged?.call(mode);
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
          .enabledBlockTypes(lang: currentLang)
          .where((capability) => capability.id != InvoiceBlockType.date),
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

    // Primary toolbar actions: billable lines (Ítem, Trabajo…) and checklist.
    // Content (Nota) also sits in the toolbar; structural and any other types
    // go into the "Estructura" dropdown.
    String toolSectionId(ManualEditorBlockTypeCapability cap) {
      if (cap.billable ||
          cap.id == InvoiceBlockType.checklist ||
          cap.id == InvoiceBlockType.worker) {
        return 'primary';
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

    final groupedBlockTypes = <String, List<ManualEditorBlockTypeCapability>>{
      'primary': [],
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

    // ── Manual-actions toolbar ────────────────────────────────────────────────
    IconData blockTypeIcon(String id) {
      switch (id) {
        case InvoiceBlockType.item:
          return LucideIcons.listPlus;
        case InvoiceBlockType.worker:
          return LucideIcons.hardHat;
        case InvoiceBlockType.checklist:
          return LucideIcons.listChecks;
        case InvoiceBlockType.note:
          return LucideIcons.stickyNote;
        case InvoiceBlockType.section:
          return LucideIcons.heading1;
        case InvoiceBlockType.subsection:
          return LucideIcons.heading2;
        case InvoiceBlockType.divider:
          return LucideIcons.separatorHorizontal;
        case InvoiceBlockType.date:
          return LucideIcons.calendar;
      }
      return LucideIcons.box;
    }

    String blockTypeLabel(ManualEditorBlockTypeCapability cap) =>
        cap.label.resolve(currentLang, fallback: cap.id);

    /// Hover help replacing the old per-tile ⓘ dialog: description, extra
    /// info and example from the server capabilities.
    String blockTypeTooltip(ManualEditorBlockTypeCapability cap) {
      final isEs = currentLang.startsWith('es');
      final parts = <String>[
        blockTypeLabel(cap),
        cap.description.resolve(currentLang).trim(),
        cap.tooltip.resolve(currentLang).trim(),
      ];
      final example = cap.example.resolve(currentLang).trim();
      if (example.isNotEmpty && example != '—') {
        parts.add('${isEs ? 'Ejemplo' : 'Example'}: $example');
      }
      if (cap.recommended) parts.add(l.invoiceAddBlockRecommended);
      return parts.where((p) => p.isNotEmpty).toSet().join('\n');
    }

    // Neutral by default, light-blue tint + blue text on hover/focus,
    // stronger tint when pressed or toggled on. No saturated fills.
    ButtonStyle toolbarButtonStyle({bool active = false}) => ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return cs.onSurface.withValues(alpha: 0.38);
            }
            if (active ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.pressed)) {
              return cs.primary;
            }
            return cs.onSurface.withValues(alpha: 0.8);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return null;
            if (states.contains(WidgetState.pressed)) {
              return cs.primary.withValues(alpha: 0.16);
            }
            if (active) return cs.primary.withValues(alpha: 0.12);
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return cs.primary.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
          fixedSize: const WidgetStatePropertyAll(Size.fromHeight(34)),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStatePropertyAll(
            t.bodySmall.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          iconSize: const WidgetStatePropertyAll(16),
        );

    Widget toolbarAction({
      required Key key,
      required IconData icon,
      required String label,
      required String tooltip,
      required VoidCallback? onPressed,
      bool active = false,
      Widget? trailing,
    }) {
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: TextButton(
          key: key,
          onPressed: onPressed,
          style: toolbarButtonStyle(active: active),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label),
              if (trailing != null) ...[const SizedBox(width: 4), trailing],
            ],
          ),
        ),
      );
    }

    Widget toolbarDivider() => Container(
          width: 1,
          height: 20,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          color: cs.outlineVariant.withValues(alpha: 0.5),
        );

    final hasDiscount =
        widget.controller != null || widget.discountConfig != null;
    final discountAmount = widget.controller?.effectiveDiscountAmount ??
        widget.discountConfig?.effectiveDiscountAmount ??
        0;
    final discountOpen = hasDiscount && (_discountOpen ?? discountAmount > 0);
    final moneyFmt = NumberFormat.simpleCurrency(name: '');

    Widget manualToolbar() {
      final isEs = currentLang.startsWith('es');
      final primaryTypes = groupedBlockTypes['primary']!;
      final contentTypes = groupedBlockTypes['content']!;
      final structureTypes = groupedBlockTypes['structure']!;
      final otherTypes = groupedBlockTypes['other']!;
      final fallbackType = availableBlockTypes.isEmpty
          ? ManualEditorCapabilities.fallback()
              .enabledBlockTypes(lang: currentLang)
              .first
          : null;

      Widget insertAction(ManualEditorBlockTypeCapability cap) => toolbarAction(
            key: ValueKey('invoice-toolbar-add-${cap.id}'),
            icon: blockTypeIcon(cap.id),
            label: blockTypeLabel(cap),
            tooltip: blockTypeTooltip(cap),
            onPressed: () => insertBlock(cap.id),
          );

      final menuTypes = [...structureTypes, ...otherTypes];
      final structureMenu = menuTypes.isEmpty
          ? null
          : MenuAnchor(
              alignmentOffset: const Offset(0, 4),
              style: MenuStyle(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 4),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              menuChildren: [
                for (final cap in menuTypes)
                  Tooltip(
                    message: blockTypeTooltip(cap),
                    waitDuration: const Duration(milliseconds: 600),
                    child: MenuItemButton(
                      key: ValueKey('invoice-toolbar-add-${cap.id}'),
                      leadingIcon: Icon(blockTypeIcon(cap.id), size: 16),
                      onPressed: () => insertBlock(cap.id),
                      child: Text(blockTypeLabel(cap)),
                    ),
                  ),
              ],
              builder: (context, menu, _) => toolbarAction(
                key: const ValueKey('invoice-toolbar-structure'),
                icon: LucideIcons.layoutList,
                label: isEs ? 'Estructura' : 'Structure',
                tooltip: isEs
                    ? 'Insertar sección, subsección o divisor'
                    : 'Insert section, subsection or divider',
                active: menu.isOpen,
                onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                trailing: const Icon(LucideIcons.chevronDown, size: 14),
              ),
            );

      final actions = <Widget>[
        for (final cap in primaryTypes) insertAction(cap),
        if (fallbackType != null) insertAction(fallbackType),
        if (hasDiscount)
          toolbarAction(
            key: const ValueKey('invoice-toolbar-discount'),
            icon: LucideIcons.percent,
            label: discountAmount > 0
                ? '${isEs ? 'Descuento' : 'Discount'} '
                    '-${moneyFmt.format(discountAmount)}'
                : (isEs ? 'Descuento' : 'Discount'),
            tooltip: isEs
                ? 'Descuento sobre la base antes de impuestos'
                : 'Discount on the pre-tax base',
            active: discountOpen,
            onPressed: () => setState(() => _discountOpen = !discountOpen),
          ),
        for (final cap in contentTypes) insertAction(cap),
        if (structureMenu != null) ...[toolbarDivider(), structureMenu],
      ];

      return Container(
        key: const ValueKey('invoice-manual-toolbar'),
        height: 46,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              // Scrolls sideways on narrow screens instead of wrapping into
              // extra rows or squeezing the buttons.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
            if (_loadingCapabilities)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      );
    }

    /// Inline discount controls shown under the toolbar when "Descuento" is
    /// toggled on. Stays inside the invoice Form so validation keeps working.
    Widget discountStrip() {
      final controller = widget.controller;
      final config = widget.discountConfig;
      final readOnly = controller?.discountReadOnly ?? config!.readOnly;
      final usePercent = controller?.useDiscountPercent ?? config!.usePercent;
      final discountAmountCtrl =
          controller?.discountAmountCtrl ?? config!.amountCtrl;
      final discountPercentCtrl =
          controller?.discountPercentCtrl ?? config!.percentCtrl;
      final discountTotal = controller?.total ?? config!.total;
      final isSpanish = currentLang.startsWith('es');
      final setPercentMode =
          controller?.setDiscountModePercent ?? config!.onModePercentChanged;

      String? validateDiscount(String? raw) {
        final text = (raw ?? '').trim();
        if (text.isEmpty) return null;
        final parsed = num.tryParse(text.replaceAll(',', '.'));
        if (parsed == null) {
          return usePercent
              ? (isSpanish ? 'Porcentaje invalido' : 'Invalid percent')
              : (isSpanish ? 'Importe invalido' : 'Invalid amount');
        }
        if (parsed < 0) return isSpanish ? 'Debe ser >= 0' : 'Must be >= 0';
        if (usePercent && parsed > 100) return '0 - 100';
        return null;
      }

      Widget modeButton(String label, bool selected, bool percent) => InkWell(
            onTap: readOnly ? null : () => setPercentMode(percent),
            borderRadius: BorderRadius.circular(7),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
          );

      return Container(
        key: const ValueKey('invoice-discount-strip'),
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: isSpanish
                  ? 'Usa EUR para restar un importe fijo o % para calcular el descuento sobre la base antes de impuestos.'
                  : 'Use Amount for a fixed deduction or % to calculate the discount from the pre-tax base.',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.percent, size: 15, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    isSpanish ? 'Descuento' : 'Discount',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.info, size: 13, color: cs.onSurfaceVariant),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  modeButton(isSpanish ? 'EUR' : 'Amount', !usePercent, false),
                  modeButton('%', usePercent, true),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              child: TextFormField(
                key: const ValueKey('invoice-discount-field'),
                controller:
                    usePercent ? discountPercentCtrl : discountAmountCtrl,
                enabled: !readOnly,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: validateDiscount,
                decoration: InputDecoration(
                  labelText: usePercent
                      ? (isSpanish ? 'Porcentaje' : 'Percent')
                      : (isSpanish ? 'Importe' : 'Amount'),
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
            ),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'Total  ',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
                TextSpan(
                  text: moneyFmt.format(discountTotal),
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ]),
            ),
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
        key: ValueKey('invoice-content-mode-$id'),
        onTap: () => _selectContentMode(id),
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

    Widget buildManualContent() {
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
          if (widget.controller != null) ...[
            const SizedBox(height: 8),
            InvoicePaymentEditor(
              invoice: widget.controller!.paymentEditorInvoice,
              compact: true,
              showSaveButton: false,
              onPaymentChanged: widget.controller!.setDraftPaymentPayload,
              onSave: (_) async {},
            ),
          ],
          const SizedBox(height: 8),
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
                '${formatMoneyEu(widget.total, fallback: '0,00')} €',
                style: t.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      );

      // Toolbar stays pinned above the lines; only the lines area scrolls, so
      // the actions are always reachable without a nested palette scroller.
      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          manualToolbar(),
          if (discountOpen) discountStrip(),
          const SizedBox(height: 8),
        ],
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedHeight) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, blocksPanel],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(
                child: SingleChildScrollView(
                  key: const PageStorageKey('invoice-manual-lines-scroll'),
                  child: blocksPanel,
                ),
              ),
            ],
          );
        },
      );
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    final activeMode = _activeContentMode;
    final activeModeIndex = switch (activeMode) {
      'photo' => 1,
      'json' => 2,
      _ => 0,
    };
    final photoContent = widget.photoExtractionPanel ??
        InvoicePhotoExtractPanel(
          state: widget.ocrState,
          controller: widget.controller,
          hasImagePreview: widget.controller?.hasLastOcrImagePreview ?? false,
          onPreviewImage: null,
          onPickImage: widget.onPickImageForLineExtraction,
          onApply: widget.onApplyExtractedLines,
          onClear: widget.onClearExtractedLines,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showModeTabs) ...[
            const SizedBox(height: 4),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  modeTab(
                    id: 'manual',
                    label: 'Manual',
                    selected: activeMode == 'manual',
                  ),
                  modeTab(
                    id: 'photo',
                    label:
                        l.localeName.startsWith('es') ? 'Chat IA' : 'AI chat',
                    selected: activeMode == 'photo',
                  ),
                  modeTab(
                    id: 'json',
                    label: 'JSON',
                    selected: activeMode == 'json',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: IndexedStack(
              index: activeModeIndex,
              sizing: StackFit.expand,
              children: [
                buildManualContent(),
                photoContent,
                buildJsonPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
