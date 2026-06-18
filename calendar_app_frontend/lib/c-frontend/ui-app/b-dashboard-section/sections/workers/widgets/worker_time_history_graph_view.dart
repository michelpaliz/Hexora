import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/a-models/group_model/worker/working_time_history.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

enum _TimeHistoryPreset {
  last7Days,
  last30Days,
  thisMonth,
  last3Months,
  custom,
}

class WorkerTimeHistoryGraphView extends StatefulWidget {
  const WorkerTimeHistoryGraphView({
    super.key,
    required this.group,
  });

  final Group group;

  @override
  State<WorkerTimeHistoryGraphView> createState() =>
      _WorkerTimeHistoryGraphViewState();
}

class _WorkerTimeHistoryGraphViewState
    extends State<WorkerTimeHistoryGraphView> {
  late final ITimeTrackingRepository _repo;
  late final UserDomain _userDomain;
  late final TooltipBehavior _tooltipBehavior;

  int _requestSerial = 0;
  bool _loading = true;
  String? _error;
  List<Worker> _workers = const <Worker>[];
  WorkingTimeHistoryResponse? _history;
  _TimeHistoryPreset _selectedPreset = _TimeHistoryPreset.last30Days;
  DateTimeRange? _customRange;
  String _selectedGranularity = 'day';
  String? _selectedWorkerId;
  bool _compareWorkers = false;

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      canShowMarker: false,
      builder: (
        dynamic data,
        dynamic point,
        dynamic series,
        int pointIndex,
        int seriesIndex,
      ) {
        if (data is _WorkerComparisonPoint) {
          return _WorkerComparisonTooltip(
            point: data,
            isSpanish: _isSpanish(context),
          );
        }
        final chartPoint = data as _WorkingTimeChartPoint;
        return _WorkingTimeTooltip(
          title: chartPoint.tooltipTitle,
          bucket: chartPoint.bucket,
          showWorkerBreakdown: _selectedWorkerId == null && !_compareWorkers,
          isSpanish: _isSpanish(context),
        );
      },
    );
    _loadData(reloadWorkers: true);
  }

  Future<String> _getToken() => _userDomain.getAuthToken();

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  DateTimeRange get _effectiveRange {
    if (_selectedPreset == _TimeHistoryPreset.custom && _customRange != null) {
      return _customRange!;
    }
    return _presetRange(_selectedPreset);
  }

  DateTimeRange _presetRange(_TimeHistoryPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (preset) {
      case _TimeHistoryPreset.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case _TimeHistoryPreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      case _TimeHistoryPreset.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: today,
        );
      case _TimeHistoryPreset.custom:
        return _customRange ??
            DateTimeRange(
              start: today.subtract(const Duration(days: 29)),
              end: today,
            );
      case _TimeHistoryPreset.last30Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
    }
  }

  DateTime _apiFrom(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _apiTo(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        23,
        59,
        59,
        999,
      );

  Future<void> _loadData({bool reloadWorkers = false}) async {
    final requestSerial = ++_requestSerial;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      final range = _effectiveRange;

      final workersFuture = (reloadWorkers || _workers.isEmpty)
          ? _repo.getWorkers(widget.group.id, token)
          : Future<List<Worker>>.value(_workers);
      final historyFuture = _repo.getWorkingTimeHistory(
        widget.group.id,
        token,
        from: _apiFrom(range.start),
        to: _apiTo(range.end),
        granularity: _selectedGranularity,
        workerId: _selectedWorkerId,
      );

      final results = await Future.wait<dynamic>([
        workersFuture,
        historyFuture,
      ]);
      if (!mounted || requestSerial != _requestSerial) return;

      final workers = List<Worker>.from(results[0] as List<Worker>)
        ..sort((a, b) => _workerLabel(a).compareTo(_workerLabel(b)));
      final history = results[1] as WorkingTimeHistoryResponse;

      final selectedWorkerId = _selectedWorkerId;
      final nextWorkerId = selectedWorkerId != null &&
              workers.any((worker) => worker.id == selectedWorkerId)
          ? selectedWorkerId
          : null;

      setState(() {
        _workers = workers;
        _history = history;
        _selectedWorkerId = nextWorkerId;
      });
    } catch (e) {
      if (!mounted || requestSerial != _requestSerial) return;
      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted && requestSerial == _requestSerial) {
        setState(() => _loading = false);
      }
    }
  }

  String _cleanError(Object error) {
    if (error is BackendApiException) {
      return error.message;
    }
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  String _workerLabel(Worker worker) {
    final name = (worker.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    final id = worker.id.trim();
    if (id.isEmpty) return 'Worker';
    final suffix = id.length <= 6 ? id : id.substring(id.length - 6);
    return 'Worker $suffix';
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _effectiveRange,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      saveText: _isSpanish(context) ? 'Aplicar' : 'Apply',
    );
    if (picked == null) return;
    setState(() {
      _selectedPreset = _TimeHistoryPreset.custom;
      _customRange = picked;
    });
    await _loadData();
  }

  Future<void> _updatePreset(_TimeHistoryPreset preset) async {
    if (_selectedPreset == preset && preset != _TimeHistoryPreset.custom)
      return;
    setState(() {
      _selectedPreset = preset;
      if (preset != _TimeHistoryPreset.custom) {
        _customRange = null;
      }
    });
    await _loadData();
  }

  Future<void> _updateGranularity(String value) async {
    if (_selectedGranularity == value) return;
    setState(() => _selectedGranularity = value);
    await _loadData();
  }

  Future<void> _updateWorker(String? workerId) async {
    final normalized =
        workerId == null || workerId.trim().isEmpty ? null : workerId.trim();
    if (_selectedWorkerId == normalized) return;
    setState(() {
      _selectedWorkerId = normalized;
      if (normalized != null) _compareWorkers = false;
    });
    await _loadData();
  }

  void _updateCompareWorkers(bool value) {
    final needsReload = value && _selectedWorkerId != null;
    setState(() {
      _compareWorkers = value;
      if (value) _selectedWorkerId = null;
    });
    if (needsReload) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _history == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _history == null) {
      return ErrorView(
        message: _error!,
        onRetry: () => _loadData(reloadWorkers: true),
      );
    }

    final history = _history;
    if (history == null) {
      return EmptyView(
        icon: Icons.bar_chart_rounded,
        title: _isSpanish(context)
            ? 'Sin datos de horas'
            : 'No working-time data yet',
        subtitle: _isSpanish(context)
            ? 'Todavia no hay historial para graficar.'
            : 'There is no history available to chart yet.',
      );
    }

    final isSpanish = _isSpanish(context);
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final materialLocalizations = MaterialLocalizations.of(context);
    final points = history.buckets
        .map(
          (bucket) => _WorkingTimeChartPoint(
            label: _bucketLabel(bucket, history.granularity, context),
            tooltipTitle: _bucketTooltipTitle(
              bucket,
              history.granularity,
              context,
            ),
            bucket: bucket,
          ),
        )
        .toList(growable: false);
    final comparingWorkers = _compareWorkers && _selectedWorkerId == null;
    final comparisonSeries = comparingWorkers
        ? _workerComparisonSeries(history: history, points: points, cs: cs)
        : const <CartesianSeries<dynamic, String>>[];
    final averageHours = history.buckets.isEmpty
        ? 0.0
        : history.totals.totalHours / history.buckets.length;

    return RefreshIndicator(
      onRefresh: () => _loadData(reloadWorkers: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.18),
                      cs.primary.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child:
                    Icon(Icons.analytics_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish
                          ? 'Graficas de horas trabajadas'
                          : 'Worked-hours graphs',
                      style: typo.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpanish
                          ? 'Analiza la evolucion de horas trabajadas por trabajador o para todo el grupo.'
                          : 'Track worked hours over time for one worker or for the whole group.',
                      style: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: isSpanish ? 'Actualizar' : 'Refresh',
                child: IconButton.filledTonal(
                  onPressed:
                      _loading ? null : () => _loadData(reloadWorkers: true),
                  icon: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Filter panel ────────────────────────────────────────
          _FilterPanel(
            workerItems: _workers,
            selectedWorkerId: _selectedWorkerId,
            compareWorkers: _compareWorkers,
            granularity: _selectedGranularity,
            selectedPreset: _selectedPreset,
            customRange: _selectedPreset == _TimeHistoryPreset.custom
                ? _customRange
                : null,
            workerLabelBuilder: _workerLabel,
            onWorkerChanged: _updateWorker,
            onCompareWorkersChanged: _updateCompareWorkers,
            onGranularityChanged: _updateGranularity,
            onPresetChanged: _updatePreset,
            onPickCustomRange: _selectCustomRange,
          ),

          const SizedBox(height: 16),

          // ── Inline progress ─────────────────────────────────────
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: cs.primary,
                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                ),
              ),
            ),

          // ── Error banner ────────────────────────────────────────
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.error_outline_rounded,
                        color: cs.error, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: typo.bodySmall.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Stats row ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: isSpanish ? 'Horas totales' : 'Total hours',
                  value: '${history.totals.totalHours.toStringAsFixed(2)} h',
                  icon: Icons.schedule_rounded,
                  background: cs.primaryContainer.withValues(alpha: 0.5),
                  foreground: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: isSpanish ? 'Entradas totales' : 'Total entries',
                  value: '${history.totals.entriesCount}',
                  icon: Icons.fact_check_outlined,
                  background: cs.secondaryContainer.withValues(alpha: 0.5),
                  foreground: cs.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: isSpanish ? 'Promedio por tramo' : 'Avg per bucket',
                  value: '${averageHours.toStringAsFixed(2)} h',
                  icon: Icons.show_chart_rounded,
                  background: cs.tertiaryContainer.withValues(alpha: 0.5),
                  foreground: cs.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: isSpanish ? 'Rango' : 'Range',
                  value:
                      '${materialLocalizations.formatShortDate(history.period.from?.toLocal() ?? _effectiveRange.start)} – ${materialLocalizations.formatShortDate(_rangeEndForDisplay(history.period.to?.toLocal()) ?? _effectiveRange.end)}',
                  icon: Icons.date_range_rounded,
                  background: cs.surfaceContainerHighest.withValues(alpha: 0.7),
                  foreground: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Chart card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bar_chart_rounded,
                          color: cs.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedWorkerId == null
                                ? (comparingWorkers
                                    ? (isSpanish
                                        ? 'Comparativa por trabajador'
                                        : 'Worker comparison')
                                    : (isSpanish
                                        ? 'Horas totales del grupo'
                                        : 'Total group hours'))
                                : (isSpanish
                                    ? 'Horas del trabajador seleccionado'
                                    : 'Selected worker hours'),
                            style: typo.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            isSpanish
                                ? 'La serie principal usa bucket.totalHours. En vista de grupo, el tooltip añade el desglose por trabajador.'
                                : 'The main series uses bucket.totalHours. In group view, the tooltip adds the worker breakdown.',
                            style: typo.bodySmall.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 24,
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
                if (!history.hasAnyHours)
                  SizedBox(
                    height: 300,
                    child: EmptyView(
                      icon: Icons.bar_chart_rounded,
                      title: isSpanish
                          ? 'Sin horas en el rango seleccionado'
                          : 'No hours in the selected range',
                      subtitle: isSpanish
                          ? 'Prueba con otro rango, otro trabajador o una granularidad distinta.'
                          : 'Try a different range, worker, or granularity.',
                    ),
                  )
                else
                  SizedBox(
                    height: 340,
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      tooltipBehavior: _tooltipBehavior,
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        labelRotation: points.length > 10 ? -45 : 0,
                        axisLine: AxisLine(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        labelStyle: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        majorTickLines: const MajorTickLines(size: 0),
                        axisLine: const AxisLine(width: 0),
                        labelFormat: '{value} h',
                        labelStyle: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        majorGridLines: MajorGridLines(
                          width: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.12),
                          dashArray: const <double>[4, 4],
                        ),
                      ),
                      legend: Legend(
                        isVisible: comparingWorkers,
                        overflowMode: LegendItemOverflowMode.wrap,
                        textStyle: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      series: <CartesianSeries<dynamic, String>>[
                        if (comparingWorkers)
                          ...comparisonSeries
                        else
                          ColumnSeries<_WorkingTimeChartPoint, String>(
                            dataSource: points,
                            xValueMapper: (point, _) => point.label,
                            yValueMapper: (point, _) => point.bucket.totalHours,
                            gradient: LinearGradient(
                              colors: [
                                cs.primary,
                                cs.primary.withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            width: 0.55,
                            borderRadius: BorderRadius.circular(6),
                            enableTooltip: true,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CartesianSeries<dynamic, String>> _workerComparisonSeries({
    required WorkingTimeHistoryResponse history,
    required List<_WorkingTimeChartPoint> points,
    required ColorScheme cs,
  }) {
    final workersById = <String, WorkingTimeHistoryBucketWorker>{};
    for (final bucket in history.buckets) {
      for (final worker in bucket.workers) {
        if (worker.workerId.trim().isEmpty) continue;
        workersById.putIfAbsent(worker.workerId, () => worker);
      }
    }
    final workers = workersById.values.toList(growable: false)
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final colors = _comparisonColors(cs);

    return [
      for (int workerIndex = 0; workerIndex < workers.length; workerIndex++)
        ColumnSeries<_WorkerComparisonPoint, String>(
          name: workers[workerIndex].displayName.trim().isEmpty
              ? workers[workerIndex].workerId
              : workers[workerIndex].displayName,
          dataSource: [
            for (int bucketIndex = 0;
                bucketIndex < history.buckets.length;
                bucketIndex++)
              _WorkerComparisonPoint.fromBucket(
                label: points[bucketIndex].label,
                tooltipTitle: points[bucketIndex].tooltipTitle,
                bucket: history.buckets[bucketIndex],
                workerId: workers[workerIndex].workerId,
                fallbackWorkerName: workers[workerIndex].displayName,
              ),
          ],
          xValueMapper: (point, _) => point.label,
          yValueMapper: (point, _) => point.totalHours,
          color: colors[workerIndex % colors.length],
          width: 0.62,
          spacing: 0.18,
          borderRadius: BorderRadius.circular(4),
          enableTooltip: true,
        ),
    ];
  }

  List<Color> _comparisonColors(ColorScheme cs) => [
        cs.primary,
        cs.tertiary,
        const Color(0xFF4DB6AC),
        const Color(0xFFFFB74D),
        const Color(0xFFBA68C8),
        const Color(0xFF81C784),
        const Color(0xFFE57373),
        const Color(0xFF64B5F6),
      ];

  String _bucketLabel(
    WorkingTimeHistoryBucket bucket,
    String granularity,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final from = bucket.from?.toLocal();
    final to = bucket.to?.toLocal();
    if (from == null) {
      return bucket.label.isNotEmpty ? bucket.label : bucket.key;
    }

    switch (granularity) {
      case 'month':
        return DateFormat.yMMM(locale).format(from);
      case 'week':
        final weekEnd = (to ?? from).subtract(const Duration(days: 1));
        return '${DateFormat('d MMM', locale).format(from)} - ${DateFormat('d MMM', locale).format(weekEnd)}';
      case 'day':
      default:
        return DateFormat('d MMM', locale).format(from);
    }
  }

  String _bucketTooltipTitle(
    WorkingTimeHistoryBucket bucket,
    String granularity,
    BuildContext context,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final from = bucket.from?.toLocal();
    final to = _rangeEndForDisplay(bucket.to?.toLocal());
    if (from == null) {
      return bucket.label.isNotEmpty ? bucket.label : bucket.key;
    }

    switch (granularity) {
      case 'month':
        return DateFormat.yMMMM(locale).format(from);
      case 'week':
        final effectiveTo = to ?? from;
        return '${DateFormat.yMMMd(locale).format(from)} - ${DateFormat.yMMMd(locale).format(effectiveTo)}';
      case 'day':
      default:
        return DateFormat.yMMMd(locale).format(from);
    }
  }

  DateTime? _rangeEndForDisplay(DateTime? value) {
    if (value == null) return null;
    if (value.hour == 0 &&
        value.minute == 0 &&
        value.second == 0 &&
        value.millisecond == 0 &&
        value.microsecond == 0) {
      return value.subtract(const Duration(days: 1));
    }
    return value;
  }
}

// ─── Filter panel ─────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.workerItems,
    required this.selectedWorkerId,
    required this.compareWorkers,
    required this.granularity,
    required this.selectedPreset,
    required this.customRange,
    required this.workerLabelBuilder,
    required this.onWorkerChanged,
    required this.onCompareWorkersChanged,
    required this.onGranularityChanged,
    required this.onPresetChanged,
    required this.onPickCustomRange,
  });

  final List<Worker> workerItems;
  final String? selectedWorkerId;
  final bool compareWorkers;
  final String granularity;
  final _TimeHistoryPreset selectedPreset;
  final DateTimeRange? customRange;
  final String Function(Worker worker) workerLabelBuilder;
  final ValueChanged<String?> onWorkerChanged;
  final ValueChanged<bool> onCompareWorkersChanged;
  final ValueChanged<String> onGranularityChanged;
  final ValueChanged<_TimeHistoryPreset> onPresetChanged;
  final VoidCallback onPickCustomRange;

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  @override
  Widget build(BuildContext context) {
    final isSpanish = _isSpanish(context);
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final localizations = MaterialLocalizations.of(context);
    final isCustom = selectedPreset == _TimeHistoryPreset.custom;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: cs.primary.withValues(alpha: 0.55), width: 1.5),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.tune_rounded,
                  size: 15, color: cs.primary.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                isSpanish ? 'Filtros' : 'Filters',
                style: typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface.withValues(alpha: 0.75),
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                label: isSpanish ? '7 dias' : 'Last 7 days',
                selected: selectedPreset == _TimeHistoryPreset.last7Days,
                onTap: () => onPresetChanged(_TimeHistoryPreset.last7Days),
              ),
              _PresetChip(
                label: isSpanish ? '30 dias' : 'Last 30 days',
                selected: selectedPreset == _TimeHistoryPreset.last30Days,
                onTap: () => onPresetChanged(_TimeHistoryPreset.last30Days),
              ),
              _PresetChip(
                label: isSpanish ? 'Este mes' : 'This month',
                selected: selectedPreset == _TimeHistoryPreset.thisMonth,
                onTap: () => onPresetChanged(_TimeHistoryPreset.thisMonth),
              ),
              _PresetChip(
                label: isSpanish ? '3 meses' : 'Last 3 months',
                selected: selectedPreset == _TimeHistoryPreset.last3Months,
                onTap: () => onPresetChanged(_TimeHistoryPreset.last3Months),
              ),
              // Custom range chip
              GestureDetector(
                onTap: onPickCustomRange,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isCustom
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCustom
                          ? cs.primary.withValues(alpha: 0.45)
                          : cs.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: isCustom
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCustom && customRange != null
                            ? '${localizations.formatShortDate(customRange!.start)} – ${localizations.formatShortDate(customRange!.end)}'
                            : (isSpanish ? 'Personalizado' : 'Custom range'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCustom
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),

          // Dropdowns
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(selectedWorkerId ?? '__all-workers__'),
                  initialValue: selectedWorkerId,
                  isExpanded: true,
                  decoration: inputDecoration.copyWith(
                    labelText: isSpanish ? 'Trabajador' : 'Worker',
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(isSpanish ? 'Todo el grupo' : 'All workers'),
                    ),
                    ...workerItems.map(
                      (worker) => DropdownMenuItem<String>(
                        value: worker.id,
                        child: Text(workerLabelBuilder(worker)),
                      ),
                    ),
                  ],
                  onChanged: onWorkerChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(granularity),
                  initialValue: granularity,
                  decoration: inputDecoration.copyWith(
                    labelText: isSpanish ? 'Granularidad' : 'Granularity',
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'day',
                      child: Text(isSpanish ? 'Dia' : 'Day'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'week',
                      child: Text(isSpanish ? 'Semana' : 'Week'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'month',
                      child: Text(isSpanish ? 'Mes' : 'Month'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return;
                    }
                    onGranularityChanged(value);
                  },
                ),
              ),
              FilterChip(
                selected: compareWorkers,
                onSelected: workerItems.isEmpty
                    ? null
                    : (value) => onCompareWorkersChanged(value),
                avatar: Icon(
                  Icons.compare_arrows_rounded,
                  size: 16,
                  color: compareWorkers ? cs.onPrimary : cs.primary,
                ),
                label: Text(
                  isSpanish ? 'Comparar trabajadores' : 'Compare workers',
                ),
                labelStyle: typo.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: compareWorkers ? cs.onPrimary : cs.onSurface,
                ),
                backgroundColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.55),
                selectedColor: cs.primary,
                checkmarkColor: cs.onPrimary,
                side: BorderSide(
                  color: compareWorkers
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Preset chip ──────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: foreground.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: foreground, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: typo.titleLarge.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: typo.bodySmall.copyWith(
              color: foreground.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart data types ─────────────────────────────────────────────────────────

class _WorkingTimeChartPoint {
  const _WorkingTimeChartPoint({
    required this.label,
    required this.tooltipTitle,
    required this.bucket,
  });

  final String label;
  final String tooltipTitle;
  final WorkingTimeHistoryBucket bucket;
}

class _WorkerComparisonPoint {
  const _WorkerComparisonPoint({
    required this.label,
    required this.tooltipTitle,
    required this.workerName,
    required this.totalHours,
    required this.entriesCount,
  });

  final String label;
  final String tooltipTitle;
  final String workerName;
  final double totalHours;
  final int entriesCount;

  factory _WorkerComparisonPoint.fromBucket({
    required String label,
    required String tooltipTitle,
    required WorkingTimeHistoryBucket bucket,
    required String workerId,
    required String fallbackWorkerName,
  }) {
    WorkingTimeHistoryBucketWorker? match;
    for (final worker in bucket.workers) {
      if (worker.workerId == workerId) {
        match = worker;
        break;
      }
    }
    return _WorkerComparisonPoint(
      label: label,
      tooltipTitle: tooltipTitle,
      workerName: (match?.displayName.trim().isNotEmpty == true)
          ? match!.displayName
          : (fallbackWorkerName.trim().isNotEmpty
              ? fallbackWorkerName
              : workerId),
      totalHours: match?.totalHours ?? 0,
      entriesCount: match?.entriesCount ?? 0,
    );
  }
}

// ─── Tooltip widget ───────────────────────────────────────────────────────────

class _WorkingTimeTooltip extends StatelessWidget {
  const _WorkingTimeTooltip({
    required this.title,
    required this.bucket,
    required this.showWorkerBreakdown,
    required this.isSpanish,
  });

  final String title;
  final WorkingTimeHistoryBucket bucket;
  final bool showWorkerBreakdown;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final workerBreakdown = List<WorkingTimeHistoryBucketWorker>.from(
      bucket.workers,
    )..sort((a, b) => b.totalHours.compareTo(a.totalHours));

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: typo.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${bucket.totalHours.toStringAsFixed(2)} h',
            style: typo.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isSpanish
                ? '${bucket.entriesCount} registros'
                : '${bucket.entriesCount} entries',
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showWorkerBreakdown && workerBreakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.3), height: 1),
            const SizedBox(height: 10),
            ...workerBreakdown.take(4).map(
                  (worker) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.displayName.trim().isEmpty
                                ? worker.workerId
                                : worker.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typo.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${worker.totalHours.toStringAsFixed(2)} h',
                          style: typo.bodySmall.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (workerBreakdown.length > 4)
              Text(
                isSpanish
                    ? '+${workerBreakdown.length - 4} mas'
                    : '+${workerBreakdown.length - 4} more',
                style: typo.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WorkerComparisonTooltip extends StatelessWidget {
  const _WorkerComparisonTooltip({
    required this.point,
    required this.isSpanish,
  });

  final _WorkerComparisonPoint point;
  final bool isSpanish;

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            point.tooltipTitle,
            style: typo.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            point.workerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${point.totalHours.toStringAsFixed(2)} h',
            style: typo.titleLarge.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isSpanish
                ? '${point.entriesCount} registros'
                : '${point.entriesCount} entries',
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
