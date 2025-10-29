import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/card/time_tracking_header_card.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/worker/edit_worker/edit_worker_sheet.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/worker/monthly_overview/worker_monthly_overview.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class GroupTimeTrackingScreen extends StatefulWidget {
  final Group group;
  const GroupTimeTrackingScreen({super.key, required this.group});

  @override
  State<GroupTimeTrackingScreen> createState() =>
      _GroupTimeTrackingScreenState();
}

class _GroupTimeTrackingScreenState extends State<GroupTimeTrackingScreen> {
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

  Future<String> _getToken() => _userDomain.getAuthToken();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _pluginDisabled = false;
    });
    try {
      final token = await _getToken();
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
      final token = await _getToken();
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
      final token = await _getToken();
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
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.createWorker,
      arguments: widget.group,
    );
    if (created == true) {
      await _load();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.workerCreated)),
        );
      }
    }
  }

  Future<bool?> _openEditWorkerDialog(
      BuildContext context, Group group, Worker worker) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditWorkerSheet(
          group: group,
          worker: worker,
          repo: _repo,
          getToken: _getToken,
        ),
      ),
    );
  }

  Widget _countChip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    // Example: "3 workers" / "3 trabajadores"
    final countLabel = '${_workers.length} ${l.membersTitle.toLowerCase()}';

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.18)),
      ),
      child: Text(
        countLabel,
        style: t.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: .2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.timeTrackingTitle, style: t.titleLarge),
        backgroundColor: cs.surface,
        actions: [
          // 👉 Replaced the add button with a total workers chip
          if (!_loading && !_pluginDisabled && _error == null)
            _countChip(context),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingList()
            : _pluginDisabled
                ? EmptyView(
                    icon: Icons.lock_clock_outlined,
                    title: l.timeTrackingDisabledTitle,
                    subtitle: l.timeTrackingDisabledSubtitle,
                    cta: l.enableTrackingCta,
                    onPressed: _toggling ? null : _enable,
                  )
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : _workers.isEmpty
                        ? EmptyView(
                            icon: Icons.group_add_outlined,
                            title: l.noWorkersYetTitle,
                            subtitle: l.noWorkersYetSubtitle,
                            cta: l.createWorkerCta,
                            onPressed: _toggling ? null : _addWorker,
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              TimeTrackingHeaderCard(
                                groupName: widget.group.name,
                                onEnable: _enable,
                                onDisable: _disable,
                                busy: _toggling,
                              ),
                              const SizedBox(height: 16),

                              // 👉 Header row WITHOUT the add button (kept compact)
                              Text(
                                l.employeesHeader,
                                style: t.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),

                              ..._workers.map((w) {
                                final isLinked =
                                    (w.userId != null && w.userId!.isNotEmpty);
                                final leadingIcon = isLinked
                                    ? Icons.person_outline
                                    : Icons.badge_outlined;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(leadingIcon),
                                    title: Text(
                                      w.displayName ?? w.userId ?? 'Unnamed',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      isLinked
                                          ? AppLocalizations.of(context)!
                                              .linkedUser
                                          : AppLocalizations.of(context)!
                                              .externalWorker,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      tooltip: AppLocalizations.of(context)!
                                          .editWorker,
                                      onPressed: () async {
                                        final updated =
                                            await _openEditWorkerDialog(
                                          context,
                                          widget.group,
                                          w,
                                        );
                                        if (updated == true) _load();
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WorkerMonthlyOverviewScreen(
                                            group: widget.group,
                                            worker: w,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                              const SizedBox(height: 100),
                            ],
                          ),
      ),
      // ✅ Keep only the bottom FAB for adding workers
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWorker,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.createWorkerCta),
      ),
    );
  }
}
