import 'client_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/search_filters_header.dart';
import 'package:hexora/l10n/app_localizations.dart';

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
  final Widget? statusContent;
  final String? statusValue;
  final ValueChanged<String>? onStatusChanged;
  final bool inactiveValueMeansHidden;
  final bool moveSummaryIntoFilters;

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
    this.statusContent,
    this.statusValue,
    this.onStatusChanged,
    this.inactiveValueMeansHidden = false,
    this.moveSummaryIntoFilters = false,
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

    final l = AppLocalizations.of(context)!;
    final summary = Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (statusContent != null)
            statusContent!
          else if (showCounts && statusValue != null && onStatusChanged != null)
            ClientStatusSegments(
                value: statusValue!,
                active: resolvedActiveCount,
                inactive: resolvedInactiveCount,
                onChanged: onStatusChanged!)
          else if (showCounts)
            Text(
                '$activeCountLabel $resolvedActiveCount  ·  $inactiveCountLabel $resolvedInactiveCount',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          if (hasInactiveToggle)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Switch.adaptive(
                value:
                    inactiveValueMeansHidden ? inactiveValue! : !inactiveValue!,
                onChanged: (hidden) => onInactiveChanged!(
                    inactiveValueMeansHidden ? hidden : !hidden),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
              Flexible(
                  child: Text(l.hideInactiveClients,
                      style: Theme.of(context).textTheme.labelMedium)),
            ]),
          if (additionalFilters != null) additionalFilters!,
        ]);
    final filterBody = LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth >= 520
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (moveSummaryIntoFilters) ...[
            summary,
            if (hasEntityFilters || hasPropertyFilters)
              const SizedBox(height: 8),
          ],
          Wrap(spacing: 12, runSpacing: 8, children: [
            if (hasEntityFilters)
              SizedBox(
                  width: width,
                  child: _ClassificationDropdown(
                      label: entityLabel!,
                      options: entityOptions,
                      selected: entityFilter,
                      onSelect: onToggleEntity!,
                      onClear: onClearEntity!)),
            if (hasPropertyFilters)
              SizedBox(
                  width: width,
                  child: _ClassificationDropdown(
                      label: propertyLabel!,
                      options: propertyOptions,
                      selected: propertyFilter,
                      onSelect: onToggleProperty!,
                      onClear: onClearProperty!)),
          ]),
        ],
      );
    });

    return SearchFiltersHeader(
      searchController: searchController,
      onSearchChanged: onSearchChanged,
      searchHint: searchHint,
      hasFilterOptions: hasEntityFilters ||
          hasPropertyFilters ||
          (moveSummaryIntoFilters && (hasInactiveToggle || showCounts)),
      hasActiveFilters: activeFilterCount > 0,
      activeFilterCount: activeFilterCount,
      padding: padding,
      autoExpandWhenActive: autoExpandWhenActive,
      persistentContent: moveSummaryIntoFilters ? null : summary,
      filtersContent: filterBody,
      onClearFilters: () {
        if (onClearFilters != null) {
          onClearFilters!();
        } else {
          if (entityActive) onClearEntity?.call();
          if (propertyActive) onClearProperty?.call();
        }
        if (clearInactiveOnClear && inactiveCounts && hasInactiveToggle) {
          onInactiveChanged!(false);
        }
      },
    );
  }
}

class _ClassificationDropdown extends StatelessWidget {
  const _ClassificationDropdown(
      {required this.label,
      required this.options,
      required this.selected,
      required this.onSelect,
      required this.onClear});
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final values = <String>{
      ...options.where((value) => value.isNotEmpty),
      if (selected != null && selected!.isNotEmpty) selected!
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 4),
      Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          constraints:
              BoxConstraints(minHeight: clientFilterControlHeight(context)),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected == null
                      ? cs.outlineVariant
                      : cs.primary.withValues(alpha: .5))),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
            key: ValueKey('client-filter-$label'),
            value: selected ?? '',
            isExpanded: true,
            isDense: true,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurface),
            icon: const Icon(Icons.expand_more, size: 16),
            items: [
              DropdownMenuItem(value: '', child: Text(l.all)),
              for (final value in values)
                DropdownMenuItem(
                    value: value,
                    child: Text(value,
                        maxLines: 1, overflow: TextOverflow.ellipsis))
            ],
            onChanged: (value) {
              if (value == null || value == '') {
                onClear();
              } else if (value != selected) {
                onSelect(value);
              }
            },
          ))),
    ]);
  }
}
