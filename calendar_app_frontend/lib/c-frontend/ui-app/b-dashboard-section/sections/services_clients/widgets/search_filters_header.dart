import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SearchFiltersHeader extends StatefulWidget {
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String searchHint;
  final bool hasFilterOptions;
  final bool hasActiveFilters;
  final int activeFilterCount;
  final Widget? filtersContent;
  final VoidCallback? onClearFilters;
  final EdgeInsetsGeometry padding;
  final bool showClearAction;
  final bool autoExpandWhenActive;

  const SearchFiltersHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchHint,
    required this.hasFilterOptions,
    required this.hasActiveFilters,
    this.activeFilterCount = 0,
    this.filtersContent,
    this.onClearFilters,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 10),
    this.showClearAction = true,
    this.autoExpandWhenActive = true,
  });

  @override
  State<SearchFiltersHeader> createState() => _SearchFiltersHeaderState();
}

class _SearchFiltersHeaderState extends State<SearchFiltersHeader> {
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoExpandWhenActive && widget.hasActiveFilters) {
      _filtersExpanded = true;
    }
  }

  void _handleSearchChanged() {
    setState(() {});
    widget.onSearchChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasFilters = widget.hasFilterOptions && widget.filtersContent != null;
    final effectiveExpanded = _filtersExpanded ||
        (widget.autoExpandWhenActive && widget.hasActiveFilters);
    final badgeCount = widget.activeFilterCount;
    final badgeText = badgeCount > 9 ? '9+' : '$badgeCount';
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
    );

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  onChanged: (_) => _handleSearchChanged(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: widget.searchHint,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                    border: fieldBorder,
                    enabledBorder: fieldBorder,
                    focusedBorder: fieldBorder.copyWith(
                      borderSide: BorderSide(color: cs.primary, width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIcon: widget.searchController.text.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .deleteButtonTooltip,
                            onPressed: () {
                              widget.searchController.clear();
                              _handleSearchChanged();
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                  style: t.bodyMedium,
                ),
              ),
              if (hasFilters) const SizedBox(width: 8),
              if (hasFilters)
                OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  icon: Icon(effectiveExpanded
                      ? Icons.tune_rounded
                      : Icons.tune_outlined),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.sectionFilters),
                      if (badgeCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText,
                            style: t.bodySmall.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    textStyle:
                        t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                    foregroundColor: widget.hasActiveFilters
                        ? cs.onPrimaryContainer
                        : cs.onSurface,
                    backgroundColor: widget.hasActiveFilters
                        ? cs.primaryContainer
                        : cs.surface,
                    side: BorderSide(
                      color: widget.hasActiveFilters
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.hasActiveFilters && widget.onClearFilters != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l.sectionFilters}: $badgeCount',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.showClearAction)
                    TextButton(
                      onPressed: widget.onClearFilters,
                      child: Text(l.clientFiltersClear),
                    ),
                ],
              ),
            ),
          if (hasFilters)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: effectiveExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: widget.filtersContent!,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
