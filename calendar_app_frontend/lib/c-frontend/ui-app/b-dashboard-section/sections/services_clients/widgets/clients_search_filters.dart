import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/search_filters_header.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class ClientsSearchFilters extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String searchHint;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onClearFilters;
  final int? activeCount;
  final int? inactiveCount;
  final List<GroupClient>? clientsForCounts;
  final bool includeSearchInCounts;
  final String? activeCountLabel;
  final String? inactiveCountLabel;

  final bool? inactiveValue;
  final ValueChanged<bool>? onInactiveChanged;
  final String? inactiveLabelOn;
  final String? inactiveLabelOff;
  final bool countInactiveAsFilter;
  final bool clearInactiveOnClear;

  final String? entityLabel;
  final List<String> entityOptions;
  final String? entityFilter;
  final ValueChanged<String>? onToggleEntity;
  final VoidCallback? onClearEntity;

  final String? propertyLabel;
  final List<String> propertyOptions;
  final String? propertyFilter;
  final ValueChanged<String>? onToggleProperty;
  final VoidCallback? onClearProperty;
  final Widget? additionalFilters;
  final int extraActiveFilterCount;
  final bool autoExpandWhenActive;

  const ClientsSearchFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchHint,
    this.padding = const EdgeInsets.fromLTRB(12, 0, 12, 10),
    this.onClearFilters,
    this.activeCount,
    this.inactiveCount,
    this.clientsForCounts,
    this.includeSearchInCounts = true,
    this.activeCountLabel,
    this.inactiveCountLabel,
    this.inactiveValue,
    this.onInactiveChanged,
    this.inactiveLabelOn,
    this.inactiveLabelOff,
    this.countInactiveAsFilter = true,
    this.clearInactiveOnClear = true,
    this.entityLabel,
    this.entityOptions = const [],
    this.entityFilter,
    this.onToggleEntity,
    this.onClearEntity,
    this.propertyLabel,
    this.propertyOptions = const [],
    this.propertyFilter,
    this.onToggleProperty,
    this.onClearProperty,
    this.additionalFilters,
    this.extraActiveFilterCount = 0,
    this.autoExpandWhenActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasInactiveToggle = inactiveValue != null &&
        onInactiveChanged != null &&
        inactiveLabelOn != null &&
        inactiveLabelOff != null;
    final hasEntityFilters = entityOptions.isNotEmpty &&
        entityLabel != null &&
        onToggleEntity != null &&
        onClearEntity != null;
    final hasPropertyFilters = propertyOptions.isNotEmpty &&
        propertyLabel != null &&
        onToggleProperty != null &&
        onClearProperty != null;
    final hasFilterOptions = hasInactiveToggle ||
        hasEntityFilters ||
        hasPropertyFilters ||
        additionalFilters != null;

    final entityActive = (entityFilter ?? '').trim().isNotEmpty;
    final propertyActive = (propertyFilter ?? '').trim().isNotEmpty;
    final inactiveCounts =
        countInactiveAsFilter && hasInactiveToggle && (inactiveValue ?? false);

    int? resolvedActiveCount = activeCount;
    int? resolvedInactiveCount = inactiveCount;
    if ((resolvedActiveCount == null || resolvedInactiveCount == null) &&
        clientsForCounts != null) {
      var active = 0;
      var inactive = 0;
      final q = searchController.text.trim().toLowerCase();
      for (final c in clientsForCounts!) {
        if (includeSearchInCounts && q.isNotEmpty) {
          final haystack = <String>[
            c.name,
            c.email ?? '',
            c.phone ?? '',
            c.billing?.legalName ?? '',
          ].join(' ').toLowerCase();
          if (!haystack.contains(q)) continue;
        }
        if (entityActive &&
            (c.entityType ?? '').trim() != (entityFilter ?? '').trim()) {
          continue;
        }
        if (propertyActive &&
            (c.propertyKind ?? '').trim() != (propertyFilter ?? '').trim()) {
          continue;
        }
        if (c.isActive == false) {
          inactive += 1;
        } else {
          active += 1;
        }
      }
      resolvedActiveCount ??= active;
      resolvedInactiveCount ??= inactive;
    }

    final activeFilterCount = (inactiveCounts ? 1 : 0) +
        (entityActive ? 1 : 0) +
        (propertyActive ? 1 : 0) +
        extraActiveFilterCount;
    final showCounts = resolvedActiveCount != null &&
        resolvedInactiveCount != null &&
        activeCountLabel != null &&
        inactiveCountLabel != null;

    final filters = <Widget>[];

    // Single responsive row: stat cards + toggle + additional chip
    final hasToggleOrAdditional =
        hasInactiveToggle || additionalFilters != null;
    if (showCounts || hasToggleOrAdditional) {
      final activeCountForDisplay = resolvedActiveCount ?? 0;
      final inactiveCountForDisplay = resolvedInactiveCount ?? 0;
      filters.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final maxToggleWidth =
                constraints.maxWidth < 360 ? constraints.maxWidth : 180.0;
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showCounts) ...[
                  _StatCard(
                    label: activeCountLabel!,
                    count: activeCountForDisplay,
                    icon: Icons.people_alt_rounded,
                    color: cs.primary,
                    background: cs.primaryContainer.withValues(alpha: 0.35),
                    foreground: cs.onPrimaryContainer,
                  ),
                  _StatCard(
                    label: inactiveCountLabel!,
                    count: inactiveCountForDisplay,
                    icon: Icons.person_off_rounded,
                    color: cs.onSurfaceVariant,
                    background:
                        cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    foreground: cs.onSurfaceVariant,
                  ),
                ],
                if (hasInactiveToggle)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxToggleWidth),
                    child: _FilterToggleRow(
                      icon: (inactiveValue ?? false)
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      label: (inactiveValue ?? false)
                          ? inactiveLabelOn!
                          : inactiveLabelOff!,
                      value: inactiveValue ?? false,
                      onChanged: (v) => onInactiveChanged!(v),
                    ),
                  ),
                if (additionalFilters != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: additionalFilters!,
                  ),
              ],
            );
          },
        ),
      );
    }

    // Row 3: Entity filter (inline label + chips)
    if (hasEntityFilters) {
      if (filters.isNotEmpty) filters.add(const SizedBox(height: 8));
      filters.add(
        _InlineFilterRow(
          label: entityLabel!,
          options: entityOptions,
          selected: entityFilter,
          onToggle: onToggleEntity!,
          onClear: onClearEntity!,
        ),
      );
    }

    // Row 4: Property filter (inline label + chips)
    if (hasPropertyFilters) {
      if (filters.isNotEmpty) filters.add(const SizedBox(height: 8));
      filters.add(
        _InlineFilterRow(
          label: propertyLabel!,
          options: propertyOptions,
          selected: propertyFilter,
          onToggle: onToggleProperty!,
          onClear: onClearProperty!,
        ),
      );
    }

    return SearchFiltersHeader(
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      searchHint: searchHint,
      hasFilterOptions: hasFilterOptions,
      hasActiveFilters: activeFilterCount > 0,
      activeFilterCount: activeFilterCount,
      padding: padding,
      autoExpandWhenActive: autoExpandWhenActive,
      filtersContent: hasFilterOptions
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: filters,
            )
          : null,
      onClearFilters: () {
        if (onClearFilters != null) {
          onClearFilters!();
        } else {
          if (entityActive && onClearEntity != null) onClearEntity!();
          if (propertyActive && onClearProperty != null) onClearProperty!();
        }
        if (clearInactiveOnClear && inactiveCounts && hasInactiveToggle) {
          onInactiveChanged!(false);
        }
      },
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;
  final Color foreground;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: foreground,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            style: t.caption.copyWith(
              color: foreground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle row ─────────────────────────────────────────────────────────────────

class _FilterToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Semantics(
      button: true,
      toggled: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.only(left: 10, right: 7, top: 3, bottom: 3),
          decoration: BoxDecoration(
            color: value
                ? cs.primaryContainer.withValues(alpha: 0.5)
                : cs.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value
                  ? cs.primary.withValues(alpha: 0.35)
                  : cs.outlineVariant.withValues(alpha: 0.38),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: value ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: value ? cs.onPrimaryContainer : cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 32,
                height: 20,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeThumbColor: cs.onPrimary,
                    activeTrackColor: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Inline filter row (label + chips on one Wrap line) ─────────────────────────

class _InlineFilterRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  const _InlineFilterRow({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isActive = selected != null;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? cs.primary : cs.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$label:',
              style: t.caption.copyWith(
                color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        for (final o in options)
          _PillChip(
            label: o,
            selected: selected == o,
            onTap: () => selected == o ? onClear() : onToggle(o),
          ),
      ],
    );
  }
}

// ── Pill chip ──────────────────────────────────────────────────────────────────

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: t.bodySmall.copyWith(
              color: selected ? cs.onPrimary : cs.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}
