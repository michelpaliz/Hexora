import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
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
      required this.hasFilterOptions,
      required this.hasActiveFilters,
      this.activeFilterCount = 0,
      this.filtersContent,
      this.persistentContent,
      this.onClearFilters,
      this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 10),
      this.showClearAction = true,
      this.autoExpandWhenActive = false});
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String searchHint;
  final bool hasFilterOptions;
  final bool hasActiveFilters;
  final int activeFilterCount;
  final Widget? filtersContent;
  final Widget? persistentContent;
  final VoidCallback? onClearFilters;
  final EdgeInsetsGeometry padding;
  final bool showClearAction;
  final bool autoExpandWhenActive;
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
    final height = clientFilterControlHeight(context);
    final hasFilters = widget.hasFilterOptions && widget.filtersContent != null;
    return Padding(
        padding: widget.padding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.searchController,
              builder: (context, value, _) => TextField(
                  controller: widget.searchController,
                  onChanged: (_) => widget.onSearchChanged(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    isDense: true,
                    filled: false,
                    constraints: BoxConstraints(minHeight: height),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            tooltip: MaterialLocalizations.of(context)
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
                  )),
            )),
            if (hasFilters) ...[
              const SizedBox(width: 8),
              Semantics(
                  expanded: _expanded,
                  child: TextButton(
                      key: const ValueKey('client-advanced-filters-toggle'),
                      onPressed: () => setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                          minimumSize: Size(32,
                              clientFilterControlHeight(context, desktop: 32)),
                          foregroundColor: widget.hasActiveFilters
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.tune_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(widget.activeFilterCount > 0
                            ? '${l.sectionFilters} (${widget.activeFilterCount})'
                            : l.sectionFilters),
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                            size: 16),
                      ]))),
            ],
          ]),
          if (widget.persistentContent != null ||
              (widget.hasActiveFilters &&
                  widget.showClearAction &&
                  widget.onClearFilters != null))
            Padding(
                padding: const EdgeInsets.only(top: HexoraTableTokens.gap),
                child: LayoutBuilder(builder: (context, constraints) {
                  final clear = widget.hasActiveFilters &&
                          widget.showClearAction &&
                          widget.onClearFilters != null
                      ? TextButton(
                          onPressed: widget.onClearFilters,
                          style: TextButton.styleFrom(
                              minimumSize: Size(
                                  0,
                                  clientFilterControlHeight(context,
                                      desktop: 32)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8)),
                          child: Text(l.clientFiltersClear,
                              style: Theme.of(context).textTheme.labelMedium))
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
          if (hasFilters)
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
