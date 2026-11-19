import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/clients_search_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
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
  final ValueChanged<GroupClient>? onEditClient;
  final VoidCallback? onCollapse;

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
    this.onEditClient,
    this.onCollapse,
  });

  @override
  State<ClientsListPanel> createState() => _ClientsListPanelState();
}

class _ClientsListPanelState extends State<ClientsListPanel> {
  String _status = 'all';
  bool _sortByType = false;
  bool _ascending = true;

  static String _clientType(GroupClient client) {
    final value =
        (client.effectiveCustomerType ?? client.effectivePropertyType ?? '')
            .trim();
    return value.isEmpty ? '—' : clientClassificationLabel(value);
  }

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
        .toList();
    visibleClients.sort((a, b) {
      final left = _sortByType ? _clientType(a) : a.name;
      final right = _sortByType ? _clientType(b) : b.name;
      final cmp = left.toLowerCase().compareTo(right.toLowerCase());
      return _ascending ? cmp : -cmp;
    });
    final hasSearch = widget.searchController.text.trim().isNotEmpty;
    final hasStructuredFilters =
        (widget.entityFilter ?? '').trim().isNotEmpty ||
            (widget.propertyFilter ?? '').trim().isNotEmpty ||
            effectiveStatus != 'all';

    // Compact summary below the toolbar: a muted count plus, when filters are
    // applied, the most relevant filter as a subtle chip and a "+N" overflow.
    final noun = isEs ? 'clientes' : 'customers';
    final visibleCount = visibleClients.length;
    final totalCount = widget.allClients.length;
    final countLabel = visibleCount == totalCount
        ? '$visibleCount $noun'
        : '$visibleCount ${isEs ? 'de' : 'of'} $totalCount $noun';
    final summaryFilters = <({String label, bool active})>[];
    if (effectiveStatus == 'active') {
      summaryFilters.add((label: isEs ? 'Activos' : 'Active', active: true));
    } else if (effectiveStatus == 'inactive') {
      summaryFilters
          .add((label: isEs ? 'Inactivos' : 'Inactive', active: false));
    }
    final entityValue = (widget.entityFilter ?? '').trim();
    if (entityValue.isNotEmpty) {
      summaryFilters
          .add((label: clientClassificationLabel(entityValue), active: false));
    }
    final propertyValue = (widget.propertyFilter ?? '').trim();
    if (propertyValue.isNotEmpty) {
      summaryFilters.add(
          (label: clientClassificationLabel(propertyValue), active: false));
    }
    if (widget.missingCurrentMonthInvoiceOnly) {
      summaryFilters
          .add((label: isEs ? 'Sin factura' : 'No invoice', active: false));
    }

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
                  filterBeforeSearch: true,
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
                    if (widget.onAddClient != null)
                      IconButton(
                        tooltip: l.addClient,
                        onPressed: widget.onAddClient,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                      ),
                    if (widget.onCollapse != null)
                      IconButton(
                        tooltip: isEs ? 'Contraer panel' : 'Collapse panel',
                        onPressed: widget.onCollapse,
                        icon: const Icon(
                            Icons.keyboard_double_arrow_left_rounded),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                      ),
                    _CompactListInfo(
                      key: const ValueKey('client-sidebar-list-summary'),
                      visibleCount: visibleCount,
                      totalCount: totalCount,
                      countLabel: countLabel,
                      activeFilters: summaryFilters,
                    ),
                  ],
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
                    ? Column(children: [
                        if (widget.selectedClient != null &&
                            widget.allClients.any((client) =>
                                client.id == widget.selectedClient!.id))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                            child: Row(children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) => _ClientRow(
                                    client: widget.selectedClient!,
                                    selected: true,
                                    showType: constraints.maxWidth >= 390,
                                    onTap: () => widget
                                        .onSelectClient(widget.selectedClient!),
                                    onEdit: widget.onEditClient == null
                                        ? null
                                        : () => widget.onEditClient!(
                                              widget.selectedClient!,
                                            ),
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: widget.selectedHiddenByFilters
                                    ? (isEs
                                        ? 'Cliente seleccionado fuera de los filtros'
                                        : 'Selected client is outside the filters')
                                    : (isEs
                                        ? 'Cliente seleccionado'
                                        : 'Selected client'),
                                child: Icon(Icons.push_pin_outlined,
                                    size: 15, color: cs.primary),
                              ),
                            ]),
                          ),
                        Expanded(
                          child: EmptyView(
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
                          ),
                        ),
                      ])
                    : Column(
                        children: [
                          Container(
                            height: 30,
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                12, 0, 8, 0),
                            decoration: BoxDecoration(
                              color:
                                  cs.surfaceContainerLow.withValues(alpha: .7),
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      cs.outlineVariant.withValues(alpha: .25),
                                ),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final showType = constraints.maxWidth >= 390;
                                return Row(children: [
                                  const SizedBox(width: 36),
                                  Expanded(
                                    flex: showType ? 5 : 1,
                                    child: _SortHeader(
                                      label: isEs ? 'Cliente' : 'Client',
                                      active: !_sortByType,
                                      ascending: _ascending,
                                      onTap: () => setState(() {
                                        if (_sortByType) {
                                          _sortByType = false;
                                          _ascending = true;
                                        } else {
                                          _ascending = !_ascending;
                                        }
                                      }),
                                    ),
                                  ),
                                  if (showType)
                                    Expanded(
                                      flex: 3,
                                      child: _SortHeader(
                                        label: isEs ? 'Tipo' : 'Type',
                                        active: _sortByType,
                                        ascending: _ascending,
                                        onTap: () => setState(() {
                                          if (!_sortByType) {
                                            _sortByType = true;
                                            _ascending = true;
                                          } else {
                                            _ascending = !_ascending;
                                          }
                                        }),
                                      ),
                                    ),
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      isEs ? 'Acc.' : 'Actions',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                ]);
                              },
                            ),
                          ),
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
                                return LayoutBuilder(
                                  builder: (context, constraints) => _ClientRow(
                                    client: c,
                                    selected: widget.selectedClient?.id == c.id,
                                    showType: constraints.maxWidth >= 390,
                                    onTap: () => widget.onSelectClient(c),
                                    onEdit: widget.onEditClient == null
                                        ? null
                                        : () => widget.onEditClient!(c),
                                  ),
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

/// Result count kept inside the toolbar to avoid consuming a second row.
class _CompactListInfo extends StatelessWidget {
  const _CompactListInfo({
    super.key,
    required this.visibleCount,
    required this.totalCount,
    required this.countLabel,
    required this.activeFilters,
  });

  final int visibleCount;
  final int totalCount;
  final String countLabel;
  final List<({String label, bool active})> activeFilters;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filters = activeFilters.map((filter) => filter.label).join(', ');
    final tooltip = filters.isEmpty ? countLabel : '$countLabel · $filters';
    final shortCount = visibleCount == totalCount
        ? '$visibleCount'
        : '$visibleCount/$totalCount';

    return Tooltip(
      message: tooltip,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 15, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              shortCount,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
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
    final label = l.clientMissingInvoiceThisMonth;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      checked: selected,
      child: InkWell(
        key: const ValueKey('client-missing-month-invoice-filter'),
        borderRadius: BorderRadius.circular(7),
        onTap: () => onChanged(!selected),
        child: SizedBox(
          height: 28,
          child: Row(
            children: [
              SizedBox.square(
                dimension: 26,
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
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withValues(alpha: .12)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.client,
    required this.selected,
    required this.showType,
    required this.onTap,
    this.onEdit,
  });

  final GroupClient client;
  final bool selected;
  final bool showType;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = client.name.trim();
    final type = _ClientsListPanelState._clientType(client);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return HexoraListRow(
      key: ValueKey('client-sidebar-row-${client.id}'),
      selected: selected,
      onTap: onTap,
      minHeight: 42,
      verticalPadding: 2,
      separatorWidth: 0,
      child: Row(children: [
        CircleAvatar(
          radius: 14,
          backgroundColor:
              selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          child: Text(
            initial,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: showType ? 5 : 1,
          child: Tooltip(
            message: name,
            waitDuration: const Duration(milliseconds: 500),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
        if (showType)
          Expanded(
            flex: 3,
            child: Row(children: [
              Expanded(
                child: Tooltip(
                  message: type,
                  child: Text(
                    type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (client.missingCurrentMonthInvoice == true)
                Tooltip(
                  message: l.clientMissingInvoiceThisMonth,
                  child: Icon(Icons.receipt_long_outlined,
                      size: 14, color: cs.error),
                ),
              if (!client.isActive)
                Tooltip(
                  message: l.statusInactive,
                  child: Icon(Icons.pause_circle_outline,
                      size: 14, color: cs.onSurfaceVariant),
                ),
            ]),
          ),
        SizedBox(
          width: 36,
          child: PopupMenuButton<_ClientRowAction>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            position: PopupMenuPosition.under,
            icon: const Icon(Icons.more_horiz_rounded),
            iconSize: 18,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              minimumSize: const Size(30, 30),
              fixedSize: const Size(30, 30),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: cs.onSurfaceVariant,
            ),
            onSelected: (_) => onEdit?.call(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ClientRowAction.edit,
                enabled: onEdit != null,
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 17),
                  const SizedBox(width: 8),
                  Text(l.editClient),
                ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (active)
          Icon(
              ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 12,
              color: cs.primary),
      ]),
    );
  }
}

enum _ClientRowAction { edit }
