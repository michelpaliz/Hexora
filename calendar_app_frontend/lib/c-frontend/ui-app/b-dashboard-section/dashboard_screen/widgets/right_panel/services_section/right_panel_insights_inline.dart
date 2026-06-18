import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/b-backend/user/domain/user_agenda_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/enum/insights_types.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/sections/bar/insights_bar_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/sections/filter/insights_filter_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/sections/past_hint/insights_past_hint.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/widgets/dimension_tabs.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InsightsInlinePanel extends StatefulWidget {
  final Group group;

  const InsightsInlinePanel({super.key, required this.group});

  @override
  State<InsightsInlinePanel> createState() => _InsightsInlinePanelState();
}

class _InsightsInlinePanelState extends State<InsightsInlinePanel> {
  bool _loading = true;
  String? _error;

  RangePreset _preset = RangePreset.m3;
  DateTimeRange? _customRange;

  Map<String, String> _clientNames = {};
  Map<String, String> _serviceNames = {};

  Dimension _dimension = Dimension.clients;

  Map<String, int> _minutesByDayLabel = const {};
  Map<String, int> _minutesByDimension = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTimeRange _resolveRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    switch (_preset) {
      case RangePreset.d7:
        start = today.subtract(const Duration(days: 7));
        break;
      case RangePreset.d30:
        start = today.subtract(const Duration(days: 30));
        break;
      case RangePreset.m3:
        start = DateTime(today.year, today.month - 3, today.day);
        break;
      case RangePreset.m4:
        start = DateTime(today.year, today.month - 4, today.day);
        break;
      case RangePreset.m6:
        start = DateTime(today.year, today.month - 6, today.day);
        break;
      case RangePreset.y1:
        start = DateTime(today.year - 1, today.month, today.day);
        break;
      case RangePreset.ytd:
        start = DateTime(today.year, 1, 1);
        break;
      case RangePreset.custom:
        final custom = _customRange;
        if (custom != null) return custom;
        start = today.subtract(const Duration(days: 30));
        break;
    }
    return DateTimeRange(
      start: start,
      end: today,
    );
  }

  Map<String, String> _idToLabelMap() =>
      _dimension == Dimension.clients ? _clientNames : _serviceNames;

  Map<String, int> _applyLabels(Map<String, int> minutesById) {
    final names = _idToLabelMap();
    return {
      for (final e in minutesById.entries) (names[e.key] ?? e.key): e.value,
    };
  }

  DateTime _endExclusive(DateTime d) =>
      DateTime(d.year, d.month, d.day).add(const Duration(days: 1));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final locale =
        WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();

    try {
      final agenda = context.read<UserAgendaDomain>();
      final range = _resolveRange(DateTime.now());
      final endExclusive = _endExclusive(range.end);

      final eventsFuture = agenda.fetchWorkItems(
        groupId: widget.group.id,
        from: range.start,
        to: endExclusive,
        types: const ['work_visit', 'work_service'],
      );

      final clientsApi = ClientsApi();
      final servicesApi = ServiceApi();
      final clientsFuture =
          clientsApi.list(groupId: widget.group.id, active: null);
      final servicesFuture =
          servicesApi.list(groupId: widget.group.id, active: null);

      final results =
          await Future.wait([eventsFuture, clientsFuture, servicesFuture]);

      final events = results[0] as List<dynamic>;
      final clients = results[1] as List<dynamic>;
      final services = results[2] as List<dynamic>;

      final onlyThisGroup = events
          .where((e) => (e as dynamic).groupId == widget.group.id)
          .toList();

      final clientNames = <String, String>{
        for (final c in clients)
          c.id: (c.name?.trim().isNotEmpty == true ? c.name!.trim() : c.id),
      };
      final serviceNames = <String, String>{
        for (final s in services)
          s.id: (s.name?.trim().isNotEmpty == true ? s.name!.trim() : s.id),
      };

      final minutesByDay = <DateTime, int>{};
      final minutesByDimension = <String, int>{};
      for (final raw in onlyThisGroup) {
        final e = raw as dynamic;
        final start = (e.startDate ?? e.start) as DateTime?;
        final end = (e.endDate ?? e.end) as DateTime?;
        if (start == null || end == null) continue;

        final s = start.toLocal();
        final en = end.toLocal();
        if (!en.isAfter(s)) continue;

        final minutes = en.difference(s).inMinutes;
        final dayKey = DateTime(s.year, s.month, s.day);
        minutesByDay[dayKey] = (minutesByDay[dayKey] ?? 0) + minutes;

        final id = _dimension == Dimension.clients
            ? (e.clientId as String?)
            : ((e.primaryServiceId ?? e.serviceId) as String?);
        if (id != null && id.isNotEmpty) {
          minutesByDimension[id] = (minutesByDimension[id] ?? 0) + minutes;
        }
      }

      if (!mounted) return;
      setState(() {
        _clientNames = clientNames;
        _serviceNames = serviceNames;
        _minutesByDayLabel = {
          for (final e in minutesByDay.entries)
            DateFormat.MMMd(locale).format(e.key): e.value,
        };
        _minutesByDimension = _applyLabels(minutesByDimension);
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

  void _onPresetChange(RangePreset preset) {
    setState(() {
      _preset = preset;
      if (preset != RangePreset.custom) _customRange = null;
    });
    _load();
  }

  void _onCustomRange(DateTimeRange? range) {
    if (range == null) return;
    setState(() {
      _preset = RangePreset.custom;
      _customRange = range;
    });
    _load();
  }

  void _onDimensionChanged(Dimension d) {
    setState(() => _dimension = d);
    _load();
  }

  String _formatMinutesLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Widget _summaryStatCard({
    required ColorScheme cs,
    required TextTheme tt,
    required IconData icon,
    required String label,
    required String value,
    Color? accent,
    double? progress,
  }) {
    final tone = accent ?? cs.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent stripe
              Container(
                width: 4,
                color: tone.withValues(alpha: 0.7),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 17, color: tone),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                fontSize: 11,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: cs.onSurface,
                                height: 1.1,
                              ),
                            ),
                            if (progress != null) ...[
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 3,
                                  backgroundColor: cs.outlineVariant
                                      .withValues(alpha: 0.25),
                                  valueColor:
                                      AlwaysStoppedAnimation(tone),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(
    BuildContext context, {
    required ColorScheme cs,
    required TextTheme tt,
    required int totalMinutes,
    required int trackedDays,
    required String averageLabel,
    required String topBucketLabel,
    required String topBucketValue,
    required int topBucketMinutes,
  }) {
    final isEs =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'es';
    final topProgress = totalMinutes == 0
        ? 0.0
        : topBucketMinutes / totalMinutes;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient accent strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.35),
                  cs.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEs ? 'Resumen del periodo' : 'Period summary',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        isEs
                            ? 'Carga y distribución del trabajo'
                            : 'Workload & distribution',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stat cards
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _summaryStatCard(
                  cs: cs,
                  tt: tt,
                  icon: Icons.schedule_rounded,
                  label: isEs ? 'Tiempo total' : 'Total time',
                  value: _formatMinutesLabel(totalMinutes),
                ),
                const SizedBox(height: 8),
                _summaryStatCard(
                  cs: cs,
                  tt: tt,
                  icon: Icons.today_rounded,
                  label: isEs ? 'Días con actividad' : 'Active days',
                  value: '$trackedDays',
                  accent: cs.secondary,
                ),
                const SizedBox(height: 8),
                _summaryStatCard(
                  cs: cs,
                  tt: tt,
                  icon: Icons.auto_graph_rounded,
                  label: isEs ? 'Promedio diario' : 'Daily average',
                  value: averageLabel,
                  accent: cs.tertiary,
                ),
                const SizedBox(height: 8),
                _summaryStatCard(
                  cs: cs,
                  tt: tt,
                  icon: _dimension == Dimension.clients
                      ? Icons.people_alt_outlined
                      : Icons.build_circle_outlined,
                  label: isEs
                      ? (_dimension == Dimension.clients
                          ? 'Cliente destacado'
                          : 'Servicio destacado')
                      : (_dimension == Dimension.clients
                          ? 'Top client'
                          : 'Top service'),
                  value: topBucketLabel.isEmpty
                      ? (isEs ? 'Sin datos' : 'No data')
                      : '$topBucketLabel · $topBucketValue',
                  accent: const Color(0xFFE8A23A),
                  progress: topBucketLabel.isEmpty ? null : topProgress,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarCard(
    BuildContext context, {
    required ColorScheme cs,
    required bool showPastHint,
  }) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final isEs = l.localeName.startsWith('es');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DimensionTabs(
              value: _dimension,
              onChanged: _onDimensionChanged,
            ),
          ),
          if (showPastHint) ...[
            const SizedBox(width: 16),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEs
                            ? 'Mostrando solo datos futuros.'
                            : 'Showing only future data.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: t.bodySmall),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _load,
              child: Text(l.refresh),
            ),
          ],
        ),
      );
    }

    final timeByDayLabel =
        l.localeName.startsWith('es') ? 'Tiempo por día' : 'Time by day';
    final range = _resolveRange(DateTime.now());
    final rangeText =
        '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}';
    final totalMinutes = _minutesByDayLabel.values.fold<int>(0, (a, b) => a + b);
    final trackedDays = _minutesByDayLabel.values.where((m) => m > 0).length;
    final averageLabel = trackedDays == 0
        ? '0m'
        : _formatMinutesLabel((totalMinutes / trackedDays).round());
    final sortedDimensionEntries = _minutesByDimension.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topBucket =
        sortedDimensionEntries.isEmpty ? null : sortedDimensionEntries.first;

    final filterCard = InsightsFiltersSection(
      preset: _preset,
      onPresetChanged: _onPresetChange,
      onPickCustom: () async {
        final now = DateTime.now();
        final initialRange = _resolveRange(now);
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year, now.month, now.day),
          initialDateRange: initialRange,
        );
        _onCustomRange(picked);
      },
      rangeText: rangeText,
    );

    final toolbarCard = _buildToolbarCard(
      context,
      cs: cs,
      showPastHint: _preset != RangePreset.custom,
    );

    final dayCard = InsightsBarsCard(
      title: timeByDayLabel,
      minutesByKey: _minutesByDayLabel,
    );
    final dimensionCard = InsightsBarsCard(
      title: _dimension == Dimension.clients ? l.timeByClient : l.timeByService,
      minutesByKey: _minutesByDimension,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1180;

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      toolbarCard,
                      const SizedBox(height: 16),
                      filterCard,
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: dayCard),
                            const SizedBox(width: 16),
                            Expanded(child: dimensionCard),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 370,
                  child: _buildSummaryPanel(
                    context,
                    cs: cs,
                    tt: tt,
                    totalMinutes: totalMinutes,
                    trackedDays: trackedDays,
                    averageLabel: averageLabel,
                    topBucketLabel: topBucket?.key ?? '',
                    topBucketValue: topBucket == null
                        ? ''
                        : _formatMinutesLabel(topBucket.value),
                    topBucketMinutes: topBucket?.value ?? 0,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              filterCard,
              const SizedBox(height: 12),
              _buildSummaryPanel(
                context,
                cs: cs,
                tt: tt,
                totalMinutes: totalMinutes,
                trackedDays: trackedDays,
                averageLabel: averageLabel,
                topBucketLabel: topBucket?.key ?? '',
                topBucketValue:
                    topBucket == null ? '' : _formatMinutesLabel(topBucket.value),
                topBucketMinutes: topBucket?.value ?? 0,
              ),
              const SizedBox(height: 12),
              toolbarCard,
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (_preset != RangePreset.custom) const InsightsPastDataHint(),
                    const SizedBox(height: 12),
                    dayCard,
                    const SizedBox(height: 16),
                    dimensionCard,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
