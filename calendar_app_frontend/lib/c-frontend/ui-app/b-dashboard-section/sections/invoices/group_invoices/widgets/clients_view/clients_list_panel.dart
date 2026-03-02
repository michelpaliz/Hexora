import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientsListPanel extends StatefulWidget {
  final List<GroupClient> allClients;
  final List<GroupClient> filteredClients;
  final GroupClient? selectedClient;
  final bool selectedHiddenByFilters;
  final bool hideInactive;
  final VoidCallback onToggleHideInactive;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;
  final String? entityFilter;
  final String? propertyFilter;
  final List<String> entityOptions;
  final List<String> propertyOptions;

  final VoidCallback onClearFilters;
  final ValueChanged<String> onToggleEntityFilter;
  final ValueChanged<String> onTogglePropertyFilter;
  final VoidCallback onClearEntityFilter;
  final VoidCallback onClearPropertyFilter;
  final ValueChanged<GroupClient> onSelectClient;

  const ClientsListPanel({
    super.key,
    required this.allClients,
    required this.filteredClients,
    required this.selectedClient,
    required this.selectedHiddenByFilters,
    required this.hideInactive,
    required this.onToggleHideInactive,
    required this.searchController,
    required this.onSearchChanged,
    required this.entityFilter,
    required this.propertyFilter,
    required this.entityOptions,
    required this.propertyOptions,
    required this.onClearFilters,
    required this.onToggleEntityFilter,
    required this.onTogglePropertyFilter,
    required this.onClearEntityFilter,
    required this.onClearPropertyFilter,
    required this.onSelectClient,
  });

  @override
  State<ClientsListPanel> createState() => _ClientsListPanelState();
}

class _ClientsListPanelState extends State<ClientsListPanel> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: ClientsSearchFilters(
              searchController: widget.searchController,
              onSearchChanged: widget.onSearchChanged,
              searchHint: l.clientSearchHint,
              padding: EdgeInsets.zero,
              clientsForCounts: widget.allClients,
              activeCountLabel: l.activeClientsSection,
              inactiveCountLabel: l.statusInactive,
              inactiveValue: widget.hideInactive,
              onInactiveChanged: (_) => widget.onToggleHideInactive(),
              inactiveLabelOn: l.clientInactiveHiddenChip,
              inactiveLabelOff: l.clientHideInactiveChip,
              countInactiveAsFilter: false,
              clearInactiveOnClear: false,
              onClearFilters: widget.onClearFilters,
              entityLabel: l.clientEntityTypeLabel,
              entityOptions: widget.entityOptions,
              entityFilter: widget.entityFilter,
              onToggleEntity: widget.onToggleEntityFilter,
              onClearEntity: widget.onClearEntityFilter,
              propertyLabel: l.clientPropertyKindLabel,
              propertyOptions: widget.propertyOptions,
              propertyFilter: widget.propertyFilter,
              onToggleProperty: widget.onTogglePropertyFilter,
              onClearProperty: widget.onClearPropertyFilter,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.allClients.isEmpty
                ? EmptyView(
                    icon: Icons.person_outline,
                    title: l.noClientsYet,
                    subtitle: l.noClientsYet,
                  )
                : Column(
                    children: [
                      if (widget.selectedHiddenByFilters)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    cs.outlineVariant.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_alt_outlined,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.clientSelectedHiddenByFilters,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: widget.onClearFilters,
                                  child: Text(l.clientFiltersClear),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: widget.filteredClients.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final c = widget.filteredClients[i];
                            final selected = widget.selectedClient?.id == c.id;

                            final subtitleParts = <String>[
                              c.billing?.legalName ?? (c.email ?? ''),
                              if ((c.entityType ?? '').trim().isNotEmpty)
                                c.entityType!.trim(),
                              if ((c.propertyKind ?? '').trim().isNotEmpty)
                                c.propertyKind!.trim(),
                            ].where((e) => e.trim().isNotEmpty).toList();

                            return _ClientRow(
                              client: c,
                              selected: selected,
                              title: c.name,
                              subtitle: subtitleParts.isEmpty
                                  ? null
                                  : subtitleParts.join(' • '),
                              onTap: () => widget.onSelectClient(c),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _HorizontalText(this.text, {this.style});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      primary: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: style,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final GroupClient client;
  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ClientRow({
    required this.client,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Use a stable, opaque selection background to avoid contrast issues with
    // custom palettes; derive text colors from the actual background.
    final titleColor = ThemeColors.textPrimary(context);
    final subtitleColor = ThemeColors.textSecondary(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListItemCard(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: selected
              ? cs.primaryContainer.withValues(alpha: 0.6)
              : Colors.transparent,
          child: Text(
            title.trim().isEmpty ? '?' : title.trim().substring(0, 1),
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: selected
                  ? cs.onPrimaryContainer
                  : ThemeColors.textSecondary(context),
            ),
          ),
        ),
        titleWidget: _HorizontalText(
          title,
          style: t.bodyMedium.copyWith(
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            color: titleColor,
          ),
        ),
        subtitleWidget: subtitle == null
            ? null
            : _HorizontalText(
                subtitle!,
                style: t.bodySmall.copyWith(
                  color: subtitleColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
        trailing: !client.isActive
            ? Icon(
                Icons.pause_circle_outline,
                size: 18,
                color: cs.onSurfaceVariant,
              )
            : null,
        selected: selected,
        showLeadingStripe: true,
        onTap: onTap,
      ),
    );
  }
}
