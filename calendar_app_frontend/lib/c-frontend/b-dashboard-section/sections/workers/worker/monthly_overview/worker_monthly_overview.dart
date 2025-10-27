import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toString();

    final selectedLabel =
        DateFormat.yMMMM(locale).format(DateTime(_year, _selectedMonth, 1));

    return Scaffold(
      appBar: AppBar(
        // keep your current bar
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.worker.displayName ?? 'Worker', style: t.titleLarge),
            Text(
              '${widget.group.name} • $selectedLabel',
              style: t.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
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
                  // NEW: year switcher row (bold year between arrows)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: l.previous,
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() => _year -= 1);
                            _loadAllMonths();
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_year',
                              style: t.accentHeading
                                  .copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l.next,
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() => _year += 1);
                            _loadAllMonths();
                          },
                        ),
                      ],
                    ),
                  ),

                  // 12-month grid
                  MonthGrid(
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
