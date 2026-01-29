import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/chip_rows.dart';
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
    this.autoExpandWhenActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasInactiveToggle = inactiveValue != null &&
        onInactiveChanged != null &&
        inactiveLabelOn != null &&
        inactiveLabelOff != null;
    final hasEntityFilters =
        entityOptions.isNotEmpty &&
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
    final inactiveCounts = countInactiveAsFilter &&
        hasInactiveToggle &&
        (inactiveValue ?? false);
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
          if (!haystack.contains(q)) {
            continue;
          }
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
    if (showCounts) {
      filters.add(
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _CountPill(
              label: activeCountLabel!,
              count: resolvedActiveCount,
              background: cs.primaryContainer.withValues(alpha: 0.55),
              foreground: cs.onPrimaryContainer,
              textStyle: t.bodySmall,
            ),
            _CountPill(
              label: inactiveCountLabel!,
              count: resolvedInactiveCount,
              background: cs.surfaceContainerHighest.withValues(alpha: 0.75),
              foreground: cs.onSurfaceVariant,
              textStyle: t.bodySmall,
            ),
          ],
        ),
      );
      filters.add(const SizedBox(height: 8));
    }
    if (hasInactiveToggle) {
      filters.add(
        FilterChip(
          label: Text(
            (inactiveValue ?? false) ? inactiveLabelOn! : inactiveLabelOff!,
          ),
          selected: inactiveValue ?? false,
          onSelected: (v) => onInactiveChanged!(v),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    if (hasEntityFilters) {
      if (filters.isNotEmpty) filters.add(const SizedBox(height: 10));
      filters.add(
        FilterChipRow(
          label: entityLabel!,
          options: entityOptions,
          selected: entityFilter,
          onToggle: onToggleEntity!,
          onClear: onClearEntity!,
        ),
      );
    }
    if (hasPropertyFilters) {
      if (filters.isNotEmpty) filters.add(const SizedBox(height: 10));
      filters.add(
        FilterChipRow(
          label: propertyLabel!,
          options: propertyOptions,
          selected: propertyFilter,
          onToggle: onToggleProperty!,
          onClear: onClearProperty!,
        ),
      );
    }
    if (additionalFilters != null) {
      if (filters.isNotEmpty) filters.add(const SizedBox(height: 10));
      filters.add(additionalFilters!);
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
              children: filters,
            )
          : null,
      onClearFilters: () {
        if (onClearFilters != null) {
          onClearFilters!();
        } else {
          if (entityActive && onClearEntity != null) {
            onClearEntity!();
          }
          if (propertyActive && onClearProperty != null) {
            onClearProperty!();
          }
        }
        if (clearInactiveOnClear && inactiveCounts && hasInactiveToggle) {
          onInactiveChanged!(false);
        }
      },
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final int count;
  final Color background;
  final Color foreground;
  final TextStyle textStyle;

  const _CountPill({
    required this.label,
    required this.count,
    required this.background,
    required this.foreground,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: textStyle.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
