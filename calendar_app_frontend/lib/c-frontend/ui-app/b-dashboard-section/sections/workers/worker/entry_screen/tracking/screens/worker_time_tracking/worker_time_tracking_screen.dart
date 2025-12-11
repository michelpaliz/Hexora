import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/controller/worker_time_tracking_controller.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/appbar_title.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/stats_header.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/widgets/time_entry_list.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // keep only if added to pubspec

class WorkerTimeTrackingScreen extends StatelessWidget {
  final Group group;
  final Worker worker;
  final int? initialYear;
  final int? initialMonth;

  const WorkerTimeTrackingScreen({
    super.key,
    required this.group,
    required this.worker,
    this.initialYear,
    this.initialMonth,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ITimeTrackingRepository>();
    final userDomain = context.read<UserDomain>();

    return ChangeNotifierProvider(
      create: (_) => WorkerTimeTrackingController(
        group: group,
        worker: worker,
        repo: repo,
        userDomain: userDomain,
        initialYear: initialYear,
        initialMonth: initialMonth,
      )..load(),
      child: const _WorkerTimeTrackingView(),
    );
  }
}

class _WorkerTimeTrackingView extends StatefulWidget {
  const _WorkerTimeTrackingView();

  @override
  State<_WorkerTimeTrackingView> createState() =>
      _WorkerTimeTrackingViewState();
}

class _WorkerTimeTrackingViewState extends State<_WorkerTimeTrackingView> {
  bool _showMissingDays = false;

  Future<void> _addEntry(BuildContext context) async {
    final c = context.read<WorkerTimeTrackingController>();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: CreateTimeEntryScreen(
          group: c.group,
          workers: [c.worker],
        ),
      ),
    );
    if (created == true) await c.load();
  }

  Future<void> _exportExcel(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final c = context.read<WorkerTimeTrackingController>();
    try {
      final bytes = await c.exportExcelFiltered();
      final fileName =
          'time_entries_${c.group.id}_${c.year}-${c.month.toString().padLeft(2, '0')}_${c.worker.id}.xlsx';
      final xfile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      await Share.shareXFiles([xfile], text: l.exportReady);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${l.error}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<WorkerTimeTrackingController>(
      builder: (context, c, _) {
        final addButton = Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _addEntry(context),
              icon: const Icon(Icons.add),
              label: Text(l.addTimeEntryCta),
            ),
          ),
        );

        final content = c.loading
            ? const Center(child: CircularProgressIndicator())
            : c.error
                ? Center(child: Text(l.errorLoadingData))
                : c.entries.isEmpty
                    ? EmptyView(
                        icon: Icons.timer_outlined,
                        title: l.noTimeEntriesYetTitle,
                        subtitle: l.noTimeEntriesYetSubtitle,
                        cta: l.addTimeEntryCta,
                        onPressed: () => _addEntry(context),
                      )
                    : RefreshIndicator(
                        onRefresh: c.load,
                        child: Column(
                          children: [
                            StatsHeader(
                                entries: c.entries,
                                totals: c.totals,
                                worker: c.worker),
                            Expanded(
                              child: TimeEntriesList(
                                entries: c.entries,
                                groupId: c.group.id,
                                repo: context.read<ITimeTrackingRepository>(),
                                getToken: () =>
                                    context.read<UserDomain>().getAuthToken(),
                                onUpdated: c.load,
                                worker: c.worker,
                                showMissingDays: _showMissingDays,
                              ),
                            ),
                            addButton,
                          ],
                        ),
                      );
        return Scaffold(
          appBar: AppBar(
            title: WorkerAppBarTitle(
              group: c.group,
              worker: c.worker,
              year: c.year,
              month: c.month,
            ),
            actions: [
              IconButton(
                tooltip: l.toggleEmptyDays,
                onPressed: () =>
                    setState(() => _showMissingDays = !_showMissingDays),
                icon: Icon(
                  _showMissingDays ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              IconButton(
                tooltip: l.exportExcel,
                onPressed: () => _exportExcel(context),
                icon: const Icon(Icons.download),
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }
}
