import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/auth/auth_services/auth_provider.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/folder_section_card.dart';
import '../statements_controller.dart';
import '../statements_formatters.dart';
import '../statements_shared.dart';
import 'statements_all_data_bulk.dart';
import 'statements_all_data_details.dart';
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
  final TextEditingController _clientProviderController =
      TextEditingController();
  final List<int> _sizeOptions = const [50, 100, 200];
  final Set<String> _selectedIds = <String>{};
  final Map<String, String> _noProcedeReasonsByEntryId = <String, String>{};
  double? _amountMinFilter;
  double? _amountMaxFilter;
  String _amountTypeFilter = 'all'; // all | income | expense
  bool _didLoad = false;
  bool _isSoftDarkTable = false;
  bool _autoStatementImportLoading = false;
  bool _exportingExcel = false;
  int _invoiceSortMode = 0; // 0=none, 1=asc, 2=desc
  static const _tableThemePrefKey = 'statements_table_soft_dark';

  void _repairHotReloadState() {
    final self = this as dynamic;
    self._amountTypeFilter ??= 'all';
    self._didLoad ??= false;
    self._isSoftDarkTable ??= false;
    self._autoStatementImportLoading ??= false;
    self._exportingExcel ??= false;
    self._invoiceSortMode ??= 0;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void reassemble() {
    _repairHotReloadState();
    super.reassemble();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _clientProviderController.removeListener(_onClientProviderTyped);
    _clientProviderController.dispose();
    super.dispose();
  }

  void _onClientProviderTyped() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    _clientProviderController.addListener(_onClientProviderTyped);
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

  bool _entryMatchesDateFilters(Map<String, dynamic> entry) {
    final year = _parseYear(_yearController.text);
    final from = _parseDate(_fromController.text);
    final to = _parseDate(_toController.text);
    if (year == null && from == null && to == null) return true;
    final date = _entryDate(entry);
    if (date == null) return false;
    final localDate = DateTime(date.year, date.month, date.day);
    if (year != null && localDate.year != year) return false;
    if (from != null) {
      final start = DateTime(from.year, from.month, from.day);
      if (localDate.isBefore(start)) return false;
    }
    if (to != null) {
      final end = DateTime(to.year, to.month, to.day);
      if (localDate.isAfter(end)) return false;
    }
    return true;
  }

  String _clientProviderLabel(
    AppLocalizations l,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    final label = StatementsSharedUtils.clientLabel(l, s, entry).trim();
    if (label.isNotEmpty && label != '-') return label;
    for (final key in const [
      'providerName',
      'provider',
      'supplierName',
      'merchantName',
      'counterpartyName',
      'counterparty',
      'clientName',
      'billingName',
    ]) {
      final value = entry[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _entryMatchesClientProviderFilter(
    AppLocalizations l,
    StatementsController s,
    Map<String, dynamic> entry,
  ) {
    final query = _clientProviderController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    final label = _clientProviderLabel(l, s, entry).toLowerCase();
    if (label.contains(query)) return true;
    final description =
        StatementsShared.entryText(entry, ['description']).trim().toLowerCase();
    return description.contains(query);
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

    var applied = false;
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
                    applied = true;
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
    if (applied && mounted) {
      await _applyFilters(context.read<StatementsController>());
    }
  }

  Future<void> _showDateFilterDialog(StatementsController s) async {
    final yearController = TextEditingController(text: _yearController.text);
    final fromController = TextEditingController(text: _fromController.text);
    final toController = TextEditingController(text: _toController.text);
    var applied = false;

    Future<void> pickDate({
      required BuildContext dialogContext,
      required TextEditingController target,
      required StateSetter setDialogState,
    }) async {
      final initial = _parseDate(target.text) ?? DateTime.now();
      final picked = await showDatePicker(
        context: dialogContext,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      );
      if (picked == null) return;
      setDialogState(() => target.text = _dateOnly(picked));
    }

    Future<void> applyAndClose(BuildContext dialogContext) async {
      _yearController.text = yearController.text.trim();
      _fromController.text = fromController.text.trim();
      _toController.text = toController.text.trim();
      applied = true;
      Navigator.of(dialogContext).pop();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        final cs = Theme.of(dialogContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget dateTile({
              required String label,
              required TextEditingController controller,
              required IconData icon,
            }) {
              final value = controller.text.trim();
              final parsed = _parseDate(value);
              final display = parsed == null
                  ? 'dd/mm/aaaa'
                  : DateFormat('dd/MM/yyyy').format(parsed);
              return InkWell(
                onTap: s.loadingAllEntries
                    ? null
                    : () => pickDate(
                          dialogContext: dialogContext,
                          target: controller,
                          setDialogState: setDialogState,
                        ),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(icon, size: 18),
                    suffixIcon: value.isEmpty
                        ? const Icon(Icons.calendar_today_outlined, size: 16)
                        : IconButton(
                            tooltip: l.statementsClearFilters,
                            onPressed: () => setDialogState(controller.clear),
                            icon: const Icon(Icons.close_rounded, size: 16),
                          ),
                  ),
                  child: Text(display),
                ),
              );
            }

            Widget preset(String label, DateTime from, DateTime to, int? year) {
              return ActionChip(
                label: Text(label),
                onPressed: s.loadingAllEntries
                    ? null
                    : () => setDialogState(() {
                          yearController.text = year?.toString() ?? '';
                          fromController.text = _dateOnly(from);
                          toController.text = _dateOnly(to);
                        }),
              );
            }

            final now = DateTime.now();
            return AlertDialog(
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l.statementsHeaderDate),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.statementsFilterYear,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon:
                            const Icon(Icons.calendar_month_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: dateTile(
                            label: l.statementsFilterFrom,
                            controller: fromController,
                            icon: Icons.arrow_forward_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: dateTile(
                            label: l.statementsFilterTo,
                            controller: toController,
                            icon: Icons.arrow_back_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          preset(
                            l.statementsPresetThisMonth,
                            DateTime(now.year, now.month, 1),
                            DateTime(now.year, now.month + 1, 0),
                            now.year,
                          ),
                          preset(
                            l.statementsPresetLast30Days,
                            now.subtract(const Duration(days: 30)),
                            now,
                            null,
                          ),
                          preset(
                            l.localeName.toLowerCase().startsWith('es')
                                ? 'Ultimos 3 meses'
                                : 'Last 3 months',
                            DateTime(now.year, now.month - 3, now.day),
                            now,
                            null,
                          ),
                          preset(
                            l.statementsPresetThisYear,
                            DateTime(now.year, 1, 1),
                            DateTime(now.year, 12, 31),
                            now.year,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: s.loadingAllEntries
                      ? null
                      : () => setDialogState(() {
                            yearController.clear();
                            fromController.clear();
                            toController.clear();
                          }),
                  child: const Text('Limpiar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l.close),
                ),
                FilledButton(
                  onPressed: s.loadingAllEntries
                      ? null
                      : () => applyAndClose(dialogContext),
                  child: Text(l.statementsApplyFilters),
                ),
              ],
            );
          },
        );
      },
    );
    yearController.dispose();
    fromController.dispose();
    toController.dispose();
    if (applied && mounted) {
      await _applyFilters(s);
    }
  }

  Future<void> _showClientProviderFilterDialog(StatementsController s) async {
    final queryController =
        TextEditingController(text: _clientProviderController.text);
    var applied = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext)!;
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          title: Text('${l.statementsHeaderClient} / Proveedor'),
          content: SizedBox(
            width: 380,
            child: TextField(
              controller: queryController,
              enabled: !s.loadingAllEntries,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                _clientProviderController.text = queryController.text.trim();
                applied = true;
                Navigator.of(dialogContext).pop();
              },
              decoration: InputDecoration(
                labelText: '${l.statementsHeaderClient} / Proveedor',
                border: const OutlineInputBorder(),
                isDense: true,
                prefixIcon: const Icon(Icons.manage_search_rounded, size: 18),
                suffixIcon: IconButton(
                  tooltip: l.statementsClearFilters,
                  onPressed: s.loadingAllEntries ? null : queryController.clear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: s.loadingAllEntries
                  ? null
                  : () {
                      queryController.clear();
                      _clientProviderController.clear();
                      applied = true;
                      Navigator.of(dialogContext).pop();
                    },
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
            FilledButton(
              onPressed: s.loadingAllEntries
                  ? null
                  : () {
                      _clientProviderController.text =
                          queryController.text.trim();
                      applied = true;
                      Navigator.of(dialogContext).pop();
                    },
              child: Text(l.statementsApplyFilters),
            ),
          ],
        );
      },
    );
    queryController.dispose();
    if (applied && mounted) {
      await _applyFilters(s);
    }
  }

  Future<void> _applyFilters(StatementsController s) async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    await s.loadAllEntries(
      year: _parseYear(_yearController.text),
      dateFrom: from.isEmpty ? '' : from,
      dateTo: to.isEmpty ? '' : to,
      page: 1,
      amountType: _amountTypeFilter,
      minAmount: _amountMinFilter,
      maxAmount: _amountMaxFilter,
      clientProviderQuery: _clientProviderController.text.trim(),
      sort: 'date_desc',
      applyAmountFilters: true,
    );
    _selectedIds.clear();
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
          onDeleted: () async {
            _amountMinFilter = null;
            _amountMaxFilter = null;
            _amountTypeFilter = 'all';
            await _applyFilters(s);
          },
        ),
      );
    }
    if (_clientProviderController.text.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text(
            '${l.statementsHeaderClient} / Proveedor: ${_clientProviderController.text.trim()}',
          ),
          onDeleted: () async {
            _clientProviderController.clear();
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

  String _fileNameFromHeaders(
    Map<String, String> headers, {
    required String fallback,
  }) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final name = Uri.decodeComponent(utf8Match.group(1)!);
        if (name.trim().isNotEmpty) return name.trim();
      }
      final match = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
          .firstMatch(raw);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        if (name.isNotEmpty) return name;
      }
    }
    return fallback;
  }

  Future<void> _exportExcel(StatementsController s) async {
    if (_exportingExcel) return;
    setState(() => _exportingExcel = true);
    try {
      final response = await s.exportAllEntriesExcel(
        year: _parseYear(_yearController.text),
        dateFrom: _fromController.text.trim(),
        dateTo: _toController.text.trim(),
        amountType: _amountTypeFilter,
        minAmount: _amountMinFilter,
        maxAmount: _amountMaxFilter,
        clientProviderQuery: _clientProviderController.text.trim(),
        sort: s.allEntriesSort,
      );
      final fileName = _fileNameFromHeaders(
        response.headers,
        fallback: 'bank-transactions.xlsx',
      );
      await launchFileDownload(
        response.bodyBytes,
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? 'Export failed' : message)),
      );
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
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

      final inv = (pickFirstFromList(e['invoiceNumbers']) ??
              (e['invoiceNumber'] ?? e['invoice_number'])?.toString())
          ?.trim();
      final exp =
          (e['expenseNumber'] ?? e['expense_number'])?.toString().trim();
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
    _repairHotReloadState();
    super.build(context);
    final s = context.watch<StatementsController>();
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final tableTheme = _isSoftDarkTable
        ? StatementsTableTheme.softDark(cs)
        : StatementsTableTheme.light(cs);

    final dateFilteredEntries = s.isUsingAggregatedEntriesPath
        ? s.allEntries
        : s.allEntries.where(_entryMatchesDateFilters).toList(growable: false);
    final partyFilteredEntries = dateFilteredEntries
        .where((entry) => _entryMatchesClientProviderFilter(l, s, entry))
        .toList(growable: false);
    final amountFilteredEntries = s.isUsingAggregatedEntriesPath
        ? partyFilteredEntries
        : partyFilteredEntries.where((entry) {
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
            if (_amountMinFilter != null && parsed < _amountMinFilter!) {
              return false;
            }
            if (_amountMaxFilter != null && parsed > _amountMaxFilter!) {
              return false;
            }
            return true;
          }).toList(growable: false);
    final totalPages = s.isUsingAggregatedEntriesPath
        ? s.allEntriesTotalPages
        : (s.allEntriesSize == 0
            ? 1
            : (amountFilteredEntries.length / s.allEntriesSize)
                .ceil()
                .clamp(1, 9999));
    final visibleEntries = s.isUsingAggregatedEntriesPath
        ? amountFilteredEntries
        : () {
            final start = (s.allEntriesPage - 1) * s.allEntriesSize;
            final end = (start + s.allEntriesSize)
                .clamp(0, amountFilteredEntries.length);
            return (start >= 0 && start < amountFilteredEntries.length)
                ? amountFilteredEntries.sublist(start, end)
                : const <Map<String, dynamic>>[];
          }();
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
      '${l.statementsTotalCount}: ${s.isUsingAggregatedEntriesPath ? s.allEntriesTotal : amountFilteredEntries.length}',
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
    final canNextPage = s.isUsingAggregatedEntriesPath
        ? ((s.allEntriesNextCursor != null &&
                s.allEntriesNextCursor!.isNotEmpty) ||
            s.allEntriesPage < totalPages)
        : s.allEntriesPage < totalPages;
    final totalResults = s.isUsingAggregatedEntriesPath
        ? s.allEntriesTotal
        : amountFilteredEntries.length;
    final rangeStart = sortedEntries.isEmpty
        ? 0
        : ((s.allEntriesPage - 1) * s.allEntriesSize) + 1;
    final rangeEnd = sortedEntries.isEmpty
        ? 0
        : (rangeStart + sortedEntries.length - 1).clamp(0, totalResults);
    final resultRangeLabel = l.localeName.toLowerCase().startsWith('es')
        ? 'Mostrando $rangeStart-$rangeEnd de $totalResults'
        : 'Showing $rangeStart-$rangeEnd of $totalResults';
    final pageNavigationActions = _HeaderActionGroup(
      children: [
        _HeaderIconAction(
          tooltip: l.statementsPrevPage,
          onPressed: s.allEntriesPage > 1
              ? () => s.loadAllEntries(page: s.allEntriesPage - 1)
              : null,
          icon: Icons.chevron_left,
        ),
        _HeaderPageBadge(
          tooltip: l.statementsPageInfo(s.allEntriesPage, totalPages),
          page: s.allEntriesPage,
          totalPages: totalPages,
        ),
        _HeaderIconAction(
          tooltip: l.statementsNextPage,
          onPressed: canNextPage
              ? () => s.loadAllEntries(
                    page: s.allEntriesPage + 1,
                    cursor: s.isUsingAggregatedEntriesPath
                        ? s.allEntriesNextCursor
                        : null,
                  )
              : null,
          icon: Icons.chevron_right,
        ),
      ],
    );
    final headerActions = <Widget>[
      _HeaderActionGroup(
        children: [
          _HeaderIconAction(
            tooltip: infoTooltipText,
            onPressed: freshnessBatchId == null
                ? null
                : () => s.fetchBatchStatus(freshnessBatchId),
            icon: freshnessIsStale
                ? Icons.warning_amber_outlined
                : Icons.info_outline,
            color: freshnessIsStale ? cs.error : null,
          ),
          _HeaderIconAction(
            tooltip: _isSoftDarkTable ? 'Tema claro' : 'Tema suave oscuro',
            onPressed: _toggleTableTheme,
            icon: _isSoftDarkTable
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          _HeaderIconAction(
            tooltip: autoImportEnabled
                ? '${l.autoStatementImportTitle}: ON\n${l.autoStatementImportHelper}'
                : '${l.autoStatementImportTitle}: OFF\n${l.autoStatementImportHelper}',
            onPressed: _autoStatementImportLoading
                ? null
                : () => _toggleAutoStatementImport(!autoImportEnabled),
            icon: autoImportEnabled
                ? Icons.sync_lock_outlined
                : Icons.sync_disabled_outlined,
            selected: autoImportEnabled,
            loading: _autoStatementImportLoading,
          ),
          _HeaderIconAction(
            tooltip: l.refreshAction,
            onPressed: s.loadingAllEntries ? null : s.loadAllEntries,
            icon: Icons.refresh,
          ),
          _HeaderIconAction(
            tooltip: 'Exportar Excel',
            onPressed: _exportingExcel ? null : () => _exportExcel(s),
            icon: Icons.table_view_outlined,
            loading: _exportingExcel,
          ),
        ],
      ),
      _HeaderActionGroup(
        children: [
          _HeaderIconAction(
            tooltip: '${l.statementsPageSize}: ${s.allEntriesSize} (-)',
            onPressed: canDecSize
                ? () => s.loadAllEntries(
                      size: _sizeOptions[sizeIndex - 1],
                      page: 1,
                    )
                : null,
            icon: Icons.remove_rounded,
          ),
          _HeaderPageSizeBadge(label: '${s.allEntriesSize}'),
          _HeaderIconAction(
            tooltip: '${l.statementsPageSize}: ${s.allEntriesSize} (+)',
            onPressed: canIncSize
                ? () => s.loadAllEntries(
                      size: _sizeOptions[sizeIndex + 1],
                      page: 1,
                    )
                : null,
            icon: Icons.add_rounded,
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatementsAllDataBulkBar(
                  controller: s,
                  selectedCount: _selectedIds.length,
                  onBulkSuggest: () => _bulkSuggest(s, l),
                  onBulkLink: () => _showBulkLinkDialog(s),
                  onClear: () => setState(_selectedIds.clear),
                ),
                const SizedBox(height: 12),
                _activeFiltersChips(l, s),
                const SizedBox(height: 12),
                if (s.loadingAllEntries && s.allEntries.isEmpty)
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
                        onDateFilterTap: () => _showDateFilterDialog(s),
                        dateFilterActive: s.allEntriesYear != null ||
                            (s.allEntriesDateFrom?.isNotEmpty ?? false) ||
                            (s.allEntriesDateTo?.isNotEmpty ?? false),
                        onAmountFilterTap: _showAmountFilterDialog,
                        amountFilterActive: _amountMinFilter != null ||
                            _amountMaxFilter != null ||
                            _amountTypeFilter != 'all',
                        onClientProviderFilterTap: () =>
                            _showClientProviderFilterDialog(s),
                        clientProviderFilterActive:
                            _clientProviderController.text.trim().isNotEmpty,
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resultRangeLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                          pageNavigationActions,
                        ],
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

class _HeaderActionGroup extends StatelessWidget {
  const _HeaderActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  const _HeaderIconAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.selected = false,
    this.loading = false,
    this.color,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool selected;
  final bool loading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? (selected ? cs.onPrimary : cs.onSurfaceVariant);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: IconButton(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 17),
          style: IconButton.styleFrom(
            minimumSize: const Size(30, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: fg,
            disabledForegroundColor: fg.withValues(alpha: 0.35),
            backgroundColor: selected ? cs.primary : Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}

class _HeaderPageSizeBadge extends StatelessWidget {
  const _HeaderPageSizeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.of(context).bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _HeaderPageBadge extends StatelessWidget {
  const _HeaderPageBadge({
    required this.tooltip,
    required this.page,
    required this.totalPages,
  });

  final String tooltip;
  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$page',
                style: typography.bodySmall.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' / $totalPages',
                style: typography.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
