import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/worker_time_tracking/worker_time_tracking_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/widgets/monthly_grid.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/widgets/year_switcher.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'month_list.dart';
import 'text_extensions.dart';

class WorkerMonthlyOverviewInline extends StatefulWidget {
  final Group group;
  final Worker worker;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;
  final VoidCallback? onBack;

  const WorkerMonthlyOverviewInline({
    super.key,
    required this.group,
    required this.worker,
    required this.repo,
    required this.getToken,
    this.onBack,
  });

  @override
  State<WorkerMonthlyOverviewInline> createState() =>
      _WorkerMonthlyOverviewInlineState();
}

class _WorkerMonthlyOverviewInlineState
    extends State<WorkerMonthlyOverviewInline> {
  late int _year;
  late int _selectedMonth;
  bool _loading = false;
  Map<int, Map<String, dynamic>> _monthlyTotals = {};

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
    _loadAllMonths();
  }

  @override
  void didUpdateWidget(covariant WorkerMonthlyOverviewInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worker.id != widget.worker.id) {
      _year = DateTime.now().year;
      _selectedMonth = DateTime.now().month;
      _loadAllMonths();
    }
  }

  Future<void> _loadAllMonths() async {
    setState(() => _loading = true);
    try {
      final token = await widget.getToken();
      final Map<int, Map<String, dynamic>> totalsByMonth = {};

      for (int month = 1; month <= 12; month++) {
        try {
          final fromLocal = DateTime(_year, month, 1);
          final toLocal = (month < 12)
              ? DateTime(_year, month + 1, 1)
              : DateTime(_year + 1, 1, 1);

          final totals = await widget.repo.getWorkerTotals(
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      children: [
        Expanded(
          child: FolderPanel(
            onBack: widget.onBack,
            title: AppLocalizations.of(context)!.workersLabel,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      YearSwitcher(
                        year: _year,
                        onYearChanged: (newYear) {
                          setState(() => _year = newYear);
                          _loadAllMonths();
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : (kIsWeb
                                ? MonthList(
                                    year: _year,
                                    locale: locale,
                                    selectedMonth: _selectedMonth,
                                    monthlyTotals: _monthlyTotals,
                                    onTapMonth: (month) =>
                                        setState(() => _selectedMonth = month),
                                    subtitleBuilder: (totals) {
                                      final hours =
                                          totals?['totalHours'] ?? '0.00';
                                      final pay = totals?['totalPay'] ?? '0.00';
                                      final curr = totals?['currency'] ?? '';
                                      return l.totalHoursAndPayFormat(
                                        hours.toString(),
                                        '$pay $curr',
                                      );
                                    },
                                  )
                                : MonthGrid(
                                    year: _year,
                                    selectedMonth: _selectedMonth,
                                    monthlyTotals: _monthlyTotals,
                                    onTapMonth: (month) =>
                                        setState(() => _selectedMonth = month),
                                    monthNameBuilder: (month) {
                                      return DateFormat.MMMM(locale)
                                          .format(DateTime(_year, month, 1))
                                          .capitalize();
                                    },
                                    subtitleBuilder: (totals) {
                                      final hours =
                                          totals?['totalHours'] ?? '0.00';
                                      final pay = totals?['totalPay'] ?? '0.00';
                                      final curr = totals?['currency'] ?? '';
                                      return l.totalHoursAndPayFormat(
                                        hours.toString(),
                                        '$pay $curr',
                                      );
                                    },
                                  )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: WorkerTimeTrackingScreen(
                    key: ValueKey(
                      '${widget.worker.id}-${_year}-${_selectedMonth}',
                    ),
                    group: widget.group,
                    worker: widget.worker,
                    initialYear: _year,
                    initialMonth: _selectedMonth,
                    embedded: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
