import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/folder_header_action_button.dart';
import '../../widgets/folder_section_card.dart';
import '../statements_controller.dart';
import '../statements_formatters.dart';
import '../statements_shared.dart';
import 'statements_all_data_bulk.dart';
import 'statements_all_data_details.dart';
import 'statements_all_data_filters.dart';
import 'statements_all_data_skeleton.dart';
import 'table/statements_all_data_table.dart';
import 'table/statements_all_data_table_theme.dart';

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
  final Map<String, String> _noProcedeReasonsByEntryId = <String, String>{};
  double? _amountMinFilter;
  double? _amountMaxFilter;
  String _amountTypeFilter = 'all'; // all | income | expense
  bool _didLoad = false;
  bool _filtersCollapsed = false;
  bool _isSoftDarkTable = false;
  bool _autoStatementImportLoading = false;
  int _invoiceSortMode = 0; // 0=none, 1=asc, 2=desc
  static const _tableThemePrefKey = 'statements_table_soft_dark';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _yearController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    _loadTableThemePref();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didLoad) return;
      _didLoad = true;
      final s = context.read<StatementsController>();
      if (s.clients.isEmpty && !s.loadingClients) {
        s.loadClients();
      }
      if (s.allEntries.isNotEmpty || s.loadingAllEntries) {
        return;
      }
      s.loadAllEntries();
    });
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

  DateTime? _entryDate(Map<String, dynamic> entry) {
    final candidates = [
      entry['valueDate'],
      entry['date'],
      entry['createdAt'],
      entry['updatedAt'],
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      if (raw is DateTime) return raw;
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(
            raw.abs() < 1000000000000 ? raw * 1000 : raw,
            isUtc: true);
      }
      if (raw is double) {
        final v = raw.round();
        return DateTime.fromMillisecondsSinceEpoch(
            v.abs() < 1000000000000 ? v * 1000 : v,
            isUtc: true);
      }
      final s = raw.toString().trim();
      if (s.isEmpty) continue;
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed;
      if (RegExp(r'^\d+$').hasMatch(s)) {
        final v = int.tryParse(s);
        if (v != null) {
          return DateTime.fromMillisecondsSinceEpoch(
              v.abs() < 1000000000000 ? v * 1000 : v,
              isUtc: true);
        }
      }
    }
    return null;
  }

  double? _parseAmountInput(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    final direct = double.tryParse(normalized.replaceAll(',', '.'));
    if (direct != null) return direct;
    return StatementsFormatters.parseAmount(normalized)?.toDouble();
  }

  Future<void> _showAmountFilterDialog() async {
    final minController = TextEditingController(
      text: _amountMinFilter?.toStringAsFixed(2) ?? '',
    );
    final maxController = TextEditingController(
      text: _amountMaxFilter?.toStringAsFixed(2) ?? '',
    );
    var localType = _amountTypeFilter;
    String? error;

    void normalizeExpenseInputs() {
      if (localType != 'expense') return;
      final minRaw = minController.text.trim();
      final maxRaw = maxController.text.trim();
      final minVal = _parseAmountInput(minRaw);
      final maxVal = _parseAmountInput(maxRaw);
      if (minVal != null && minVal > 0) {
        minController.text = (-minVal).toStringAsFixed(2);
      }
      if (maxVal != null && maxVal > 0) {
        maxController.text = (-maxVal).toStringAsFixed(2);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final l = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l.statementsHeaderAmount),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: localType == 'all',
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.7),
                          ),
                          onSelected: (_) => setState(() => localType = 'all'),
                        ),
                        ChoiceChip(
                          label: Text(l.statementsSummaryIncome),
                          selected: localType == 'income',
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.7),
                          ),
                          onSelected: (_) =>
                              setState(() => localType = 'income'),
                        ),
                        ChoiceChip(
                          label: Text(l.statementsSummaryExpense),
                          selected: localType == 'expense',
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.7),
                          ),
                          onSelected: (_) => setState(() {
                            localType = 'expense';
                            normalizeExpenseInputs();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          error!,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      minController.clear();
                      maxController.clear();
                      localType = 'all';
                      error = null;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
                FilledButton(
                  onPressed: () {
                    normalizeExpenseInputs();
                    var min = _parseAmountInput(minController.text);
                    var max = _parseAmountInput(maxController.text);
                    if (localType == 'expense') {
                      if (min != null) min = -min.abs();
                      if (max != null) max = -max.abs();
                      if (min != null && max != null && min > max) {
                        final tmp = min;
                        min = max;
                        max = tmp;
                      }
                    }
                    final minInvalid =
                        minController.text.trim().isNotEmpty && min == null;
                    final maxInvalid =
                        maxController.text.trim().isNotEmpty && max == null;
                    if (minInvalid || maxInvalid) {
                      setState(() => error = 'Importe invalido');
                      return;
                    }
                    if (min != null && max != null && min > max) {
                      setState(
                          () => error = 'Min debe ser menor o igual a Max');
                      return;
                    }
                    this.setState(() {
                      _amountMinFilter = min;
                      _amountMaxFilter = max;
                      _amountTypeFilter = localType;
                      _selectedIds.clear();
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
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
    _yearController.text = DateTime.now().year.toString();
    _fromController.clear();
    _toController.clear();
    _amountMinFilter = null;
    _amountMaxFilter = null;
    _amountTypeFilter = 'all';
    await s.loadAllEntries(
      year: _parseYear(_yearController.text),
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
    if (_amountMinFilter != null ||
        _amountMaxFilter != null ||
        _amountTypeFilter != 'all') {
      final minLabel =
          _amountMinFilter == null ? '' : _amountMinFilter!.toStringAsFixed(2);
      final maxLabel =
          _amountMaxFilter == null ? '' : _amountMaxFilter!.toStringAsFixed(2);
      final typeLabel = _amountTypeFilter == 'income'
          ? l.statementsSummaryIncome
          : (_amountTypeFilter == 'expense'
              ? l.statementsSummaryExpense
              : 'Todos');
      chips.add(
        InputChip(
          label: Text(
            '${l.statementsHeaderAmount} ($typeLabel): ${minLabel.isEmpty ? "-inf" : minLabel} - ${maxLabel.isEmpty ? "+inf" : maxLabel}',
          ),
          onDeleted: () => setState(() {
            _amountMinFilter = null;
            _amountMaxFilter = null;
            _amountTypeFilter = 'all';
          }),
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
    if (_amountMinFilter != null ||
        _amountMaxFilter != null ||
        _amountTypeFilter != 'all') {
      final minLabel = _amountMinFilter == null
          ? '-inf'
          : _amountMinFilter!.toStringAsFixed(2);
      final maxLabel = _amountMaxFilter == null
          ? '+inf'
          : _amountMaxFilter!.toStringAsFixed(2);
      final typeLabel = _amountTypeFilter == 'income'
          ? l.statementsSummaryIncome
          : (_amountTypeFilter == 'expense'
              ? l.statementsSummaryExpense
              : 'Todos');
      parts.add(
          '${l.statementsHeaderAmount} ($typeLabel): $minLabel .. $maxLabel');
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

  int _compareInvoiceNumbers(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    String pick(Map<String, dynamic> e) {
      String? pickFirstFromList(dynamic raw) {
        if (raw is List && raw.isNotEmpty) {
          final first = raw.first?.toString().trim();
          if (first != null && first.isNotEmpty) return first;
        }
        return null;
      }

      final inv =
          (pickFirstFromList(e['invoiceNumbers']) ??
                  (e['invoiceNumber'] ?? e['invoice_number'])?.toString())
              ?.trim();
      final exp = (e['expenseNumber'] ?? e['expense_number'])
          ?.toString()
          .trim();
      if (inv != null && inv.isNotEmpty) return inv;
      if (exp != null && exp.isNotEmpty) return exp;
      return '';
    }

    final av = pick(a);
    final bv = pick(b);
    if (av.isEmpty && bv.isEmpty) return 0;
    if (av.isEmpty) return 1;
    if (bv.isEmpty) return -1;

    final ad = RegExp(r'\d+')
        .allMatches(av)
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList();
    final bd = RegExp(r'\d+')
        .allMatches(bv)
        .map((m) => int.tryParse(m.group(0) ?? '0') ?? 0)
        .toList();
    final n = ad.length < bd.length ? ad.length : bd.length;
    for (var i = 0; i < n; i++) {
      final c = ad[i].compareTo(bd[i]);
      if (c != 0) return c;
    }
    if (ad.length != bd.length) return ad.length.compareTo(bd.length);
    return av.toLowerCase().compareTo(bv.toLowerCase());
  }

  String _freshnessTooltip(
    BuildContext context,
    StatementsController s,
    AppLocalizations l,
    String? batchId,
  ) {
    final id = batchId;
    if (id == null || id.isEmpty) return l.statementsFreshnessNoData;
    final status = s.batchStatus[id];
    final statusLoading = s.loadingStatus[id] == true;
    final statusErr = s.statusError[id];

    if (!statusLoading && status == null && statusErr == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        s.fetchBatchStatus(id);
      });
    }

    if (statusLoading) return l.statementsFreshnessLoading;
    if (statusErr != null && statusErr.trim().isNotEmpty) return statusErr;
    if (status == null) return l.statementsFreshnessNoData;

    final isStale = status['stale'] == true;
    final lastDate = status['lastDate'];
    final hasLastDate = lastDate != null && lastDate.toString().isNotEmpty;
    final lastDateLabel =
        hasLastDate ? StatementsFormatters.formatDate(context, lastDate) : '';
    final daysSince = status['daysSince'];
    final daysLabel = daysSince == null
        ? ''
        : StatementsFormatters.formatCount(context, daysSince);
    return !hasLastDate
        ? l.statementsFreshnessNoData
        : isStale
            ? l.statementsFreshnessStale(lastDateLabel, daysLabel)
            : l.statementsFreshnessUpToDate(lastDateLabel);
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
      if (dt != null && (latestDate == null || dt.isAfter(latestDate))) {
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

  Future<void> _showNoProcedeDialog(Map<String, dynamic> entry) async {
    final entryId = (entry['_id'] ?? entry['id'])?.toString() ?? '';
    if (entryId.isEmpty) return;
    final initial = _noProcedeReasonsByEntryId[entryId] ?? '';
    final reasonController = TextEditingController(text: initial);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('No procede'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Indica el motivo. Este estado es solo local (UI) por ahora.',
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Motivo',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      reasonController.clear();
                      error = null;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                TextButton(
                  onPressed: () {
                    this.setState(() {
                      _noProcedeReasonsByEntryId.remove(entryId);
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Quitar marca'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
                FilledButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      setState(() => error = 'Escribe un motivo');
                      return;
                    }
                    this.setState(() {
                      _noProcedeReasonsByEntryId[entryId] = reason;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadTableThemePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _isSoftDarkTable = prefs.getBool(_tableThemePrefKey) ?? false;
      });
    } catch (_) {}
  }

  Future<void> _toggleTableTheme() async {
    setState(() {
      _isSoftDarkTable = !_isSoftDarkTable;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tableThemePrefKey, _isSoftDarkTable);
    } catch (_) {}
  }

  Future<void> _toggleAutoStatementImport(bool enabled) async {
    if (_autoStatementImportLoading) return;
    setState(() => _autoStatementImportLoading = true);
    try {
      await context.read<AuthProvider>().setAutoStatementImportEnabled(enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.autoStatementImportUpdateFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _autoStatementImportLoading = false);
      }
    }
  }

  int _sizeIndexFor(int size) {
    final direct = _sizeOptions.indexOf(size);
    if (direct >= 0) return direct;
    var best = 0;
    var bestDiff = (size - _sizeOptions.first).abs();
    for (var i = 1; i < _sizeOptions.length; i++) {
      final diff = (size - _sizeOptions[i]).abs();
      if (diff < bestDiff) {
        best = i;
        bestDiff = diff;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.watch<StatementsController>();
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final typography = AppTypography.of(context);
    final tableTheme = _isSoftDarkTable
        ? StatementsTableTheme.softDark(cs)
        : StatementsTableTheme.light(cs);

    final amountFilteredEntries = s.allEntries.where((entry) {
      if (_amountMinFilter == null &&
          _amountMaxFilter == null &&
          _amountTypeFilter == 'all') {
        return true;
      }
      final parsed = StatementsFormatters.parseAmount(
        StatementsShared.entryText(entry, ['amount']),
      );
      if (parsed == null) return false;
      if (_amountTypeFilter == 'income' && parsed <= 0) return false;
      if (_amountTypeFilter == 'expense' && parsed >= 0) return false;
      if (_amountMinFilter != null && parsed < _amountMinFilter!) return false;
      if (_amountMaxFilter != null && parsed > _amountMaxFilter!) return false;
      return true;
    }).toList(growable: false);
    final totalPages = s.allEntriesSize == 0
        ? 1
        : (amountFilteredEntries.length / s.allEntriesSize)
            .ceil()
            .clamp(1, 9999);
    final start = (s.allEntriesPage - 1) * s.allEntriesSize;
    final end =
        (start + s.allEntriesSize).clamp(0, amountFilteredEntries.length);
    final visibleEntries = (start >= 0 && start < amountFilteredEntries.length)
        ? amountFilteredEntries.sublist(start, end)
        : const <Map<String, dynamic>>[];
    final sortedEntries = [...visibleEntries]..sort((a, b) {
        if (_invoiceSortMode == 1) {
          return _compareInvoiceNumbers(a, b);
        }
        if (_invoiceSortMode == 2) {
          return -_compareInvoiceNumbers(a, b);
        }
        final aDate = _entryDate(a);
        final bDate = _entryDate(b);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
    final summary = _computeSummary(context, amountFilteredEntries);

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
    final freshnessText = _freshnessTooltip(context, s, l, freshnessBatchId);
    final summaryText = [
      l.statementsAllDataSummaryTitle,
      '${l.statementsTotalAmount}: ${summary['totalAmount'] ?? ''}',
      '${l.statementsTotalCount}: ${amountFilteredEntries.length}',
      '${l.statementsLastBalance}: ${summary['lastBalance'] ?? ''}',
      if ((summary['lastDate'] ?? '').isNotEmpty)
        l.statementsLastBalanceDate(summary['lastDate']!),
    ].join('\n');
    final infoTooltipText = '$freshnessText\n\n$summaryText';
    final freshnessStatus =
        freshnessBatchId == null ? null : s.batchStatus[freshnessBatchId];
    final freshnessIsStale = freshnessStatus?['stale'] == true;
    final autoImportEnabled =
        auth.currentUser?.autoStatementImportEnabled ?? false;
    final sizeIndex = _sizeIndexFor(s.allEntriesSize);
    final canDecSize = sizeIndex > 0;
    final canIncSize = sizeIndex < _sizeOptions.length - 1;
    final headerActions = <Widget>[
      Tooltip(
        message: infoTooltipText,
        child: FolderHeaderActionButton(
          onPressed: freshnessBatchId == null
              ? null
              : () => s.fetchBatchStatus(freshnessBatchId),
          icon: Icon(
            freshnessIsStale
                ? Icons.warning_amber_outlined
                : Icons.info_outline,
            size: 18,
            color: freshnessIsStale ? cs.error : null,
          ),
        ),
      ),
      Tooltip(
        message: _isSoftDarkTable ? 'Tema claro' : 'Tema suave oscuro',
        child: FolderHeaderActionButton(
          onPressed: _toggleTableTheme,
          icon: Icon(
            _isSoftDarkTable
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 18,
          ),
        ),
      ),
      Tooltip(
        message: autoImportEnabled
            ? '${l.autoStatementImportTitle}: ON\n${l.autoStatementImportHelper}'
            : '${l.autoStatementImportTitle}: OFF\n${l.autoStatementImportHelper}',
        child: FolderHeaderActionButton(
          onPressed: _autoStatementImportLoading
              ? null
              : () => _toggleAutoStatementImport(!autoImportEnabled),
          selected: autoImportEnabled,
          icon: _autoStatementImportLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  autoImportEnabled
                      ? Icons.sync_lock_outlined
                      : Icons.sync_disabled_outlined,
                  size: 18,
                ),
        ),
      ),
      Tooltip(
        message: _filtersCollapsed
            ? l.statementsPanelExpand
            : l.statementsPanelCollapse,
        child: FolderHeaderActionButton(
          onPressed: () =>
              setState(() => _filtersCollapsed = !_filtersCollapsed),
          icon: Icon(
            _filtersCollapsed ? Icons.unfold_more : Icons.unfold_less,
            size: 18,
          ),
        ),
      ),
      Tooltip(
        message: l.refreshAction,
        child: FolderHeaderActionButton(
          onPressed: s.loadingAllEntries ? null : s.loadAllEntries,
          icon: const Icon(Icons.refresh, size: 18),
        ),
      ),
      Tooltip(
        message: '${l.statementsPageSize}: ${s.allEntriesSize} (-)',
        child: FolderHeaderActionButton(
          onPressed: canDecSize
              ? () =>
                  s.loadAllEntries(size: _sizeOptions[sizeIndex - 1], page: 1)
              : null,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
      ),
      Tooltip(
        message: '${l.statementsPageSize}: ${s.allEntriesSize} (+)',
        child: FolderHeaderActionButton(
          onPressed: canIncSize
              ? () =>
                  s.loadAllEntries(size: _sizeOptions[sizeIndex + 1], page: 1)
              : null,
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ),
      Tooltip(
        message: l.statementsPageInfo(s.allEntriesPage, totalPages),
        child: FolderHeaderActionButton(
          onPressed: null,
          icon: Text('${s.allEntriesPage}/$totalPages'),
        ),
      ),
      Tooltip(
        message: l.statementsPrevPage,
        child: FolderHeaderActionButton(
          onPressed: s.allEntriesPage > 1
              ? () => s.loadAllEntries(page: s.allEntriesPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left, size: 18),
        ),
      ),
      Tooltip(
        message: l.statementsNextPage,
        child: FolderHeaderActionButton(
          onPressed: s.allEntriesPage < totalPages
              ? () => s.loadAllEntries(page: s.allEntriesPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right, size: 18),
        ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FolderSectionCard(
          label: l.statementsAllDataTitle,
          actions: headerActions,
          leftTabOffset: 0,
          rightTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
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
                        : Padding(
                            key: const ValueKey('filters-expanded'),
                            padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return StatementsAllDataFilters(
                                      controller: s,
                                      yearController: _yearController,
                                      fromController: _fromController,
                                      toController: _toController,
                                      onApply: () => _applyFilters(s),
                                      onClear: () => _clearFilters(s),
                                      onPickFrom: () => _pickFromDate(s),
                                      onPickTo: () => _pickToDate(s),
                                      onPickRange: () => _pickRange(s),
                                      includePresetsInline: true,
                                      onPresetSelect: (from, to, year) =>
                                          _applyPreset(
                                        s,
                                        from,
                                        to,
                                        year: year,
                                      ),
                                      showTitle: false,
                                      compact: true,
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                _activeFiltersChips(l, s),
                              ],
                            ),
                          ),
                  ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StatementsAllDataTable(
                        entries: sortedEntries,
                        controller: s,
                        selectedIds: _selectedIds,
                        tableTheme: tableTheme,
                        onMarkNoProcede: _showNoProcedeDialog,
                        noProcedeReasonForEntry: (entry) {
                          final id = (entry['_id'] ?? entry['id'])?.toString();
                          if (id == null || id.isEmpty) return null;
                          return _noProcedeReasonsByEntryId[id];
                        },
                        onAmountFilterTap: _showAmountFilterDialog,
                        amountFilterActive: _amountMinFilter != null ||
                            _amountMaxFilter != null ||
                            _amountTypeFilter != 'all',
                        onInvoiceSortTap: () => setState(() {
                          _invoiceSortMode = (_invoiceSortMode + 1) % 3;
                        }),
                        invoiceSortMode: _invoiceSortMode,
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
                            StatementsAllDataDetails.show(context, l, entry, s),
                        onSuggest: (entry) async {
                          await StatementsShared.showInvoiceSuggestionsDialog(
                              context, s, entry);
                        },
                        onLink: (entry) async {
                          await StatementsShared.showClientPickerDialog(
                              context, s, entry);
                        },
                        onLinkInvoice: (entry) async {
                          final id =
                              (entry['_id'] ?? entry['id'])?.toString() ?? '';
                          if (id.isNotEmpty) {
                            setState(() {
                              _noProcedeReasonsByEntryId.remove(id);
                            });
                          }
                          final amountText =
                              StatementsShared.entryText(entry, ['amount']);
                          final amountValue =
                              StatementsFormatters.parseAmount(amountText) ?? 0;
                          final expenseOnly = amountValue < 0;
                          await StatementsShared.showInvoiceLinkDialog(
                            context,
                            s,
                            entry,
                            expenseOnly: expenseOnly,
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
