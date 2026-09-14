import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/mobile_theme.dart';

import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../statements_controller.dart';
import '../../statements_formatters.dart';
import '../../statements_shared.dart';
import '../statements_all_data_details.dart';
import 'statements_mobile_card.dart';

enum _DateRange { all, thisMonth, last30, thisYear }

enum _AmountType { all, income, expense }

class StatementsMobileView extends StatefulWidget {
  const StatementsMobileView({super.key});

  @override
  State<StatementsMobileView> createState() => _StatementsMobileViewState();
}

class _StatementsMobileViewState extends State<StatementsMobileView> {
  _DateRange _dateRange = _DateRange.thisMonth;
  _AmountType _amountType = _AmountType.all;
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didLoad) return;
      _didLoad = true;
      final s = context.read<StatementsController>();
      if (s.allEntries.isEmpty && !s.loadingAllEntries) {
        s.loadAllEntries();
      }
    });
  }

  DateTime? _entryDate(Map<String, dynamic> entry) {
    final candidates = [entry['valueDate'], entry['date'], entry['createdAt']];
    for (final raw in candidates) {
      if (raw == null) continue;
      if (raw is DateTime) return raw;
      if (raw is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          raw.abs() < 1000000000000 ? raw * 1000 : raw,
          isUtc: true,
        );
      }
      final s = raw.toString().trim();
      if (s.isEmpty) continue;
      final parsed = DateTime.tryParse(s);
      if (parsed != null) return parsed;
    }
    return null;
  }

  bool _matchesDateRange(Map<String, dynamic> entry) {
    if (_dateRange == _DateRange.all) return true;
    final d = _entryDate(entry);
    if (d == null) return false;
    final now = DateTime.now();
    switch (_dateRange) {
      case _DateRange.all:
        return true;
      case _DateRange.thisMonth:
        return d.year == now.year && d.month == now.month;
      case _DateRange.last30:
        return d.isAfter(now.subtract(const Duration(days: 30)));
      case _DateRange.thisYear:
        return d.year == now.year;
    }
  }

  bool _matchesAmountType(Map<String, dynamic> entry) {
    if (_amountType == _AmountType.all) return true;
    String rawIndex(int idx) {
      final raw = entry['raw'];
      if (raw is List && raw.length > idx) {
        final value = raw[idx];
        if (value != null) return value.toString();
      }
      return '';
    }

    final rawAmount = rawIndex(4);
    final amount = rawAmount.isNotEmpty
        ? rawAmount
        : StatementsShared.entryText(entry, ['amount']);
    final value = StatementsFormatters.parseAmount(amount) ?? 0;
    return _amountType == _AmountType.income ? value > 0 : value < 0;
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> entries) =>
      entries
          .where((e) => _matchesDateRange(e) && _matchesAmountType(e))
          .toList();

  void _showDetails(BuildContext context, Map<String, dynamic> entry) {
    final l = AppLocalizations.of(context)!;
    final s = context.read<StatementsController>();
    StatementsAllDataDetails.show(context, l, entry, s);
  }

  String _dateLabel(_DateRange r, bool isSpanish) {
    switch (r) {
      case _DateRange.all:
        return isSpanish ? 'Todos' : 'All';
      case _DateRange.thisMonth:
        return isSpanish ? 'Este mes' : 'This month';
      case _DateRange.last30:
        return isSpanish ? 'Últimos 30d' : 'Last 30d';
      case _DateRange.thisYear:
        return isSpanish ? 'Este año' : 'This year';
    }
  }

  String _amountLabel(_AmountType type, AppLocalizations l, bool isSpanish) {
    switch (type) {
      case _AmountType.all:
        return isSpanish ? 'Todos' : 'All';
      case _AmountType.income:
        return isSpanish ? 'Ingresos' : l.statementsSummaryIncome;
      case _AmountType.expense:
        return isSpanish ? 'Gastos' : l.statementsSummaryExpense;
    }
  }

  Future<void> _showFilters() async {
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    var date = _dateRange;
    var amount = _amountType;
    final result = await showModalBottomSheet<(_DateRange, _AmountType)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          final cs = Theme.of(context).colorScheme;
          Widget option(String label, bool selected, VoidCallback onTap) {
            return ListTile(
              title: Text(label,
                  style: TextStyle(
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  )),
              selected: selected,
              selectedTileColor: cs.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              trailing: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
              onTap: onTap,
            );
          }

          return SizedBox(
            height: MediaQuery.sizeOf(context).height * .8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                  child: Row(children: [
                    Expanded(
                        child: Text(isSpanish ? 'Filtros' : 'Filters',
                            style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ]),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(isSpanish ? 'Periodo' : 'Period',
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      for (final value in _DateRange.values)
                        option(_dateLabel(value, isSpanish), date == value,
                            () => updateSheet(() => date = value)),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                            isSpanish
                                ? 'Tipo de movimiento'
                                : 'Transaction type',
                            style: Theme.of(context).textTheme.titleSmall),
                      ),
                      for (final value in _AmountType.values)
                        option(
                            _amountLabel(value, l, isSpanish),
                            amount == value,
                            () => updateSheet(() => amount = value)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, (date, amount)),
                          child: Text(
                              isSpanish ? 'Aplicar filtros' : 'Apply filters'),
                        ),
                        TextButton(
                          onPressed: () => updateSheet(() {
                            date = _DateRange.all;
                            amount = _AmountType.all;
                          }),
                          child: Text(isSpanish
                              ? 'Restablecer filtros'
                              : 'Reset filters'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _dateRange = result.$1;
      _amountType = result.$2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StatementsController>();
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final filtered = _filtered(s.allEntries);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Material(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: Icon(Icons.tune_rounded, color: cs.primary),
              title: Text(
                '${_dateLabel(_dateRange, isSpanish)} · ${_amountLabel(_amountType, l, isSpanish)}',
                style: t.bodyMedium.copyWith(color: cs.onSurface),
              ),
              subtitle: Text(isSpanish ? 'Cambiar filtros' : 'Change filters',
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              trailing:
                  Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              onTap: _showFilters,
            ),
          ),
        ),
        // ── Count + refresh ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filtered.length} ${isSpanish ? 'movimientos' : 'movements'}',
                      style: t.bodyMedium.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSpanish
                          ? 'Pulsa un movimiento para ver el detalle'
                          : 'Tap a movement to view details',
                      style: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: MobileTheme.isActive(context) ? 14 : 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (s.loadingAllEntries)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                        minWidth: MobileTheme.isActive(context) ? 48 : 36,
                        minHeight: MobileTheme.isActive(context) ? 48 : 36),
                    tooltip: isSpanish ? 'Actualizar' : 'Refresh',
                    onPressed: s.loadAllEntries,
                  ),
                ),
            ],
          ),
        ),
        // ── List ────────────────────────────────────────────────────────────
        Expanded(
          child: s.loadingAllEntries && s.allEntries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isSpanish
                                ? 'Sin movimientos'
                                : 'No movements found',
                            style: t.bodyMedium
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          0,
                          2,
                          0,
                          24 +
                              (MobileTheme.isActive(context)
                                  ? MediaQuery.paddingOf(context).bottom
                                  : 0)),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) => StatementsMobileCard(
                        entry: filtered[i],
                        index: i,
                        controller: s,
                        onTap: () => _showDetails(context, filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}
