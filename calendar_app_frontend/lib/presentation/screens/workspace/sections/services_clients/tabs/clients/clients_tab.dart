import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/client_filter_controls.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
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
  final String? propertyKindFilter;
  final List<String> propertyKindOptions;
  final ValueChanged<String?>? onPropertyKindChanged;
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
    this.propertyKindFilter,
    this.propertyKindOptions = const [],
    this.onPropertyKindChanged,
    this.onDelete,
  });

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  String _status = 'all';
  String? _entityTypeFilter;
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

    final entityTypeOptions = widget.items
        .map((c) => (c.entityType ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filtered = widget.items.where((client) {
      final matchesEntity = _entityTypeFilter == null ||
          _entityTypeFilter!.isEmpty ||
          (client.entityType ?? '').trim() == _entityTypeFilter;
      final matchesProperty = widget.propertyKindFilter == null ||
          widget.propertyKindFilter!.isEmpty ||
          (client.propertyKind ?? '').trim() ==
              widget.propertyKindFilter!.trim();
      return matchesEntity && matchesProperty;
    }).toList(growable: false);
    final searched = filtered.where(_matchesSearch).toList(growable: false);
    final flagged = widget.missingCurrentMonthInvoiceOnly
        ? searched
            .where((c) => c.missingCurrentMonthInvoice == true)
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
    final missingInvoiceCount =
        widget.items.where((c) => c.missingCurrentMonthInvoice == true).length;
    final filterCountSource = widget.missingCurrentMonthInvoiceOnly
        ? widget.items
            .where((c) => c.missingCurrentMonthInvoice == true)
            .toList(growable: false)
        : widget.items;

    final query = _searchCtrl.text.trim();
    final hasSearch = query.isNotEmpty;
    final hasPropertyFilter =
        (widget.propertyKindFilter ?? '').trim().isNotEmpty;
    final hasEntityFilter = (_entityTypeFilter ?? '').trim().isNotEmpty;
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
          (hasSearch || hasEntityFilter || hasPropertyFilter)) {
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          clientsForCounts: filterCountSource,
          statusContent: ClientStatusSegments(
              value: _status,
              active: activeItems.length,
              inactive: inactiveItems.length,
              onChanged: (value) => setState(() {
                    _status = value;
                    _page = 0;
                  })),
          activeCountLabel: l.activeClientsSection,
          inactiveCountLabel: l.statusInactive,
          additionalFilters: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SortChip(
                ascending: _ascending,
                onChanged: (v) => setState(() {
                  _ascending = v;
                  _page = 0;
                }),
              ),
              ClientMissingInvoiceFilter(
                selected: widget.missingCurrentMonthInvoiceOnly,
                count: hasInvoiceFlagData ? missingInvoiceCount : null,
                onTap: widget.onToggleMissingCurrentMonthInvoiceOnly == null
                    ? null
                    : () => widget.onToggleMissingCurrentMonthInvoiceOnly!(
                          !widget.missingCurrentMonthInvoiceOnly,
                        ),
              ),
            ],
          ),
          extraActiveFilterCount:
              (widget.missingCurrentMonthInvoiceOnly ? 1 : 0) +
                  (_status != 'all' ? 1 : 0),
          propertyLabel: l.clientPropertyKindLabel,
          propertyOptions: widget.propertyKindOptions,
          propertyFilter: widget.propertyKindFilter,
          onToggleProperty: widget.onPropertyKindChanged == null
              ? null
              : (v) => widget.onPropertyKindChanged!(v),
          onClearProperty: widget.onPropertyKindChanged == null
              ? null
              : () => widget.onPropertyKindChanged!(null),
          onClearFilters: () {
            setState(() {
              _status = 'all';
              _entityTypeFilter = null;
              _page = 0;
            });
            if (widget.onPropertyKindChanged != null) {
              widget.onPropertyKindChanged!(null);
            }
            if (widget.onToggleInactive != null && widget.showInactive) {
              widget.onToggleInactive!(false);
            }
            if (widget.onToggleMissingCurrentMonthInvoiceOnly != null &&
                widget.missingCurrentMonthInvoiceOnly) {
              widget.onToggleMissingCurrentMonthInvoiceOnly!(false);
            }
          },
          entityLabel: l.clientEntityTypeLabel,
          entityOptions: entityTypeOptions,
          entityFilter: _entityTypeFilter,
          onToggleEntity: (value) => setState(() {
            _entityTypeFilter = value;
            _page = 0;
          }),
          onClearEntity: () => setState(() {
            _entityTypeFilter = null;
            _page = 0;
          }),
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

class _SortChip extends StatelessWidget {
  const _SortChip({required this.ascending, required this.onChanged});

  final bool ascending;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return PopupMenuButton<bool>(
      tooltip: 'Ordenar por nombre',
      onSelected: onChanged,
      itemBuilder: (_) => const [
        NavigationPopupMenuItem(value: true, child: Text('Nombre (A–Z)')),
        NavigationPopupMenuItem(value: false, child: Text('Nombre (Z–A)')),
      ],
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.sizeOf(context).width >= 760 ? 32.0 : 48.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.swap_vert_rounded, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            ascending ? 'Nombre (A–Z)' : 'Nombre (Z–A)',
            style: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}
