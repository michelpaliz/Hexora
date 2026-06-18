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
                .where(
                  (c) =>
                      (c.propertyKind ?? '').trim() ==
                      widget.propertyKindFilter!.trim(),
                )
                .toList(growable: false);
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
    final visible = widget.showInactive
        ? [...activeItems, ...inactiveItems]
        : activeItems;
    final hasInvoiceFlagData =
        widget.items.any((c) => c.hasCurrentMonthInvoiceFlagData);
    final missingInvoiceCount = widget.items
        .where((c) => c.missingCurrentMonthInvoice == true)
        .length;
    final filterCountSource = widget.missingCurrentMonthInvoiceOnly
        ? widget.items
            .where((c) => c.missingCurrentMonthInvoice == true)
            .toList(growable: false)
        : widget.items;

    final query = _searchCtrl.text.trim();
    final hasSearch = query.isNotEmpty;
    final hasPropertyFilter =
        (widget.propertyKindFilter ?? '').trim().isNotEmpty;
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
      } else if (hasSourceData && (hasSearch || hasPropertyFilter)) {
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: visible.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final c = visible[i];
            return ClientListItem(
              client: c,
              onTap: widget.onEdit == null ? null : () => widget.onEdit!(c),
              onDelete:
                  widget.onDelete == null ? null : () => widget.onDelete!(c),
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
          clientsForCounts: filterCountSource,
          activeCountLabel: l.activeClientsSection,
          inactiveCountLabel: l.statusInactive,
          inactiveValue: widget.showInactive,
          onInactiveChanged: widget.onToggleInactive,
          inactiveLabelOn: l.hideInactiveClients,
          inactiveLabelOff: l.showInactiveClients,
          countInactiveAsFilter: true,
          clearInactiveOnClear: true,
          additionalFilters: _MissingInvoiceFilterRow(
            label: l.clientMissingInvoiceThisMonth,
            selected: widget.missingCurrentMonthInvoiceOnly,
            count: hasInvoiceFlagData ? missingInvoiceCount : null,
            onTap: widget.onToggleMissingCurrentMonthInvoiceOnly == null
                ? null
                : () => widget.onToggleMissingCurrentMonthInvoiceOnly!(
                      !widget.missingCurrentMonthInvoiceOnly,
                    ),
          ),
          extraActiveFilterCount:
              widget.missingCurrentMonthInvoiceOnly ? 1 : 0,
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
          entityLabel: null,
          entityOptions: const [],
          entityFilter: null,
        ),
        Expanded(child: content),
      ],
    );
  }
}

class _MissingInvoiceFilterRow extends StatelessWidget {
  const _MissingInvoiceFilterRow({
    required this.label,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    const activeColor = Color(0xFFD97706); // amber-600
    const activeBg = Color(0xFFFEF3C7);   // amber-100

    final chipColor = selected ? activeColor : cs.onSurfaceVariant;
    final chipBg = selected
        ? activeBg.withValues(alpha: 0.35)
        : cs.surfaceContainerHighest.withValues(alpha: 0.4);
    final chipBorder = selected
        ? activeColor.withValues(alpha: 0.45)
        : cs.outlineVariant.withValues(alpha: 0.35);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: chipBorder, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: chipColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: typo.bodySmall.copyWith(
                    color: chipColor,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: activeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${count!}',
              style: typo.caption.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
