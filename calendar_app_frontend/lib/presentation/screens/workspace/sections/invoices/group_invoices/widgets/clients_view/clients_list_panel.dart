import 'dart:math' as math;
import 'package:hexora/presentation/shared/widgets/hexora_list_row.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  final GlobalKey _selectedRowKey = GlobalKey();
  final ScrollController _clientsScrollController = ScrollController();
  double? _connectionTop;
  double? _connectionHeight;

  @override
  void initState() {
    super.initState();
    _clientsScrollController.addListener(_scheduleConnectionMeasure);
  }

  @override
  void dispose() {
    _clientsScrollController
      ..removeListener(_scheduleConnectionMeasure)
      ..dispose();
    super.dispose();
  }

  void _scheduleConnectionMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measureSelectedConnection();
    });
  }

  void _measureSelectedConnection() {
    final rowContext = _selectedRowKey.currentContext;
    final stackContext = context;
    final rowObject = rowContext?.findRenderObject();
    final stackObject = stackContext.findRenderObject();
    if (rowObject is! RenderBox ||
        stackObject is! RenderBox ||
        !rowObject.attached ||
        !stackObject.attached ||
        !rowObject.hasSize ||
        !stackObject.hasSize) {
      _clearSelectedConnection();
      return;
    }

    final topLeft =
        stackObject.globalToLocal(rowObject.localToGlobal(Offset.zero));
    final rowRect = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      rowObject.size.width,
      rowObject.size.height,
    );
    final viewportHeight = stackObject.size.height;
    final visibleTop = math.max(0, rowRect.top).toDouble();
    final visibleBottom = math.min(viewportHeight, rowRect.bottom).toDouble();
    if (visibleBottom <= visibleTop ||
        rowRect.bottom < 0 ||
        rowRect.top > viewportHeight) {
      _clearSelectedConnection();
      return;
    }

    if (_connectionTop != visibleTop || _connectionHeight != rowRect.height) {
      setState(() {
        _connectionTop = visibleTop;
        _connectionHeight = rowRect.height;
      });
    }
  }

  void _clearSelectedConnection() {
    if (_connectionTop == null && _connectionHeight == null) return;
    setState(() {
      _connectionTop = null;
      _connectionHeight = null;
    });
  }

  static String _clientType(GroupClient client) {
    final value =
        (client.effectiveCustomerType ?? client.effectivePropertyType ?? '')
            .trim();
    return value.isEmpty ? '—' : clientClassificationLabel(value);
  }

  Future<void> _openClientSearch(BuildContext context) async {
    final controller =
        TextEditingController(text: widget.searchController.text);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(Localizations.localeOf(context).languageCode == 'es'
            ? 'Buscar clientes'
            : 'Search clients'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onChanged: (value) {
            widget.searchController.text = value;
            widget.onSearchChanged();
          },
          decoration: InputDecoration(
            hintText: Localizations.localeOf(context).languageCode == 'es'
                ? 'Nombre, tipo o inmueble'
                : 'Name, type or property',
            prefixIcon: const Icon(LucideIcons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      widget.searchController.clear();
                      widget.onSearchChanged();
                    },
                    icon: const Icon(LucideIcons.x),
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final hasInvoiceFlagData =
        widget.allClients.any((c) => c.hasCurrentMonthInvoiceFlagData);
    final effectiveStatus = widget.hideInactive ? 'active' : _status;
    _scheduleConnectionMeasure();
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
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                widget.allClients.isEmpty
                    ? EmptyView(
                        icon: LucideIcons.user,
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
                                      builder: (context, constraints) =>
                                          _ClientRow(
                                        key: _selectedRowKey,
                                        client: widget.selectedClient!,
                                        selected: true,
                                        showType: constraints.maxWidth >= 390,
                                        showProperty:
                                            constraints.maxWidth >= 560,
                                        showStatus:
                                            constraints.maxWidth >= 680 &&
                                                effectiveStatus != 'active',
                                        onTap: () => widget.onSelectClient(
                                            widget.selectedClient!),
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
                                    child: Icon(LucideIcons.pin,
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
                                        ? LucideIcons.badgeCheck
                                        : LucideIcons.hourglass)
                                    : LucideIcons.searchX,
                                title: widget.missingCurrentMonthInvoiceOnly &&
                                        !hasSearch &&
                                        !hasStructuredFilters
                                    ? (hasInvoiceFlagData
                                        ? l.clientAllHaveInvoiceTitle
                                        : l.clientInvoiceStatusUnavailableTitle)
                                    : l.clientNoMatchFiltersTitle,
                                subtitle: widget
                                            .missingCurrentMonthInvoiceOnly &&
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
                                  color: cs.surfaceContainerLow
                                      .withValues(alpha: .7),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: .25),
                                    ),
                                  ),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final showType =
                                        constraints.maxWidth >= 390;
                                    final showProperty =
                                        constraints.maxWidth >= 560;
                                    final showStatus =
                                        constraints.maxWidth >= 680 &&
                                            effectiveStatus != 'active';
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
                                          trailing: IconButton(
                                            tooltip: isEs
                                                ? 'Buscar clientes'
                                                : 'Search clients',
                                            onPressed: () =>
                                                _openClientSearch(context),
                                            icon: Icon(
                                              LucideIcons.search,
                                              size: 15,
                                              color: widget
                                                      .searchController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? cs.onSurfaceVariant
                                                  : cs.primary,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                              width: 24,
                                              height: 26,
                                            ),
                                          ),
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
                                            trailing: PopupMenuButton<String>(
                                              tooltip: isEs
                                                  ? 'Filtrar por tipo'
                                                  : 'Filter by type',
                                              icon: Icon(
                                                LucideIcons.funnel,
                                                size: 14,
                                                color:
                                                    (widget.entityFilter ?? '')
                                                            .trim()
                                                            .isEmpty
                                                        ? cs.onSurfaceVariant
                                                        : cs.primary,
                                              ),
                                              padding: EdgeInsets.zero,
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(24, 26),
                                                fixedSize: const Size(24, 26),
                                                padding: EdgeInsets.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              itemBuilder: (_) => [
                                                PopupMenuItem<String>(
                                                  value: '__clear__',
                                                  enabled:
                                                      widget.entityFilter !=
                                                          null,
                                                  child: Text(
                                                      isEs ? 'Todos' : 'All'),
                                                ),
                                                ...widget.entityOptions.map(
                                                  (value) =>
                                                      PopupMenuItem<String>(
                                                    value: value,
                                                    child: Row(children: [
                                                      if (widget.entityFilter ==
                                                          value)
                                                        const Icon(
                                                            LucideIcons.check,
                                                            size: 16)
                                                      else
                                                        const SizedBox(
                                                            width: 16),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          clientClassificationLabel(
                                                              value),
                                                        ),
                                                      ),
                                                    ]),
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == '__clear__') {
                                                  widget.onClearEntityFilter();
                                                } else {
                                                  widget.onToggleEntityFilter(
                                                      value);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      if (showProperty)
                                        Expanded(
                                          flex: 3,
                                          child: _SortHeader(
                                            label:
                                                isEs ? 'Inmueble' : 'Property',
                                            active: false,
                                            ascending: true,
                                            onTap: () {},
                                            trailing: PopupMenuButton<String>(
                                              tooltip: isEs
                                                  ? 'Filtrar inmueble'
                                                  : 'Filter property',
                                              icon: Icon(
                                                LucideIcons.funnel,
                                                size: 14,
                                                color: (widget.propertyFilter ??
                                                            '')
                                                        .trim()
                                                        .isEmpty
                                                    ? cs.onSurfaceVariant
                                                    : cs.primary,
                                              ),
                                              padding: EdgeInsets.zero,
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(24, 26),
                                                fixedSize: const Size(24, 26),
                                                padding: EdgeInsets.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              itemBuilder: (_) => [
                                                PopupMenuItem<String>(
                                                  value: '__clear__',
                                                  enabled:
                                                      widget.propertyFilter !=
                                                          null,
                                                  child: Text(
                                                      isEs ? 'Todos' : 'All'),
                                                ),
                                                ...widget.propertyOptions.map(
                                                  (value) =>
                                                      PopupMenuItem<String>(
                                                    value: value,
                                                    child: Row(children: [
                                                      if (widget
                                                              .propertyFilter ==
                                                          value)
                                                        const Icon(
                                                            LucideIcons.check,
                                                            size: 16)
                                                      else
                                                        const SizedBox(
                                                            width: 16),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          clientClassificationLabel(
                                                              value),
                                                        ),
                                                      ),
                                                    ]),
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == '__clear__') {
                                                  widget
                                                      .onClearPropertyFilter();
                                                } else {
                                                  widget.onTogglePropertyFilter(
                                                      value);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      if (showStatus)
                                        Expanded(
                                          flex: 2,
                                          child: _SortHeader(
                                            label: isEs ? 'Estado' : 'Status',
                                            active: effectiveStatus != 'all',
                                            ascending: true,
                                            onTap: () {},
                                            trailing: PopupMenuButton<String>(
                                              tooltip: isEs
                                                  ? 'Filtrar estado'
                                                  : 'Filter status',
                                              icon: Icon(
                                                LucideIcons.funnel,
                                                size: 14,
                                                color: effectiveStatus == 'all'
                                                    ? cs.onSurfaceVariant
                                                    : cs.primary,
                                              ),
                                              padding: EdgeInsets.zero,
                                              style: IconButton.styleFrom(
                                                minimumSize: const Size(24, 26),
                                                fixedSize: const Size(24, 26),
                                                padding: EdgeInsets.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              itemBuilder: (_) => [
                                                for (final option in [
                                                  (
                                                    'all',
                                                    isEs ? 'Todos' : 'All'
                                                  ),
                                                  (
                                                    'active',
                                                    isEs ? 'Activos' : 'Active'
                                                  ),
                                                  (
                                                    'inactive',
                                                    isEs
                                                        ? 'Inactivos'
                                                        : 'Inactive'
                                                  ),
                                                  (
                                                    'missing',
                                                    isEs
                                                        ? 'Sin factura este mes'
                                                        : 'No invoice this month'
                                                  ),
                                                ])
                                                  PopupMenuItem<String>(
                                                    value: option.$1,
                                                    child: Text(option.$2),
                                                  ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'missing') {
                                                  widget
                                                      .onToggleMissingCurrentMonthInvoiceOnly(
                                                    !widget
                                                        .missingCurrentMonthInvoiceOnly,
                                                  );
                                                  return;
                                                }
                                                setState(() => _status = value);
                                                if (value == 'active' &&
                                                    !widget.hideInactive) {
                                                  widget.onToggleHideInactive();
                                                } else if (value != 'active' &&
                                                    widget.hideInactive) {
                                                  widget.onToggleHideInactive();
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        width: widget.onAddClient != null
                                            ? 110
                                            : 84,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            if (widget.onAddClient != null)
                                              IconButton(
                                                tooltip: l.addClient,
                                                onPressed: widget.onAddClient,
                                                icon: const Icon(
                                                  LucideIcons.userPlus,
                                                  size: 16,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints
                                                        .tightFor(
                                                  width: 26,
                                                  height: 26,
                                                ),
                                              ),
                                            if (widget.onRefresh != null)
                                              IconButton(
                                                tooltip: l.refreshAction,
                                                onPressed: widget.refreshing
                                                    ? null
                                                    : widget.onRefresh,
                                                icon: widget.refreshing
                                                    ? const SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        LucideIcons.refreshCw,
                                                        size: 16,
                                                      ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints
                                                        .tightFor(
                                                  width: 26,
                                                  height: 26,
                                                ),
                                              ),
                                            if (!showStatus)
                                              _StatusFilterMenu(
                                                isEs: isEs,
                                                selected: effectiveStatus,
                                                missingSelected: widget
                                                    .missingCurrentMonthInvoiceOnly,
                                                onSelected: (value) {
                                                  if (value == 'missing') {
                                                    widget
                                                        .onToggleMissingCurrentMonthInvoiceOnly(
                                                      !widget
                                                          .missingCurrentMonthInvoiceOnly,
                                                    );
                                                    return;
                                                  }
                                                  setState(
                                                      () => _status = value);
                                                  if (value == 'active' &&
                                                      !widget.hideInactive) {
                                                    widget
                                                        .onToggleHideInactive();
                                                  } else if (value !=
                                                          'active' &&
                                                      widget.hideInactive) {
                                                    widget
                                                        .onToggleHideInactive();
                                                  }
                                                },
                                              ),
                                            if (widget.onCollapse != null)
                                              IconButton(
                                                tooltip: isEs
                                                    ? 'Contraer panel'
                                                    : 'Collapse panel',
                                                onPressed: widget.onCollapse,
                                                icon: const Icon(
                                                  LucideIcons.chevronsLeft,
                                                  size: 16,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints
                                                        .tightFor(
                                                  width: 26,
                                                  height: 26,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  },
                                ),
                              ),
                              if (widget.selectedHiddenByFilters ||
                                  (widget.selectedClient != null &&
                                      !visibleClients.any((client) =>
                                          client.id ==
                                          widget.selectedClient!.id)))
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 10, 12, 0),
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
                                          LucideIcons.funnel,
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
                                  controller: _clientsScrollController,
                                  itemCount: visibleClients.length,
                                  itemBuilder: (_, i) {
                                    final c = visibleClients[i];
                                    return LayoutBuilder(
                                      builder: (context, constraints) =>
                                          _ClientRow(
                                        key: widget.selectedClient?.id == c.id
                                            ? _selectedRowKey
                                            : ValueKey(
                                                'client-sidebar-row-${c.id}',
                                              ),
                                        client: c,
                                        selected:
                                            widget.selectedClient?.id == c.id,
                                        showType: constraints.maxWidth >= 390,
                                        showProperty:
                                            constraints.maxWidth >= 560,
                                        showStatus:
                                            constraints.maxWidth >= 680 &&
                                                effectiveStatus != 'active',
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
                if (_connectionTop != null &&
                    _connectionHeight != null &&
                    widget.selectedClient != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    top: _connectionTop,
                    right: -10,
                    width: 18,
                    height: _connectionHeight,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SelectedClientConnectorPainter(
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .07),
                        ),
                      ),
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

/*
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

*/
class _SelectedClientConnectorPainter extends CustomPainter {
  const _SelectedClientConnectorPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .45, 0)
      ..quadraticBezierTo(
        size.width * .62,
        size.height * .28,
        size.width,
        size.height * .5,
      )
      ..quadraticBezierTo(
        size.width * .62,
        size.height * .72,
        size.width * .45,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SelectedClientConnectorPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _StatusFilterMenu extends StatelessWidget {
  const _StatusFilterMenu({
    required this.isEs,
    required this.selected,
    required this.missingSelected,
    required this.onSelected,
  });

  final bool isEs;
  final String selected;
  final bool missingSelected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: isEs ? 'Filtrar estado' : 'Filter status',
      icon: Icon(LucideIcons.funnel,
          size: 16,
          color: selected == 'all' && !missingSelected
              ? cs.onSurfaceVariant
              : cs.primary),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        minimumSize: const Size(26, 26),
        fixedSize: const Size(26, 26),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'all', child: Text(isEs ? 'Todos' : 'All')),
        PopupMenuItem(
            value: 'active', child: Text(isEs ? 'Activos' : 'Active')),
        PopupMenuItem(
            value: 'inactive', child: Text(isEs ? 'Inactivos' : 'Inactive')),
        PopupMenuItem(
            value: 'missing',
            child:
                Text(isEs ? 'Sin factura este mes' : 'No invoice this month')),
      ],
      onSelected: onSelected,
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({
    super.key,
    required this.client,
    required this.selected,
    required this.showType,
    required this.showProperty,
    required this.showStatus,
    required this.onTap,
    this.onEdit,
  });

  final GroupClient client;
  final bool selected;
  final bool showType;
  final bool showProperty;
  final bool showStatus;
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
      margin: EdgeInsets.zero,
      borderRadius: selected ? 8 : 0,
      child: Row(children: [
        CircleAvatar(
          radius: 12,
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
            ]),
          ),
        if (showProperty)
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (client.effectivePropertyType != null &&
                    client.effectivePropertyType!.trim().isNotEmpty) ...[
                  Icon(LucideIcons.house, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    client.effectivePropertyType == null ||
                            client.effectivePropertyType!.trim().isEmpty
                        ? '—'
                        : clientClassificationLabel(
                            client.effectivePropertyType!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (showStatus)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: client.isActive
                        ? const Color(0xFF22A06B)
                        : cs.onSurfaceVariant.withValues(alpha: .55),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    client.isActive ? l.active : l.inactive,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: client.isActive
                          ? const Color(0xFF247A55)
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: 70,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PopupMenuButton<_ClientRowAction>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              position: PopupMenuPosition.under,
              icon: const Icon(LucideIcons.ellipsis),
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
                    const Icon(LucideIcons.pencil, size: 17),
                    const SizedBox(width: 8),
                    Text(l.editClient),
                  ]),
                ),
              ],
            ),
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
    this.trailing,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;
  final Widget? trailing;

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
          Icon(ascending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 12, color: cs.primary),
        if (trailing != null) ...[
          const SizedBox(width: 2),
          trailing!,
        ],
      ]),
    );
  }
}

enum _ClientRowAction { edit }
