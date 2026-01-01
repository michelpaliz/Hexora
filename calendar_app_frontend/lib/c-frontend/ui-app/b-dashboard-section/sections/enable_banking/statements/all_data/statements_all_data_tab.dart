import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../statements_controller.dart';
import '../statements_formatters.dart';
import '../statements_freshness_banner.dart';
import '../statements_shared.dart';
import 'statements_all_data_bulk.dart';
import 'statements_all_data_details.dart';
import 'statements_all_data_filters.dart';
import 'statements_all_data_skeleton.dart';
import 'statements_all_data_summary.dart';
import 'table/statements_all_data_table.dart';

class StatementsAllDataTab extends StatefulWidget {
  const StatementsAllDataTab({super.key});

  @override
  State<StatementsAllDataTab> createState() => _StatementsAllDataTabState();
}

class _StatementsAllDataTabState extends State<StatementsAllDataTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final List<int> _sizeOptions = const [50, 100, 200];
  final Set<String> _selectedIds = <String>{};
  bool _didLoad = false;
  bool _filtersCollapsed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _yearController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  int? _parseYear(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  String _dateOnly(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  Future<void> _applyFilters(StatementsController s) async {
    await s.loadAllEntries(
      year: _parseYear(_yearController.text),
      dateFrom: _fromController.text.trim().isEmpty
          ? null
          : _fromController.text.trim(),
      dateTo:
          _toController.text.trim().isEmpty ? null : _toController.text.trim(),
      page: 1,
    );
    _selectedIds.clear();
  }

  Future<void> _clearFilters(StatementsController s) async {
    _yearController.clear();
    _fromController.clear();
    _toController.clear();
    await s.loadAllEntries(
      year: null,
      dateFrom: null,
      dateTo: null,
      page: 1,
    );
    _selectedIds.clear();
  }

  Future<void> _pickFromDate(StatementsController s) async {
    final initial = _parseDate(_fromController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    _fromController.text = _dateOnly(picked);
    await _applyFilters(s);
  }

  Future<void> _pickToDate(StatementsController s) async {
    final initial = _parseDate(_toController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
    );
    if (picked == null) return;
    _toController.text = _dateOnly(picked);
    await _applyFilters(s);
  }

  Future<void> _pickRange(StatementsController s) async {
    final start = _parseDate(_fromController.text);
    final end = _parseDate(_toController.text);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: (start != null && end != null)
          ? DateTimeRange(start: start, end: end)
          : null,
      saveText: AppLocalizations.of(context)!.statementsApplyFilters,
    );
    if (picked == null) return;
    _fromController.text = _dateOnly(picked.start);
    _toController.text = _dateOnly(picked.end);
    await _applyFilters(s);
  }

  Future<void> _applyPreset(StatementsController s, DateTime from, DateTime to,
      {int? year}) async {
    _fromController.text = _dateOnly(from);
    _toController.text = _dateOnly(to);
    _yearController.text = year?.toString() ?? '';
    await _applyFilters(s);
  }

  Widget _activeFiltersChips(AppLocalizations l, StatementsController s) {
    final chips = <Widget>[];
    if (s.allEntriesYear != null) {
      chips.add(
        InputChip(
          label: Text('${l.statementsFilterYear}: ${s.allEntriesYear}'),
          onDeleted: () async {
            _yearController.clear();
            await _applyFilters(s);
          },
        ),
      );
    }
    if (s.allEntriesDateFrom != null && s.allEntriesDateFrom!.isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('${l.statementsFilterFrom}: ${s.allEntriesDateFrom}'),
          onDeleted: () async {
            _fromController.clear();
            await _applyFilters(s);
          },
        ),
      );
    }
    if (s.allEntriesDateTo != null && s.allEntriesDateTo!.isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('${l.statementsFilterTo}: ${s.allEntriesDateTo}'),
          onDeleted: () async {
            _toController.clear();
            await _applyFilters(s);
          },
        ),
      );
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: chips,
    );
  }

  String _filterSummary(AppLocalizations l, StatementsController s) {
    final parts = <String>[];
    if (s.allEntriesYear != null) {
      parts.add('${l.statementsFilterYear}: ${s.allEntriesYear}');
    }
    if (s.allEntriesDateFrom != null && s.allEntriesDateFrom!.isNotEmpty) {
      parts.add('${l.statementsFilterFrom}: ${s.allEntriesDateFrom}');
    }
    if (s.allEntriesDateTo != null && s.allEntriesDateTo!.isNotEmpty) {
      parts.add('${l.statementsFilterTo}: ${s.allEntriesDateTo}');
    }
    if (parts.isEmpty) return l.statementsFiltersNone;
    return '${l.statementsFiltersActive}: ${parts.join(' · ')}';
  }

  String? _resolveFreshnessBatchId(StatementsController s) {
    final selected = s.selectedBatchId;
    if (selected != null && selected.isNotEmpty) return selected;
    if (s.imports.isEmpty) return null;
    final first = s.imports.first;
    return (first['batchId'] ?? first['_id'] ?? first['id'])?.toString();
  }

  Map<String, String> _computeSummary(
      BuildContext context, List<Map<String, dynamic>> entries) {
    num total = 0;
    DateTime? latestDate;
    Map<String, dynamic>? latestEntry;
    for (final entry in entries) {
      final amount = StatementsShared.entryText(entry, ['amount']);
      final parsed = StatementsFormatters.parseAmount(amount);
      if (parsed != null) total += parsed;
      final dateText = StatementsShared.entryText(entry, ['valueDate', 'date']);
      final dt = DateTime.tryParse(dateText);
      if (dt != null && (latestDate == null || dt.isAfter(latestDate!))) {
        latestDate = dt;
        latestEntry = entry;
      }
    }
    final balanceText = latestEntry == null
        ? ''
        : StatementsShared.entryText(latestEntry, ['balance']);
    return {
      'totalAmount': StatementsFormatters.formatAmount(context, total),
      'lastBalance': StatementsFormatters.formatAmount(context, balanceText),
      'lastDate': latestDate == null
          ? ''
          : StatementsFormatters.formatDate(context, latestDate),
    };
  }

  Future<void> _bulkSuggest(StatementsController s, AppLocalizations l) async {
    if (_selectedIds.isEmpty) return;
    int suggestionsFound = 0;
    int linked = 0;
    final selectedEntries = s.allEntries
        .where((e) =>
            _selectedIds.contains((e['_id'] ?? e['id'])?.toString() ?? ''))
        .toList();
    for (final entry in selectedEntries) {
      final entryId = (entry['_id'] ?? entry['id'])?.toString();
      if (entryId == null || entryId.isEmpty) continue;
      final options = await s.suggestClients(entryId);
      if (options.isEmpty) continue;
      suggestionsFound++;
      final firstId =
          options.first['_id']?.toString() ?? options.first['id']?.toString();
      if (firstId != null && firstId.isNotEmpty) {
        await s.linkClient(entryId: entryId, clientId: firstId);
        linked++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l.statementsBulkSuggestResult(suggestionsFound, linked)),
        ),
      );
      await s.loadAllEntries(page: s.allEntriesPage);
    }
  }

  Future<void> _showBulkLinkDialog(StatementsController s) async {
    await s.loadClients();
    if (!mounted) return;
    String query = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = s.clients.where((c) {
              final name = c['name']?.toString().toLowerCase() ?? '';
              final legal = (c['billing'] is Map)
                  ? (c['billing'] as Map)['legalName']
                          ?.toString()
                          .toLowerCase() ??
                      ''
                  : '';
              return query.isEmpty ||
                  name.contains(query) ||
                  legal.contains(query);
            }).toList();
            return AlertDialog(
              title: Text(l.statementsBulkLinkTitle),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l.statementsSearchClients,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          setState(() => query = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    if (s.loadingClients)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (s.clientsError != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          s.clientsError!,
                          style: TextStyle(
                              color: Theme.of(dialogContext).colorScheme.error),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l.statementsNoClientsMatch),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            final id = c['id']?.toString() ??
                                c['_id']?.toString() ??
                                '';
                            final name = c['name']?.toString() ??
                                l.statementsUnnamedClient;
                            final legal = (c['billing'] is Map)
                                ? (c['billing'] as Map)['legalName']?.toString()
                                : null;
                            return ListTile(
                              title: Text(name),
                              subtitle: Text(
                                [
                                  if (legal != null && legal.isNotEmpty) legal,
                                  if (id.isNotEmpty) id
                                ].where((v) => v.isNotEmpty).join(' • '),
                              ),
                              onTap: () async {
                                Navigator.of(dialogContext).pop();
                                for (final entryId in _selectedIds) {
                                  await s.linkClient(
                                      entryId: entryId,
                                      clientId: id.isEmpty ? null : id);
                                }
                                if (!mounted) return;
                                await s.loadAllEntries(page: s.allEntriesPage);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didLoad) return;
      _didLoad = true;
      final s = context.read<StatementsController>();
      if (s.allEntries.isNotEmpty || s.loadingAllEntries) {
        return;
      }
      s.loadAllEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.watch<StatementsController>();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);

    final totalPages = s.allEntriesSize == 0
        ? 1
        : (s.allEntries.length / s.allEntriesSize).ceil().clamp(1, 9999);
    final start = (s.allEntriesPage - 1) * s.allEntriesSize;
    final end = (start + s.allEntriesSize).clamp(0, s.allEntries.length);
    final visibleEntries = (start >= 0 && start < s.allEntries.length)
        ? s.allEntries.sublist(start, end)
        : const <Map<String, dynamic>>[];
    final summary = _computeSummary(context, s.allEntries);

    if (s.allEntriesYear != null &&
        _yearController.text != s.allEntriesYear.toString()) {
      _yearController.text = s.allEntriesYear.toString();
    }
    if (s.allEntriesDateFrom != null &&
        _fromController.text != s.allEntriesDateFrom) {
      _fromController.text = s.allEntriesDateFrom ?? '';
    }
    if (s.allEntriesDateTo != null &&
        _toController.text != s.allEntriesDateTo) {
      _toController.text = s.allEntriesDateTo ?? '';
    }

    final freshnessBatchId = _resolveFreshnessBatchId(s);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_chart_outlined),
                    const SizedBox(width: 8),
                    Text(l.statementsAllDataTitle,
                        style: typography.titleLarge),
                    const Spacer(),
                    IconButton(
                      tooltip: _filtersCollapsed
                          ? l.statementsPanelExpand
                          : l.statementsPanelCollapse,
                      onPressed: () => setState(
                          () => _filtersCollapsed = !_filtersCollapsed),
                      icon: Icon(_filtersCollapsed
                          ? Icons.unfold_more
                          : Icons.unfold_less),
                    ),
                    IconButton(
                      tooltip: l.refreshAction,
                      onPressed: s.loadingAllEntries ? null : s.loadAllEntries,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                if (freshnessBatchId != null) ...[
                  const SizedBox(height: 6),
                  StatementsFreshnessBanner(
                    controller: s,
                    batchId: freshnessBatchId,
                  ),
                ],
                const SizedBox(height: 10),
                Text(l.statementsAllDataSubtitle, style: typography.bodyMedium),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final fade = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      );
                      return FadeTransition(
                        opacity: fade,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      );
                    },
                    child: _filtersCollapsed
                        ? Row(
                            key: const ValueKey('filters-compact'),
                            children: [
                              Expanded(
                                child: Text(
                                  _filterSummary(l, s),
                                  style: typography.bodySmall,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _filtersCollapsed = false),
                                icon: const Icon(Icons.tune, size: 18),
                                label: Text(l.statementsFiltersTitle),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('filters-expanded'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatementsAllDataFilters(
                                      controller: s,
                                      yearController: _yearController,
                                      fromController: _fromController,
                                      toController: _toController,
                                      onApply: () => _applyFilters(s),
                                      onClear: () => _clearFilters(s),
                                      onPickFrom: () => _pickFromDate(s),
                                      onPickTo: () => _pickToDate(s),
                                      onPickRange: () => _pickRange(s),
                                      showTitle: false,
                                    ),
                                    StatementsAllDataPresets(
                                      controller: s,
                                      onSelect: (from, to, year) =>
                                          _applyPreset(s, from, to, year: year),
                                    ),
                                    const SizedBox(height: 8),
                                    _activeFiltersChips(l, s),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              StatementsAllDataPagination(
                                controller: s,
                                sizeOptions: _sizeOptions,
                                totalPages: totalPages,
                                onSizeChanged: (value) =>
                                    s.loadAllEntries(size: value, page: 1),
                                onPrev: () => s.loadAllEntries(
                                    page: s.allEntriesPage - 1),
                                onNext: () => s.loadAllEntries(
                                    page: s.allEntriesPage + 1),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                StatementsAllDataSummary(
                  totalAmount: summary['totalAmount'] ?? '',
                  totalCount: s.allEntries.length,
                  lastBalance: summary['lastBalance'] ?? '',
                  lastBalanceDate: summary['lastDate'] ?? '',
                ),
                const SizedBox(height: 16),
                StatementsAllDataBulkBar(
                  controller: s,
                  selectedCount: _selectedIds.length,
                  onBulkSuggest: () => _bulkSuggest(s, l),
                  onBulkLink: () => _showBulkLinkDialog(s),
                  onClear: () => setState(_selectedIds.clear),
                ),
                if (_selectedIds.isNotEmpty) const SizedBox(height: 12),
                if (s.loadingAllEntries)
                  const StatementsAllDataSkeleton()
                else if (s.allEntriesError != null)
                  Text(s.allEntriesError!, style: TextStyle(color: cs.error))
                else if (s.allEntries.isEmpty)
                  Text(l.statementsAllDataEmpty)
                else
                  StatementsAllDataTable(
                    entries: visibleEntries,
                    controller: s,
                    selectedIds: _selectedIds,
                    onToggleAll: (checked) {
                      setState(() {
                        if (checked) {
                          for (final entry in visibleEntries) {
                            final id =
                                (entry['_id'] ?? entry['id'])?.toString();
                            if (id != null && id.isNotEmpty) {
                              _selectedIds.add(id);
                            }
                          }
                        } else {
                          for (final entry in visibleEntries) {
                            final id =
                                (entry['_id'] ?? entry['id'])?.toString();
                            if (id != null) _selectedIds.remove(id);
                          }
                        }
                      });
                    },
                    onToggleRow: (entryId) {
                      setState(() {
                        if (_selectedIds.contains(entryId)) {
                          _selectedIds.remove(entryId);
                        } else {
                          _selectedIds.add(entryId);
                        }
                      });
                    },
                    onShowDetails: (entry) =>
                        StatementsAllDataDetails.show(context, l, entry),
                    onSuggest: (entry) async {
                      await StatementsShared.showSuggestionsDialog(
                          context, s, entry);
                    },
                    onLink: (entry) async {
                      await StatementsShared.showClientPickerDialog(
                          context, s, entry);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
