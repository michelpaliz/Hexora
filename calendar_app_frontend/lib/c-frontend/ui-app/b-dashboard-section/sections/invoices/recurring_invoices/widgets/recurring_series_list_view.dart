import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_filters.dart';
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
  });

  @override
  State<RecurringSeriesListView> createState() =>
      _RecurringSeriesListViewState();
}

class _RecurringSeriesListViewState extends State<RecurringSeriesListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showInactiveClients = false;

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
      series['name'] ?? '',
      clientName,
      series['status'] ?? '',
      series['frequency'] ?? series['freq'] ?? '',
      series['interval'] ?? '',
      series['billDay'] ?? '',
      series['timezone'] ?? '',
      schedule,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
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
    if (_showInactiveClients) {
      activeFilters.add(l.showInactiveClients);
    }
    final activeFilterCount = (widget.statusFilter != 'all' ? 1 : 0) +
        (widget.clientFilter != null && widget.clientFilter!.isNotEmpty
            ? 1
            : 0) +
        (widget.dueSoonOnly ? 1 : 0) +
        (_showInactiveClients ? 1 : 0);
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
    final visibleSeries = widget.series.where((s) {
      if (!_showInactiveClients) {
        final clientId = _seriesClientId(s);
        if (clientId != null &&
            clientId.isNotEmpty &&
            !activeClientIds.contains(clientId)) {
          return false;
        }
      }
      return _matchesSearch(s, clientNamesById, l);
    }).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecurringSeriesListHeader(
            title: l.recurringInvoicesTitle,
            subtitle: l.recurringInvoicesSubtitle,
            onRefresh: widget.onRefresh,
            onCreate: widget.onCreate,
            canManage: widget.canManage,
            refreshLabel: l.recurringInvoicesRefreshCta,
            createLabel: l.recurringInvoicesCreateCta,
          ),
          const SizedBox(height: 10),
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
            dueSoonOnly: widget.dueSoonOnly,
            onDueSoonChanged: widget.onDueSoon,
            showInactiveClients: _showInactiveClients,
            onShowInactiveChanged: (v) =>
                setState(() => _showInactiveClients = v),
            activeFilters: activeFilters,
            onClearFilters: () {
              widget.onStatusFilter('active');
              widget.onClientFilter(null);
              widget.onDueSoon(false);
              setState(() => _showInactiveClients = false);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: visibleSeries.isEmpty
                ? Center(
                    child: Text(
                      l.recurringInvoicesEmpty,
                      style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleSeries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => RecurringSeriesCard(
                      series: visibleSeries[i],
                      clientNamesById: clientNamesById,
                      onOpen: widget.onOpenSeries,
                      onPreview: widget.onPreviewSeries,
                      onPause: widget.onPauseSeries,
                      onResume: widget.onResumeSeries,
                      onCancel: widget.onCancelSeries,
                      canManage: widget.canManage,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
