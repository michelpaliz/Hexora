import 'package:flutter/material.dart';
import 'package:hexora/models/group_model/worker/worker.dart';
import 'package:hexora/l10n/app_localizations.dart';
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
  });

  final List<Worker> workers;
  final Widget summary;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddWorker;
  final VoidCallback? onRegisterHours;
  final ValueChanged<Worker> onAddHours;
  final ValueChanged<Worker> onEdit;
  final ValueChanged<Worker> onOverview;

  @override
  State<WorkersMobileView> createState() => _WorkersMobileViewState();
}

class _WorkersMobileViewState extends State<WorkersMobileView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.startsWith('es');
    final cs = Theme.of(context).colorScheme;
    final workers = widget.workers
        .where((w) =>
            (w.displayName ?? '').toLowerCase().contains(_query) ||
            (w.roleTag ?? '').toLowerCase().contains(_query))
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        widget.summary,
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (value) => setState(
                              () => _query = value.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText:
                                isEs ? 'Buscar trabajador' : 'Search workers',
                            prefixIcon: const Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                              child: Text(
                                  '${l.employeesHeader} (${workers.length})',
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          IconButton(
                            tooltip: l.createWorkerCta,
                            onPressed: widget.onAddWorker,
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                          ),
                        ]),
                      ]),
                ),
              ),
              if (workers.isEmpty)
                SliverToBoxAdapter(
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                      isEs
                          ? 'No hay trabajadores que coincidan.'
                          : 'No matching workers.',
                      textAlign: TextAlign.center),
                )),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.builder(
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: WorkerMobileCard(
                        worker: worker,
                        onAddHours: () => widget.onAddHours(worker),
                        onEdit: () => widget.onEdit(worker),
                        onOverview: () => widget.onOverview(worker),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
      Material(
        color: cs.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onRegisterHours,
                icon: const Icon(Icons.add_rounded),
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
  const WorkerMobileCard(
      {super.key,
      required this.worker,
      required this.onAddHours,
      required this.onEdit,
      required this.onOverview});
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
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAddHours,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name.isEmpty ? l.workersLabel : name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                      [
                        worker.status == WorkerStatus.archived
                            ? l.statusInactive
                            : l.statusActive,
                        if (role.isNotEmpty) role,
                      ].join(' · '),
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  if (rateLabel != null) ...[
                    const SizedBox(height: 6),
                    Text('$rateLabel/h',
                        style: TextStyle(
                            color: cs.onSurface, fontWeight: FontWeight.w600)),
                  ],
                ])),
            PopupMenuButton<String>(
              tooltip: l.localeName.startsWith('es')
                  ? 'Acciones del trabajador'
                  : 'Worker actions',
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
                PopupMenuItem(value: 'hours', child: Text(l.addTimeEntryCta)),
                PopupMenuItem(
                    value: 'overview', child: Text(l.overviewInfoTitle)),
                PopupMenuItem(value: 'edit', child: Text(l.editWorker)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
