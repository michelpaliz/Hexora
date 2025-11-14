import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/event/model/event.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/service/service_api_client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/enum/insights_types.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/sections/bar/insights_bar_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/sections/filter/insights_filter_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/graphs/sections/past_hint/insights_past_hint.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'widgets/dimension_tabs.dart';

class GroupInsightsScreen extends StatefulWidget {
  final Group group;
  const GroupInsightsScreen({super.key, required this.group});

  @override
  State<GroupInsightsScreen> createState() => _GroupInsightsScreenState();
}

class _GroupInsightsScreenState extends State<GroupInsightsScreen> {
  bool _loading = true;
  String? _error;

  RangePreset _preset = RangePreset.m3;
  DateTimeRange? _customRange;

  Map<String, String> _clientNames = {};
  Map<String, String> _serviceNames = {};

  // Only “Clients / Services” for this screen
  Dimension _dimension = Dimension.clients;

  List<Event> _events = const [];

  @override
  void initState() {
    super.initState();
    _load();
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

    try {
      final userDomain = context.read<UserDomain>();
      final range = _resolveRange(DateTime.now());

      final endExclusive = _endExclusive(range.end);

      // 1) Unified agenda events
      final eventsFuture = userDomain.fetchWorkItems(
        groupId: widget.group.id,
        from: range.start,
        to: endExclusive, // end-exclusive
        types: const ['work_visit', 'work_service'],
      );

      // 2) Catalogs
      final clientsApi = ClientsApi();
      final servicesApi = ServiceApi();
      final clientsFuture =
          clientsApi.list(groupId: widget.group.id, active: null);
      final servicesFuture =
          servicesApi.list(groupId: widget.group.id, active: null);

      final results =
          await Future.wait([eventsFuture, clientsFuture, servicesFuture]);

      final events = results[0] as List<Event>;
      final clients = results[1] as List<dynamic>;
      final services = results[2] as List<dynamic>;

      final onlyThisGroup =
          events.where((e) => e.groupId == widget.group.id).toList();

      final clientNames = <String, String>{
        for (final c in clients)
          c.id: (c.name?.trim().isNotEmpty == true ? c.name!.trim() : c.id),
      };
      final serviceNames = <String, String>{
        for (final s in services)
          s.id: (s.name?.trim().isNotEmpty == true ? s.name!.trim() : s.id),
      };

      setState(() {
        _events = onlyThisGroup;
        _clientNames = clientNames;
        _serviceNames = serviceNames;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DateTimeRange _resolveRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_preset) {
      case RangePreset.d7:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 6)), end: today);
      case RangePreset.d30:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 29)), end: today);
      case RangePreset.m3:
        return DateTimeRange(
            start: DateTime(today.year, today.month - 3, today.day),
            end: today);
      case RangePreset.m4:
        return DateTimeRange(
            start: DateTime(today.year, today.month - 4, today.day),
            end: today);
      case RangePreset.m6:
        return DateTimeRange(
            start: DateTime(today.year, today.month - 6, today.day),
            end: today);
      case RangePreset.y1:
        return DateTimeRange(
            start: DateTime(today.year - 1, today.month, today.day),
            end: today);
      case RangePreset.ytd:
        return DateTimeRange(start: DateTime(today.year, 1, 1), end: today);
      case RangePreset.custom:
        return _customRange ??
            DateTimeRange(
                start: today.subtract(const Duration(days: 29)), end: today);
    }
  }

  Map<String, int> _aggregateMinutes(Dimension dim, DateTimeRange range) {
    final out = <String, int>{};
    for (final e in _events) {
      final start = e.startDate.toLocal();
      final end = (e.endDate).toLocal();

      final s = start.isBefore(range.start) ? range.start : start;
      final en = end.isAfter(range.end) ? range.end : end;
      if (!en.isAfter(s)) continue;

      final minutes = en.difference(s).inMinutes;
      final key = (dim == Dimension.clients)
          ? (e.clientId ?? 'unknown_client')
          : (e.primaryServiceId ?? 'unknown_service');

      out.update(key, (v) => v + minutes, ifAbsent: () => minutes);
    }
    return out;
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _resolveRange(DateTime.now()),
      helpText: l.dateRangeCustom,
    );
    if (picked != null) {
      setState(() {
        _preset = RangePreset.custom;
        _customRange = picked;
      });
      _load();
    }
  }

  Map<String, int> _sortDesc(Map<String, int> m) {
    final entries = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    final range = _resolveRange(DateTime.now());
    final minutesById = _aggregateMinutes(_dimension, range);
    final minutesLabeled = _sortDesc(_applyLabels(minutesById));
    final df = DateFormat.yMMMd(l.localeName);
    final rangeText = '${df.format(range.start)} – ${df.format(range.end)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.insightsTitle,
          style: typo.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        backgroundColor: cs.surface,
        iconTheme: IconThemeData(color: cs.onSurface),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: typo.bodySmall.copyWith(color: cs.error),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // BIG TABS (Clients / Services)
                    DimensionTabs(
                      value: _dimension,
                      onChanged: (d) => setState(() => _dimension = d),
                    ),
                    const SizedBox(height: 12),

                    // PERIOD CARD (chips + date)
                    InsightsFiltersSection(
                      preset: _preset,
                      onPresetChanged: (p) {
                        setState(() => _preset = p);
                        _load();
                      },
                      onPickCustom: () => _pickCustomRange(context),
                      rangeText: rangeText,
                    ),

                    const SizedBox(height: 16),

                    // BARS
                    InsightsBarsCard(
                      title: _dimension == Dimension.clients
                          ? l.timeByClient
                          : l.timeByService,
                      minutesByKey: minutesLabeled, // human-readable names
                    ),

                    const SizedBox(height: 24),

                    if (_preset != RangePreset.custom &&
                        _resolveRange(DateTime.now())
                            .start
                            .isBefore(DateTime.now()) &&
                        _events.isEmpty)
                      const InsightsPastDataHint(),
                  ],
                ),
    );
  }
}
