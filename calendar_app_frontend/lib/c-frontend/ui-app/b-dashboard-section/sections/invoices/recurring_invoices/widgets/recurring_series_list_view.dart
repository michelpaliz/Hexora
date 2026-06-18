import 'package:flutter/material.dart';
import 'package:hexora/b-backend/invoicing/recurring_invoices_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_filters.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_generated_panel.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_list_header.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class RecurringSeriesListView extends StatefulWidget {
  final List<Map<String, dynamic>> series;
  final List<GroupClient> clients;
  final bool canManage;
  final String statusFilter;
  final String? clientFilter;
  final bool dueSoonOnly;
  final ValueChanged<String> onStatusFilter;
  final ValueChanged<String?> onClientFilter;
  final ValueChanged<bool> onDueSoon;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onOpenSeries;
  final ValueChanged<Map<String, dynamic>> onPreviewSeries;
  final ValueChanged<Map<String, dynamic>>? onPauseSeries;
  final ValueChanged<Map<String, dynamic>>? onResumeSeries;
  final ValueChanged<Map<String, dynamic>>? onCancelSeries;
  final bool showHeader;
  final RecurringInvoicesApi? api;
  final bool receiptsMode;

  const RecurringSeriesListView({
    super.key,
    required this.series,
    required this.clients,
    required this.canManage,
    required this.statusFilter,
    required this.clientFilter,
    required this.dueSoonOnly,
    required this.onStatusFilter,
    required this.onClientFilter,
    required this.onDueSoon,
    required this.onRefresh,
    required this.onCreate,
    required this.onOpenSeries,
    required this.onPreviewSeries,
    required this.onPauseSeries,
    required this.onResumeSeries,
    required this.onCancelSeries,
    this.showHeader = true,
    this.api,
    this.receiptsMode = false,
  });

  @override
  State<RecurringSeriesListView> createState() =>
      _RecurringSeriesListViewState();
}

class _RecurringSeriesListViewState extends State<RecurringSeriesListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showInactiveClients = false;
  bool _sortByClientName = true;
  String? _frequencyFilter;
  String? _selectedSeriesId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _seriesClientId(Map<String, dynamic> series) {
    final rawClientId = series['clientId'] ??
        series['client']?['id'] ??
        series['client']?['_id'];
    if (rawClientId is Map) {
      return (rawClientId[r'$oid'] ?? '').toString();
    }
    return rawClientId?.toString();
  }

  bool _matchesSearch(
    Map<String, dynamic> series,
    Map<String, String> clientNamesById,
    AppLocalizations l,
  ) {
    String asText(dynamic value) => (value ?? '').toString();

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    final rule = series['rule'];
    final schedule = ruleSummary(rule is Map ? rule : series, l);
    final clientId = _seriesClientId(series);
    final clientName = (series['clientName'] ??
            series['client']?['name'] ??
            (clientId == null ? null : clientNamesById[clientId]) ??
            '')
        .toString();
    final haystack = <String>[
      asText(series['name']),
      clientName,
      asText(series['status']),
      asText(series['frequency'] ?? series['freq']),
      asText(series['interval']),
      asText(series['billDay']),
      asText(series['timezone']),
      schedule,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  String _seriesFrequency(Map<String, dynamic> series) {
    final rule = series['rule'];
    final rawFrequency = rule is Map
        ? (rule['frequency'] ??
            rule['freq'] ??
            series['frequency'] ??
            series['freq'])
        : (series['frequency'] ?? series['freq']);
    return normalizeFrequencyFromApi(rawFrequency?.toString());
  }

  DateTime? _nextCreationDate(Map<String, dynamic> series) {
    final rule = series['rule'];
    final candidates = [
      series['nextRunAt'],
      series['nextOccurrenceAt'],
      series['nextInvoiceAt'],
      series['nextExecutionAt'],
      series['nextAt'],
      series['nextRun'],
      series['nextDate'],
      series['upcomingAt'],
      if (rule is Map) rule['nextRunAt'],
      if (rule is Map) rule['nextOccurrenceAt'],
      if (rule is Map) rule['nextExecutionAt'],
    ];
    for (final candidate in candidates) {
      final parsed = parseDate(candidate);
      if (parsed != null) return parsed;
    }
    return null;
  }

  int _compareSeriesByNextCreation(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    Map<String, String> clientNamesById,
  ) {
    final aDate = _nextCreationDate(a);
    final bDate = _nextCreationDate(b);
    if (aDate != null && bDate != null) {
      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) return byDate;
    } else if (aDate != null) {
      return -1;
    } else if (bDate != null) {
      return 1;
    }

    final aClientId = _seriesClientId(a);
    final bClientId = _seriesClientId(b);
    final aLabel = (a['clientName'] ??
            a['client']?['name'] ??
            (aClientId == null ? null : clientNamesById[aClientId]) ??
            a['name'] ??
            '')
        .toString()
        .toLowerCase();
    final bLabel = (b['clientName'] ??
            b['client']?['name'] ??
            (bClientId == null ? null : clientNamesById[bClientId]) ??
            b['name'] ??
            '')
        .toString()
        .toLowerCase();
    return aLabel.compareTo(bLabel);
  }

  int _compareSeriesByClientName(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    Map<String, String> clientNamesById,
  ) {
    String labelFor(Map<String, dynamic> series) {
      final clientId = _seriesClientId(series);
      return (series['clientName'] ??
              series['client']?['name'] ??
              (clientId == null ? null : clientNamesById[clientId]) ??
              series['name'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();
    }

    final byClient = labelFor(a).compareTo(labelFor(b));
    if (byClient != 0) return byClient;
    return _compareSeriesByNextCreation(a, b, clientNamesById);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final statusLabels = {
      'all': l.recurringInvoicesStatusAll,
      'active': l.recurringInvoicesStatusActive,
      'paused': l.recurringInvoicesStatusPaused,
      'cancelled': l.recurringInvoicesStatusCancelled,
      'completed': l.recurringInvoicesStatusCompleted,
    };
    final statusKeys = [
      'all',
      'active',
      'paused',
      'cancelled',
      'completed',
    ];
    final statusLabelToKey = {
      for (final k in statusKeys) (statusLabels[k] ?? k): k,
    };
    final activeFilters = <String>[];
    if (widget.statusFilter != 'all') {
      activeFilters.add(
        '${l.recurringInvoicesStatusFilterLabel}: ${statusLabels[widget.statusFilter] ?? widget.statusFilter}',
      );
    }
    if (widget.clientFilter != null && widget.clientFilter!.isNotEmpty) {
      final client = widget.clients
          .where((c) => c.id == widget.clientFilter)
          .cast<GroupClient?>()
          .firstWhere((c) => c != null, orElse: () => null);
      activeFilters.add(
        '${l.recurringInvoicesClientFilterLabel}: ${client?.name ?? widget.clientFilter}',
      );
    }
    if (widget.dueSoonOnly) {
      activeFilters.add(l.recurringInvoicesDueSoon);
    }
    if (_frequencyFilter != null && _frequencyFilter!.isNotEmpty) {
      activeFilters.add(
        '${l.recurringInvoicesFrequencyLabel}: ${recurringFrequencyLabel(l, _frequencyFilter)}',
      );
    }
    if (_showInactiveClients) {
      activeFilters.add(l.showInactiveClients);
    }
    if (_sortByClientName) {
      activeFilters.add('A-Z cliente');
    }
    final activeFilterCount = (widget.statusFilter != 'all' ? 1 : 0) +
        (widget.clientFilter != null && widget.clientFilter!.isNotEmpty
            ? 1
            : 0) +
        (widget.dueSoonOnly ? 1 : 0) +
        (_frequencyFilter != null && _frequencyFilter!.isNotEmpty ? 1 : 0) +
        (_showInactiveClients ? 1 : 0) +
        (_sortByClientName ? 1 : 0);
    final clientNamesById = {
      for (final c in widget.clients) c.id: c.name,
    };
    final clientLabelToId = <String, String>{};
    final clientOptionLabels = <String>[];
    for (final c in widget.clients) {
      final name = c.name.trim();
      if (name.isEmpty || clientLabelToId.containsKey(name)) continue;
      clientLabelToId[name] = c.id;
      clientOptionLabels.add(name);
    }
    clientOptionLabels
        .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final selectedClientLabel = widget.clientFilter == null
        ? null
        : (clientNamesById[widget.clientFilter!] ?? widget.clientFilter);
    if (selectedClientLabel != null &&
        selectedClientLabel.trim().isNotEmpty &&
        !clientLabelToId.containsKey(selectedClientLabel)) {
      clientOptionLabels.insert(0, selectedClientLabel);
    }
    final activeClientIds = widget.clients
        .where((c) => c.isActive != false)
        .map((c) => c.id)
        .toSet();
    final frequencyOptions = widget.series
        .map(_seriesFrequency)
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => recurringFrequencyDropdownOrder
          .indexOf(a)
          .compareTo(recurringFrequencyDropdownOrder.indexOf(b)));
    final visibleSeries = widget.series.where((s) {
      if (!_showInactiveClients) {
        final clientId = _seriesClientId(s);
        if (clientId != null &&
            clientId.isNotEmpty &&
            !activeClientIds.contains(clientId)) {
          return false;
        }
      }
      if (_frequencyFilter != null &&
          _frequencyFilter!.isNotEmpty &&
          _seriesFrequency(s) != _frequencyFilter) {
        return false;
      }
      return _matchesSearch(s, clientNamesById, l);
    }).toList()
      ..sort(
        (a, b) => _sortByClientName
            ? _compareSeriesByClientName(a, b, clientNamesById)
            : _compareSeriesByNextCreation(a, b, clientNamesById),
      );
    final selectedSeries = visibleSeries.isEmpty
        ? null
        : visibleSeries.firstWhere(
            (s) => seriesId(s) == _selectedSeriesId,
            orElse: () => visibleSeries.first,
          );
    final selectedSeriesId =
        selectedSeries == null ? null : seriesId(selectedSeries);

    Widget buildList() {
      return visibleSeries.isEmpty
          ? Center(
              child: Text(
                l.recurringInvoicesEmpty,
                style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          : ListView.separated(
              itemCount: visibleSeries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final item = visibleSeries[i];
                return RecurringSeriesCard(
                  series: item,
                  clientNamesById: clientNamesById,
                  selected: seriesId(item) == selectedSeriesId,
                  onSelect: (series) => setState(
                    () => _selectedSeriesId = seriesId(series),
                  ),
                  onOpen: widget.onOpenSeries,
                  onPreview: widget.onPreviewSeries,
                  onPause: widget.onPauseSeries,
                  onResume: widget.onResumeSeries,
                  onCancel: widget.onCancelSeries,
                  canManage: widget.canManage,
                );
              },
            );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            RecurringSeriesListHeader(
              title: l.recurringInvoicesTitle,
              subtitle: l.recurringInvoicesSubtitle,
              onRefresh: widget.onRefresh,
              onCreate: widget.onCreate,
              canManage: widget.canManage,
              refreshLabel: l.recurringInvoicesRefreshCta,
              createLabel: l.recurringInvoicesCreateCta,
            ),
            const SizedBox(height: 8),
          ],
          RecurringSeriesFilters(
            searchController: _searchCtrl,
            onSearchChanged: () => setState(() {}),
            activeFilterCount: activeFilterCount,
            statusOptions: statusKeys
                .map((k) => statusLabels[k] ?? k)
                .toList(growable: false),
            selectedStatus:
                statusLabels[widget.statusFilter] ?? widget.statusFilter,
            onStatusSelected: (label) =>
                widget.onStatusFilter(statusLabelToKey[label] ?? 'all'),
            onStatusClear: () => widget.onStatusFilter('active'),
            clientOptions: clientOptionLabels,
            selectedClient: selectedClientLabel,
            onClientSelected: (label) {
              final id = clientLabelToId[label];
              widget.onClientFilter(id);
            },
            onClientClear: () => widget.onClientFilter(null),
            frequencyOptions: frequencyOptions,
            selectedFrequency: _frequencyFilter,
            onFrequencySelected: (value) =>
                setState(() => _frequencyFilter = value),
            onFrequencyClear: () => setState(() => _frequencyFilter = null),
            dueSoonOnly: widget.dueSoonOnly,
            onDueSoonChanged: widget.onDueSoon,
            showInactiveClients: _showInactiveClients,
            onShowInactiveChanged: (v) =>
                setState(() => _showInactiveClients = v),
            sortByClientName: _sortByClientName,
            onSortByClientNameChanged: (v) =>
                setState(() => _sortByClientName = v),
            activeFilters: activeFilters,
            onClearFilters: () {
              widget.onStatusFilter('active');
              widget.onClientFilter(null);
              widget.onDueSoon(false);
              setState(() {
                _frequencyFilter = null;
                _showInactiveClients = false;
                _sortByClientName = true;
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showPanel = widget.api != null &&
                    selectedSeries != null &&
                    constraints.maxWidth >= 1080;
                if (!showPanel) return buildList();
                return Row(
                  children: [
                    Expanded(flex: 5, child: buildList()),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: RecurringSeriesGeneratedPanel(
                        key: ValueKey('generated-$selectedSeriesId'),
                        api: widget.api!,
                        series: selectedSeries,
                        receiptsMode: widget.receiptsMode,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
