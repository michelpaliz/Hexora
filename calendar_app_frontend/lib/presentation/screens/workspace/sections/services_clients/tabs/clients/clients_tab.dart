import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';

import 'client_list_item.dart';

class ClientsTab extends StatefulWidget {
  final List<GroupClient> items;
  final String? selectedClientId;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool showInlineCTA;
  final VoidCallback? onAddTap;
  final void Function(GroupClient client)? onEdit;
  final bool showInactive;
  final ValueChanged<bool>? onToggleInactive;
  final bool missingCurrentMonthInvoiceOnly;
  final ValueChanged<bool>? onToggleMissingCurrentMonthInvoiceOnly;
  final String? propertyTypeFilter;
  final List<String> propertyTypeOptions;
  final ValueChanged<String?>? onPropertyTypeChanged;
  final String? customerTypeFilter;
  final List<String> customerTypeOptions;
  final ValueChanged<String?>? onCustomerTypeChanged;
  final void Function(GroupClient client)? onDelete;

  const ClientsTab({
    super.key,
    required this.items,
    this.selectedClientId,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.showInlineCTA = false,
    this.onAddTap,
    this.onEdit,
    this.showInactive = false,
    this.onToggleInactive,
    this.missingCurrentMonthInvoiceOnly = false,
    this.onToggleMissingCurrentMonthInvoiceOnly,
    this.propertyTypeFilter,
    this.propertyTypeOptions = const [],
    this.onPropertyTypeChanged,
    this.customerTypeFilter,
    this.customerTypeOptions = const [],
    this.onCustomerTypeChanged,
    this.onDelete,
  });

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  String _status = 'all';
  bool _ascending = true;
  int _page = 0;
  int? _pageSize;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(GroupClient c) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = <String>[
      c.name,
      c.email ?? '',
      c.phone ?? '',
      c.billing?.legalName ?? '',
      c.billing?.taxId ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final filtered = widget.items.where((client) {
      final matchesCustomer = widget.customerTypeFilter == null ||
          widget.customerTypeFilter!.isEmpty ||
          (client.effectiveCustomerType ?? '').trim() ==
              widget.customerTypeFilter!.trim();
      final matchesProperty = widget.propertyTypeFilter == null ||
          widget.propertyTypeFilter!.isEmpty ||
          (client.effectivePropertyType ?? '').trim() ==
              widget.propertyTypeFilter!.trim();
      return matchesCustomer && matchesProperty;
    }).toList(growable: false);
    final searched = filtered.where(_matchesSearch).toList(growable: false);
    final flagged = widget.missingCurrentMonthInvoiceOnly
        ? searched
            .where((c) =>
                c.isActive != false && c.missingCurrentMonthInvoice == true)
            .toList(growable: false)
        : searched;
    final activeItems =
        flagged.where((c) => c.isActive != false).toList(growable: false);
    final inactiveItems =
        flagged.where((c) => c.isActive == false).toList(growable: false);
    final visible = (_status == 'active'
            ? activeItems
            : _status == 'inactive'
                ? inactiveItems
                : flagged)
        .toList();
    visible.sort((a, b) => _ascending
        ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
        : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    final pageSize =
        _pageSize ?? (MediaQuery.sizeOf(context).width >= 760 ? 25 : 10);
    final pages = (visible.length / pageSize).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final pageItems = visible.skip(page * pageSize).take(pageSize).toList();
    final hasInvoiceFlagData =
        widget.items.any((c) => c.hasCurrentMonthInvoiceFlagData);
    final missingInvoiceCount = searched
        .where(
            (c) => c.isActive != false && c.missingCurrentMonthInvoice == true)
        .length;

    final query = _searchCtrl.text.trim();
    final hasSearch = query.isNotEmpty;
    final hasPropertyFilter =
        (widget.propertyTypeFilter ?? '').trim().isNotEmpty;
    final hasCustomerFilter =
        (widget.customerTypeFilter ?? '').trim().isNotEmpty;
    final hasSourceData = widget.items.isNotEmpty;

    late final Widget content;
    if (widget.loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (widget.error != null) {
      content = ErrorView(message: widget.error!, onRetry: widget.onRefresh);
    } else if (visible.isEmpty) {
      if (widget.missingCurrentMonthInvoiceOnly &&
          !hasSearch &&
          !hasPropertyFilter) {
        content = EmptyView(
          icon: hasInvoiceFlagData
              ? Icons.verified_outlined
              : Icons.hourglass_empty_rounded,
          title: hasInvoiceFlagData
              ? 'All clients have an invoice this month'
              : 'Current-month invoice status unavailable',
          subtitle: hasInvoiceFlagData
              ? 'No clients are currently flagged as missing an invoice this month.'
              : 'The backend did not return current-month invoice flags for these clients yet.',
        );
      } else if (hasSourceData &&
          (hasSearch || hasCustomerFilter || hasPropertyFilter)) {
        content = EmptyView(
          icon: Icons.search_off_rounded,
          title: hasSearch ? l.noMatchesForX(query) : l.noMatchesInvite,
          subtitle: hasSearch
              ? '${l.activeClientsSection} - 0'
              : '${l.activeClientsSection} - 0 - ${l.statusInactive}: 0',
        );
      } else {
        content = EmptyView(
          icon: Icons.person_outline,
          title: l.noClientsYet,
          subtitle: widget.showInactive
              ? '${l.activeClientsSection} - 0 - ${l.statusInactive}: 0'
              : '${l.activeClientsSection} - 0',
          cta: widget.showInlineCTA ? l.addClient : null,
          onPressed: widget.showInlineCTA ? widget.onAddTap : null,
        );
      }
    } else {
      content = RefreshIndicator(
        color: cs.primary,
        backgroundColor: cs.surface,
        onRefresh: widget.onRefresh,
        child: ListView.separated(
          cacheExtent: 800,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          itemCount: pageItems.length,
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemBuilder: (_, i) {
            final c = pageItems[i];
            return ClientListItem(
              client: c,
              selected: c.id == widget.selectedClientId,
              onTap: widget.onEdit == null ? null : () => widget.onEdit!(c),
              onDelete:
                  widget.onDelete == null ? null : () => widget.onDelete!(c),
              nameStyle: typo.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
                color: cs.onSurface,
              ),
              metaStyle: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: .1,
              ),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientsSearchFilters(
          searchController: _searchCtrl,
          onSearchChanged: () => setState(() => _page = 0),
          searchHint: l.clientSearchHint,
          clearFiltersLabel: l.localeName.toLowerCase().startsWith('es')
              ? 'Restablecer'
              : 'Reset',
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          searchDesktopHeight: 34,
          topSpacing: 0,
          clientsForCounts: filtered,
          trailingActions: [
            _SortButton(
              ascending: _ascending,
              onChanged: (v) => setState(() {
                _ascending = v;
                _page = 0;
              }),
            ),
            HexoraButton.iconOnly(
              key: const ValueKey('client-refresh-control'),
              tooltip: l.refresh,
              onPressed: widget.loading ? null : widget.onRefresh,
              icon: Icons.refresh_rounded,
              variant: HexoraButtonVariant.ghost,
              size: HexoraButtonSize.standard,
            ),
          ],
          statusContent: _ClientStatusFilter(
            value: _status,
            active: activeItems.length,
            inactive: inactiveItems.length,
            onChanged: (value) => setState(() {
              _status = value;
              _page = 0;
            }),
          ),
          activeCountLabel: l.activeClientsSection,
          inactiveCountLabel: l.statusInactive,
          additionalFilters: _MissingInvoiceToggle(
            selected: widget.missingCurrentMonthInvoiceOnly,
            count: hasInvoiceFlagData ? missingInvoiceCount : null,
            onTap: widget.onToggleMissingCurrentMonthInvoiceOnly == null
                ? null
                : () => widget.onToggleMissingCurrentMonthInvoiceOnly!(
                      !widget.missingCurrentMonthInvoiceOnly,
                    ),
          ),
          extraActiveFilterCount:
              (widget.missingCurrentMonthInvoiceOnly ? 1 : 0) +
                  (_status == 'all' ? 0 : 1),
          moveSummaryIntoFilters: true,
          filtersInMenu: true,
          filterMenuWidth: 320,
          additionalFiltersInFilterBody: true,
          compactClassificationDropdowns: true,
          propertyLabel: 'Tipo de inmueble',
          propertyOptions: widget.propertyTypeOptions,
          propertyFilter: widget.propertyTypeFilter,
          onToggleProperty: widget.onPropertyTypeChanged == null
              ? null
              : (v) => widget.onPropertyTypeChanged!(v),
          onClearProperty: widget.onPropertyTypeChanged == null
              ? null
              : () => widget.onPropertyTypeChanged!(null),
          onClearFilters: () {
            setState(() {
              _status = 'all';
              _page = 0;
            });
            if (widget.onPropertyTypeChanged != null) {
              widget.onPropertyTypeChanged!(null);
            }
            if (widget.onCustomerTypeChanged != null) {
              widget.onCustomerTypeChanged!(null);
            }
            if (widget.onToggleInactive != null && widget.showInactive) {
              widget.onToggleInactive!(false);
            }
            if (widget.onToggleMissingCurrentMonthInvoiceOnly != null &&
                widget.missingCurrentMonthInvoiceOnly) {
              widget.onToggleMissingCurrentMonthInvoiceOnly!(false);
            }
          },
          entityLabel: 'Tipo de cliente',
          entityOptions: widget.customerTypeOptions,
          entityFilter: widget.customerTypeFilter,
          onToggleEntity: widget.onCustomerTypeChanged,
          onClearEntity: widget.onCustomerTypeChanged == null
              ? null
              : () => widget.onCustomerTypeChanged!(null),
        ),
        Expanded(child: content),
        if (!widget.loading && widget.error == null && pages > 1)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Tooltip(
                    message: MaterialLocalizations.of(context).rowsPerPageTitle,
                    child: DropdownButton<int>(
                        value: pageSize,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: [10, 20, 25]
                            .map((size) => DropdownMenuItem(
                                value: size,
                                child: Text('$size', style: typo.bodySmall)))
                            .toList(),
                        onChanged: (value) => setState(() {
                              _pageSize = value;
                              _page = 0;
                            }),
                        hint: Text(MaterialLocalizations.of(context)
                            .rowsPerPageTitle))),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'Mostrando ${visible.isEmpty ? 0 : page * pageSize + 1}–${page * pageSize + pageItems.length} de ${visible.length} clientes',
                        style: typo.bodySmall)),
                IconButton(
                    tooltip: 'Página anterior',
                    onPressed: page > 0
                        ? () => setState(() => _page = page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 18)),
                Text('${page + 1} / ${pages == 0 ? 1 : pages}',
                    style: typo.bodySmall),
                IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: page + 1 < pages
                        ? () => setState(() => _page = page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 18)),
              ])),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.ascending, required this.onChanged});

  final bool ascending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      key: const ValueKey('client-sort-control'),
      tooltip: ascending ? 'Orden A–Z' : 'Orden Z–A',
      onSelected: onChanged,
      itemBuilder: (_) => const [
        NavigationPopupMenuItem(value: true, child: Text('Nombre (A–Z)')),
        NavigationPopupMenuItem(value: false, child: Text('Nombre (Z–A)')),
      ],
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        fixedSize: const Size(34, 34),
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      icon: Icon(
        ascending ? Icons.sort_by_alpha_rounded : Icons.sort_rounded,
        size: 18,
      ),
    );
  }
}

class _ClientStatusFilter extends StatelessWidget {
  const _ClientStatusFilter({
    required this.value,
    required this.active,
    required this.inactive,
    required this.onChanged,
  });

  final String value;
  final int active;
  final int inactive;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    Widget option(String optionValue, String label) {
      final selected = value == optionValue;
      return InkWell(
        key: ValueKey('client-status-filter-$optionValue'),
        onTap: () => onChanged(optionValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: .10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.localeName.toLowerCase().startsWith('es') ? 'Estado' : 'Status',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: .65),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 96,
                  child: option('all', '${l.all} ${active + inactive}'),
                ),
                SizedBox(
                  width: 96,
                  child: option('active', '${l.active} $active'),
                ),
                SizedBox(
                  width: 96,
                  child: option('inactive', '${l.inactive} $inactive'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingInvoiceToggle extends StatelessWidget {
  const _MissingInvoiceToggle({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = count == null
        ? l.clientMissingInvoiceThisMonth
        : l.clientMissingCountThisMonth(count!);

    return InkWell(
      key: const ValueKey('client-missing-month-invoice-filter'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: selected,
                onChanged: onTap == null ? null : (_) => onTap!(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
