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
    this.autoExpandWhenActive = false,
  });

  @override
  State<SearchFiltersHeader> createState() => _SearchFiltersHeaderState();
}

class _SearchFiltersHeaderState extends State<SearchFiltersHeader>
    with SingleTickerProviderStateMixin {
  bool _filtersExpanded = false;
  late AnimationController _animController;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    if (widget.autoExpandWhenActive && widget.hasActiveFilters) {
      _filtersExpanded = true;
      _animController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
    widget.onSearchChanged();
  }

  void _toggleFilters() {
    setState(() => _filtersExpanded = !_filtersExpanded);
    if (_filtersExpanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
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

    final searchEmpty = widget.searchController.text.trim().isEmpty;

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: searchEmpty
                          ? Colors.transparent
                          : cs.primary.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: (_) => _handleSearchChanged(),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: searchEmpty
                            ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                            : cs.primary,
                      ),
                      hintText: widget.searchHint,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 11,
                      ),
                      suffixIcon: searchEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () {
                                widget.searchController.clear();
                                _handleSearchChanged();
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                    ),
                    style: t.bodySmall.copyWith(fontSize: 13),
                  ),
                ),
              ),
              if (hasFilters) const SizedBox(width: 8),
              if (hasFilters)
                _FiltersButton(
                  badgeCount: badgeCount,
                  isActive: widget.hasActiveFilters,
                  isExpanded: effectiveExpanded,
                  rotateAnim: _rotateAnim,
                  label: l.sectionFilters,
                  onTap: _toggleFilters,
                ),
            ],
          ),

          // Active-filter clear bar
          if (widget.hasActiveFilters &&
              widget.onClearFilters != null &&
              widget.showClearAction)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: widget.onClearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: cs.error.withValues(alpha: 0.22)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_off_rounded,
                              size: 12, color: cs.error),
                          const SizedBox(width: 4),
                          Text(
                            l.clientFiltersClear,
                            style: t.caption.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Animated filter panel
          if (hasFilters)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: effectiveExpanded
                  ? Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.filtersContent!,
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  final int badgeCount;
  final bool isActive;
  final bool isExpanded;
  final Animation<double> rotateAnim;
  final String label;
  final VoidCallback onTap;

  const _FiltersButton({
    required this.badgeCount,
    required this.isActive,
    required this.isExpanded,
    required this.rotateAnim,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final bgColor = isActive
        ? cs.primary
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final fgColor = isActive ? cs.onPrimary : cs.onSurface;
    final borderColor = isActive
        ? Colors.transparent
        : cs.outlineVariant.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: rotateAnim,
              child: Icon(Icons.tune_rounded, size: 16, color: fgColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : cs.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: t.caption.copyWith(
                    color: isActive ? Colors.white : cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
