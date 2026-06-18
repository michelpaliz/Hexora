import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
  bool _filtersExpanded = true;

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

  Widget _buildFilterChips({
    required AppTypography t,
    required AppLocalizations l,
    required bool isSpanish,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in _DateRange.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_dateLabel(r, isSpanish)),
                    selected: _dateRange == r,
                    onSelected: (_) => setState(() => _dateRange = r),
                    visualDensity: VisualDensity.compact,
                    labelStyle: t.bodySmall.copyWith(fontSize: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final type in _AmountType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_amountLabel(type, l, isSpanish)),
                    selected: _amountType == type,
                    onSelected: (_) => setState(() => _amountType = type),
                    visualDensity: VisualDensity.compact,
                    labelStyle: t.bodySmall.copyWith(fontSize: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<StatementsController>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final filtered = _filtered(s.allEntries);

    return Column(
      children: [
        // ── Filter bar ──────────────────────────────────────────────────────
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
                      : cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSpanish ? 'Filtros' : 'Filters',
                                style: t.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _ActiveFilterChip(
                                    label: _dateLabel(_dateRange, isSpanish),
                                  ),
                                  _ActiveFilterChip(
                                    label:
                                        _amountLabel(_amountType, l, isSpanish),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _filtersExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildFilterChips(
                    t: t,
                    l: l,
                    isSpanish: isSpanish,
                  ),
                ),
                crossFadeState: _filtersExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
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
                        fontSize: 11,
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
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 24),
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

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.secondary.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}
