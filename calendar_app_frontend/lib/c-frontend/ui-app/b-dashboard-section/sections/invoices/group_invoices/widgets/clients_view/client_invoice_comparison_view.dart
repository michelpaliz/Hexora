import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/client/client_invoice_stats.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ClientInvoiceComparisonView extends StatefulWidget {
  final List<GroupClient> clients;
  final GroupClient? selectedClient;
  final ValueChanged<GroupClient> onSelectClient;

  const ClientInvoiceComparisonView({
    super.key,
    required this.clients,
    required this.selectedClient,
    required this.onSelectClient,
  });

  @override
  State<ClientInvoiceComparisonView> createState() =>
      _ClientInvoiceComparisonViewState();
}

class _ClientInvoiceComparisonViewState
    extends State<ClientInvoiceComparisonView> {
  static const int _maxClients = 4;
  static const List<Color> _seriesColors = [
    Color(0xFF4FC3F7),
    Color(0xFF66BB6A),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
  ];

  final ClientsApi _clientsApi = ClientsApi();
  final TextEditingController _searchController = TextEditingController();
  final TooltipBehavior _tooltipBehavior =
      TooltipBehavior(enable: true, canShowMarker: false);

  int _selectedMonths = 12;
  int _requestVersion = 0;
  bool _loading = true;
  String? _error;
  List<String> _selectedClientIds = const [];
  Map<String, ClientInvoiceStats> _statsByClientId = const {};
  Map<String, String> _errorsByClientId = const {};

  @override
  void initState() {
    super.initState();
    _selectedClientIds = _initialSelectedClientIds();
    _loadStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClientInvoiceComparisonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final availableIds = widget.clients.map((client) => client.id).toSet();
    final filteredIds = _selectedClientIds
        .where(availableIds.contains)
        .toList(growable: false);
    if (filteredIds.length != _selectedClientIds.length) {
      _selectedClientIds = filteredIds;
    }
    if (_selectedClientIds.isEmpty && widget.clients.isNotEmpty) {
      _selectedClientIds = _initialSelectedClientIds();
      _loadStats();
    }
  }

  List<String> _initialSelectedClientIds() {
    if (widget.selectedClient != null &&
        widget.clients.any((client) => client.id == widget.selectedClient!.id)) {
      return [widget.selectedClient!.id];
    }
    if (widget.clients.isEmpty) return const [];
    return [widget.clients.first.id];
  }

  List<GroupClient> get _selectedClients {
    final selectedIds = _selectedClientIds.toSet();
    return widget.clients
        .where((client) => selectedIds.contains(client.id))
        .toList(growable: false);
  }

  List<GroupClient> get _visibleClients {
    final query = _searchController.text.trim().toLowerCase();
    final source = query.isEmpty
        ? widget.clients
        : widget.clients.where((client) {
            final haystack = <String>[
              client.name,
              client.email ?? '',
              client.phone ?? '',
              client.billing?.legalName ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          });
    final sorted = source.toList(growable: false);
    sorted.sort((a, b) {
      final aSelected = _selectedClientIds.contains(a.id);
      final bSelected = _selectedClientIds.contains(b.id);
      if (aSelected != bSelected) return aSelected ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  Future<void> _loadStats() async {
    final requestVersion = ++_requestVersion;
    final selectedClients = _selectedClients;

    if (selectedClients.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _statsByClientId = const {};
        _errorsByClientId = const {};
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await Future.wait(
      selectedClients.map(_fetchStats),
    );

    if (!mounted || requestVersion != _requestVersion) return;

    final statsByClientId = <String, ClientInvoiceStats>{};
    final errorsByClientId = <String, String>{};

    for (final result in results) {
      if (result.stats != null) {
        statsByClientId[result.client.id] = result.stats!;
      }
      if (result.error != null && result.error!.trim().isNotEmpty) {
        errorsByClientId[result.client.id] = result.error!;
      }
    }

    setState(() {
      _loading = false;
      _statsByClientId = statsByClientId;
      _errorsByClientId = errorsByClientId;
      _error = statsByClientId.isEmpty && errorsByClientId.isNotEmpty
          ? errorsByClientId.values.first
          : null;
    });
  }

  Future<_ClientStatsResult> _fetchStats(GroupClient client) async {
    try {
      final stats = await _clientsApi.getInvoiceStats(
        client.id,
        months: _selectedMonths,
      );
      return _ClientStatsResult(client: client, stats: stats);
    } catch (e) {
      return _ClientStatsResult(
        client: client,
        error: e.toString().replaceFirst('Exception: ', '').trim(),
      );
    }
  }

  void _toggleClient(GroupClient client) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final nextIds = List<String>.from(_selectedClientIds);
    if (nextIds.contains(client.id)) {
      nextIds.remove(client.id);
    } else {
      if (nextIds.length >= _maxClients) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish
                  ? 'Puedes comparar hasta $_maxClients clientes.'
                  : 'You can compare up to $_maxClients clients.',
            ),
          ),
        );
        return;
      }
      nextIds.add(client.id);
      widget.onSelectClient(client);
    }

    setState(() => _selectedClientIds = nextIds);

    if (nextIds.isNotEmpty) {
      final focused = widget.clients.cast<GroupClient?>().firstWhere(
            (item) => item?.id == nextIds.last,
            orElse: () => null,
          );
      if (focused != null) {
        widget.onSelectClient(focused);
      }
    }

    _loadStats();
  }

  Future<void> _changeRange(int months) async {
    if (_selectedMonths == months) return;
    setState(() => _selectedMonths = months);
    await _loadStats();
  }

  List<String> _monthKeys(List<GroupClient> selectedClients) {
    final keys = <String>{};
    for (final client in selectedClients) {
      final stats = _statsByClientId[client.id];
      if (stats == null) continue;
      for (final month in stats.months) {
        keys.add(month.month);
      }
    }
    final values = keys.toList(growable: false)..sort();
    return values;
  }

  List<_SeriesPoint> _seriesPoints(
    GroupClient client,
    List<String> monthKeys,
    String locale,
  ) {
    final stats = _statsByClientId[client.id];
    if (stats == null) return const [];

    final byMonth = <String, ClientInvoiceStatsMonth>{
      for (final month in stats.months) month.month: month,
    };

    return monthKeys
        .map((monthKey) {
          final month = byMonth[monthKey];
          return _SeriesPoint(
            clientName: client.name,
            monthKey: monthKey,
            label: _formatMonthLabel(monthKey, locale),
            issuedTotal: month?.issuedTotal ?? 0,
            issuedCount: month?.issuedCount ?? 0,
            draftTotal: month?.draftTotal ?? 0,
            draftCount: month?.draftCount ?? 0,
            voidTotal: month?.voidTotal ?? 0,
            voidCount: month?.voidCount ?? 0,
          );
        })
        .toList(growable: false);
  }

  String _formatMonthLabel(String rawMonth, String locale) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(rawMonth);
    if (match == null) return rawMonth;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (year == null || month == null) return rawMonth;
    return DateFormat.yMMM(locale).format(DateTime(year, month));
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 1180;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: isCompact
          ? Column(
              children: [
                SizedBox(height: 300, child: _buildSelectorPanel(context)),
                const SizedBox(height: 12),
                Expanded(child: _buildComparisonPanel(context)),
              ],
            )
          : Row(
              children: [
                SizedBox(width: 340, child: _buildSelectorPanel(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildComparisonPanel(context)),
              ],
            ),
    );
  }

  Widget _buildSelectorPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final clients = _visibleClients;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSpanish ? 'Comparar clientes' : 'Compare clients',
              style: typo.titleLarge.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSpanish
                  ? 'Selecciona hasta $_maxClients clientes para comparar sus importes emitidos.'
                  : 'Select up to $_maxClients clients to compare issued totals.',
              style: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: typo.bodySmall.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                hintText:
                    isSpanish ? 'Buscar clientes...' : 'Search clients...',
                hintStyle: typo.bodySmall.copyWith(color: cs.onSurfaceVariant),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                suffixIcon: _searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: Icon(Icons.close_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                        splashRadius: 14,
                      ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_selectedClientIds.length}/$_maxClients',
                  style: typo.bodySmall.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: clients.isEmpty
                  ? EmptyView(
                      icon: Icons.search_off_rounded,
                      title: isSpanish
                          ? 'No se encontraron clientes'
                          : 'No clients found',
                      subtitle: isSpanish
                          ? 'Prueba con otro termino de busqueda.'
                          : 'Try a different search term.',
                    )
                  : ListView.separated(
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        final selected = _selectedClientIds.contains(client.id);
                        final focused = widget.selectedClient?.id == client.id;
                        return _ClientSelectorRow(
                          client: client,
                          selected: selected,
                          focused: focused,
                          onTap: () => _toggleClient(client),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: 'EUR ',
      decimalDigits: 2,
    );
    final compactCurrency = NumberFormat.compactCurrency(
      locale: locale,
      symbol: 'EUR ',
    );
    final selectedClients = _selectedClients;

    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: selectedClients.isEmpty
            ? EmptyView(
                icon: Icons.insights_outlined,
                title: isSpanish
                    ? 'Selecciona clientes para comparar'
                    : 'Select clients to compare',
                subtitle: isSpanish
                    ? 'Usa la lista de la izquierda para abrir una comparacion mensual.'
                    : 'Use the list on the left to open a monthly comparison.',
              )
            : _error != null
                ? ErrorView(message: _error!, onRetry: _loadStats)
                : _buildLoadedComparison(
                    context,
                    selectedClients,
                    typo,
                    cs,
                    isSpanish,
                    locale,
                    currency,
                    compactCurrency,
                  ),
      ),
    );
  }

  Widget _buildLoadedComparison(
    BuildContext context,
    List<GroupClient> selectedClients,
    AppTypography typo,
    ColorScheme cs,
    bool isSpanish,
    String locale,
    NumberFormat currency,
    NumberFormat compactCurrency,
  ) {
    final monthKeys = _monthKeys(selectedClients);
    final activeClients = selectedClients
        .where((client) => _statsByClientId.containsKey(client.id))
        .toList(growable: false);
    final allSeriesEmpty = activeClients.isEmpty ||
        activeClients.every(
          (client) => !(_statsByClientId[client.id]?.hasAnyMonthlyActivity ?? false),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpanish ? 'Grafico comparativo' : 'Comparison graph',
                    style: typo.titleLarge.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSpanish
                        ? 'Los importes emitidos se comparan mes a mes usando el endpoint de estadisticas por cliente.'
                        : 'Issued totals are compared month by month using the client stats endpoint.',
                    style: typo.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _loadStats,
              tooltip: isSpanish ? 'Actualizar' : 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [6, 12, 24]
              .map(
                (months) => ChoiceChip(
                  label: Text(
                    isSpanish ? '$months meses' : '$months months',
                  ),
                  selected: _selectedMonths == months,
                  onSelected: (_) => _changeRange(months),
                ),
              )
              .toList(growable: false),
        ),
        if (_loading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            minHeight: 3,
            borderRadius: BorderRadius.circular(999),
          ),
        ],
        if (_errorsByClientId.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              isSpanish
                  ? 'Algunos clientes no pudieron cargarse. El resto de la comparacion sigue visible.'
                  : 'Some clients could not be loaded. The rest of the comparison is still visible.',
              style: typo.bodySmall.copyWith(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var index = 0; index < activeClients.length; index++)
              _ClientSummaryCard(
                client: activeClients[index],
                stats: _statsByClientId[activeClients[index].id]!,
                color: _seriesColors[index % _seriesColors.length],
                currency: currency,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
            ),
            child: allSeriesEmpty
                ? const Center(child: _ComparisonEmptyState())
                : SfCartesianChart(
                    legend: Legend(
                      isVisible: activeClients.length > 1,
                      position: LegendPosition.top,
                      textStyle: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    plotAreaBorderWidth: 0,
                    tooltipBehavior: _tooltipBehavior,
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelRotation: monthKeys.length > 8 ? -45 : 0,
                      axisLine: AxisLine(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                      labelStyle: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      majorTickLines: const MajorTickLines(size: 0),
                      axisLine: const AxisLine(width: 0),
                      numberFormat: compactCurrency,
                      labelStyle: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      majorGridLines: MajorGridLines(
                        width: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                    series: [
                      for (var index = 0; index < activeClients.length; index++)
                        LineSeries<_SeriesPoint, String>(
                          name: activeClients[index].name,
                          color: _seriesColors[index % _seriesColors.length],
                          width: 3,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            width: 6,
                            height: 6,
                          ),
                          enableTooltip: true,
                          dataSource: _seriesPoints(
                            activeClients[index],
                            monthKeys,
                            locale,
                          ),
                          xValueMapper: (point, _) => point.label,
                          yValueMapper: (point, _) => point.issuedTotal,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ClientStatsResult {
  final GroupClient client;
  final ClientInvoiceStats? stats;
  final String? error;

  const _ClientStatsResult({
    required this.client,
    this.stats,
    this.error,
  });
}

class _ClientSelectorRow extends StatelessWidget {
  final GroupClient client;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;

  const _ClientSelectorRow({
    required this.client,
    required this.selected,
    required this.focused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final email = client.email?.trim() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onTap(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: BorderSide(
                  color: selected
                      ? cs.primary
                      : cs.outlineVariant,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typo.bodySmall.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (focused) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Focus',
                            style: typo.caption.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typo.caption.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientSummaryCard extends StatelessWidget {
  final GroupClient client;
  final ClientInvoiceStats stats;
  final Color color;
  final NumberFormat currency;

  const _ClientSummaryCard({
    required this.client,
    required this.stats,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  client.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMedium.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SummaryLine(
            label: isSpanish ? 'Emitido' : 'Issued',
            value: currency.format(stats.summary.issuedTotal),
          ),
          _SummaryLine(
            label: isSpanish ? 'Facturas' : 'Invoices',
            value: '${stats.summary.issuedCount}',
          ),
          _SummaryLine(
            label: isSpanish ? 'Borradores' : 'Drafts',
            value: '${stats.summary.draftCount}',
          ),
          _SummaryLine(
            label: isSpanish ? 'Ultima emitida' : 'Last issued',
            value: stats.summary.lastIssuedAt == null
                ? '-'
                : materialLocalizations
                    .formatShortDate(stats.summary.lastIssuedAt!.toLocal()),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: typo.bodySmall.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: typo.bodySmall.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesPoint {
  final String clientName;
  final String monthKey;
  final String label;
  final double issuedTotal;
  final int issuedCount;
  final double draftTotal;
  final int draftCount;
  final double voidTotal;
  final int voidCount;

  const _SeriesPoint({
    required this.clientName,
    required this.monthKey,
    required this.label,
    required this.issuedTotal,
    required this.issuedCount,
    required this.draftTotal,
    required this.draftCount,
    required this.voidTotal,
    required this.voidCount,
  });
}

class _ComparisonEmptyState extends StatelessWidget {
  const _ComparisonEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.insights_outlined,
          size: 44,
          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 12),
        Text(
          isSpanish
              ? 'Sin actividad en el rango seleccionado'
              : 'No activity in the selected range',
          style: typo.bodyMedium.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
