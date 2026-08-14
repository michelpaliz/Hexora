import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/card/time_tracking_header_card.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/loading_list.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/telegram_worker_hours_import_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/time_tracking_excel_import_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_current_month_summary_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_month_picker_dialog.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_time_history_graph_view.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/worker_list_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/monthly_overview/worker_monthly_overview.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/nav_section.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/c-frontend/ui-app/shared/widgets/folder_panel.dart';

import 'widgets/status_filter_chips.dart';
import 'widgets/worker_monthly_overview_inline.dart';
import 'widgets/workers_form_panel.dart';

enum _InlineSection {
  workers,
  graphs,
  historial,
  telegramImport,
  registerHours
}

class _WorkersNavHeader extends StatelessWidget {
  const _WorkersNavHeader({
    required this.title,
    required this.subtitle,
    required this.onCollapse,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.38),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.group_outlined,
                size: 18,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: AppLocalizations.of(context)!.groupInvoicesNavCollapse,
              child: IconButton.filledTonal(
                onPressed: onCollapse,
                icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                iconSize: 18,
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 34),
                  fixedSize: const Size(40, 34),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkersCollapsedRail extends StatelessWidget {
  const _WorkersCollapsedRail({
    required this.width,
    required this.selected,
    required this.onSelect,
    required this.onExpand,
    required this.onCreateWorker,
    required this.workersLabel,
    required this.chartsLabel,
    required this.summaryLabel,
    required this.telegramLabel,
    required this.registerHoursLabel,
    required this.createWorkerLabel,
  });

  final double width;
  final _InlineSection selected;
  final ValueChanged<_InlineSection> onSelect;
  final VoidCallback onExpand;
  final VoidCallback onCreateWorker;
  final String workersLabel;
  final String chartsLabel;
  final String summaryLabel;
  final String telegramLabel;
  final String registerHoursLabel;
  final String createWorkerLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item(
      IconData icon,
      String tooltip, {
      _InlineSection? section,
      VoidCallback? onTap,
      bool selectedOverride = false,
    }) {
      final isSelected = selectedOverride || selected == section;
      return Tooltip(
        message: tooltip,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: onTap ?? (section == null ? null : () => onSelect(section)),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.22)
                    : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    Widget divider() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Divider(
            height: 1,
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 8),
      child: Column(
        children: [
          Tooltip(
            message: AppLocalizations.of(context)!.groupInvoicesNavExpand,
            preferBelow: false,
            child: InkWell(
              onTap: onExpand,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  item(
                    Icons.person_add_alt_1,
                    createWorkerLabel,
                    onTap: onCreateWorker,
                  ),
                  const SizedBox(height: 3),
                  item(
                    Icons.group_outlined,
                    workersLabel,
                    section: _InlineSection.workers,
                  ),
                  const SizedBox(height: 3),
                  item(
                    Icons.schedule_outlined,
                    registerHoursLabel,
                    section: _InlineSection.registerHours,
                  ),
                  const SizedBox(height: 3),
                  item(
                    Icons.telegram,
                    telegramLabel,
                    section: _InlineSection.telegramImport,
                  ),
                  divider(),
                  item(
                    Icons.history_outlined,
                    summaryLabel,
                    section: _InlineSection.historial,
                  ),
                  divider(),
                  item(
                    Icons.bar_chart_rounded,
                    chartsLabel,
                    section: _InlineSection.graphs,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkersInlinePanel extends StatefulWidget {
  final Group group;
  const WorkersInlinePanel({super.key, required this.group});

  @override
  State<WorkersInlinePanel> createState() => _WorkersInlinePanelState();
}

class _WorkersInlinePanelState extends State<WorkersInlinePanel>
    with SingleTickerProviderStateMixin {
  static const double _expandedMenuWidth = 218;
  static const double _collapsedMenuWidth = 50;

  late UserDomain _userDomain;
  late ITimeTrackingRepository _repo;

  bool _loading = false;
  bool _toggling = false;
  bool _pluginDisabled = false;
  String? _error;
  List<Worker> _workers = const [];
  Worker? _selectedWorker;
  _InlineSection _section = _InlineSection.workers;
  late final TabController _tabController;
  WorkerStatusFilter _statusFilter = WorkerStatusFilter.all;
  bool _showOverview = false;
  Map<String, dynamic>? _activeTotals;
  bool _activeTotalsLoading = false;
  String? _activeTotalsError;
  late int _totalsYear;
  late int _totalsMonth;
  bool _sideMenuCollapsed = false;
  bool _dataMenuExpanded = true;
  bool _historyMenuExpanded = true;
  bool _analyticsMenuExpanded = true;

  @override
  void initState() {
    super.initState();
    _userDomain = context.read<UserDomain>();
    _repo = context.read<ITimeTrackingRepository>();
    final now = DateTime.now();
    _totalsYear = now.year;
    _totalsMonth = now.month;
    _tabController = TabController(length: kIsWeb ? 3 : 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _token() => _userDomain.getAuthToken();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _pluginDisabled = false;
    });
    try {
      final token = await _token();
      final items = await _repo.getWorkers(
        widget.group.id,
        token,
        status: _statusFilter == WorkerStatusFilter.all
            ? null
            : (_statusFilter == WorkerStatusFilter.inactive
                ? WorkerStatus.archived
                : WorkerStatus.active),
      );
      final totals = await _repo.getActiveWorkersTotals(
        widget.group.id,
        token,
        year: _totalsYear,
        month: _totalsMonth,
      );
      if (!mounted) return;
      setState(() {
        _workers = items;
        _activeTotals = totals;
        _activeTotalsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('403')) {
        setState(() {
          _pluginDisabled = true;
          _workers = const [];
        });
      } else if (msg.contains('404')) {
        setState(() => _workers = const []);
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  String _activeWorkersLabel(BuildContext context) =>
      _isSpanish(context) ? 'activos' : 'active';

  String _emptyTotalsLabel(BuildContext context) => _isSpanish(context)
      ? 'Aún no hay registros este mes.'
      : 'No entries yet this month.';

  String _defaultTotalsErrorLabel(BuildContext context) => _isSpanish(context)
      ? 'No se pudo cargar el total.'
      : 'Could not load total.';

  String _money(BuildContext context, num amount, {String? currency}) {
    final locale = AppLocalizations.of(context)!.localeName;
    final formatted = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: 2,
    ).format(amount).trim();
    if (currency == null || currency.isEmpty) return formatted;
    return '$formatted $currency';
  }

  String _selectedMonthLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMM(locale).format(DateTime(_totalsYear, _totalsMonth));
  }

  Future<void> _pickTotalsMonth() async {
    final selected = await showWorkerMonthPickerDialog(
      context: context,
      initialDate: DateTime(_totalsYear, _totalsMonth, 1),
      isSpanish: _isSpanish(context),
      firstYear: 2018,
      maxYear: 2100,
      allowFutureMonths: true,
    );

    if (selected == null) return;
    setState(() {
      _totalsYear = selected.year;
      _totalsMonth = selected.month;
    });
    await _reloadActiveTotals();
  }

  Future<void> _reloadActiveTotals() async {
    setState(() {
      _activeTotalsLoading = true;
      _activeTotalsError = null;
    });
    try {
      final token = await _token();
      final totals = await _repo.getActiveWorkersTotals(
        widget.group.id,
        token,
        year: _totalsYear,
        month: _totalsMonth,
      );
      if (!mounted) return;
      setState(() => _activeTotals = totals);
    } catch (e) {
      if (!mounted) return;
      var message = _defaultTotalsErrorLabel(context);
      if (e is BackendApiException && e.message.trim().isNotEmpty) {
        message = e.message;
      }
      setState(() => _activeTotalsError = message);
    } finally {
      if (mounted) {
        setState(() => _activeTotalsLoading = false);
      }
    }
  }

  Future<void> _openPayrollHistoryDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _PayrollHistoryDialog(
        group: widget.group,
        repo: _repo,
        getToken: _token,
      ),
    );
  }

  Widget _buildActiveTotalsInlineCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final entriesCount = (_activeTotals?['entriesCount'] as num?)?.toInt() ?? 0;
    final activeWorkers =
        (_activeTotals?['activeWorkersCount'] as num?)?.toInt() ?? 0;
    final totalHours = (_activeTotals?['totalHours'] as num?)?.toDouble() ?? 0;
    final totalPay = (_activeTotals?['totalPay'] as num?)?.toDouble();
    final currency = _activeTotals?['currency']?.toString();
    final totalsByCurrency =
        (_activeTotals?['totalsByCurrency'] as List?) ?? const [];
    final multiCurrency = currency == null || totalsByCurrency.length > 1;

    Widget statChip(IconData icon, String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Month picker chip
          GestureDetector(
            onTap: _activeTotalsLoading ? null : _pickTotalsMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 13, color: cs.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    _selectedMonthLabel(context),
                    style: t.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Amount / state
          if (_activeTotalsLoading)
            SizedBox(
              width: 14,
              height: 14,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            )
          else if (_activeTotalsError != null && _activeTotalsError!.isNotEmpty)
            Flexible(
              child: Text(
                _activeTotalsError!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(color: cs.error, fontSize: 11),
              ),
            )
          else if (entriesCount <= 0)
            Flexible(
              child: Text(
                _emptyTotalsLabel(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(fontSize: 11),
              ),
            )
          else ...[
            if (!multiCurrency && totalPay != null)
              Text(
                _money(context, totalPay, currency: currency),
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              )
            else
              ...totalsByCurrency.map<Widget>((item) {
                if (item is! Map) return const SizedBox.shrink();
                final curr = item['currency']?.toString() ?? '-';
                final pay = (item['totalPay'] as num?)?.toDouble() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _money(context, pay, currency: curr),
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                );
              }),
            const SizedBox(width: 10),
            statChip(Icons.people_outline_rounded,
                '$activeWorkers ${_activeWorkersLabel(context).toLowerCase()}'),
            const SizedBox(width: 6),
            statChip(
                Icons.schedule_rounded, '${totalHours.toStringAsFixed(1)} h'),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: _openPayrollHistoryDialog,
                icon: const Icon(Icons.history_rounded, size: 14),
                label: Text(_isSpanish(context) ? 'Historial' : 'History'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  textStyle: t.bodySmall.copyWith(fontSize: 11),
                ),
              ),
            ),
          ],
          const Spacer(),
          // Refresh
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              tooltip: AppLocalizations.of(context)!.refresh,
              onPressed: _activeTotalsLoading ? null : _reloadActiveTotals,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enable() async {
    setState(() => _toggling = true);
    try {
      final token = await _token();
      await _repo.enable(widget.group.id, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.timeTrackingEnabled)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _toggling = true);
    try {
      final token = await _token();
      await _repo.disable(widget.group.id, token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.timeTrackingDisabled)),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _addSharedHours() async {
    if (_workers.isEmpty) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CreateTimeEntryScreen(
          group: widget.group,
          workers: _workers,
        ),
      ),
    );
    if (created == true) _load();
  }

  Future<bool?> _openEditWorkerDialog(Worker w) async {
    _tabController.animateTo(0);
    setState(() {
      _selectedWorker = w;
      _showOverview = false;
    });
    return null;
  }

  void _openOverviewInline(Worker w) {
    setState(() {
      _selectedWorker = w;
      _showOverview = true;
    });
  }

  void _openCreateWorkerForm() {
    _tabController.animateTo(1);
    setState(() {
      _section = _InlineSection.workers;
      _selectedWorker = null;
      _showOverview = false;
    });
  }

  Widget _buildSideMenu(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = _isSpanish(context);

    if (_sideMenuCollapsed) {
      return _WorkersCollapsedRail(
        width: _collapsedMenuWidth,
        selected: _section,
        onExpand: () => setState(() => _sideMenuCollapsed = false),
        onSelect: (section) => setState(() => _section = section),
        onCreateWorker: _openCreateWorkerForm,
        workersLabel: l.workersLabel,
        chartsLabel: isEs ? 'Graficas' : 'Charts',
        summaryLabel: isEs ? 'Resumen del mes' : 'Summary this month',
        telegramLabel: isEs ? 'Importar Telegram' : 'Telegram import',
        registerHoursLabel: isEs ? 'Registrar horas' : 'Register hours',
        createWorkerLabel: l.createWorkerCta,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: _expandedMenuWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkersNavHeader(
            title: l.workersLabel,
            subtitle: isEs ? 'Menu de datos' : 'Data menu',
            onCollapse: () => setState(() => _sideMenuCollapsed = true),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupInvoicesNavSection(
                    title: isEs ? 'Datos' : 'Data',
                    icon: Icons.dataset_outlined,
                    expanded: _dataMenuExpanded,
                    onToggle: () => setState(
                      () => _dataMenuExpanded = !_dataMenuExpanded,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GroupInvoicesSubMenuItem(
                          icon: Icons.person_add_alt_1,
                          label: l.createWorkerCta,
                          selected: false,
                          primaryAction: true,
                          indent: 12,
                          onPressed: _openCreateWorkerForm,
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.group_outlined,
                          label: l.workersLabel,
                          selected: _section == _InlineSection.workers,
                          indent: 12,
                          onPressed: () => setState(
                            () => _section = _InlineSection.workers,
                          ),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.schedule_outlined,
                          label: isEs ? 'Registrar horas' : 'Register hours',
                          selected: _section == _InlineSection.registerHours,
                          indent: 12,
                          onPressed: () => setState(
                            () => _section = _InlineSection.registerHours,
                          ),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.telegram,
                          label: isEs ? 'Importar Telegram' : 'Telegram import',
                          selected: _section == _InlineSection.telegramImport,
                          indent: 12,
                          onPressed: () => setState(
                            () => _section = _InlineSection.telegramImport,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GroupInvoicesNavSection(
                    title: isEs ? 'Historial' : 'History',
                    icon: Icons.history_outlined,
                    expanded: _historyMenuExpanded,
                    onToggle: () => setState(
                      () => _historyMenuExpanded = !_historyMenuExpanded,
                    ),
                    child: GroupInvoicesSubMenuItem(
                      icon: Icons.history_outlined,
                      label: isEs ? 'Resumen del mes' : 'Summary this month',
                      selected: _section == _InlineSection.historial,
                      indent: 12,
                      onPressed: () => setState(
                        () => _section = _InlineSection.historial,
                      ),
                    ),
                  ),
                  GroupInvoicesNavSection(
                    title: isEs ? 'Analiticas' : 'Analytics',
                    icon: Icons.analytics_outlined,
                    expanded: _analyticsMenuExpanded,
                    onToggle: () => setState(
                      () => _analyticsMenuExpanded = !_analyticsMenuExpanded,
                    ),
                    child: GroupInvoicesSubMenuItem(
                      icon: Icons.bar_chart_rounded,
                      label: isEs ? 'Graficas' : 'Charts',
                      selected: _section == _InlineSection.graphs,
                      indent: 12,
                      onPressed: () => setState(
                        () => _section = _InlineSection.graphs,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = _isSpanish(context);
    return switch (_section) {
      _InlineSection.workers => l.workersLabel,
      _InlineSection.graphs => isEs ? 'Graficas' : 'Charts',
      _InlineSection.historial =>
        isEs ? 'Resumen del mes' : 'Summary this month',
      _InlineSection.telegramImport =>
        isEs ? 'Importar Telegram' : 'Telegram import',
      _InlineSection.registerHours =>
        isEs ? 'Registrar horas' : 'Register hours',
    };
  }

  Widget _buildWorkersSection(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (_selectedWorker != null && _showOverview) {
      return WorkerMonthlyOverviewInline(
        group: widget.group,
        worker: _selectedWorker!,
        repo: _repo,
        getToken: _token,
        onBack: () {
          _tabController.animateTo(0);
          setState(() => _showOverview = false);
        },
      );
    }

    return Column(
      children: [
        if (_selectedWorker == null) ...[
          TimeTrackingHeaderCard(
            groupName: widget.group.name,
            onEnable: _enable,
            onDisable: _disable,
            busy: _toggling,
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildActiveTotalsInlineCard(context),
                    Expanded(
                      child: SingleChildScrollView(
                        child: WorkerListSection(
                          workers: _workers,
                          selectedWorkerId: _selectedWorker?.id,
                          tapSelects: true,
                          onSelect: (w) => _openEditWorkerDialog(w),
                          onEdit: (w) => _openEditWorkerDialog(w),
                          onAddHours: _addHoursForWorker,
                          onOpenOverviewIcon: (w) => _openOverviewInline(w),
                          onOpenOverview: _openOverview,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.statusLabel,
                            style: t.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusFilterChips(
                            value: _statusFilter,
                            onChanged: (next) {
                              setState(() => _statusFilter = next);
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: WorkersFormPanel(
                  group: widget.group,
                  repo: _repo,
                  getToken: _token,
                  selectedWorker: _selectedWorker,
                  allWorkers: _workers,
                  onSaved: (created, savedWorker) async {
                    final loc = AppLocalizations.of(context)!;
                    final messenger = ScaffoldMessenger.of(context);
                    await _load();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          created ? loc.workerCreated : loc.workerUpdated,
                        ),
                      ),
                    );
                    if (created) _tabController.animateTo(0);
                    setState(() => _selectedWorker = savedWorker);
                  },
                  tabController: _tabController,
                  enableAddHoursTab: kIsWeb,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialSection(BuildContext context) {
    return WorkerCurrentMonthSummaryView(group: widget.group);
  }

  // ignore: unused_element
  Widget _buildRegisterHoursSection(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isEs = _isSpanish(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 44,
            color: cs.onSurfaceVariant.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),
          Text(
            isEs ? 'Próximamente' : 'Coming soon',
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isEs
                  ? 'La funcionalidad de registro de horas estará disponible próximamente.'
                  : 'The hour registration feature will be available soon.',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _workers.isEmpty ? null : _addSharedHours,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(isEs ? 'Registro manual' : 'Manual entry'),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final imported = await TimeTrackingExcelImportDialog.show(
                    context,
                    group: widget.group,
                  );
                  if (imported) {
                    await _load();
                  }
                },
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(isEs ? 'Importar Excel' : 'Import Excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterHoursImportSection(BuildContext context) {
    return TimeTrackingExcelImportDialog(
      group: widget.group,
      embedded: true,
      onImported: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);

    if (_loading) return const LoadingList();
    if (_pluginDisabled) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.timeTrackingDisabledTitle,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l.timeTrackingDisabledSubtitle,
                  style: t.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _toggling ? null : _enable,
                child: Text(l.enableTrackingCta),
              ),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: t.bodySmall.copyWith(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _load, child: Text(l.refresh)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSideMenu(context),
                const SizedBox(width: 12),
                Expanded(
                  child: FolderPanel(
                    title: _sectionTitle(context),
                    showTab: true,
                    child: IndexedStack(
                      index: _section.index,
                      children: [
                        _buildWorkersSection(context),
                        WorkerTimeHistoryGraphView(
                          key: ValueKey(
                              'inline-worker-graphs-${widget.group.id}'),
                          group: widget.group,
                        ),
                        _buildHistorialSection(context),
                        TelegramWorkerHoursImportView(group: widget.group),
                        _buildRegisterHoursImportSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addHoursForWorker(Worker w) async {
    if (kIsWeb) {
      _tabController.animateTo(2);
      setState(() {
        _selectedWorker = w;
        _showOverview = false;
      });
      return;
    }
    final ordered = [w, ..._workers.where((x) => x.id != w.id)];
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CreateTimeEntryScreen(group: widget.group, workers: ordered),
      ),
    );
    if (created == true) _load();
  }

  Future<void> _openOverview(Worker w) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.95,
        child: WorkerMonthlyOverviewScreen(group: widget.group, worker: w),
      ),
    );
    if (created == true) _load();
  }
}

class _PayrollHistoryDialog extends StatefulWidget {
  const _PayrollHistoryDialog({
    required this.group,
    required this.repo,
    required this.getToken,
  });

  final Group group;
  final ITimeTrackingRepository repo;
  final Future<String> Function() getToken;

  @override
  State<_PayrollHistoryDialog> createState() => _PayrollHistoryDialogState();
}

class _PayrollHistoryDialogState extends State<_PayrollHistoryDialog> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _history;
  late int _year;
  bool _hideEmpty = false;

  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'es';

  String _formatMonth(String monthStr) {
    try {
      final dt = DateTime.parse('$monthStr-01');
      final locale = Localizations.localeOf(context).toLanguageTag();
      final raw = DateFormat('MMMM y', locale).format(dt);
      return raw.isEmpty ? monthStr : raw[0].toUpperCase() + raw.substring(1);
    } catch (_) {
      return monthStr;
    }
  }

  bool _isCurrentMonth(String monthStr) {
    final now = DateTime.now();
    return monthStr == '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    _load();
  }

  String _money(num amount, {String? currency}) {
    final locale = AppLocalizations.of(context)!.localeName;
    final formatted = NumberFormat.currency(
      locale: locale,
      symbol: '',
      decimalDigits: 2,
    ).format(amount).trim();
    if (currency == null || currency.isEmpty) return formatted;
    return '$formatted $currency';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final from = DateTime.utc(_year, 1, 1);
    final to = DateTime.utc(_year + 1, 1, 1);
    try {
      final token = await widget.getToken();
      final data = await widget.repo.getMonthlyPayrollHistory(
        widget.group.id,
        token,
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() => _history = data);
    } catch (e) {
      if (!mounted) return;
      var message = _isSpanish
          ? 'No se pudo cargar el historial.'
          : 'Could not load payroll history.';
      if (e is BackendApiException && e.message.trim().isNotEmpty) {
        message = e.message;
      }
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final months = (_history?['months'] as List?) ?? const [];
    final totals = (_history?['totals'] as Map?) ?? const {};

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: t.bodyMedium.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l.refresh),
            ),
          ],
        ),
      );
    } else {
      final totalsByCurrency =
          (totals['totalsByCurrency'] as List?) ?? const [];
      final totalPay = (totals['totalPay'] as num?)?.toDouble();
      final currency = totals['currency']?.toString();
      final multiCurrency = currency == null || totalsByCurrency.length > 1;
      final totalEntries = (totals['entriesCount'] as num?)?.toInt() ?? 0;
      final totalHours = (totals['totalHours'] as num?)?.toDouble() ?? 0;

      final visibleMonths = _hideEmpty
          ? months
              .where((m) =>
                  m is Map && ((m['entriesCount'] as num?)?.toInt() ?? 0) > 0)
              .toList()
          : months;

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Totals summary card ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.08),
                  cs.primary.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                _statBlock(
                  icon: Icons.receipt_long_rounded,
                  label: _isSpanish ? 'Registros' : 'Entries',
                  value: '$totalEntries',
                  color: cs.primary,
                  t: t,
                  cs: cs,
                ),
                const SizedBox(width: 20),
                _statBlock(
                  icon: Icons.schedule_rounded,
                  label: _isSpanish ? 'Horas' : 'Hours',
                  value: '${totalHours.toStringAsFixed(1)} h',
                  color: cs.secondary,
                  t: t,
                  cs: cs,
                ),
                const Spacer(),
                if (!multiCurrency && totalPay != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isSpanish ? 'Total' : 'Total',
                        style: t.caption
                            .copyWith(color: cs.onSurfaceVariant, fontSize: 10),
                      ),
                      Text(
                        _money(totalPay, currency: currency),
                        style: t.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: totalsByCurrency.map<Widget>((item) {
                      if (item is! Map) return const SizedBox.shrink();
                      final curr = item['currency']?.toString() ?? '-';
                      final pay = (item['totalPay'] as num?)?.toDouble() ?? 0;
                      return Text(
                        _money(pay, currency: curr),
                        style: t.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700, color: cs.primary),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Section label + hide-empty toggle ───────────────────────
          Row(
            children: [
              Text(
                (_isSpanish ? 'Meses' : 'Months').toUpperCase(),
                style: t.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _hideEmpty = !_hideEmpty),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hideEmpty
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 13,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSpanish
                            ? (_hideEmpty ? 'Mostrar vacíos' : 'Ocultar vacíos')
                            : (_hideEmpty ? 'Show empty' : 'Hide empty'),
                        style: t.caption.copyWith(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Month list ──────────────────────────────────────────────
          Expanded(
            child: visibleMonths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(
                          _isSpanish
                              ? 'Sin datos para este periodo.'
                              : 'No data for this period.',
                          style:
                              t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleMonths.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final item = visibleMonths[i];
                      if (item is! Map) return const SizedBox.shrink();
                      final monthStr = item['month']?.toString() ?? '-';
                      final entries =
                          (item['entriesCount'] as num?)?.toInt() ?? 0;
                      final hours =
                          (item['totalHours'] as num?)?.toDouble() ?? 0;
                      final pay = (item['totalPay'] as num?)?.toDouble();
                      final curr = item['currency']?.toString();
                      final byCurrency =
                          (item['totalsByCurrency'] as List?) ?? const [];
                      final itemMultiCurrency =
                          curr == null || byCurrency.length > 1;
                      final isEmpty = entries == 0;
                      final isCurrent = _isCurrentMonth(monthStr);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? cs.primary.withValues(alpha: 0.07)
                              : isEmpty
                                  ? cs.surfaceContainerHighest
                                      .withValues(alpha: 0.08)
                                  : cs.surfaceContainerHighest
                                      .withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? cs.primary.withValues(alpha: 0.25)
                                : cs.outlineVariant
                                    .withValues(alpha: isEmpty ? 0.15 : 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Month indicator dot
                            if (isCurrent)
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(right: 7),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // Month name
                            SizedBox(
                              width: 120,
                              child: Text(
                                _formatMonth(monthStr),
                                style: t.bodySmall.copyWith(
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : (isEmpty
                                          ? FontWeight.w400
                                          : FontWeight.w600),
                                  color: isEmpty
                                      ? cs.onSurface.withValues(alpha: 0.35)
                                      : cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Entries
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 12,
                                    color: isEmpty
                                        ? cs.onSurface.withValues(alpha: 0.25)
                                        : cs.primary.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$entries',
                                    style: t.bodySmall.copyWith(
                                      color: isEmpty
                                          ? cs.onSurface.withValues(alpha: 0.30)
                                          : cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Hours
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: isEmpty
                                        ? cs.onSurface.withValues(alpha: 0.25)
                                        : cs.secondary.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${hours.toStringAsFixed(1)} h',
                                    style: t.bodySmall.copyWith(
                                      color: isEmpty
                                          ? cs.onSurface.withValues(alpha: 0.30)
                                          : cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Pay amount
                            if (!isEmpty) ...[
                              if (!itemMultiCurrency && pay != null)
                                Text(
                                  _money(pay, currency: curr),
                                  style: t.bodySmall
                                      .copyWith(fontWeight: FontWeight.w700),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: byCurrency.map<Widget>(
                                    (currItem) {
                                      if (currItem is! Map) {
                                        return const SizedBox.shrink();
                                      }
                                      final itemCurr =
                                          currItem['currency']?.toString() ??
                                              '-';
                                      final itemPay =
                                          (currItem['totalPay'] as num?)
                                                  ?.toDouble() ??
                                              0;
                                      return Text(
                                        _money(itemPay, currency: itemCurr),
                                        style: t.bodySmall.copyWith(
                                            fontWeight: FontWeight.w700),
                                      );
                                    },
                                  ).toList(),
                                ),
                            ] else
                              Text(
                                '—',
                                style: t.bodySmall.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.25),
                                ),
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

    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: cs.primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isSpanish ? 'Historial de nóminas' : 'Payroll history',
            ),
          ),
          // Year prev/next navigation
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: _isSpanish ? 'Año anterior' : 'Previous year',
            onPressed: () {
              setState(() => _year--);
              _load();
            },
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$_year',
              textAlign: TextAlign.center,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: _isSpanish ? 'Año siguiente' : 'Next year',
            onPressed: _year >= DateTime.now().year + 1
                ? null
                : () {
                    setState(() => _year++);
                    _load();
                  },
          ),
          if (_loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              tooltip: l.refresh,
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  }

  Widget _statBlock({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required AppTypography t,
    required ColorScheme cs,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: t.caption.copyWith(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
