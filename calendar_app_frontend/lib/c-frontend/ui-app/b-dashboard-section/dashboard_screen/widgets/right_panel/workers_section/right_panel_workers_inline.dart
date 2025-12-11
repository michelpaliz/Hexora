import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/card/time_tracking_header_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/edit_worker/edit_worker_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/worker_monthly_overview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class WorkersInlinePanel extends StatefulWidget {
  final Group group;
  const WorkersInlinePanel({super.key, required this.group});

  @override
  State<WorkersInlinePanel> createState() => _WorkersInlinePanelState();
}

class _WorkersInlinePanelState extends State<WorkersInlinePanel> {
  late UserDomain _userDomain;
  late ITimeTrackingRepository _repo;

  bool _loading = false;
  bool _toggling = false;
  bool _pluginDisabled = false;
  String? _error;
  List<Worker> _workers = const [];

  @override
  void initState() {
    super.initState();
    _userDomain = context.read<UserDomain>();
    _repo = context.read<ITimeTrackingRepository>();
    _load();
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
      final items = await _repo.getWorkers(widget.group.id, token);
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
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditWorkerSheet(
        group: widget.group,
        repo: _repo,
        getToken: _token,
        worker: Worker.newExternal(groupId: widget.group.id),
      ),
    );
    if (created == true) {
      await _load();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.workerCreated)));
      }
    }
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
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditWorkerSheet(
        group: widget.group,
        repo: _repo,
        getToken: _token,
        worker: w,
      ),
    );
  }

  Widget _countChip(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_workers.length} ${l.workersLabel.toLowerCase()}',
        style:
            AppTypography.of(context).bodySmall.copyWith(color: cs.onSurface),
      ),
    );
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
          TimeTrackingHeaderCard(
            groupName: widget.group.name,
            onEnable: _enable,
            onDisable: _disable,
            busy: _toggling,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.employeesHeader,
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  _countChip(context),
                ],
              ),
              Row(
                children: [
                  if (_workers.isNotEmpty)
                    FilledButton.tonal(
                      onPressed: _toggling ? null : _addSharedHours,
                      child: Text(l.addTimeEntryCta),
                    ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _toggling ? null : _addWorker,
                    child: Text(l.createWorkerCta),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: WorkerListSection(
              workers: _workers,
              onEdit: (w) async {
                final updated = await _openEditWorkerDialog(w);
                if (updated == true) _load();
              },
              onAddHours: _addHoursForWorker,
              onOpenOverview: _openOverview,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addHoursForWorker(Worker w) async {
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
