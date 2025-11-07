import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/worker/entry_screen/tracking/worker_time_tracking_screen.dart';
import 'package:hexora/c-frontend/b-dashboard-section/sections/workers/worker/monthly_overview/widgets/monthly_grid.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WorkerMonthlyOverviewScreen extends StatefulWidget {
  final Group group;
  final Worker worker;

  const WorkerMonthlyOverviewScreen({
    super.key,
    required this.group,
    required this.worker,
  });

  @override
  State<WorkerMonthlyOverviewScreen> createState() =>
      _WorkerMonthlyOverviewScreenState();
}

class _WorkerMonthlyOverviewScreenState
    extends State<WorkerMonthlyOverviewScreen> {
  late ITimeTrackingRepository _repo;
  late UserDomain _userDomain;
  late int _year;
  int _selectedMonth = DateTime.now().month;

  bool _loading = false;
  Map<int, Map<String, dynamic>> _monthlyTotals = {}; // month → totals

  @override
  void initState() {
    super.initState();
    _repo = context.read<ITimeTrackingRepository>();
    _userDomain = context.read<UserDomain>();
    _year = DateTime.now().year;
    _loadAllMonths();
  }

  Future<String> _getToken() => _userDomain.getAuthToken();

  Future<void> _loadAllMonths() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final Map<int, Map<String, dynamic>> totalsByMonth = {};

      for (int month = 1; month <= 12; month++) {
        try {
          final fromLocal = DateTime(_year, month, 1);
          final toLocal = (month < 12)
              ? DateTime(_year, month + 1, 1)
              : DateTime(_year + 1, 1, 1);
          final totals = await _repo.getWorkerTotals(
            widget.group.id,
            token,
            workerId: widget.worker.id,
            from: fromLocal.toUtc(),
            to: toLocal.toUtc(),
          );
          totalsByMonth[month] = totals;
        } catch (_) {
          totalsByMonth[month] = {
            'totalHours': '0.00',
            'totalPay': '0.00',
            'currency': '',
          };
        }
      }

      if (!mounted) return;
      setState(() => _monthlyTotals = totalsByMonth);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToSelectedMonth() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerTimeTrackingScreen(
          group: widget.group,
          worker: widget.worker,
          initialYear: _year,
          initialMonth: _selectedMonth,
        ),
      ),
    );
  }

  void _selectMonth(int month) {
    setState(() => _selectedMonth = month);
    _navigateToSelectedMonth();
  }

  void _showInfoSheet() {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.overviewInfoTitle,
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                l.overviewInfoBody,
                style: t.bodyMedium.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),
              _legendRow(context),
              const SizedBox(height: 8),
              Text(
                '• ${l.tipTapMonthToOpen}\n• ${l.tipPullToRefresh}',
                style: t.bodySmall.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _legendRow(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _legendChip(
          context,
          icon: Icons.timer_outlined,
          label: l.hours,
          color: Theme.of(context).colorScheme.primary,
        ),
        _legendChip(
          context,
          icon: Icons.attach_money,
          label: l.pay,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _legendChip(
          context,
          icon: Icons.task_alt,
          label: l.entries,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _legendChip(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    final selectedLabel =
        DateFormat.yMMMM(locale).format(DateTime(_year, _selectedMonth, 1));

    // Slight contrast boost specifically around the grid area (helps “see better”)
    final highContrast = theme.copyWith(
      cardTheme: theme.cardTheme.copyWith(
        color: theme.colorScheme.surface,
      ),
      colorScheme: theme.colorScheme.copyWith(
        surfaceVariant: theme.colorScheme.surface,
        onSurfaceVariant: theme.colorScheme.onSurface,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.worker.displayName ?? 'Worker',
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w700)),
            Text(
              '${widget.group.name} • $selectedLabel',
              style: t.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.info,
            onPressed: _showInfoSheet,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllMonths,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator())),
                ],
              )
            : ListView(
                children: [
                  // Year switcher with higher contrast buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              theme.colorScheme.primaryContainer
                                  .withOpacity(.5),
                            ),
                          ),
                          tooltip: l.previous,
                          icon: Icon(Icons.chevron_left,
                              color: theme.colorScheme.onPrimaryContainer),
                          onPressed: () {
                            setState(() => _year -= 1);
                            _loadAllMonths();
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_year',
                              style: t.accentHeading.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ),
                        IconButton.filledTonal(
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              theme.colorScheme.primaryContainer
                                  .withOpacity(.5),
                            ),
                          ),
                          tooltip: l.next,
                          icon: Icon(Icons.chevron_right,
                              color: theme.colorScheme.onPrimaryContainer),
                          onPressed: () {
                            setState(() => _year += 1);
                            _loadAllMonths();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Legend row (subtle, compact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _legendRow(context),
                  ),

                  // 12-month grid with boosted contrast
                  Theme(
                    data: highContrast,
                    child: MonthGrid(
                      year: _year,
                      selectedMonth: _selectedMonth,
                      monthlyTotals: _monthlyTotals,
                      onTapMonth: _selectMonth,
                      monthNameBuilder: (month) {
                        return DateFormat.MMMM(locale)
                            .format(DateTime(_year, month, 1))
                            .capitalize();
                      },
                      subtitleBuilder: (totals) {
                        final totalHours = totals?['totalHours'] ?? '0.00';
                        final totalPay = totals?['totalPay'] ?? '0.00';
                        final currency = totals?['currency'] ?? '';
                        return l.totalHoursAndPayFormat(
                          totalHours.toString(),
                          '$totalPay $currency',
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                      onPressed: _navigateToSelectedMonth,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(l.viewDetails),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
