import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/group_time_tracking_screen_state.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/telegram_worker_hours_import_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_current_month_summary_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/time_tracking_excel_import_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_time_history_graph_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/worker_time_tracking_screen.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/sidebar_item.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum _WorkersSection {
  workers,
  graphs,
  historial,
  telegramImport,
  registerHours
}

class WorkersHubScreen extends StatefulWidget {
  final Group group;
  const WorkersHubScreen({super.key, required this.group});

  @override
  State<WorkersHubScreen> createState() => _WorkersHubScreenState();
}

class _WorkersHubScreenState extends State<WorkersHubScreen> {
  _WorkersSection _section = _WorkersSection.workers;

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  Widget _buildSectionContent() {
    return IndexedStack(
      index: _section.index,
      children: [
        GroupTimeTrackingScreen(
          key: ValueKey('workers-${widget.group.id}'),
          group: widget.group,
          embedded: true,
          onOpenHistorial: () =>
              setState(() => _section = _WorkersSection.historial),
        ),
        WorkerTimeHistoryGraphView(
          key: ValueKey('worker-graphs-${widget.group.id}'),
          group: widget.group,
        ),
        WorkerCurrentMonthSummaryView(group: widget.group),
        TelegramWorkerHoursImportView(group: widget.group),
        _RegisterHoursImportPanel(group: widget.group),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = _isSpanish(context);

    final navItems = [
      (
        icon: Icons.group_outlined,
        label: l.workersLabel,
        mobileLabel: isEs ? 'Trabajadores' : 'Workers',
        section: _WorkersSection.workers,
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: isEs ? 'Graficas' : 'Charts',
        mobileLabel: isEs ? 'Graficas' : 'Charts',
        section: _WorkersSection.graphs,
      ),
      (
        icon: Icons.history_outlined,
        label: isEs ? 'Resumen del mes' : 'Summary this month',
        mobileLabel: isEs ? 'Resumen' : 'Summary',
        section: _WorkersSection.historial,
      ),
      (
        icon: Icons.telegram,
        label: isEs ? 'Importar Telegram' : 'Telegram import',
        mobileLabel: 'Telegram',
        section: _WorkersSection.telegramImport,
      ),
      (
        icon: Icons.schedule_outlined,
        label: isEs ? 'Registrar horas' : 'Register hours',
        mobileLabel: isEs ? 'Horas' : 'Hours',
        section: _WorkersSection.registerHours,
      ),
    ];
    final isNarrow = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.timeTrackingTitle,
          style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.inverseSurface),
      ),
      body: isNarrow
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in navItems)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _MobileWorkersNavChip(
                              icon: item.icon,
                              label: item.mobileLabel,
                              selected: _section == item.section,
                              onTap: () =>
                                  setState(() => _section = item.section),
                              textStyle: t.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildSectionContent()),
              ],
            )
          : Row(
        children: [
          // ── Left side nav ─────────────────────────────────────────────
          SizedBox(
            width: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...navItems.map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: SidebarItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: _section == item.section,
                      collapsed: false,
                      onTap: () => setState(() => _section = item.section),
                    ),
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
          // ── Content area ──────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _section.index,
              children: [
                GroupTimeTrackingScreen(
                  key: ValueKey('workers-${widget.group.id}'),
                  group: widget.group,
                  embedded: true,
                  onOpenHistorial: () =>
                      setState(() => _section = _WorkersSection.historial),
                ),
                WorkerTimeHistoryGraphView(
                  key: ValueKey('worker-graphs-${widget.group.id}'),
                  group: widget.group,
                ),
                WorkerCurrentMonthSummaryView(group: widget.group),
                TelegramWorkerHoursImportView(group: widget.group),
                _RegisterHoursImportPanel(group: widget.group),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Historial Tab ────────────────────────────────────────────────────────────

class _MobileWorkersNavChip extends StatelessWidget {
  const _MobileWorkersNavChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textStyle,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primaryContainer.withValues(alpha: 0.95)
          : cs.surfaceContainerHighest.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: textStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkersHistorialContent extends StatefulWidget {
  final Group group;
  const _WorkersHistorialContent({required this.group});

  @override
  State<_WorkersHistorialContent> createState() =>
      _WorkersHistorialContentState();
}

class _WorkersHistorialContentState extends State<_WorkersHistorialContent> {
  List<Worker> _workers = const [];
  bool _loading = true;
  String? _error;
  Worker? _selectedWorker;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ITimeTrackingRepository>();
      final userDomain = context.read<UserDomain>();
      final token = await userDomain.getAuthToken();
      final workers = await repo.getWorkers(widget.group.id, token);
      if (!mounted) return;
      setState(() {
        _workers = workers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = _isSpanish(context);

    if (_loading) return const LoadingList();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: t.bodySmall.copyWith(color: cs.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: Text(l.tryAgain)),
          ],
        ),
      );
    }

    if (_workers.isEmpty) {
      return Center(
        child: EmptyView(
          icon: Icons.group_outlined,
          title: l.noWorkersYetTitle,
          subtitle: l.noWorkersYetSubtitle,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 600;

        if (wide) {
          // ── Wide: worker list left | tracking view right ───────────────
          return Row(
            children: [
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Text(
                        l.workersLabel,
                        style:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                        children: [
                          WorkerListSection(
                            workers: _workers,
                            tapSelects: true,
                            selectedWorkerId: _selectedWorker?.id,
                            onSelect: (w) =>
                                setState(() => _selectedWorker = w),
                            onEdit: (_) {},
                            onAddHours: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: _selectedWorker == null
                    ? Center(
                        child: Text(
                          isEs
                              ? 'Selecciona un trabajador para ver su historial.'
                              : 'Select a worker to view their history.',
                          style:
                              t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : WorkerTimeTrackingScreen(
                        key: ValueKey(_selectedWorker!.id),
                        group: widget.group,
                        worker: _selectedWorker!,
                        embedded: true,
                      ),
              ),
            ],
          );
        }

        // ── Narrow: worker list → tracking view (back button) ─────────────
        if (_selectedWorker == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Text(
                  l.workersLabel,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  children: [
                    WorkerListSection(
                      workers: _workers,
                      tapSelects: true,
                      onSelect: (w) => setState(() => _selectedWorker = w),
                      onEdit: (_) {},
                      onAddHours: (_) {},
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              child: InkWell(
                onTap: () => setState(() => _selectedWorker = null),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: cs.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        l.workersLabel,
                        style:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: WorkerTimeTrackingScreen(
                key: ValueKey(_selectedWorker!.id),
                group: widget.group,
                worker: _selectedWorker!,
                embedded: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Register Hours Placeholder ───────────────────────────────────────────────

// ignore: unused_element
class _RegisterHoursInline extends StatelessWidget {
  const _RegisterHoursInline({required this.group});

  final Group group;

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = _isSpanish(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            isEs ? 'Próximamente' : 'Coming soon',
            style: t.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isEs
                  ? 'La funcionalidad de registro de horas estará disponible próximamente.'
                  : 'The hour registration feature will be available soon.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => TimeTrackingExcelImportDialog.show(
              context,
              group: group,
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(isEs ? 'Importar Excel' : 'Import Excel'),
          ),
        ],
      ),
    );
  }
}

class _RegisterHoursImportPanel extends StatelessWidget {
  const _RegisterHoursImportPanel({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return TimeTrackingExcelImportDialog(
      group: group,
      embedded: true,
    );
  }
}
