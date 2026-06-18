import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/card/time_tracking_header_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/edit_worker/edit_worker_sheet.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/worker_monthly_overview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _ActiveWorkersPeriodMode { currentMonth, yearMonth, customRange }

class GroupTimeTrackingScreen extends StatefulWidget {
  final Group group;
  final bool embedded;
  // Optional: called when the user taps the "Historial" shortcut in the header.
  final VoidCallback? onOpenHistorial;
  const GroupTimeTrackingScreen({
    super.key,
    required this.group,
    this.embedded = false,
    this.onOpenHistorial,
  });

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

  bool _activeTotalsLoading = false;
  String? _activeTotalsError;
  Map<String, dynamic>? _activeTotals;
  _ActiveWorkersPeriodMode _periodMode = _ActiveWorkersPeriodMode.currentMonth;
  late int _periodYear;
  late int _periodMonth;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _userDomain = context.read<UserDomain>();
    _repo = context.read<ITimeTrackingRepository>();
    final now = DateTime.now();
    _periodYear = now.year;
    _periodMonth = now.month;
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
      final results = await Future.wait([
        _repo.getWorkers(widget.group.id, token),
        _repo.getActiveWorkersTotals(widget.group.id, token),
      ]);

      final items = results[0] as List<Worker>;
      final totals = results[1] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _workers = items;
        _activeTotals = totals;
        _activeTotalsError = null;
      });
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

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  String _monthLabel(BuildContext context) =>
      _isSpanish(context) ? 'Mes' : 'Month';

  String _customRangeLabel(BuildContext context) =>
      _isSpanish(context) ? 'Rango personalizado' : 'Custom range';

  String _failedTotalsLabel(BuildContext context) => _isSpanish(context)
      ? 'No se pudo cargar el total de trabajadores activos.'
      : 'Failed to load active workers total.';

  Future<void> _reloadActiveWorkersTotals() async {
    setState(() {
      _activeTotalsLoading = true;
      _activeTotalsError = null;
    });
    try {
      final token = await _getToken();
      final payload = await _repo.getActiveWorkersTotals(
        widget.group.id,
        token,
        from: _periodMode == _ActiveWorkersPeriodMode.customRange
            ? _customRange?.start
            : null,
        to: _periodMode == _ActiveWorkersPeriodMode.customRange
            ? _customRange?.end
            : null,
        year: _periodMode == _ActiveWorkersPeriodMode.yearMonth
            ? _periodYear
            : null,
        month: _periodMode == _ActiveWorkersPeriodMode.yearMonth
            ? _periodMonth
            : null,
      );
      if (!mounted) return;
      setState(() => _activeTotals = payload);
    } catch (e) {
      if (!mounted) return;
      var message = _failedTotalsLabel(context);
      if (e is BackendApiException && e.message.trim().isNotEmpty) {
        message = e.message;
      }
      setState(() => _activeTotalsError = message);
    } finally {
      if (mounted) {
        setState(() => _activeTotalsLoading = false);
      }
    }
  }

  Future<void> _pickYearMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_periodYear, _periodMonth, 1),
      firstDate: DateTime(2018, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: _monthLabel(context),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null) return;
    setState(() {
      _periodMode = _ActiveWorkersPeriodMode.yearMonth;
      _periodYear = picked.year;
      _periodMonth = picked.month;
      _customRange = null;
    });
    await _reloadActiveWorkersTotals();
  }

  String _toMoney(num value) => value.toStringAsFixed(2);

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

  Future<void> _addSharedHours() async {
    if (_workers.isEmpty) return;
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.createTimeEntry,
      arguments: {
        'group': widget.group,
        'workers': _workers,
      },
    );
    if (created == true) {
      await _load();
    }
  }

  Future<void> _addSharedHoursFor(Worker worker) async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.createTimeEntry,
      arguments: {
        'group': widget.group,
        'workers': [worker],
      },
    );
    if (created == true) {
      await _load();
    }
  }

  void _replaceWorkerLocally(Worker updatedWorker) {
    setState(() {
      _workers = [
        for (final worker in _workers)
          if (worker.id == updatedWorker.id) updatedWorker else worker,
      ];
    });
  }

  Future<Worker?> _openEditWorkerDialog(
      BuildContext context, Group group, Worker worker) {
    return showModalBottomSheet<Worker>(
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

    final countLabel = '${_workers.length} ${l.membersTitle.toLowerCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        countLabel,
        style: t.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.primary,
          fontSize: 12,
        ),
      ),
    );
  }

  String _currentPeriodModeLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    switch (_periodMode) {
      case _ActiveWorkersPeriodMode.currentMonth:
        return DateFormat.yMMM(locale).format(DateTime.now());
      case _ActiveWorkersPeriodMode.yearMonth:
        return DateFormat.yMMM(locale)
            .format(DateTime(_periodYear, _periodMonth));
      case _ActiveWorkersPeriodMode.customRange:
        return _customRangeLabel(context);
    }
  }

  // ── Compact single-row workforce summary header ──────────────────────────
  Widget _buildActiveTotalsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isEs = _isSpanish(context);

    final activeWorkers =
        (_activeTotals?['activeWorkersCount'] as num?)?.toInt() ?? 0;
    final totalHours =
        (_activeTotals?['totalHours'] as num?)?.toDouble() ?? 0;
    final totalPay = (_activeTotals?['totalPay'] as num?)?.toDouble();
    final currency = _activeTotals?['currency']?.toString();
    final totalsByCurrency =
        (_activeTotals?['totalsByCurrency'] as List?) ?? const [];
    final isMultiCurrency = currency == null || totalsByCurrency.length > 1;
    final entriesCount =
        (_activeTotals?['entriesCount'] as num?)?.toInt() ?? 0;

    // ── Divider helper ───────────────────────────────────────────────────
    Widget divider() => Container(
          width: 1,
          height: 18,
          color: cs.outlineVariant.withValues(alpha: 0.3),
          margin: const EdgeInsets.symmetric(horizontal: 8),
        );

    // ── Labeled metric pill (icon · label: value) ────────────────────────
    Widget metric({
      required IconData icon,
      required String label,
      required String value,
      Color? valueColor,
      VoidCallback? onTap,
    }) {
      final content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: t.bodySmall.copyWith(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: t.bodySmall.copyWith(
              fontSize: 12,
              color: valueColor ?? cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );

      if (onTap == null) return content;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: content,
        ),
      );
    }

    // ── Cost display (handles single or multi-currency) ──────────────────
    Widget costWidget() {
      if (_activeTotalsLoading) {
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        );
      }
      if (_activeTotalsError != null && _activeTotalsError!.isNotEmpty) {
        return Tooltip(
          message: _activeTotalsError!,
          child: Icon(Icons.error_outline, color: cs.error, size: 14),
        );
      }
      if (entriesCount <= 0) {
        return Text(
          isEs ? 'Sin registros' : 'No entries',
          style: t.bodySmall.copyWith(
            fontSize: 11,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      }
      if (!isMultiCurrency && totalPay != null) {
        return metric(
          icon: Icons.payments_outlined,
          label: isEs ? 'Coste' : 'Cost',
          value: '${_toMoney(totalPay)} $currency',
          valueColor: cs.primary,
        );
      }
      // Multi-currency: show as stacked abbreviations
      final parts = totalsByCurrency
          .whereType<Map>()
          .map((item) {
            final curr = item['currency']?.toString() ?? '?';
            final pay = (item['totalPay'] as num?)?.toDouble() ?? 0;
            return '${_toMoney(pay)} $curr';
          })
          .take(2)
          .join(' · ');
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined,
              size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            parts,
            style: t.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Period picker ──────────────────────────────────────────
            GestureDetector(
              onTap: _activeTotalsLoading ? null : _pickYearMonth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: cs.primary),
                  const SizedBox(width: 5),
                  Text(
                    _currentPeriodModeLabel(context),
                    style: t.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more_rounded,
                      size: 13, color: cs.primary),
                ],
              ),
            ),

            divider(),

            // ── Labor cost ─────────────────────────────────────────────
            costWidget(),

            if (entriesCount > 0) ...[
              divider(),

              // ── Active workers ─────────────────────────────────────
              metric(
                icon: Icons.group_outlined,
                label: isEs ? 'Activos' : 'Active',
                value: '$activeWorkers',
              ),

              divider(),

              // ── Total hours ────────────────────────────────────────
              metric(
                icon: Icons.schedule_outlined,
                label: isEs ? 'Horas' : 'Hours',
                value:
                    '${totalHours % 1 == 0 ? totalHours.toInt() : totalHours.toStringAsFixed(1)} h',
              ),
            ],

            divider(),

            // ── Historial shortcut ─────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onOpenHistorial,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 13, color: cs.onSurfaceVariant),
                    const SizedBox(width: 5),
                    Text(
                      isEs ? 'Historial' : 'History',
                      style: t.bodySmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // ── Refresh ────────────────────────────────────────────────
            Tooltip(
              message: l.refresh,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _activeTotalsLoading
                    ? null
                    : _reloadActiveWorkersTotals,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _activeTotalsLoading
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.primary),
                          ),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 15, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return RefreshIndicator(
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
                            _buildActiveTotalsCard(context),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l.employeesHeader,
                                    style: t.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (!_loading &&
                                    !_pluginDisabled &&
                                    _error == null)
                                  _countChip(context),
                              ],
                            ),
                            const SizedBox(height: 10),
                            WorkerListSection(
                              workers: _workers,
                              onEdit: (w) async {
                                final updatedWorker =
                                    await _openEditWorkerDialog(
                                  context,
                                  widget.group,
                                  w,
                                );
                                if (updatedWorker != null) {
                                  _replaceWorkerLocally(updatedWorker);
                                  await _reloadActiveWorkersTotals();
                                }
                              },
                              onAddHours: _addSharedHoursFor,
                              onOpenOverview: (w) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WorkerMonthlyOverviewScreen(
                                      group: widget.group,
                                      worker: w,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
    );
  }

  Widget _buildFabsWidget(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Tooltip(
          message: l.createWorkerCta,
          child: FloatingActionButton.small(
            heroTag: 'add-worker-fab',
            onPressed: _addWorker,
            child: const Icon(Icons.person_add_alt_1),
          ),
        ),
        const SizedBox(height: 10),
        if (!_loading &&
            !_pluginDisabled &&
            _error == null &&
            _workers.isNotEmpty)
          FloatingActionButton.extended(
            heroTag: 'add-hours-fab',
            onPressed: _toggling ? null : _addSharedHours,
            icon: const Icon(Icons.schedule_outlined),
            label: Text(l.addTimeEntryCta),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (widget.embedded) {
      return Stack(
        children: [
          Positioned.fill(child: _buildBodyContent(context)),
          Positioned(
            bottom: 12,
            right: 12,
            child: _buildFabsWidget(context),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.timeTrackingTitle,
            style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.inverseSurface),
      ),
      body: _buildBodyContent(context),
      floatingActionButton: _buildFabsWidget(context),
    );
  }
}
