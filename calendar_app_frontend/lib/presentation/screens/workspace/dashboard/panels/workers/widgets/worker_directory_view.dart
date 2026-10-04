import 'package:flutter/material.dart';
import 'package:hexora/l10n/build_context_locale.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
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
  final Widget statusFilter;
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
    final search = TextField(
      controller: _search,
      style: const TextStyle(fontSize: 13),
      onChanged: (_) => setState(() => _page = 0),
      decoration: InputDecoration(
        hintText: widget.showPartners
            ? (isEs ? 'Buscar socio…' : 'Search partners…')
            : (isEs ? 'Buscar trabajador…' : 'Search workers…'),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: isEs ? 'Limpiar búsqueda' : 'Clear search',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(_search.clear),
              ),
        isDense: true,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide:
                BorderSide(color: cs.outlineVariant.withValues(alpha: .6))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide(color: cs.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
    );
    final add = FilledButton.icon(
      onPressed: widget.onCreate,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(isEs ? 'Añadir trabajador' : 'Add worker'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        ? (isEs
            ? 'Mostrando ${visible.length} de ${visible.length} $noun'
            : 'Showing ${visible.length} of ${visible.length} $noun')
        : (isEs
            ? 'Mostrando $first–$last de ${visible.length} $noun'
            : 'Showing $first–$last of ${visible.length} $noun');
    final iconStyle = IconButton.styleFrom(
      minimumSize: const Size(34, 34),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      side: BorderSide(color: cs.outlineVariant.withValues(alpha: .55)),
    );
    final viewToggle = Row(mainAxisSize: MainAxisSize.min, children: [
      for (final grid in [false, true]) ...[
        if (grid) const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: grid
              ? (isEs ? 'Vista de tarjetas' : 'Card view')
              : (isEs ? 'Vista de lista' : 'List view'),
          isSelected: _grid == grid,
          style: iconStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll(_grid == grid
                ? cs.primaryContainer.withValues(alpha: .5)
                : cs.surface),
            foregroundColor: WidgetStatePropertyAll(
                _grid == grid ? cs.primary : cs.onSurfaceVariant),
          ),
          onPressed: () => setState(() => _grid = grid),
          icon: Icon(
              grid
                  ? Icons.grid_view_rounded
                  : Icons.format_list_bulleted_rounded,
              size: 21),
        ),
      ],
    ]);
    final sorting = Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: .55))),
            child: DropdownButtonHideUnderline(
                child: DropdownButton<bool>(
              value: _ascending,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              icon: const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(Icons.expand_more_rounded)),
              items: [
                DropdownMenuItem(
                    value: true,
                    child: Text(isEs ? 'Nombre (A–Z)' : 'Name (A–Z)')),
                DropdownMenuItem(
                    value: false,
                    child: Text(isEs ? 'Nombre (Z–A)' : 'Name (Z–A)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _ascending = value;
                    _page = 0;
                  });
                }
              },
            )),
          ),
        ]);
    return LayoutBuilder(builder: (context, constraints) {
      final inline = constraints.maxWidth >= 520 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      return SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (inline)
          Row(children: [Expanded(child: tabs), const SizedBox(width: 8), add])
        else
          Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [tabs, add]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: .35))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [widget.monthSummary, widget.statusFilter]),
            const SizedBox(height: 8),
            if (inline)
              Row(children: [
                Expanded(child: search),
                const SizedBox(width: 8),
                sorting,
                const SizedBox(width: 8),
                viewToggle
              ])
            else
              Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                        width: (constraints.maxWidth - 24)
                            .clamp(160, 320)
                            .toDouble(),
                        child: search),
                    sorting,
                    viewToggle
                  ]),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: .35))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                  ))
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
                  grid: _grid),
            Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    Text(showing,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton.outlined(
                          tooltip: isEs ? 'Página anterior' : 'Previous page',
                          style: iconStyle,
                          onPressed: page == 0
                              ? null
                              : () => setState(() => _page = page - 1),
                          icon: const Icon(Icons.chevron_left_rounded)),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: .6),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: cs.primary.withValues(alpha: .25))),
                          child: Text('${page + 1}',
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600))),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                          tooltip: isEs ? 'Página siguiente' : 'Next page',
                          style: iconStyle,
                          onPressed: page >= pageCount - 1
                              ? null
                              : () => setState(() => _page = page + 1),
                          icon: const Icon(Icons.chevron_right_rounded)),
                    ]),
                  ],
                )),
          ]),
        ),
      ]));
    });
  }
}
