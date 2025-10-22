import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/time_tracking_header_card.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/widgets/worker_title.dart';
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
    });
    try {
      final token = await _getToken();
      final items = await _repo.getWorkers(widget.group.id, token);
      if (!mounted) return;
      setState(() => _workers = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
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

  Future<void> _exportExcel() async {
    setState(() => _toggling = true);
    try {
      final token = await _getToken();
      final _ = await _repo.exportExcel(widget.group.id, token);
      if (!mounted) return;
      // Save/share bytes according to your app’s flow.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.exportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${AppLocalizations.of(context)!.exportFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.timeTrackingTitle, style: t.titleLarge),
        actions: [
          IconButton(
            tooltip: l.exportToExcelTooltip,
            onPressed: _toggling ? null : _exportExcel,
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const LoadingList()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _workers.isEmpty
                    ? EmptyView(
                        icon: Icons.access_time_rounded,
                        title: l.noWorkersYetTitle,
                        subtitle: l.noWorkersYetSubtitle,
                        cta: l.enableTrackingCta,
                        onPressed: _toggling
                            ? null
                            : _enable, // disable button while toggling
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
                          const SizedBox(height: 12),
                          Text(
                            l.employeesHeader,
                            style: t.titleLarge
                                .copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          ..._workers.map((w) => WorkerTile(worker: w)),
                          const SizedBox(height: 100),
                        ],
                      ),
      ),
      floatingActionButton: _workers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggling ? null : _exportExcel,
              icon: const Icon(Icons.table_view_outlined),
              label: Text(l.exportToExcelCta),
            ),
    );
  }
}
