import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_month_picker_dialog.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkerCurrentMonthSummaryView extends StatefulWidget {
  const WorkerCurrentMonthSummaryView({
    super.key,
    required this.group,
  });

  final Group group;

  @override
  State<WorkerCurrentMonthSummaryView> createState() =>
      _WorkerCurrentMonthSummaryViewState();
}

class _WorkerCurrentMonthSummaryViewState
    extends State<WorkerCurrentMonthSummaryView> {
  late final ITimeTrackingRepository _repo;
  late final UserDomain _userDomain;
  late DateTime _selectedMonthDate;

  bool _loading = true;
  String? _error;
  List<_WorkerMonthSummary> _summaries = const <_WorkerMonthSummary>[];

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
    final now = DateTime.now();
    _selectedMonthDate = DateTime(now.year, now.month, 1);
    _load();
  }

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  Future<String> _token() => _userDomain.getAuthToken();

  DateTime get _monthStart {
    return DateTime(_selectedMonthDate.year, _selectedMonthDate.month, 1);
  }

  DateTime get _monthEnd {
    final start = _monthStart;
    return DateTime(start.year, start.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }

  String _workerLabel(Worker worker) {
    final name = (worker.displayName ?? '').trim();
    if (name.isNotEmpty) return name;
    final external = (worker.externalId ?? '').trim();
    if (external.isNotEmpty) return external;
    final userId = (worker.userId ?? '').trim();
    if (userId.isNotEmpty) return userId;
    return _isSpanish ? 'Trabajador' : 'Worker';
  }

  String _formatMoney(num amount, {String? currency}) {
    final locale = Localizations.localeOf(context).toString();
    final formatted = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: 2,
    ).format(amount).trim();
    if (currency == null || currency.trim().isEmpty) return formatted;
    return '$formatted ${currency.trim()}';
  }

  String _monthLabel() {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(_selectedMonthDate);
  }

  bool get _canGoNext {
    final now = DateTime.now();
    final next =
        DateTime(_selectedMonthDate.year, _selectedMonthDate.month + 1, 1);
    return !(next.year > now.year ||
        (next.year == now.year && next.month > now.month));
  }

  Future<void> _prevMonth() async {
    final d = _selectedMonthDate;
    setState(() => _selectedMonthDate = DateTime(d.year, d.month - 1, 1));
    await _load();
  }

  Future<void> _nextMonth() async {
    if (!_canGoNext) return;
    final d = _selectedMonthDate;
    setState(() => _selectedMonthDate = DateTime(d.year, d.month + 1, 1));
    await _load();
  }

  Future<void> _pickMonth() async {
    final result = await showWorkerMonthPickerDialog(
      context: context,
      initialDate: _selectedMonthDate,
      isSpanish: _isSpanish,
    );
    if (result == null) return;
    if (result.year == _selectedMonthDate.year &&
        result.month == _selectedMonthDate.month) {
      return;
    }
    setState(() => _selectedMonthDate = result);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      final workers = await _repo.getWorkers(widget.group.id, token);
      final summaries = await Future.wait(
        workers.map((worker) async {
          try {
            final totals = await _repo.getWorkerTotals(
              widget.group.id,
              token,
              workerId: worker.id,
              from: _monthStart,
              to: _monthEnd,
            );
            return _WorkerMonthSummary(worker: worker, totals: totals);
          } catch (error) {
            return _WorkerMonthSummary(worker: worker, error: error.toString());
          }
        }),
      );
      summaries.sort((a, b) {
        final payCompare = b.payable.compareTo(a.payable);
        if (payCompare != 0) return payCompare;
        return _workerLabel(a.worker).compareTo(_workerLabel(b.worker));
      });
      if (!mounted) return;
      setState(() {
        _summaries = summaries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, double> _totalsByCurrency() {
    final result = <String, double>{};
    for (final summary in _summaries) {
      final currency = summary.currency?.trim().isNotEmpty == true
          ? summary.currency!.trim()
          : '—';
      result.update(currency, (value) => value + summary.payable,
          ifAbsent: () => summary.payable);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: t.bodySmall.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(_isSpanish ? 'Reintentar' : 'Retry'),
            ),
          ],
        ),
      );
    }

    if (_summaries.isEmpty) {
      return Center(
        child: EmptyView(
          icon: Icons.payments_outlined,
          title: _isSpanish
              ? 'No hay trabajadores para resumir este mes.'
              : 'There are no workers to summarize this month.',
          subtitle: _isSpanish
              ? 'Cuando existan trabajadores con horas registradas, aparecerán aquí.'
              : 'Once workers and monthly hours exist, they will appear here.',
        ),
      );
    }

    final totalsByCurrency = _totalsByCurrency();
    final totalWorkers = _summaries.length;
    final withHours = _summaries.where((item) => item.totalHours > 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withValues(alpha: 0.10),
                cs.primary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSpanish
                          ? 'Resumen rápido del mes'
                          : 'Quick summary for this month',
                      style: t.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prev month
                        _MonthNavBtn(
                          icon: Icons.chevron_left_rounded,
                          onPressed: _loading ? null : _prevMonth,
                        ),
                        // Month label — tap to open picker
                        GestureDetector(
                          onTap: _loading ? null : _pickMonth,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_outlined,
                                    size: 14, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  _monthLabel(),
                                  style: t.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.expand_more_rounded,
                                    size: 14, color: cs.primary),
                              ],
                            ),
                          ),
                        ),
                        // Next month (disabled when at current month)
                        _MonthNavBtn(
                          icon: Icons.chevron_right_rounded,
                          onPressed:
                              (_loading || !_canGoNext) ? null : _nextMonth,
                        ),
                        const SizedBox(width: 4),
                        // Refresh
                        Tooltip(
                          message: _isSpanish ? 'Actualizar' : 'Refresh',
                          child: _MonthNavBtn(
                            icon: Icons.refresh_rounded,
                            onPressed: _loading ? null : _load,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _summaryChip(
                          context,
                          icon: Icons.group_outlined,
                          label: _isSpanish
                              ? '$totalWorkers trabajadores'
                              : '$totalWorkers workers',
                        ),
                        _summaryChip(
                          context,
                          icon: Icons.schedule_outlined,
                          label: _isSpanish
                              ? '$withHours con horas'
                              : '$withHours with hours',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _isSpanish ? 'A pagar' : 'To pay',
                    style: t.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...totalsByCurrency.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        _formatMoney(entry.value,
                            currency: entry.key == '—' ? null : entry.key),
                        style: t.bodyLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: _summaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final summary = _summaries[index];
              final statusColor = summary.worker.status == WorkerStatus.active
                  ? Colors.green
                  : cs.onSurfaceVariant;
              final initial = _workerLabel(summary.worker)
                  .trim()
                  .characters
                  .first
                  .toUpperCase();
              final label = _workerLabel(summary.worker);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + chips
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: t.bodyMedium
                                .copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              _statusChip(
                                  context, statusColor, summary.worker.status),
                              _metricChip(
                                context,
                                icon: Icons.schedule_rounded,
                                label:
                                    '${summary.totalHours.toStringAsFixed(1)} h',
                              ),
                              _metricChip(
                                context,
                                icon: Icons.receipt_long_rounded,
                                label: _isSpanish
                                    ? '${summary.entriesCount} reg.'
                                    : '${summary.entriesCount} entries',
                              ),
                              if (summary.advanceAmount > 0)
                                _metricChip(
                                  context,
                                  icon: Icons.payments_outlined,
                                  label: _isSpanish
                                      ? 'Ant. ${_formatMoney(summary.advanceAmount, currency: summary.currency)}'
                                      : 'Adv. ${_formatMoney(summary.advanceAmount, currency: summary.currency)}',
                                ),
                            ],
                          ),
                          if (summary.error != null &&
                              summary.error!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              summary.error!,
                              style: t.bodySmall.copyWith(color: cs.error),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Amount — always right-aligned
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isSpanish ? 'A pagar' : 'To pay',
                          style: t.caption.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatMoney(summary.payable,
                              currency: summary.currency),
                          style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    BuildContext context,
    Color statusColor,
    WorkerStatus? status,
  ) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Text(
        status == WorkerStatus.active
            ? (_isSpanish ? 'Activo' : 'Active')
            : (_isSpanish ? 'Inactivo' : 'Inactive'),
        style: t.bodySmall.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _metricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WorkerMonthSummary {
  const _WorkerMonthSummary({
    required this.worker,
    this.totals,
    this.error,
  });

  final Worker worker;
  final Map<String, dynamic>? totals;
  final String? error;

  double _toNum(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double get payable {
    if (totals == null) return 0;
    final gross = _toNum(totals!['grossPay'] ?? totals!['totalPay']);
    final advance = _toNum(totals!['advanceAmount']);
    if (totals!.containsKey('netPay')) {
      final net = _toNum(totals!['netPay']);
      return net < 0 ? 0 : net;
    }
    final fallback = gross - advance;
    return fallback < 0 ? 0 : fallback;
  }

  double get totalHours => _toNum(totals?['totalHours']);

  int get entriesCount => _toInt(totals?['entriesCount']);

  double get advanceAmount => _toNum(totals?['advanceAmount']);

  String? get currency =>
      totals?['currency']?.toString() ?? worker.currency?.toString();
}

// ── Month navigation icon button ───────────────────────────────────────────────

class _MonthNavBtn extends StatelessWidget {
  const _MonthNavBtn({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(icon, size: 17),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      color: cs.onSurfaceVariant,
      disabledColor: cs.onSurfaceVariant.withValues(alpha: 0.28),
      style: IconButton.styleFrom(
        minimumSize: const Size(30, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
