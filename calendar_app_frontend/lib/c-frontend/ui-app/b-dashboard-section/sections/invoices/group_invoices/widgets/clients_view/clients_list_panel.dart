import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/chip_rows.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/clients_view/client_classification_box.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class ClientsListPanel extends StatelessWidget {
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

  final List<String> savedEntityTypes;
  final List<String> savedPropertyKinds;

  final VoidCallback onClearFilters;
  final ValueChanged<String> onToggleEntityFilter;
  final ValueChanged<String> onTogglePropertyFilter;
  final VoidCallback onClearEntityFilter;
  final VoidCallback onClearPropertyFilter;

  final VoidCallback onManageClassificationOptions;
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
    required this.savedEntityTypes,
    required this.savedPropertyKinds,
    required this.onClearFilters,
    required this.onToggleEntityFilter,
    required this.onTogglePropertyFilter,
    required this.onClearEntityFilter,
    required this.onClearPropertyFilter,
    required this.onManageClassificationOptions,
    required this.onSelectClient,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.clientsTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                FilterChip(
                  label: Text(
                    hideInactive
                        ? l.clientInactiveHiddenChip
                        : l.clientHideInactiveChip,
                  ),
                  selected: hideInactive,
                  onSelected: (_) => onToggleHideInactive(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                if (entityFilter != null || propertyFilter != null)
                  TextButton(
                    onPressed: onClearFilters,
                    child: Text(l.clientFiltersClear),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: searchController,
              onChanged: (_) => onSearchChanged(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.clientSearchHint,
                suffixIcon: searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              style: t.bodyMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child:
                (savedEntityTypes.isNotEmpty || savedPropertyKinds.isNotEmpty)
                    ? ClientClassificationBox(
                        entityTypes: savedEntityTypes,
                        propertyKinds: savedPropertyKinds,
                        onManage: onManageClassificationOptions,
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.tune_outlined),
                        label: Text(l.clientClassificationManageCta),
                        onPressed: onManageClassificationOptions,
                      ),
          ),
          if (entityOptions.isNotEmpty || propertyOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.clientFiltersTitle,
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (entityOptions.isNotEmpty)
                    FilterChipRow(
                      label: l.clientEntityTypeLabel,
                      options: entityOptions,
                      selected: entityFilter,
                      onToggle: onToggleEntityFilter,
                      onClear: onClearEntityFilter,
                    ),
                  if (entityOptions.isNotEmpty && propertyOptions.isNotEmpty)
                    const SizedBox(height: 10),
                  if (propertyOptions.isNotEmpty)
                    FilterChipRow(
                      label: l.clientPropertyKindLabel,
                      options: propertyOptions,
                      selected: propertyFilter,
                      onToggle: onTogglePropertyFilter,
                      onClear: onClearPropertyFilter,
                    ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: allClients.isEmpty
                ? EmptyView(
                    icon: Icons.person_outline,
                    title: l.noClientsYet,
                    subtitle: l.noClientsYet,
                  )
                : Column(
                    children: [
                      if (selectedHiddenByFilters)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Material(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
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
                                    onPressed: onClearFilters,
                                    child: Text(l.clientFiltersClear),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filteredClients.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = filteredClients[i];
                            final selected = selectedClient?.id == c.id;

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
                              onTap: () => onSelectClient(c),
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
    final bg = selected ? cs.surfaceContainerHighest : Colors.transparent;
    final titleColor = selected
        ? ThemeColors.contrastOn(bg)
        : ThemeColors.textPrimary(context);
    final subtitleColor = selected
        ? ThemeColors.contrastOn(bg).withValues(alpha: 0.82)
        : ThemeColors.textSecondary(context);
    final borderColor = selected
        ? cs.outlineVariant.withValues(alpha: 0.35)
        : cs.outlineVariant.withValues(alpha: 0.18);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: cs.primary,
                  ),
                ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: selected
                              ? cs.primaryContainer
                              : cs.surfaceContainerHighest,
                          child: Text(
                            title.trim().isEmpty
                                ? '?'
                                : title.trim().substring(0, 1),
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: selected
                                  ? cs.onPrimaryContainer
                                  : ThemeColors.textSecondary(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HorizontalText(
                                title,
                                style: t.bodyMedium.copyWith(
                                  fontWeight:
                                      selected ? FontWeight.w900 : FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                _HorizontalText(
                                  subtitle!,
                                  style: t.bodySmall.copyWith(
                                    color: subtitleColor,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!client.isActive)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.pause_circle_outline,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
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
