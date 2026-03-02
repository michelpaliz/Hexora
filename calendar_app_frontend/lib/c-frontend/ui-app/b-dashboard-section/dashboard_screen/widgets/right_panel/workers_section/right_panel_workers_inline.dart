import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/card/time_tracking_header_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/worker_monthly_overview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';

import 'widgets/status_filter_chips.dart';
import 'widgets/worker_monthly_overview_inline.dart';
import 'widgets/workers_form_panel.dart';

class WorkersInlinePanel extends StatefulWidget {
  final Group group;
  const WorkersInlinePanel({super.key, required this.group});

  @override
  State<WorkersInlinePanel> createState() => _WorkersInlinePanelState();
}

class _WorkersInlinePanelState extends State<WorkersInlinePanel>
    with SingleTickerProviderStateMixin {
  late UserDomain _userDomain;
  late ITimeTrackingRepository _repo;

  bool _loading = false;
  bool _toggling = false;
  bool _pluginDisabled = false;
  String? _error;
  List<Worker> _workers = const [];
  Worker? _selectedWorker;
  late final TabController _tabController;
  WorkerStatusFilter _statusFilter = WorkerStatusFilter.all;
  bool _showOverview = false;

  @override
  void initState() {
    super.initState();
    _userDomain = context.read<UserDomain>();
    _repo = context.read<ITimeTrackingRepository>();
    _tabController = TabController(length: kIsWeb ? 3 : 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _token() => _userDomain.getAuthToken();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _pluginDisabled = false;
    });
    try {
      final token = await _token();
      final items = await _repo.getWorkers(
        widget.group.id,
        token,
        status: _statusFilter == WorkerStatusFilter.all
            ? null
            : (_statusFilter == WorkerStatusFilter.inactive
                ? WorkerStatus.archived
                : WorkerStatus.active),
      );
      if (!mounted) return;
      setState(() => _workers = items);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('403')) {
        setState(() {
          _pluginDisabled = true;
          _workers = const [];
        });
      } else if (msg.contains('404')) {
        setState(() => _workers = const []);
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enable() async {
    setState(() => _toggling = true);
    try {
      final token = await _token();
      await _repo.enable(widget.group.id, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.timeTrackingEnabled)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _toggling = true);
    try {
      final token = await _token();
      await _repo.disable(widget.group.id, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.timeTrackingDisabled)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _addWorker() async {
    _tabController.animateTo(1);
    setState(() {
      _selectedWorker = null;
      _showOverview = false;
    });
  }

  Future<void> _addSharedHours() async {
    if (_workers.isEmpty) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CreateTimeEntryScreen(
          group: widget.group,
          workers: _workers,
        ),
      ),
    );
    if (created == true) _load();
  }

  Future<bool?> _openEditWorkerDialog(Worker w) async {
    _tabController.animateTo(0);
    setState(() {
      _selectedWorker = w;
      _showOverview = false;
    });
    return null;
  }

  void _openOverviewInline(Worker w) {
    setState(() {
      _selectedWorker = w;
      _showOverview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    if (_loading) return const LoadingList();
    if (_pluginDisabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.timeTrackingDisabledTitle,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l.timeTrackingDisabledSubtitle,
                  style: t.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _toggling ? null : _enable,
                child: Text(l.enableTrackingCta),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: t.bodySmall.copyWith(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _load, child: Text(l.refresh)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (_selectedWorker == null) ...[
            TimeTrackingHeaderCard(
              groupName: widget.group.name,
              onEnable: _enable,
              onDisable: _disable,
              busy: _toggling,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 4),
          Expanded(
            child: (_selectedWorker != null && _showOverview)
                ? Column(
                    children: [
                      Expanded(
                        child: WorkerMonthlyOverviewInline(
                          group: widget.group,
                          worker: _selectedWorker!,
                          repo: _repo,
                          getToken: _token,
                          onBack: () {
                            _tabController.animateTo(0);
                            setState(() {
                              _showOverview = false;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FolderPanel(
                          title: l.workersLabel,
                          showTab: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: WorkerListSection(
                                          workers: _workers,
                                          selectedWorkerId:
                                              _selectedWorker?.id,
                                          tapSelects: true,
                                          onSelect: (w) =>
                                              _openEditWorkerDialog(w),
                                          onEdit: (w) =>
                                              _openEditWorkerDialog(w),
                                          onAddHours: _addHoursForWorker,
                                          onOpenOverviewIcon: (w) =>
                                              _openOverviewInline(w),
                                          onOpenOverview: _openOverview,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.statusLabel,
                                            style: AppTypography.of(context)
                                                .bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          StatusFilterChips(
                                            value: _statusFilter,
                                            onChanged: (next) {
                                              setState(() =>
                                                  _statusFilter = next);
                                              _load();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: WorkersFormPanel(
                                  group: widget.group,
                                  repo: _repo,
                                  getToken: _token,
                                  selectedWorker: _selectedWorker,
                                  onSaved: (created, savedWorker) async {
                                    await _load();
                                    if (!mounted) return;
                                    final l = AppLocalizations.of(context)!;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          created
                                              ? l.workerCreated
                                              : l.workerUpdated,
                                        ),
                                      ),
                                    );
                                    if (created) {
                                      _tabController.animateTo(0);
                                    }
                                    setState(
                                        () => _selectedWorker = savedWorker);
                                  },
                                  tabController: _tabController,
                                  enableAddHoursTab: kIsWeb,
                                ),
                              ),
                            ],
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

  Future<void> _addHoursForWorker(Worker w) async {
    if (kIsWeb) {
      _tabController.animateTo(2);
      setState(() {
        _selectedWorker = w;
        _showOverview = false;
      });
      return;
    }
    final ordered = [w, ..._workers.where((x) => x.id != w.id)];
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CreateTimeEntryScreen(group: widget.group, workers: ordered),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _openOverview(Worker w) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: WorkerMonthlyOverviewScreen(group: widget.group, worker: w),
      ),
    );
    if (created == true) _load();
  }
}
