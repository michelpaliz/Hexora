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
  final bool missingCurrentMonthInvoiceOnly;
  final ValueChanged<bool> onToggleMissingCurrentMonthInvoiceOnly;
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
    required this.missingCurrentMonthInvoiceOnly,
    required this.onToggleMissingCurrentMonthInvoiceOnly,
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
    final hasInvoiceFlagData =
        widget.allClients.any((c) => c.hasCurrentMonthInvoiceFlagData);
    final missingInvoiceCount = widget.allClients
        .where((c) => c.missingCurrentMonthInvoice == true)
        .length;
    final countsSource = widget.missingCurrentMonthInvoiceOnly
        ? widget.allClients
            .where((c) => c.missingCurrentMonthInvoice == true)
            .toList(growable: false)
        : widget.allClients;
    final hasSearch = widget.searchController.text.trim().isNotEmpty;
    final hasStructuredFilters =
        (widget.entityFilter ?? '').trim().isNotEmpty ||
            (widget.propertyFilter ?? '').trim().isNotEmpty;

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
              clientsForCounts: countsSource,
              activeCountLabel: l.activeClientsSection,
              inactiveCountLabel: l.statusInactive,
              inactiveValue: widget.hideInactive,
              onInactiveChanged: (_) => widget.onToggleHideInactive(),
              inactiveLabelOn: l.clientInactiveHiddenChip,
              inactiveLabelOff: l.clientHideInactiveChip,
              countInactiveAsFilter: false,
              clearInactiveOnClear: false,
              additionalFilters: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MissingInvoiceFilterChip(
                    label: l.clientMissingInvoiceThisMonth,
                    selected: widget.missingCurrentMonthInvoiceOnly,
                    onSelected: widget.onToggleMissingCurrentMonthInvoiceOnly,
                  ),
                  if (hasInvoiceFlagData)
                    _MissingInvoiceCountChip(count: missingInvoiceCount),
                ],
              ),
              extraActiveFilterCount:
                  widget.missingCurrentMonthInvoiceOnly ? 1 : 0,
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
                : widget.filteredClients.isEmpty
                    ? EmptyView(
                        icon: widget.missingCurrentMonthInvoiceOnly &&
                                !hasSearch &&
                                !hasStructuredFilters
                            ? (hasInvoiceFlagData
                                ? Icons.verified_outlined
                                : Icons.hourglass_empty_rounded)
                            : Icons.search_off_rounded,
                        title: widget.missingCurrentMonthInvoiceOnly &&
                                !hasSearch &&
                                !hasStructuredFilters
                            ? (hasInvoiceFlagData
                                ? l.clientAllHaveInvoiceTitle
                                : l.clientInvoiceStatusUnavailableTitle)
                            : l.clientNoMatchFiltersTitle,
                        subtitle: widget.missingCurrentMonthInvoiceOnly &&
                                !hasSearch &&
                                !hasStructuredFilters
                            ? (hasInvoiceFlagData
                                ? l.clientAllHaveInvoiceDesc
                                : l.clientInvoiceStatusUnavailableDesc)
                            : l.clientNoMatchFiltersDesc,
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
                                    color: cs.outlineVariant.withValues(
                                      alpha: 0.35,
                                    ),
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
                                final selected =
                                    widget.selectedClient?.id == c.id;

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
                                      : subtitleParts.join(' | '),
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

  static const List<Color> _avatarPalette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFF8D6E63),
  ];

  Color _avatarColor() {
    if (title.trim().isEmpty) return _avatarPalette[0];
    return _avatarPalette[title.codeUnitAt(0) % _avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final titleColor = ThemeColors.textPrimary(context);
    final subtitleColor = ThemeColors.textSecondary(context);
    final avatarBg = selected ? cs.primaryContainer : _avatarColor();
    final avatarFg = selected ? cs.onPrimaryContainer : Colors.white;
    final initial = title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListItemCard(
        leading: CircleAvatar(
          radius: 17,
          backgroundColor: avatarBg,
          child: Text(
            initial,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: avatarFg,
              fontSize: 13,
            ),
          ),
        ),
        titleWidget: _HorizontalText(
          title,
          style: t.bodyMedium.copyWith(
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            color: titleColor,
          ),
        ),
        subtitleWidget: subtitle != null
            ? _HorizontalText(
                subtitle!,
                style: t.bodySmall.copyWith(
                  color: subtitleColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              )
            : null,
        trailing: _buildTrailing(context, l, cs),
        selected: selected,
        showLeadingStripe: true,
        onTap: onTap,
      ),
    );
  }

  Widget? _buildTrailing(
    BuildContext context,
    AppLocalizations l,
    ColorScheme cs,
  ) {
    final parts = <Widget>[];

    if (client.hasCurrentMonthInvoiceFlagData) {
      final isMissing = client.missingCurrentMonthInvoice == true;
      final icon = isMissing
          ? Icons.warning_amber_rounded
          : Icons.check_circle_outline_rounded;
      final color = isMissing ? cs.error : cs.secondary;
      final count = client.currentMonthInvoiceCount;
      final tooltip = count != null
          ? l.clientInvoiceCountThisMonth(count)
          : (isMissing
              ? l.clientMissingInvoiceThisMonth
              : l.clientInvoiceAllGood);

      parts.add(
        Tooltip(
          message: tooltip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              if (count != null) ...[
                const SizedBox(width: 3),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!client.isActive) {
      if (parts.isNotEmpty) parts.add(const SizedBox(width: 6));
      parts.add(
        Tooltip(
          message: l.statusInactive,
          child: Icon(
            Icons.pause_circle_outline,
            size: 15,
            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (parts.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }
}

class _MissingInvoiceCountChip extends StatelessWidget {
  const _MissingInvoiceCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        constraints: const BoxConstraints(minHeight: 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: cs.onErrorContainer,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l.clientMissingCountThisMonth(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingInvoiceFilterChip extends StatelessWidget {
  const _MissingInvoiceFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final color = selected ? cs.error : cs.onSurfaceVariant;
    final background = selected
        ? cs.errorContainer.withValues(alpha: 0.34)
        : cs.surfaceContainerHighest.withValues(alpha: 0.42);
    final border = selected
        ? cs.error.withValues(alpha: 0.32)
        : cs.outlineVariant.withValues(alpha: 0.36);

    return Semantics(
      button: true,
      toggled: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelected(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 34, maxWidth: 218),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
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
