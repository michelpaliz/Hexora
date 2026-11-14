import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/shared/widgets/navigation_popup_menu_item.dart';
import 'package:intl/intl.dart';

/// Mobile presentation only. Loading, permissions and mutations stay in the parent.
class WorkersMobileView extends StatefulWidget {
  const WorkersMobileView({
    super.key,
    required this.workers,
    required this.summary,
    required this.onRefresh,
    required this.onAddWorker,
    required this.onRegisterHours,
    required this.onAddHours,
    required this.onEdit,
    required this.onOverview,
    this.directoryTabs,
    this.showPartners = false,
  });

  final List<Worker> workers;
  final Widget summary;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddWorker;
  final VoidCallback? onRegisterHours;
  final ValueChanged<Worker> onAddHours;
  final ValueChanged<Worker> onEdit;
  final ValueChanged<Worker> onOverview;
  final Widget? directoryTabs;
  final bool showPartners;

  @override
  State<WorkersMobileView> createState() => _WorkersMobileViewState();
}

class _WorkersMobileViewState extends State<WorkersMobileView> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.startsWith('es');
    final cs = Theme.of(context).colorScheme;
    final workers = widget.workers
        .where((worker) =>
            (worker.displayName ?? '').toLowerCase().contains(_query) ||
            (worker.roleTag ?? '').toLowerCase().contains(_query))
        .toList();

    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.summary,
                      const SizedBox(height: 8),
                      if (widget.directoryTabs != null) ...[
                        widget.directoryTabs!,
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: widget.showPartners
                              ? (isEs ? 'Buscar socio' : 'Search partners')
                              : (isEs
                                  ? 'Buscar trabajador'
                                  : 'Search workers'),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: isEs
                                      ? 'Limpiar búsqueda'
                                      : 'Clear search',
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                          child: Text(
                            '${widget.showPartners ? (isEs ? 'Socios' : 'Partners') : l.workersLabel} (${workers.length})',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: l.createWorkerCta,
                          onPressed: widget.onAddWorker,
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.person_add_alt_1_outlined,
                              size: 20),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              if (workers.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.showPartners
                          ? (isEs
                              ? 'No hay socios que coincidan.'
                              : 'No matching partners.')
                          : (isEs
                              ? 'No hay trabajadores que coincidan.'
                              : 'No matching workers.'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverList.separated(
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return WorkerMobileCard(
                      worker: worker,
                      onAddHours: () => widget.onAddHours(worker),
                      onEdit: () => widget.onEdit(worker),
                      onOverview: () => widget.onOverview(worker),
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],
          ),
        ),
      ),
      Material(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: widget.onRegisterHours,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(l.addTimeEntryCta, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class WorkerMobileCard extends StatelessWidget {
  const WorkerMobileCard({
    super.key,
    required this.worker,
    required this.onAddHours,
    required this.onEdit,
    required this.onOverview,
  });

  final Worker worker;
  final VoidCallback onAddHours;
  final VoidCallback onEdit;
  final VoidCallback onOverview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final name = (worker.displayName ?? '').trim();
    final role = (worker.roleTag ?? '').trim();
    final rate = worker.defaultHourlyRate;
    final rateLabel = rate == null
        ? null
        : NumberFormat.currency(
                locale: l.localeName, name: worker.currency ?? 'EUR')
            .format(rate);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 66),
      child: Material(
        color: cs.surface,
        child: InkWell(
          onTap: onAddHours,
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 2),
            child: Row(children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                foregroundColor: cs.primary,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? l.workersLabel : name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (role.isNotEmpty) role,
                        worker.status == WorkerStatus.archived
                            ? l.statusInactive
                            : l.statusActive,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (rateLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 64,
                    child: Text(
                      '$rateLabel/h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: l.localeName.startsWith('es')
                    ? 'Acciones del trabajador'
                    : 'Worker actions',
                iconSize: 20,
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  switch (value) {
                    case 'hours':
                      onAddHours();
                    case 'overview':
                      onOverview();
                    case 'edit':
                      onEdit();
                  }
                },
                itemBuilder: (_) => [
                  NavigationPopupMenuItem(
                    value: 'hours',
                    child: Text(l.addTimeEntryCta),
                  ),
                  NavigationPopupMenuItem(
                    value: 'overview',
                    child: Text(l.overviewInfoTitle),
                  ),
                  NavigationPopupMenuItem(
                    value: 'edit',
                    child: Text(l.editWorker),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
