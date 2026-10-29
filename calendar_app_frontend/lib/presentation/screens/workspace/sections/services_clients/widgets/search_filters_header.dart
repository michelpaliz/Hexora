import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Compact visual controls retain larger targets on touch layouts.
double clientFilterControlHeight(BuildContext context, {double desktop = 36}) {
  final platform = Theme.of(context).platform;
  final touch = MediaQuery.sizeOf(context).width < 760 ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;
  return math.max(
      touch ? 48 : desktop, MediaQuery.textScalerOf(context).scale(13) + 16);
}

class SearchFiltersHeader extends StatefulWidget {
  const SearchFiltersHeader(
      {super.key,
      required this.searchController,
      required this.onSearchChanged,
      required this.searchHint,
      this.clearSearchTooltip,
      this.clearFiltersLabel,
      required this.hasFilterOptions,
      required this.hasActiveFilters,
      this.activeFilterCount = 0,
      this.filtersContent,
      this.persistentContent,
      this.onClearFilters,
      this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 10),
      this.searchDesktopHeight = 40,
      this.searchMaxWidth = 450,
      this.topSpacing = 6,
      this.showClearAction = true,
      this.autoExpandWhenActive = false,
      this.filtersInMenu = false,
      this.toolbarContent,
      this.trailingActions = const []});
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String searchHint;
  final String? clearSearchTooltip;
  final String? clearFiltersLabel;
  final bool hasFilterOptions;
  final bool hasActiveFilters;
  final int activeFilterCount;
  final Widget? filtersContent;
  final Widget? persistentContent;
  final VoidCallback? onClearFilters;
  final EdgeInsetsGeometry padding;
  final bool showClearAction;
  final bool autoExpandWhenActive;
  final bool filtersInMenu;
  final Widget? toolbarContent;
  final double searchDesktopHeight;
  final double searchMaxWidth;
  final double topSpacing;
  final List<Widget> trailingActions;
  @override
  State<SearchFiltersHeader> createState() => _SearchFiltersHeaderState();
}

class _SearchFiltersHeaderState extends State<SearchFiltersHeader> {
  late bool _expanded;
  @override
  void initState() {
    super.initState();
    _expanded = widget.autoExpandWhenActive && widget.hasActiveFilters;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final height = clientFilterControlHeight(
      context,
      desktop: widget.searchDesktopHeight,
    );
    final hasFilters = widget.hasFilterOptions && widget.filtersContent != null;
    return Padding(
        padding: widget.padding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (widget.topSpacing > 0) SizedBox(height: widget.topSpacing),
          LayoutBuilder(builder: (context, constraints) {
            final search = ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.searchController,
                builder: (context, value, _) => TextField(
                    controller: widget.searchController,
                    onChanged: (_) => widget.onSearchChanged(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      isDense: true,
                      filled: true,
                      fillColor: cs.surfaceContainerLow,
                      constraints: BoxConstraints(minHeight: height),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      prefixIconConstraints:
                          BoxConstraints(minWidth: 36, minHeight: height),
                      suffixIconConstraints:
                          BoxConstraints(minWidth: 36, minHeight: height),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              constraints: BoxConstraints.tightFor(
                                  width: height, height: height),
                              padding: const EdgeInsets.all(8),
                              tooltip: widget.clearSearchTooltip ??
                                  MaterialLocalizations.of(context)
                                      .deleteButtonTooltip,
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged();
                              },
                              icon: const Icon(Icons.close_rounded, size: 16)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.outlineVariant)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.outlineVariant)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: cs.primary)),
                    )));
            final searchSlot = constraints.maxWidth >= 760
                ? Flexible(
                    fit: FlexFit.loose,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: widget.searchMaxWidth,
                      ),
                      child: search,
                    ),
                  )
                : Expanded(child: search);
            Widget filterButton(VoidCallback onPressed,
                {bool expanded = false}) {
              return Semantics(
                expanded: expanded,
                child: OutlinedButton(
                  key: const ValueKey('client-advanced-filters-toggle'),
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(32, height),
                    foregroundColor: widget.hasActiveFilters
                        ? cs.primary
                        : cs.onSurfaceVariant,
                    backgroundColor: widget.hasActiveFilters
                        ? cs.primary.withValues(alpha: .06)
                        : Colors.transparent,
                    side: BorderSide(
                      color: widget.hasActiveFilters
                          ? cs.primary.withValues(alpha: .55)
                          : cs.outlineVariant.withValues(alpha: .6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text(widget.activeFilterCount > 0
                          ? '${l.sectionFilters} (${widget.activeFilterCount})'
                          : l.sectionFilters),
                      Icon(
                        widget.filtersInMenu
                            ? Icons.expand_more
                            : expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            }

            final filterControl = hasFilters && widget.filtersInMenu
                ? MenuAnchor(
                    alignmentOffset: const Offset(0, 6),
                    style: MenuStyle(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 6),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    menuChildren: [
                      SizedBox(
                        width: math.max(
                          240,
                          math.min(360, constraints.maxWidth - 16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              widget.filtersContent!,
                              if (widget.hasActiveFilters &&
                                  widget.onClearFilters != null) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: HexoraButton(
                                    onPressed: widget.onClearFilters,
                                    label: widget.clearFiltersLabel ??
                                        l.clientFiltersClear,
                                    variant: HexoraButtonVariant.ghost,
                                    size: HexoraButtonSize.compact,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    builder: (context, controller, child) =>
                        filterButton(controller.open),
                  )
                : hasFilters
                    ? filterButton(
                        () => setState(() => _expanded = !_expanded),
                        expanded: _expanded,
                      )
                    : null;

            final primaryControls = <Widget>[
              searchSlot,
              if (filterControl != null) ...[
                const SizedBox(width: 8),
                filterControl,
              ],
              if (widget.trailingActions.isNotEmpty) ...[
                const SizedBox(width: 8),
                ...widget.trailingActions,
              ],
            ];
            if (widget.toolbarContent != null && constraints.maxWidth < 980) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: primaryControls),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: widget.toolbarContent!,
                  ),
                ],
              );
            }
            return Row(children: [
              ...primaryControls,
              if (widget.toolbarContent != null) ...[
                const SizedBox(width: 10),
                widget.toolbarContent!,
              ],
            ]);
          }),
          if (widget.persistentContent != null ||
              (!widget.filtersInMenu &&
                  widget.hasActiveFilters &&
                  widget.showClearAction &&
                  widget.onClearFilters != null))
            Padding(
                padding: const EdgeInsets.only(top: HexoraTableTokens.gap),
                child: LayoutBuilder(builder: (context, constraints) {
                  final clear = widget.hasActiveFilters &&
                          widget.showClearAction &&
                          widget.onClearFilters != null
                      ? HexoraButton(
                          onPressed: widget.onClearFilters,
                          label:
                              widget.clearFiltersLabel ?? l.clientFiltersClear,
                          variant: HexoraButtonVariant.ghost,
                          size: HexoraButtonSize.compact)
                      : null;
                  if (constraints.maxWidth < 620) {
                    return Wrap(
                        spacing: HexoraTableTokens.gap,
                        runSpacing: HexoraDimensions.space,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.persistentContent != null)
                            widget.persistentContent!,
                          if (clear != null) clear,
                        ]);
                  }
                  return Row(children: [
                    if (widget.persistentContent != null)
                      Expanded(child: widget.persistentContent!),
                    if (clear != null) ...[
                      const SizedBox(width: HexoraTableTokens.gap),
                      clear,
                    ],
                  ]);
                })),
          if (hasFilters && !widget.filtersInMenu)
            AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: widget.filtersContent!)
                    : const SizedBox.shrink()),
        ]));
  }
}
