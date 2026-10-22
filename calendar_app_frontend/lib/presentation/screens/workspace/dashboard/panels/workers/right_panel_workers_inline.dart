import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/presentation/shared/widgets/navigation_menu_header.dart';
import 'package:hexora/theme/themes/navigation_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/services/time_tracking/repository/time_tracking_repository.dart';
import 'package:hexora/services/shared/backend_api_exception.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/loading_list.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/telegram_worker_hours_import_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/time_tracking_excel_import_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_current_month_summary_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_month_picker_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_time_history_graph_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_directory_tabs.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker_account_setup_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/worker/entry_screen/tracking/screens/create_time_entry/create_time_entry_screen.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/l10n/build_context_locale.dart';
import 'package:provider/provider.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/nav_section.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/side_menu/sub_menu_item.dart';
import 'package:hexora/presentation/shared/widgets/folder_panel.dart';

import 'widgets/status_filter_chips.dart';
import 'widgets/worker_directory_view.dart';
import 'widgets/worker_monthly_overview_inline.dart';
import 'widgets/workers_form_panel.dart';

enum _InlineSection {
  workers,
  graphs,
  historial,
  telegramImport,
  registerHours,
  accountSetup,
}

String _formatMoney(
  BuildContext context,
  num amount, {
  String? currency,
}) {
  final locale = AppLocalizations.of(context)!.localeName;
  final formatted = NumberFormat.currency(
    locale: locale,
    symbol: '',
    decimalDigits: 2,
  ).format(amount).trim();
  if (currency == null || currency.isEmpty) return formatted;
  return '$formatted $currency';
}

class _WorkersNavHeader extends StatelessWidget {
  const _WorkersNavHeader({
    required this.title,
    required this.onCollapse,
  });

  final String title;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    return NavigationMenuHeader(
        title: title, icon: Icons.people_outline, onToggle: onCollapse);
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
    required this.showAccountSetup,
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
  final bool showAccountSetup;

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
      return SidebarItem(
          icon: icon,
          label: tooltip,
          isSelected: selectedOverride || selected == section,
          collapsed: true,
          onTap: onTap ?? (section == null ? null : () => onSelect(section)));
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
                width: NavigationTokens.rowHeight(context),
                height: NavigationTokens.rowHeight(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: NavigationTokens.iconSize,
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
                  if (showAccountSetup) ...[
                    const SizedBox(height: 3),
                    item(Icons.manage_accounts_outlined, 'Cuentas de acceso',
                        section: _InlineSection.accountSetup),
                  ],
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
  static const double _expandedMenuWidth = NavigationTokens.sidebarWidth;
  static const double _collapsedMenuWidth = NavigationTokens.railWidth;

  late UserDomain _userDomain;
  late ITimeTrackingRepository _repo;

  bool _loading = false;
  bool _toggling = false;
  bool _pluginDisabled = false;
  String? _error;
  List<Worker> _workers = const [];
  bool _showPartners = false;
  bool _showWorkerForm = false;
  Worker? _selectedWorker;
  Worker? _overviewWorker;
  _InlineSection _section = _InlineSection.workers;
  late final TabController _tabController;
  WorkerStatusFilter _statusFilter = WorkerStatusFilter.all;
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

  bool _isSpanish(BuildContext context) => context.isSpanishLocale;

  String _activeWorkersLabel(BuildContext context) =>
      _isSpanish(context) ? 'activos' : 'active';

  String _emptyTotalsLabel(BuildContext context) => _isSpanish(context)
      ? 'Aún no hay registros este mes.'
      : 'No entries yet this month.';

  String _defaultTotalsErrorLabel(BuildContext context) => _isSpanish(context)
      ? 'No se pudo cargar el total.'
      : 'Could not load total.';

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

  void _shiftTotalsMonth(int offset) {
    final month = DateTime(_totalsYear, _totalsMonth + offset);
    setState(() {
      _totalsYear = month.year;
      _totalsMonth = month.month;
    });
    _reloadActiveTotals();
  }

  Widget _buildActiveTotalsInlineCard(BuildContext context,
      {bool controlsOnly = false}) {
    final cs = Theme.of(context).colorScheme;
    final isEs = _isSpanish(context);
    final entries = (_activeTotals?['entriesCount'] as num?) ?? 0;
    final totalsByCurrency =
        (_activeTotals?['totalsByCurrency'] as List?) ?? [];
    final currency = _activeTotals?['currency']?.toString();
    final pay = _activeTotals?['totalPay'] as num?;
    final summary = _activeTotalsLoading
        ? const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)))
        : _activeTotalsError != null
            ? Text(_activeTotalsError!, style: TextStyle(color: cs.error))
            : entries <= 0
                ? Text(_emptyTotalsLabel(context),
                    style: TextStyle(color: cs.onSurfaceVariant))
                : Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                        if (currency != null &&
                            totalsByCurrency.length <= 1 &&
                            pay != null)
                          Text(_formatMoney(context, pay, currency: currency),
                              style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700))
                        else
                          for (final item in totalsByCurrency)
                            if (item is Map)
                              Text(_formatMoney(
                                  context, (item['totalPay'] as num?) ?? 0,
                                  currency: item['currency']?.toString())),
                        Text(
                            '${_activeTotals?['activeWorkersCount'] ?? 0} ${_activeWorkersLabel(context)}'),
                        Text(
                            '${((_activeTotals?['totalHours'] as num?) ?? 0).toStringAsFixed(1)} h'),
                        TextButton.icon(
                            onPressed: _openPayrollHistoryDialog,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: Text(isEs ? 'Historial' : 'History')),
                      ]);
    final controls = Row(mainAxisSize: MainAxisSize.min, children: [
      OutlinedButton.icon(
        onPressed: _activeTotalsLoading ? null : _pickTotalsMonth,
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_selectedMonthLabel(context)),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more_rounded, size: 18),
        ]),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 34),
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 13),
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: .55)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      const SizedBox(width: 12),
      IconButton.outlined(
        tooltip: isEs ? 'Mes anterior' : 'Previous month',
        style: IconButton.styleFrom(
          minimumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: .55)),
        ),
        onPressed:
            _activeTotalsLoading || (_totalsYear == 2018 && _totalsMonth == 1)
                ? null
                : () => _shiftTotalsMonth(-1),
        icon: const Icon(Icons.chevron_left_rounded, size: 20),
      ),
      const SizedBox(width: 6),
      IconButton.outlined(
        tooltip: isEs ? 'Mes siguiente' : 'Next month',
        style: IconButton.styleFrom(
          minimumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: .55)),
        ),
        onPressed:
            _activeTotalsLoading || (_totalsYear == 2100 && _totalsMonth == 12)
                ? null
                : () => _shiftTotalsMonth(1),
        icon: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    ]);
    if (controlsOnly) return controls;
    final refresh = IconButton.outlined(
      tooltip: AppLocalizations.of(context)!.refresh,
      onPressed: _activeTotalsLoading ? null : _reloadActiveTotals,
      icon: const Icon(Icons.refresh_rounded, size: 20),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 700 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [controls, refresh]),
                const SizedBox(height: 12),
                summary,
              ]);
        }
        return Row(children: [
          controls,
          const SizedBox(width: 20),
          Expanded(child: summary),
          const SizedBox(width: 12),
          refresh
        ]);
      }),
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
      _showWorkerForm = true;
    });
    return null;
  }

  void _openMonthlyOverview(Worker w) {
    setState(() => _overviewWorker = w);
  }

  void _openCreateWorkerForm() {
    _tabController.animateTo(1);
    setState(() {
      _section = _InlineSection.workers;
      _overviewWorker = null;
      _selectedWorker = null;
      _showWorkerForm = true;
    });
  }

  bool get _canManageAccounts {
    final userId = _userDomain.user?.id;
    if (userId == null) return false;
    final role = widget.group.userRoles[userId]?.toLowerCase();
    return widget.group.ownerId == userId ||
        role == 'owner' ||
        role == 'admin' ||
        role == 'co-admin';
  }

  Widget _buildSideMenu(BuildContext context) =>
      NavigationSurface(builder: _buildNavigation);

  Widget _buildNavigation(BuildContext context) {
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
        showAccountSetup: _canManageAccounts,
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
                          indent: NavigationTokens.nestedIndent,
                          onPressed: _openCreateWorkerForm,
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.group_outlined,
                          label: l.workersLabel,
                          selected: _section == _InlineSection.workers,
                          indent: NavigationTokens.nestedIndent,
                          onPressed: () => setState(
                            () => _section = _InlineSection.workers,
                          ),
                        ),
                        if (_canManageAccounts)
                          GroupInvoicesSubMenuItem(
                            icon: Icons.manage_accounts_outlined,
                            label:
                                isEs ? 'Cuentas de acceso' : 'Worker accounts',
                            selected: _section == _InlineSection.accountSetup,
                            indent: NavigationTokens.nestedIndent,
                            onPressed: () => setState(
                              () => _section = _InlineSection.accountSetup,
                            ),
                          ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.schedule_outlined,
                          label: isEs ? 'Registrar horas' : 'Register hours',
                          selected: _section == _InlineSection.registerHours,
                          indent: NavigationTokens.nestedIndent,
                          onPressed: () => setState(
                            () => _section = _InlineSection.registerHours,
                          ),
                        ),
                        GroupInvoicesSubMenuItem(
                          icon: Icons.telegram,
                          label: isEs ? 'Importar Telegram' : 'Telegram import',
                          selected: _section == _InlineSection.telegramImport,
                          indent: NavigationTokens.nestedIndent,
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
                      indent: NavigationTokens.nestedIndent,
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
                      indent: NavigationTokens.nestedIndent,
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
      _InlineSection.accountSetup =>
        isEs ? 'Cuentas de acceso' : 'Worker accounts',
    };
  }

  Widget _buildWorkersSection(BuildContext context) {
    final directory = WorkerDirectoryView(
      group: widget.group,
      workers: _workers,
      showPartners: _showPartners,
      selectedWorkerId: _selectedWorker?.id,
      onTabChanged: (value) => setState(() {
        _showPartners = value;
        _selectedWorker = null;
        _showWorkerForm = false;
        _tabController.animateTo(0);
      }),
      monthSummary: _buildActiveTotalsInlineCard(context, controlsOnly: true),
      statusFilter: StatusFilterChips(
        value: _statusFilter,
        onChanged: (next) {
          setState(() => _statusFilter = next);
          _load();
        },
      ),
      onCreate: _openCreateWorkerForm,
      onEdit: _openEditWorkerDialog,
      onAddHours: _addHoursForWorker,
      onOverview: _openMonthlyOverview,
    );
    final details = WorkersFormPanel(
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
        messenger.showSnackBar(SnackBar(
            content: Text(
          created ? loc.workerCreated : loc.workerUpdated,
        )));
        setState(() {
          _selectedWorker = savedWorker;
          _showPartners = isPartnerWorker(savedWorker, widget.group);
          _showWorkerForm = false;
          _tabController.animateTo(0);
        });
      },
      tabController: _tabController,
      enableAddHoursTab: kIsWeb,
      onTimeEntryChanged: _reloadActiveTotals,
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1040) {
        return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 3, child: directory),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: details),
        ]);
      }
      return Stack(children: [
        Positioned.fill(child: directory),
        if (_showWorkerForm)
          Positioned.fill(
              child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _showWorkerForm = false;
                        }),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(_isSpanish(context)
                            ? 'Volver al equipo'
                            : 'Back to team'),
                      )),
                  Expanded(child: details),
                ]),
          )),
      ]);
    });
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

    if (_loading && _workers.isEmpty) return const LoadingList();
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
      padding: EdgeInsets.zero,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: FolderPanel(
                      title: _sectionTitle(context),
                      showTab: _section != _InlineSection.workers,
                      contentTopPadding:
                          _section == _InlineSection.workers ? 12 : 30,
                      child: IndexedStack(
                        index: _section.index,
                        children: [
                          IndexedStack(
                            index: _overviewWorker == null ? 0 : 1,
                            children: [
                              _buildWorkersSection(context),
                              if (_overviewWorker != null)
                                WorkerMonthlyOverviewInline(
                                  group: widget.group,
                                  worker: _overviewWorker!,
                                  repo: _repo,
                                  getToken: _token,
                                  onBack: () =>
                                      setState(() => _overviewWorker = null),
                                  onDataChanged: _reloadActiveTotals,
                                ),
                            ],
                          ),
                          WorkerTimeHistoryGraphView(
                            key: ValueKey(
                                'inline-worker-graphs-${widget.group.id}'),
                            group: widget.group,
                          ),
                          _buildHistorialSection(context),
                          TelegramWorkerHoursImportView(group: widget.group),
                          _buildRegisterHoursImportSection(context),
                          WorkerAccountSetupScreen(group: widget.group),
                        ],
                      ),
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
        _showWorkerForm = true;
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

  bool get _isSpanish => context.isSpanishLocale;

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
                        _formatMoney(context, totalPay, currency: currency),
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
                        _formatMoney(context, pay, currency: curr),
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
                                  _formatMoney(context, pay, currency: curr),
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
                                        _formatMoney(context, itemPay,
                                            currency: itemCurr),
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
