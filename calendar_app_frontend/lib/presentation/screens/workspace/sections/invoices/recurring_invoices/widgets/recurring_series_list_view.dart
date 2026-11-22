import 'package:flutter/material.dart';
import 'package:hexora/services/invoicing/recurring_invoices_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurrence_frequency.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurrence_time_utils.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/utils/recurring_invoices_helpers.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_filters.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_drawer.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/state/group_dashboard_state.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:provider/provider.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/widgets/recurring_series_list_view/recurring_series_list_header.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
  final bool refreshing;
  final VoidCallback onCreate;
  final ValueChanged<Map<String, dynamic>> onOpenSeries;
  final ValueChanged<Map<String, dynamic>> onPreviewSeries;
  final ValueChanged<Map<String, dynamic>>? onPauseSeries;
  final ValueChanged<Map<String, dynamic>>? onResumeSeries;
  final ValueChanged<Map<String, dynamic>>? onCancelSeries;
  final bool showHeader;
  final RecurringInvoicesApi? api;
  final bool receiptsMode;
  final int? totalSeriesCount;

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
    this.refreshing = false,
    required this.onCreate,
    required this.onOpenSeries,
    required this.onPreviewSeries,
    required this.onPauseSeries,
    required this.onResumeSeries,
    required this.onCancelSeries,
    this.showHeader = true,
    this.api,
    this.receiptsMode = false,
    this.totalSeriesCount,
  });

  @override
  State<RecurringSeriesListView> createState() =>
      _RecurringSeriesListViewState();
}

class _RecurringSeriesListViewState extends State<RecurringSeriesListView> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showInactiveClients = false;
  // The default order answers the most useful operational question first:
  // which recurrence is scheduled next.
  bool _sortByClientName = false;
  String? _frequencyFilter;
  String? _conceptFilter;
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

  /// Client name for a series: embedded name first, then the loaded client
  /// list by id. Returns null (never "-") when it cannot be resolved.
  String? _resolveClientName(
    Map<String, dynamic> series,
    Map<String, String> clientNamesById,
  ) {
    final clientId = _seriesClientId(series);
    for (final candidate in [
      series['clientName'],
      series['client'] is Map ? series['client']['name'] : null,
      clientId == null ? null : clientNamesById[clientId],
      series['billing'] is Map ? series['billing']['name'] : null,
    ]) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '-') return value;
    }
    return null;
  }

  /// Opens a generated document in the workspace (its own tab, using the
  /// existing invoice/receipt preview). Only on wide layouts, where tabs keep
  /// this list's filters, scroll and selection alive; elsewhere returns null
  /// and the drawer falls back to its inline preview.
  ValueChanged<Invoice>? _workspacePreview(BuildContext context) {
    GroupDashboardState? state;
    try {
      state = Provider.of<GroupDashboardState>(context, listen: false);
    } catch (_) {
      return null;
    }
    if (!state.isWide) return null;
    final dashboard = state;
    return (invoice) {
      if (invoice.id.trim().isEmpty) return;
      final number = invoice.invoiceNumber.trim();
      if (widget.receiptsMode) {
        dashboard.openInvoicesWorkspace(
          initialMenu: 'receipts',
          initialReceiptId: invoice.id,
          tabTitle: number.isEmpty ? null : 'Recibo $number',
        );
      } else {
        dashboard.openInvoicesWorkspace(
          initialMenu: 'invoices_issued',
          initialInvoiceId: invoice.id,
          tabTitle: number.isEmpty ? null : 'Factura $number',
        );
      }
    };
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
      asText(series['concept']),
      asText(series['description']),
      asText(series['serviceDescription']),
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
      'inactive': l.localeName.startsWith('es') ? 'Inactivas' : 'Inactive',
    };
    final statusKeys = ['all', 'active', 'inactive'];
    final statusLabelToKey = {
      for (final k in statusKeys) (statusLabels[k] ?? k): k,
    };
    final activeFilterCount = (widget.statusFilter != 'all' ? 1 : 0) +
        (widget.clientFilter != null && widget.clientFilter!.isNotEmpty
            ? 1
            : 0) +
        (widget.dueSoonOnly ? 1 : 0) +
        (_frequencyFilter != null && _frequencyFilter!.isNotEmpty ? 1 : 0) +
        (_conceptFilter != null && _conceptFilter!.isNotEmpty ? 1 : 0) +
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
    final conceptOptions = widget.series
        .map((s) => (s['name'] ?? s['concept'] ?? s['description'] ?? '')
            .toString()
            .trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
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
      if (_conceptFilter != null &&
          _conceptFilter!.isNotEmpty &&
          !(s['name'] ?? s['concept'] ?? s['description'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_conceptFilter!.toLowerCase())) {
        return false;
      }
      return _matchesSearch(s, clientNamesById, l);
    }).toList()
      ..sort(
        (a, b) => _sortByClientName
            ? _compareSeriesByClientName(a, b, clientNamesById)
            : _compareSeriesByNextCreation(a, b, clientNamesById),
      );
    // Do not select the first row implicitly. The default view is a browsable
    // table; details only appear after the user explicitly selects a row.
    final selectedSeries = _selectedSeriesId == null
        ? null
        : visibleSeries.cast<Map<String, dynamic>?>().firstWhere(
              (s) => s != null && seriesId(s) == _selectedSeriesId,
              orElse: () => null,
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
              key: const PageStorageKey<String>('recurring-series-list'),
              itemCount: visibleSeries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (_, i) {
                final item = visibleSeries[i];
                final clientName =
                    _resolveClientName(item, clientNamesById) ?? '-';
                final concept = (item['name'] ??
                        item['concept'] ??
                        item['description'] ??
                        '-')
                    .toString();
                final next = _nextCreationDate(item);
                final dateLabel = next == null
                    ? '-'
                    : DateFormat.yMMMd(l.localeName).format(next);
                final status = (item['status'] ?? 'active').toString();
                final statusLabel = status == 'paused'
                    ? (l.localeName.startsWith('es') ? 'Pausada' : 'Paused')
                    : status == 'cancelled'
                        ? (l.localeName.startsWith('es')
                            ? 'Cancelada'
                            : 'Cancelled')
                        : l.recurringInvoicesStatusActive;
                final selected = seriesId(item) == selectedSeriesId;
                final bg =
                    selected ? cs.surface : cs.surface.withValues(alpha: 0.001);
                return InkWell(
                  onTap: () =>
                      setState(() => _selectedSeriesId = seriesId(item)),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border(
                        bottom: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: .35)),
                        left: BorderSide(
                          color: selected ? cs.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(children: [
                      Expanded(
                          flex: 3,
                          child: Text(clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700))),
                      Expanded(
                          flex: 3,
                          child: Text(concept,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall)),
                      Expanded(
                          flex: 2,
                          child: Text(
                              recurringFrequencyLabel(
                                  l, _seriesFrequency(item)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall)),
                      Expanded(
                          flex: 2,
                          child: Text(dateLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall)),
                      SizedBox(
                          width: 100,
                          child: Text(seriesTotal(context, item),
                              textAlign: TextAlign.right,
                              style: t.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700))),
                      SizedBox(
                          width: 100,
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: status == 'active'
                                          ? cs.primaryContainer
                                          : cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(statusLabel,
                                      style: t.caption.copyWith(
                                          color: status == 'active'
                                              ? cs.onPrimaryContainer
                                              : cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w700))))),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                    ]),
                  ),
                );
              },
            );
    }

    final filters = RecurringSeriesFilters(
      searchController: _searchCtrl,
      onSearchChanged: () => setState(() {}),
      activeFilterCount: activeFilterCount,
      statusOptions:
          statusKeys.map((k) => statusLabels[k] ?? k).toList(growable: false),
      selectedStatus: statusLabels[widget.statusFilter] ?? widget.statusFilter,
      onStatusSelected: (label) =>
          widget.onStatusFilter(statusLabelToKey[label] ?? 'all'),
      onStatusClear: () => widget.onStatusFilter('all'),
      clientOptions: clientOptionLabels,
      selectedClient: selectedClientLabel,
      onClientSelected: (label) {
        final id = clientLabelToId[label];
        widget.onClientFilter(id);
      },
      onClientClear: () => widget.onClientFilter(null),
      frequencyOptions: frequencyOptions,
      selectedFrequency: _frequencyFilter,
      onFrequencySelected: (value) => setState(() => _frequencyFilter = value),
      onFrequencyClear: () => setState(() => _frequencyFilter = null),
      dueSoonOnly: widget.dueSoonOnly,
      onDueSoonChanged: widget.onDueSoon,
      showInactiveClients: _showInactiveClients,
      onShowInactiveChanged: (v) => setState(() => _showInactiveClients = v),
      sortByClientName: _sortByClientName,
      onSortByClientNameChanged: (v) => setState(() => _sortByClientName = v),
      onClearFilters: () {
        widget.onStatusFilter('all');
        widget.onClientFilter(null);
        widget.onDueSoon(false);
        setState(() {
          _frequencyFilter = null;
          _conceptFilter = null;
          _showInactiveClients = false;
        });
      },
      onRefresh: widget.onRefresh,
      refreshing: widget.refreshing,
      onCreate: widget.onCreate,
      canManage: widget.canManage,
      visibleCount: visibleSeries.length,
      totalCount: widget.totalSeriesCount ?? widget.series.length,
    );

    Widget buildTablePane() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            filters,
            const SizedBox(height: 8),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: cs.surfaceContainerHighest.withValues(alpha: .55),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: _RecurringHeaderCell(
                        label: l.clientLabel,
                        active: widget.clientFilter != null,
                        options: clientOptionLabels,
                        selected: selectedClientLabel,
                        onSelected: (value) =>
                            widget.onClientFilter(clientLabelToId[value]),
                        onClear: () => widget.onClientFilter(null))),
                Expanded(
                    flex: 3,
                    child: _RecurringHeaderCell(
                        label: l.localeName.startsWith('es')
                            ? 'Concepto'
                            : 'Concept',
                        active: _conceptFilter != null,
                        options: conceptOptions,
                        selected: _conceptFilter,
                        onSelected: (value) =>
                            setState(() => _conceptFilter = value),
                        onClear: () => setState(() => _conceptFilter = null))),
                Expanded(
                    flex: 2,
                    child: _RecurringHeaderCell(
                        label: l.localeName.startsWith('es')
                            ? 'Frecuencia'
                            : 'Frequency',
                        active: _frequencyFilter != null,
                        options: frequencyOptions
                            .map((value) => recurringFrequencyLabel(l, value))
                            .toList(),
                        selected: _frequencyFilter == null
                            ? null
                            : recurringFrequencyLabel(l, _frequencyFilter!),
                        onSelected: (value) => setState(() => _frequencyFilter =
                            frequencyOptions.firstWhere((option) =>
                                recurringFrequencyLabel(l, option) == value)),
                        onClear: () =>
                            setState(() => _frequencyFilter = null))),
                Expanded(
                    flex: 2,
                    child: _RecurringHeaderCell(
                        label: l.localeName.startsWith('es')
                            ? 'Próxima emisión'
                            : 'Next issue',
                        active: widget.dueSoonOnly,
                        options: [
                          l.localeName.startsWith('es')
                              ? 'Próximos 7 días'
                              : 'Next 7 days'
                        ],
                        selected: widget.dueSoonOnly
                            ? (l.localeName.startsWith('es')
                                ? 'Próximos 7 días'
                                : 'Next 7 days')
                            : null,
                        onSelected: (_) => widget.onDueSoon(true),
                        onClear: () => widget.onDueSoon(false))),
                SizedBox(
                    width: 100,
                    child: Text(
                        l.localeName.startsWith('es') ? 'Importe' : 'Amount',
                        textAlign: TextAlign.right,
                        style:
                            t.caption.copyWith(fontWeight: FontWeight.w700))),
                SizedBox(
                    width: 100,
                    child: _RecurringHeaderCell(
                        label:
                            l.localeName.startsWith('es') ? 'Estado' : 'Status',
                        active: widget.statusFilter != 'all',
                        options: statusKeys
                            .map((key) => statusLabels[key] ?? key)
                            .toList(),
                        selected: statusLabels[widget.statusFilter],
                        onSelected: (value) => widget
                            .onStatusFilter(statusLabelToKey[value] ?? 'all'),
                        onClear: () => widget.onStatusFilter('all'),
                        alignEnd: true)),
                const SizedBox(width: 26),
              ]),
            ),
            const SizedBox(height: 2),
            Expanded(child: buildList()),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
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
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final drawerWidth = constraints.maxWidth < 720
                  ? constraints.maxWidth
                  : constraints.maxWidth.clamp(420.0, 480.0);
              return Stack(children: [
                buildTablePane(),
                if (selectedSeries != null)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: drawerWidth,
                        child: RecurringSeriesDrawer(
                          key: ValueKey('recurring-drawer-$selectedSeriesId'),
                          series: selectedSeries,
                          clientName: _resolveClientName(
                              selectedSeries, clientNamesById),
                          client: widget.clients
                              .where((client) =>
                                  client.id == _seriesClientId(selectedSeries))
                              .firstOrNull,
                          frequencyLabel: recurringFrequencyLabel(
                              l, _seriesFrequency(selectedSeries)),
                          nextIssueDate: _nextCreationDate(selectedSeries),
                          canManage: widget.canManage,
                          onClose: () =>
                              setState(() => _selectedSeriesId = null),
                          onEdit: () => widget.onOpenSeries(selectedSeries),
                          onPreviewUpcoming: () =>
                              widget.onPreviewSeries(selectedSeries),
                          onPause: widget.onPauseSeries == null
                              ? null
                              : () => widget.onPauseSeries!(selectedSeries),
                          onResume: widget.onResumeSeries == null
                              ? null
                              : () => widget.onResumeSeries!(selectedSeries),
                          onCancel: widget.onCancelSeries == null
                              ? null
                              : () => widget.onCancelSeries!(selectedSeries),
                          api: widget.api,
                          receiptsMode: widget.receiptsMode,
                          onPreviewInvoice: _workspacePreview(context),
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ),
        ],
      ),
    );
  }
}

class _RecurringHeaderCell extends StatelessWidget {
  const _RecurringHeaderCell({
    required this.label,
    required this.active,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onClear,
    this.alignEnd = false,
  });

  final String label;
  final bool active;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return PopupMenuButton<String>(
      tooltip: 'Filter $label',
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value != '__clear__') onSelected(value);
      },
      itemBuilder: (context) => [
        if (active)
          PopupMenuItem<String>(
            value: '__clear__',
            onTap: onClear,
            child: const Text('Clear filter'),
          ),
        ...options.map((option) => PopupMenuItem<String>(
              value: option,
              child: Text(option, maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(
                      color: active ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 3),
            Icon(Icons.filter_list_rounded,
                size: 13, color: active ? cs.primary : cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
