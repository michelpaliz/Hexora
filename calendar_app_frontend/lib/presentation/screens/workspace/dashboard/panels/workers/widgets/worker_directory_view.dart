import 'package:flutter/material.dart';
import 'package:hexora/l10n/build_context_locale.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/workers/widgets/status_filter_chips.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/presentation/shared/widgets/hexora_popup_menu.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_directory_tabs.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_list_section.dart';

class WorkerDirectoryView extends StatefulWidget {
  const WorkerDirectoryView({
    super.key,
    required this.group,
    required this.workers,
    required this.showPartners,
    required this.onTabChanged,
    required this.monthSummary,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onCreate,
    required this.onEdit,
    required this.onAddHours,
    required this.onOverview,
    this.selectedWorkerId,
  });

  final Group group;
  final List<Worker> workers;
  final bool showPartners;
  final ValueChanged<bool> onTabChanged;
  final Widget monthSummary;
  final WorkerStatusFilter statusFilter;
  final ValueChanged<WorkerStatusFilter> onStatusFilterChanged;
  final VoidCallback onCreate;
  final ValueChanged<Worker> onEdit;
  final ValueChanged<Worker> onAddHours;
  final ValueChanged<Worker> onOverview;
  final String? selectedWorkerId;

  @override
  State<WorkerDirectoryView> createState() => _WorkerDirectoryViewState();
}

class _WorkerDirectoryViewState extends State<WorkerDirectoryView> {
  final _search = TextEditingController();
  bool _ascending = true;
  bool _grid = false;
  int _page = 0;
  static const _pageSize = 8;

  @override
  void didUpdateWidget(covariant WorkerDirectoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workers != widget.workers ||
        oldWidget.showPartners != widget.showPartners) {
      _page = 0;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEs = context.isSpanishLocale;
    final cs = Theme.of(context).colorScheme;

    final partners = widget.workers
        .where((worker) => isPartnerWorker(worker, widget.group))
        .length;
    final query = _search.text.trim().toLowerCase();
    final visible = widget.workers.where((worker) {
      return isPartnerWorker(worker, widget.group) == widget.showPartners &&
          '${worker.displayName ?? ''} ${worker.roleTag ?? ''} ${worker.externalId ?? ''}'
              .toLowerCase()
              .contains(query);
    }).toList()
      ..sort((a, b) {
        if (widget.showPartners) {
          final roleOrder = partnerRoleForWorker(a, widget.group)!
              .index
              .compareTo(partnerRoleForWorker(b, widget.group)!.index);
          if (roleOrder != 0) return roleOrder;
        }
        final result = (a.displayName ?? a.userId ?? '')
            .toLowerCase()
            .compareTo((b.displayName ?? b.userId ?? '').toLowerCase());
        return _ascending ? result : -result;
      });

    final tabs = WorkerDirectoryTabs(
      showPartners: widget.showPartners,
      workerCount: widget.workers.length - partners,
      partnerCount: partners,
      onChanged: (value) {
        setState(() => _page = 0);
        widget.onTabChanged(value);
      },
      decorated: true,
      compact: true,
    );
    final search = SizedBox(
      height: 34,
      child: TextField(
        controller: _search,
        style: const TextStyle(fontSize: 13),
        onChanged: (_) => setState(() => _page = 0),
        decoration: InputDecoration(
          hintText: widget.showPartners
              ? (isEs ? 'Buscar socio…' : 'Search partners…')
              : (isEs ? 'Buscar trabajador…' : 'Search workers…'),
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: isEs ? 'Limpiar búsqueda' : 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(_search.clear),
                ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
    final add = HexoraButton(
      icon: Icons.add_rounded,
      label: widget.showPartners
          ? (isEs ? 'Añadir socio' : 'Add partner')
          : (isEs ? 'Añadir trabajador' : 'Add worker'),
      size: HexoraButtonSize.compact,
      onPressed: widget.onCreate,
    );
    final pageCount = (visible.length / _pageSize).ceil().clamp(1, 1000000);
    final page = _page.clamp(0, pageCount - 1);
    final pageWorkers = visible.skip(page * _pageSize).take(_pageSize).toList();
    final first = visible.isEmpty ? 0 : page * _pageSize + 1;
    final last = page * _pageSize + pageWorkers.length;
    final noun = widget.showPartners
        ? (isEs ? 'socios' : 'partners')
        : (isEs ? 'trabajadores' : 'workers');
    final showing = pageCount == 1
        ? '${visible.length} $noun'
        : '$first–$last / ${visible.length} $noun';

    final filters = _DirectoryFilterMenu(
      value: widget.statusFilter,
      isSpanish: isEs,
      onChanged: widget.onStatusFilterChanged,
    );
    final statusFilters = StatusFilterChips(
      value: widget.statusFilter,
      onChanged: widget.onStatusFilterChanged,
    );
    final options = _DirectoryOptionsMenu(
      ascending: _ascending,
      grid: _grid,
      isSpanish: isEs,
      onSelected: (value) {
        setState(() {
          switch (value) {
            case 'sort-asc':
              _ascending = true;
              _page = 0;
            case 'sort-desc':
              _ascending = false;
              _page = 0;
            case 'view-list':
              _grid = false;
            case 'view-grid':
              _grid = true;
          }
        });
      },
    );
    final sorting = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.swap_vert_rounded, size: 17, color: cs.onSurfaceVariant),
        const SizedBox(width: 5),
        DropdownButtonHideUnderline(
          child: DropdownButton<bool>(
            value: _ascending,
            isDense: true,
            borderRadius: BorderRadius.circular(8),
            style: TextStyle(fontSize: 13, color: cs.onSurface),
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            items: const [
              DropdownMenuItem(value: true, child: Text('A–Z')),
              DropdownMenuItem(value: false, child: Text('Z–A')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _ascending = value;
                _page = 0;
              });
            },
          ),
        ),
      ]),
    );
    final viewToggle = Row(mainAxisSize: MainAxisSize.min, children: [
      for (final grid in [false, true])
        HexoraButton.iconOnly(
          tooltip: grid
              ? (isEs ? 'Vista de tarjetas' : 'Card view')
              : (isEs ? 'Vista de lista' : 'List view'),
          icon: grid
              ? Icons.grid_view_rounded
              : Icons.format_list_bulleted_rounded,
          size: HexoraButtonSize.compact,
          variant: _grid == grid
              ? HexoraButtonVariant.tonal
              : HexoraButtonVariant.ghost,
          accentColor: cs.primary,
          onPressed: () => setState(() => _grid = grid),
        ),
    ]);

    return LayoutBuilder(builder: (context, constraints) {
      final inline = constraints.maxWidth >= 720 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      final fullToolbar = constraints.maxWidth >= 840 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.3;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── tabs + add button ──
            if (inline)
              Row(children: [
                Expanded(child: tabs),
                const SizedBox(width: 8),
                add,
              ])
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [tabs, add],
              ),
            const SizedBox(height: 10),

            if (fullToolbar)
              Row(children: [
                widget.monthSummary,
                const SizedBox(width: 10),
                statusFilters,
                const SizedBox(width: 12),
                Expanded(child: search),
                const SizedBox(width: 10),
                sorting,
                const SizedBox(width: 6),
                viewToggle,
              ])
            else if (inline)
              Row(children: [
                Expanded(child: search),
                const SizedBox(width: 8),
                widget.monthSummary,
                const SizedBox(width: 8),
                filters,
                const SizedBox(width: 4),
                options,
              ])
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width:
                        (constraints.maxWidth - 24).clamp(160, 320).toDouble(),
                    child: search,
                  ),
                  widget.monthSummary,
                  filters,
                  options,
                ],
              ),
            const SizedBox(height: 10),

            // ── worker list (flat) ──
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  query.isNotEmpty
                      ? (isEs
                          ? 'No hay resultados para esta búsqueda.'
                          : 'No results for this search.')
                      : (isEs
                          ? (widget.showPartners
                              ? 'No hay socios con este estado.'
                              : 'No hay trabajadores con este estado.')
                          : (widget.showPartners
                              ? 'No partners with this status.'
                              : 'No workers with this status.')),
                  textAlign: TextAlign.center,
                ),
              )
            else
              WorkerListSection(
                workers: pageWorkers,
                partnerRoles: {
                  for (final worker in pageWorkers)
                    if (partnerRoleForWorker(worker, widget.group)
                        case final role?)
                      worker.id: role,
                },
                selectedWorkerId: widget.selectedWorkerId,
                tapSelects: true,
                onSelect: widget.onEdit,
                onEdit: widget.onEdit,
                onAddHours: widget.onAddHours,
                onOpenOverview: widget.onOverview,
                spacious: true,
                grid: _grid,
              ),

            // ── pagination (compact, no border) ──
            if (pageCount > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      showing,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      HexoraButton.iconOnly(
                        tooltip: isEs ? 'Página anterior' : 'Previous page',
                        icon: Icons.chevron_left_rounded,
                        size: HexoraButtonSize.compact,
                        variant: HexoraButtonVariant.ghost,
                        onPressed: page == 0
                            ? null
                            : () => setState(() => _page = page - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${page + 1} / $pageCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      HexoraButton.iconOnly(
                        tooltip: isEs ? 'Página siguiente' : 'Next page',
                        icon: Icons.chevron_right_rounded,
                        size: HexoraButtonSize.compact,
                        variant: HexoraButtonVariant.ghost,
                        onPressed: page >= pageCount - 1
                            ? null
                            : () => setState(() => _page = page + 1),
                      ),
                    ]),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
                child: Text(
                  showing,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _DirectoryFilterMenu extends StatelessWidget {
  const _DirectoryFilterMenu({
    required this.value,
    required this.isSpanish,
    required this.onChanged,
  });

  final WorkerStatusFilter value;
  final bool isSpanish;
  final ValueChanged<WorkerStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeCount = value == WorkerStatusFilter.all ? 0 : 1;
    final label = isSpanish ? 'Filtros' : 'Filters';
    return SizedBox.square(
      dimension: 34,
      child: PopupMenuButton<WorkerStatusFilter>(
        tooltip: activeCount == 0 ? label : '$label ($activeCount)',
        position: PopupMenuPosition.under,
        constraints: const BoxConstraints(minWidth: 210, maxWidth: 240),
        onSelected: onChanged,
        itemBuilder: (_) => [
          for (final filter in WorkerStatusFilter.values)
            CheckedPopupMenuItem(
              value: filter,
              checked: value == filter,
              child: Text(switch (filter) {
                WorkerStatusFilter.all => isSpanish ? 'Todos' : 'All',
                WorkerStatusFilter.active => isSpanish ? 'Activo' : 'Active',
                WorkerStatusFilter.inactive =>
                  isSpanish ? 'Inactivo' : 'Inactive',
              }),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: WorkerStatusFilter.all,
            enabled: value != WorkerStatusFilter.all,
            child: Row(children: [
              const Icon(Icons.restart_alt_rounded, size: 17),
              const SizedBox(width: 8),
              Text(isSpanish ? 'Restablecer' : 'Reset'),
            ]),
          ),
        ],
        icon: Stack(clipBehavior: Clip.none, children: [
          Icon(
            Icons.filter_list_rounded,
            size: 19,
            color: activeCount == 0 ? cs.onSurfaceVariant : cs.primary,
          ),
          if (activeCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                width: 15,
                height: 15,
                alignment: Alignment.center,
                decoration:
                    BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _DirectoryOptionsMenu extends StatelessWidget {
  const _DirectoryOptionsMenu({
    required this.ascending,
    required this.grid,
    required this.isSpanish,
    required this.onSelected,
  });

  final bool ascending;
  final bool grid;
  final bool isSpanish;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 34,
        child: HexoraPopupMenuButton<String>(
          tooltip: isSpanish ? 'Opciones de vista' : 'View options',
          icon: const Icon(Icons.tune_rounded, size: 19),
          onSelected: onSelected,
          itemBuilder: (_) => [
            HexoraPopupMenuActionItem(
              value: 'sort-asc',
              icon: ascending
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              label: isSpanish ? 'Nombre (A–Z)' : 'Name (A–Z)',
              tone: ascending
                  ? HexoraPopupMenuTone.primary
                  : HexoraPopupMenuTone.neutral,
            ),
            HexoraPopupMenuActionItem(
              value: 'sort-desc',
              icon: !ascending
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              label: isSpanish ? 'Nombre (Z–A)' : 'Name (Z–A)',
              tone: !ascending
                  ? HexoraPopupMenuTone.primary
                  : HexoraPopupMenuTone.neutral,
            ),
            const HexoraPopupMenuDivider(),
            HexoraPopupMenuActionItem(
              value: 'view-list',
              icon: !grid
                  ? Icons.check_rounded
                  : Icons.format_list_bulleted_rounded,
              label: isSpanish ? 'Vista de lista' : 'List view',
              tone: !grid
                  ? HexoraPopupMenuTone.primary
                  : HexoraPopupMenuTone.neutral,
            ),
            HexoraPopupMenuActionItem(
              value: 'view-grid',
              icon: grid ? Icons.check_rounded : Icons.grid_view_rounded,
              label: isSpanish ? 'Vista de tarjetas' : 'Card view',
              tone: grid
                  ? HexoraPopupMenuTone.primary
                  : HexoraPopupMenuTone.neutral,
            ),
          ],
        ),
      );
}
