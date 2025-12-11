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
      end: today.add(const Duration(days: 1)),
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

      // Aggregate minutes
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

      setState(() {
        _clientNames = clientNames;
        _serviceNames = serviceNames;
        _minutesByDayLabel = {
          for (final e in minutesByDay.entries)
            DateFormat.MMMd(locale).format(e.key): e.value
        };
        _minutesByDimension = _applyLabels(minutesByDimension);
        _loading = false;
      });
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InsightsFiltersSection(
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
            rangeText:
                '${DateFormat.yMMMd().format(_resolveRange(DateTime.now()).start)} – ${DateFormat.yMMMd().format(_resolveRange(DateTime.now()).end)}',
          ),
          const SizedBox(height: 12),
          DimensionTabs(
            value: _dimension,
            onChanged: _onDimensionChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (_preset != RangePreset.custom) const InsightsPastDataHint(),
                const SizedBox(height: 12),
                InsightsBarsCard(
                  title: timeByDayLabel,
                  minutesByKey: _minutesByDayLabel,
                ),
                const SizedBox(height: 16),
                InsightsBarsCard(
                  title: _dimension == Dimension.clients
                      ? l.timeByClient
                      : l.timeByService,
                  minutesByKey: _minutesByDimension,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
