import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'client_list_item.dart';

class ClientsTab extends StatefulWidget {
  final List<GroupClient> items;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final bool showInlineCTA;
  final VoidCallback? onAddTap; // optional
  final void Function(GroupClient client)? onEdit; // tap-to-edit
  final bool showInactive;
  final ValueChanged<bool>? onToggleInactive;
  final String? propertyKindFilter;
  final List<String> propertyKindOptions;
  final ValueChanged<String?>? onPropertyKindChanged;
  final void Function(GroupClient client)? onDelete;

  const ClientsTab({
    super.key,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRefresh,
    this.showInlineCTA = false,
    this.onAddTap,
    this.onEdit,
    this.showInactive = false,
    this.onToggleInactive,
    this.propertyKindFilter,
    this.propertyKindOptions = const [],
    this.onPropertyKindChanged,
    this.onDelete,
  });

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
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
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final filtered =
        widget.propertyKindFilter == null || widget.propertyKindFilter!.isEmpty
            ? widget.items
            : widget.items
                .where((c) =>
                    (c.propertyKind ?? '').trim() ==
                    widget.propertyKindFilter!.trim())
                .toList(growable: false);
    final searched = filtered.where(_matchesSearch).toList(growable: false);
    final activeItems =
        searched.where((c) => c.isActive != false).toList(growable: false);
    final inactiveItems =
        searched.where((c) => c.isActive == false).toList(growable: false);
    final visible =
        widget.showInactive ? [...activeItems, ...inactiveItems] : activeItems;
    final activeCount = activeItems.length;
    final inactiveCount = inactiveItems.length;

    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null) {
      return ErrorView(message: widget.error!, onRetry: widget.onRefresh);
    }

    if (visible.isEmpty) {
      return EmptyView(
        icon: Icons.person_outline,
        title: l.noClientsYet,
        subtitle: widget.showInactive
            ? '${l.activeClientsSection} · 0 · ${l.statusInactive}: 0'
            : '${l.activeClientsSection} · 0',
        cta: widget.showInlineCTA ? l.addClient : null,
        onPressed: widget.showInlineCTA ? widget.onAddTap : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClientsSearchFilters(
          searchController: _searchCtrl,
          onSearchChanged: () => setState(() {}),
          searchHint: l.clientSearchHint,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          clientsForCounts: widget.items,
          activeCountLabel: l.activeClientsSection,
          inactiveCountLabel: l.statusInactive,
          inactiveValue: widget.showInactive,
          onInactiveChanged: widget.onToggleInactive,
          inactiveLabelOn: l.hideInactiveClients,
          inactiveLabelOff: l.showInactiveClients,
          countInactiveAsFilter: true,
          clearInactiveOnClear: true,
          propertyLabel: l.clientPropertyKindLabel,
          propertyOptions: widget.propertyKindOptions,
          propertyFilter: widget.propertyKindFilter,
          onToggleProperty: widget.onPropertyKindChanged == null
              ? null
              : (v) => widget.onPropertyKindChanged!(v),
          onClearProperty: widget.onPropertyKindChanged == null
              ? null
              : () => widget.onPropertyKindChanged!(null),
          entityLabel: null,
          entityOptions: const [],
          entityFilter: null,
        ),
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            backgroundColor: cs.surface,
            onRefresh: widget.onRefresh,
            child: ListView.separated(
              cacheExtent: 800,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = visible[i];
                return ClientListItem(
                  client: c,
                  onTap: widget.onEdit == null ? null : () => widget.onEdit!(c),
                  onDelete: widget.onDelete == null
                      ? null
                      : () => widget.onDelete!(c),
                  nameStyle: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
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
          ),
        ),
      ],
    );
  }
}
