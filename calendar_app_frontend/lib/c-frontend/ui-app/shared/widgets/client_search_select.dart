import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientSearchSelect extends StatefulWidget {
  final List<GroupClient> clients;
  final String? selectedClientId;
  final ValueChanged<String?> onClientChanged;
  final bool useDefaultPropertyKind;
  final String defaultPropertyKind;
  final double maxListHeight;

  const ClientSearchSelect({
    super.key,
    required this.clients,
    required this.selectedClientId,
    required this.onClientChanged,
    this.useDefaultPropertyKind = true,
    this.defaultPropertyKind = 'comunidad de propietarios',
    this.maxListHeight = 280,
  });

  @override
  State<ClientSearchSelect> createState() => _ClientSearchSelectState();
}

class _ClientSearchSelectState extends State<ClientSearchSelect> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showInactive = false;
  String? _entityFilter;
  String? _propertyFilter;

  @override
  void initState() {
    super.initState();
    _applyDefaultPropertyFilter();
  }

  @override
  void didUpdateWidget(covariant ClientSearchSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clients != oldWidget.clients) {
      _applyDefaultPropertyFilter(useSetState: true);
    }
  }

  String? _resolveDefaultPropertyKind() {
    if (!widget.useDefaultPropertyKind) return null;
    final match = widget.clients
        .map((c) => (c.propertyKind ?? '').trim())
        .firstWhere(
          (v) => v.toLowerCase() == widget.defaultPropertyKind,
          orElse: () => '',
        );
    return match.isEmpty ? null : match;
  }

  void _applyDefaultPropertyFilter({bool useSetState = false}) {
    if ((_propertyFilter ?? '').trim().isNotEmpty) return;
    final match = _resolveDefaultPropertyKind();
    if (match == null || match.isEmpty) return;
    if (useSetState) {
      setState(() => _propertyFilter = match);
    } else {
      _propertyFilter = match;
    }
  }

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
      c.entityType ?? '',
      c.propertyKind ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final entityOptions = widget.clients
        .map((c) => (c.entityType ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final propertyOptions = widget.clients
        .map((c) => (c.propertyKind ?? '').trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filtered = widget.clients.where((c) {
      if (!_showInactive && c.isActive == false) return false;
      if ((_entityFilter ?? '').trim().isNotEmpty &&
          (c.entityType ?? '').trim() != (_entityFilter ?? '').trim()) {
        return false;
      }
      if ((_propertyFilter ?? '').trim().isNotEmpty &&
          (c.propertyKind ?? '').trim() != (_propertyFilter ?? '').trim()) {
        return false;
      }
      return _matchesSearch(c);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            chipTheme: ChipTheme.of(context).copyWith(
              selectedColor: cs.primaryContainer.withValues(alpha: 0.45),
              checkmarkColor: cs.primary,
              labelStyle: t.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              secondaryLabelStyle: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child: ClientsSearchFilters(
            searchController: _searchCtrl,
            onSearchChanged: () => setState(() {}),
            searchHint: l.clientSearchHint,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            clientsForCounts: widget.clients,
            activeCountLabel: l.activeClientsSection,
            inactiveCountLabel: l.statusInactive,
            inactiveValue: _showInactive,
            onInactiveChanged: (v) => setState(() => _showInactive = v),
            inactiveLabelOn: l.hideInactiveClients,
            inactiveLabelOff: l.showInactiveClients,
            entityLabel: l.clientEntityTypeLabel,
            entityOptions: entityOptions,
            entityFilter: _entityFilter,
            onToggleEntity: (v) => setState(() => _entityFilter = v),
            onClearEntity: () => setState(() => _entityFilter = null),
            propertyLabel: l.clientPropertyKindLabel,
            propertyOptions: propertyOptions,
            propertyFilter: _propertyFilter,
            onToggleProperty: (v) => setState(() => _propertyFilter = v),
            onClearProperty: () => setState(() => _propertyFilter = null),
            onClearFilters: () {
              final defaultKind = _resolveDefaultPropertyKind();
              setState(() {
                _showInactive = false;
                _entityFilter = null;
                _propertyFilter = defaultKind;
              });
            },
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxListHeight),
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l.noClientsYet,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final client = filtered[i];
                    final selected = client.id == widget.selectedClientId;
                    final meta = <String>[
                      if ((client.email ?? '').isNotEmpty) client.email!,
                      if ((client.phone ?? '').isNotEmpty) client.phone!,
                      if ((client.propertyKind ?? '').isNotEmpty)
                        client.propertyKind!,
                    ].join(' · ');
                    return ListItemCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: cs.primary.withValues(alpha: 0.1),
                        child: Text(
                          client.name.trim().isEmpty
                              ? '?'
                              : client.name.trim()[0].toUpperCase(),
                          style: t.bodySmall.copyWith(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: client.name,
                      titleStyle: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: cs.onSurface,
                      ),
                      subtitle: meta.isEmpty ? null : meta,
                      subtitleStyle: t.bodySmall.copyWith(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      selected: selected,
                      showLeadingStripe: true,
                      borderRadius: BorderRadius.circular(8),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: cs.primary,
                              size: 18,
                            )
                          : null,
                      onTap: () => widget.onClientChanged(client.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
