import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/presentation/shared/widgets/buttons/buttons.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  final VoidCallback? onAddClient;
  final VoidCallback? onRefresh;
  final bool refreshing;

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
    this.onAddClient,
    this.onRefresh,
    this.refreshing = false,
  });

  @override
  State<ClientsListPanel> createState() => _ClientsListPanelState();
}

class _ClientsListPanelState extends State<ClientsListPanel> {
  String _status = 'all';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
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
    final effectiveStatus = widget.hideInactive ? 'active' : _status;
    final normalizedSearch = widget.searchController.text.trim().toLowerCase();
    final statusCountSource = countsSource.where((client) {
      if (normalizedSearch.isNotEmpty) {
        final haystack = <String>[
          client.name,
          client.email ?? '',
          client.phone ?? '',
          client.billing?.legalName ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(normalizedSearch)) return false;
      }
      if ((widget.entityFilter ?? '').trim().isNotEmpty &&
          (client.effectiveCustomerType ?? '').trim() !=
              widget.entityFilter!.trim()) {
        return false;
      }
      if ((widget.propertyFilter ?? '').trim().isNotEmpty &&
          (client.effectivePropertyType ?? '').trim() !=
              widget.propertyFilter!.trim()) {
        return false;
      }
      return true;
    }).toList(growable: false);
    final activeCount =
        statusCountSource.where((client) => client.isActive != false).length;
    final inactiveCount = statusCountSource.length - activeCount;
    final visibleClients = widget.filteredClients
        .where((client) =>
            effectiveStatus == 'all' ||
            (effectiveStatus == 'active'
                ? client.isActive != false
                : client.isActive == false))
        .toList(growable: false);
    final hasSearch = widget.searchController.text.trim().isNotEmpty;
    final hasStructuredFilters =
        (widget.entityFilter ?? '').trim().isNotEmpty ||
            (widget.propertyFilter ?? '').trim().isNotEmpty ||
            effectiveStatus != 'all';

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClientsSearchFilters(
                  searchController: widget.searchController,
                  onSearchChanged: widget.onSearchChanged,
                  searchHint: l.clientSearchHint,
                  clearFiltersLabel: isEs ? 'Restablecer' : 'Reset',
                  padding: EdgeInsets.zero,
                  activeCount: activeCount,
                  inactiveCount: inactiveCount,
                  activeCountLabel: l.activeClientsSection,
                  inactiveCountLabel: l.statusInactive,
                  countInactiveAsFilter: false,
                  clearInactiveOnClear: false,
                  moveSummaryIntoFilters: true,
                  filtersInMenu: true,
                  filterMenuWidth: 310,
                  compactClassificationDropdowns: true,
                  additionalFiltersInFilterBody: true,
                  searchDesktopHeight: 32,
                  compactDesktopControls: true,
                  searchMaxWidth: double.infinity,
                  topSpacing: 0,
                  statusContent: _SidebarStatusFilter(
                    value: effectiveStatus,
                    active: activeCount,
                    inactive: inactiveCount,
                    onChanged: (value) {
                      setState(() => _status = value);
                      if (value != 'active' && widget.hideInactive) {
                        widget.onToggleHideInactive();
                      }
                    },
                  ),
                  additionalFilters: _SidebarMissingInvoiceFilter(
                    count: hasInvoiceFlagData ? missingInvoiceCount : null,
                    selected: widget.missingCurrentMonthInvoiceOnly,
                    onChanged: (value) =>
                        widget.onToggleMissingCurrentMonthInvoiceOnly(value),
                  ),
                  extraActiveFilterCount:
                      (widget.missingCurrentMonthInvoiceOnly ? 1 : 0) +
                          (effectiveStatus != 'all' ? 1 : 0),
                  onClearFilters: () {
                    setState(() => _status = 'all');
                    if (widget.hideInactive) widget.onToggleHideInactive();
                    widget.onClearFilters();
                  },
                  entityLabel: isEs ? 'Tipo de cliente' : 'Client type',
                  entityOptions: widget.entityOptions,
                  entityFilter: widget.entityFilter,
                  onToggleEntity: widget.onToggleEntityFilter,
                  onClearEntity: widget.onClearEntityFilter,
                  propertyLabel: isEs ? 'Tipo de inmueble' : 'Property type',
                  propertyOptions: widget.propertyOptions,
                  propertyFilter: widget.propertyFilter,
                  onToggleProperty: widget.onTogglePropertyFilter,
                  onClearProperty: widget.onClearPropertyFilter,
                  trailingActions: [
                    if (widget.onRefresh != null)
                      HexoraButton.iconOnly(
                        key: const ValueKey('client-sidebar-refresh'),
                        onPressed: widget.refreshing ? null : widget.onRefresh,
                        tooltip: l.refreshAction,
                        icon: Icons.refresh_rounded,
                        loading: widget.refreshing,
                        variant: HexoraButtonVariant.ghost,
                        size: HexoraButtonSize.compact,
                      ),
                    if (widget.onAddClient != null)
                      HexoraButton.iconOnly(
                        key: const ValueKey('client-sidebar-add'),
                        onPressed: widget.onAddClient,
                        tooltip: l.addClient,
                        icon: Icons.person_add_outlined,
                        variant: HexoraButtonVariant.ghost,
                        size: HexoraButtonSize.compact,
                        accentColor: cs.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  visibleClients.length == widget.allClients.length
                      ? '${visibleClients.length} ${isEs ? 'clientes' : 'customers'}  ·  A–Z'
                      : '${visibleClients.length} ${isEs ? 'de' : 'of'} ${widget.allClients.length}  ·  A–Z',
                  key: const ValueKey('client-sidebar-list-summary'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: widget.allClients.isEmpty
                ? EmptyView(
                    icon: Icons.person_outline,
                    title: l.noClientsYet,
                    subtitle: l.noClientsYet,
                    cta: widget.onAddClient != null ? l.addClient : null,
                    onPressed: widget.onAddClient,
                  )
                : visibleClients.isEmpty
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
                          if (widget.selectedHiddenByFilters ||
                              (widget.selectedClient != null &&
                                  !visibleClients.any((client) =>
                                      client.id == widget.selectedClient!.id)))
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
                            child: ListView.builder(
                              itemCount: visibleClients.length,
                              itemBuilder: (_, i) {
                                final c = visibleClients[i];
                                return _ClientRow(
                                  client: c,
                                  selected: widget.selectedClient?.id == c.id,
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

class _SidebarStatusFilter extends StatelessWidget {
  const _SidebarStatusFilter({
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
    final textTheme = Theme.of(context).textTheme;
    final options = <(String, String)>[
      ('all', '${l.all} ${active + inactive}'),
      ('active', '${l.active} $active'),
      ('inactive', '${l.inactive} $inactive'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSpanish(context) ? 'Estado' : 'Status',
          style: textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        RadioGroup<String>(
          groupValue: value,
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                for (final option in options)
                  SizedBox(
                    width: 92,
                    height: 30,
                    child: InkWell(
                      key: ValueKey('client-sidebar-status-${option.$1}'),
                      borderRadius: BorderRadius.circular(7),
                      onTap: () => onChanged(option.$1),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 28,
                            child: Radio<String>(
                              value: option.$1,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              option.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: value == option.$1
                                    ? cs.primary
                                    : cs.onSurface,
                                fontWeight: value == option.$1
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'es';
}

class _SidebarMissingInvoiceFilter extends StatelessWidget {
  const _SidebarMissingInvoiceFilter({
    required this.count,
    required this.selected,
    required this.onChanged,
  });

  final int? count;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = count == null
        ? l.clientMissingInvoiceThisMonth
        : l.clientMissingCountThisMonth(count!);
    return Semantics(
      checked: selected,
      child: InkWell(
        key: const ValueKey('client-missing-month-invoice-filter'),
        borderRadius: BorderRadius.circular(7),
        onTap: () => onChanged(!selected),
        child: SizedBox(
          height: 32,
          child: Row(
            children: [
              SizedBox.square(
                dimension: 30,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => onChanged(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 2),
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
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final GroupClient client;
  final bool selected;
  final VoidCallback onTap;

  const _ClientRow({
    required this.client,
    required this.selected,
    required this.onTap,
  });

  static String _clean(String? v) => (v ?? '').trim();

  /// One concise secondary line: the client's category, falling back to the
  /// legal name only when it adds information, then the email.
  String? _secondary() {
    final property = _clean(client.effectivePropertyType);
    if (property.isNotEmpty) return clientClassificationLabel(property);
    final entity = _clean(client.effectiveCustomerType);
    if (entity.isNotEmpty) return clientClassificationLabel(entity);
    final legal = _clean(client.billing?.legalName);
    final name = client.name.trim().toLowerCase();
    if (legal.isNotEmpty && !legal.toLowerCase().contains(name)) return legal;
    final email = _clean(client.email);
    return email.isEmpty ? null : email;
  }

  /// Full metadata, still available on hover.
  String _details() {
    final seen = <String>{};
    return [
      _clean(client.billing?.legalName),
      clientClassificationLabel(_clean(client.effectiveCustomerType)),
      clientClassificationLabel(_clean(client.effectivePropertyType)),
      _clean(client.email),
    ].where((v) => v.isNotEmpty && seen.add(v.toLowerCase())).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final title = client.name.trim();
    final secondary = _secondary();
    final details = _details();
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();

    Widget summary = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.bodyMedium.copyWith(
            fontSize: HexoraTypography.body,
            fontWeight: FontWeight.w600,
            color: ThemeColors.textPrimary(context),
          ),
        ),
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.bodySmall.copyWith(
              fontSize: HexoraTypography.caption,
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    if (details.isNotEmpty && details != secondary) {
      summary = Tooltip(
        message: details,
        waitDuration: const Duration(milliseconds: 600),
        child: summary,
      );
    }

    return HexoraListRow(
      key: ValueKey('client-sidebar-row-${client.id}'),
      selected: selected,
      onTap: onTap,
      minHeight: 48,
      verticalPadding: 4,
      child: Row(children: [
        // Neutral avatars: identity comes from the name, not a loud color.
        CircleAvatar(
          radius: 16,
          backgroundColor:
              selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          child: Text(
            initial,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: summary),
        if (_buildTrailing(l, cs) case final trailing?) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ]),
    );
  }

  Widget? _buildTrailing(AppLocalizations l, ColorScheme cs) {
    final parts = <Widget>[];

    if (client.missingCurrentMonthInvoice == true) {
      parts.add(
        Tooltip(
          message: l.clientMissingInvoiceThisMonth,
          child: Icon(Icons.receipt_long_outlined, size: 16, color: cs.error),
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
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    if (parts.isEmpty) return null;
    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }
}
