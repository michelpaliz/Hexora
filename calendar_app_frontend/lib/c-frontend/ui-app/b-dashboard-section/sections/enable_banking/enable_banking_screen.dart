import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'banking_tab.dart';
import 'enable_banking_controller.dart';
import 'enable_banking_left_nav.dart';
import 'enable_banking_link_store.dart';
import 'statements/all_data/mobile/statements_mobile_view.dart';
import 'statements/all_data/statements_all_data_tab.dart';
import 'statements/analytics/mobile/statements_analytics_mobile.dart';
import 'statements/analytics/statements_analytics_copy.dart';
import 'statements/analytics/statements_analytics_controller.dart';
import 'statements/analytics/statements_analytics_view.dart';
import 'statements/statements_controller.dart';
import 'statements/statements_history_tab.dart';
import 'statements/statements_import_view.dart';
import 'truelayer_controller.dart';
import 'widgets/folder_section_card.dart';

class EnableBankingScreen extends StatelessWidget {
  const EnableBankingScreen({
    super.key,
    this.group,
    this.embedded = false,
  });

  final Group? group;
  final bool embedded;

  static EnableBankingScreen fromRoute(BuildContext context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group?;
    return EnableBankingScreen(group: group);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnableBankingController()),
        ChangeNotifierProvider(create: (_) => TrueLayerController()),
        ChangeNotifierProvider(
          create: (_) => StatementsController(groupId: group?.id),
        ),
        ChangeNotifierProvider(
          create: (_) => StatementsAnalyticsController(groupId: group?.id),
        ),
      ],
      child: _EnableBankingView(group: group, embedded: embedded),
    );
  }
}

class _EnableBankingView extends StatefulWidget {
  const _EnableBankingView({
    required this.group,
    required this.embedded,
  });

  final Group? group;
  final bool embedded;

  @override
  State<_EnableBankingView> createState() => _EnableBankingViewState();
}

class _EnableBankingViewState extends State<_EnableBankingView>
    with SingleTickerProviderStateMixin {
  bool _didInit = false;
  EnableBankingMenu _selectedMenu = EnableBankingMenu.allData;
  late final TabController _mobileTabController;
  // null = auto (collapses when width < 1100), true/false = user override
  bool? _sidebarCollapsedManual;

  // Mobile shows only these two tabs
  static const _mobileTabs = [
    EnableBankingMenu.allData,
    EnableBankingMenu.analyticsOverview,
  ];

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(
      length: _mobileTabs.length,
      vsync: this,
    );
    _mobileTabController.addListener(() {
      if (_mobileTabController.indexIsChanging) return;
      setState(() => _selectedMenu = _mobileTabs[_mobileTabController.index]);
    });
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    super.dispose();
  }

  bool? _parseBool(String? v) {
    if (v == null) return null;
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
    return null;
  }

  String _menuTitle(AppLocalizations l, EnableBankingMenu menu) {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    switch (menu) {
      case EnableBankingMenu.imports:
        return isSpanish ? 'Importar Excel' : 'Import Excel';
      case EnableBankingMenu.history:
        return l.statementsHistoryTabTitle;
      case EnableBankingMenu.banking:
        return 'Bank';
      case EnableBankingMenu.allData:
        return isSpanish ? 'Movimientos' : l.statementsAllDataTitle;
      case EnableBankingMenu.analyticsOverview:
        return isSpanish ? 'Analiticas · Resumen' : l.statementsAnalyticsTitle;
      case EnableBankingMenu.analyticsSplit:
        return isSpanish
            ? 'Analiticas · ${StatementsAnalyticsCopy.splitTitle(context)}'
            : StatementsAnalyticsCopy.splitTitle(context);
      case EnableBankingMenu.analyticsVolume:
        return isSpanish
            ? 'Analiticas · ${StatementsAnalyticsCopy.volumeTitle(context)}'
            : StatementsAnalyticsCopy.volumeTitle(context);
      case EnableBankingMenu.analyticsTicket:
        return isSpanish
            ? 'Analiticas · ${StatementsAnalyticsCopy.ticketTitle(context)}'
            : StatementsAnalyticsCopy.ticketTitle(context);
      case EnableBankingMenu.analyticsLinked:
        return isSpanish
            ? 'Analiticas · ${StatementsAnalyticsCopy.linkedTitle(context)}'
            : StatementsAnalyticsCopy.linkedTitle(context);
      case EnableBankingMenu.analyticsActivity:
        return isSpanish
            ? 'Analiticas · ${StatementsAnalyticsCopy.activityTitle(context)}'
            : StatementsAnalyticsCopy.activityTitle(context);
      case EnableBankingMenu.analyticsStatus:
        return isSpanish
            ? 'Analiticas · ${StatementsAnalyticsCopy.statusTitle(context)}'
            : StatementsAnalyticsCopy.statusTitle(context);
      case EnableBankingMenu.analyticsTrends:
        return isSpanish
            ? 'Analiticas · Tendencias'
            : l.statementsAnalyticsTrends;
      case EnableBankingMenu.analyticsTopMerchants:
        return isSpanish
            ? 'Analiticas · Top comercios'
            : l.statementsAnalyticsTopMerchants;
      case EnableBankingMenu.analyticsComparison:
        return isSpanish
            ? 'Analiticas · Comparacion'
            : l.statementsAnalyticsCompareTitle;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    Future<void>(() => context.read<StatementsController>().listImports());

    Future<void>(() async {
      final name = ModalRoute.of(context)?.settings.name;
      if (name == null) return;
      final uri = Uri.tryParse(name);
      final qp = uri?.queryParameters;
      if (qp == null || qp.isEmpty) return;

      final linked = _parseBool(qp['linked']);
      final sessionId = qp['session_id'] ?? qp['sessionId'];
      final error = qp['error'];

      if (linked != null || sessionId != null || error != null) {
        await EnableBankingLinkStore.save(
          linked: linked,
          sessionId: sessionId,
          error: error,
        );
        if (!mounted) return;
        await context.read<EnableBankingController>().refreshLinkStatus();
      }
    });
  }

  Widget _buildContentArea(
    BuildContext context,
    AppLocalizations l, {
    EnableBankingMenu? forMenu,
    bool isMobile = false,
  }) {
    switch (forMenu ?? _selectedMenu) {
      case EnableBankingMenu.imports:
        return const StatementsImportView();

      case EnableBankingMenu.history:
        return Builder(builder: (context) {
          final s = context.watch<StatementsController>();
          final cs = Theme.of(context).colorScheme;
          Widget thresholdButton(int value) {
            final sel = s.statusThreshold == value;
            return OutlinedButton(
              onPressed: () => s.setStatusThreshold(value),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(36, 30),
                backgroundColor:
                    sel ? cs.primaryContainer.withValues(alpha: 0.9) : null,
              ),
              child: Text('$value'),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: FolderSectionCard(
              label: l.statementsHistoryTabTitle,
              leftTabOffset: 0,
              actions: [
                Tooltip(
                  message: l.statementsFreshnessThreshold,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      thresholdButton(3),
                      const SizedBox(width: 4),
                      thresholdButton(5),
                      const SizedBox(width: 4),
                      thresholdButton(7),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.refreshAction,
                  onPressed: s.loadingImports ? null : s.listImports,
                  icon: const Icon(Icons.refresh, size: 18),
                  constraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                  padding: EdgeInsets.zero,
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.only(top: 12),
                child: StatementsHistoryTab(),
              ),
            ),
          );
        });

      case EnableBankingMenu.allData:
        return isMobile
            ? const StatementsMobileView()
            : const StatementsAllDataTab();

      case EnableBankingMenu.analyticsOverview:
      case EnableBankingMenu.analyticsSplit:
      case EnableBankingMenu.analyticsVolume:
      case EnableBankingMenu.analyticsTicket:
      case EnableBankingMenu.analyticsLinked:
      case EnableBankingMenu.analyticsActivity:
      case EnableBankingMenu.analyticsStatus:
      case EnableBankingMenu.analyticsTrends:
      case EnableBankingMenu.analyticsTopMerchants:
      case EnableBankingMenu.analyticsComparison:
        return isMobile
            ? const StatementsMobileAnalyticsView()
            : StatementsAnalyticsView(section: forMenu ?? _selectedMenu);

      case EnableBankingMenu.banking:
        return const BankingTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final group = widget.group;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    // ── Mobile layout ─────────────────────────────────────────────────────────
    if (isMobile) {
      final mobileMenu = _mobileTabs[_mobileTabController.index];
      final body =
          _buildContentArea(context, l, forMenu: mobileMenu, isMobile: true);

      final cs = Theme.of(context).colorScheme;
      final t = AppTypography.of(context);
      final tabBar = TabBar(
        controller: _mobileTabController,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor:
            WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.08)),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
        labelColor: cs.onPrimaryContainer,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: t.bodyMedium.copyWith(fontWeight: FontWeight.w900),
        unselectedLabelStyle:
            t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        tabs: [
          Tab(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_chart_outlined, size: 15),
                const SizedBox(width: 6),
                Text(isSpanish ? 'Movimientos' : l.statementsAllDataTitle),
              ],
            ),
          ),
          Tab(
            height: 36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.analytics_outlined, size: 15),
                const SizedBox(width: 6),
                Text(isSpanish ? 'Analíticas' : l.statementsAnalyticsTitle),
              ],
            ),
          ),
        ],
      );

      if (widget.embedded) {
        return Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: tabBar,
            ),
            Expanded(child: body),
          ],
        );
      }

      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Bank',
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: tabBar,
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    // ── Wide / desktop layout ─────────────────────────────────────────────────
    final desktopContent = LayoutBuilder(
      builder: (context, constraints) {
        final autoCollapse = constraints.maxWidth < 1100;
        final collapsed = _sidebarCollapsedManual ?? autoCollapse;
        return Row(
          children: [
            EnableBankingLeftNav(
              selected: _selectedMenu,
              onSelect: (menu) => setState(() => _selectedMenu = menu),
              collapsed: collapsed,
              onToggleCollapse: () =>
                  setState(() => _sidebarCollapsedManual = !collapsed),
            ),
            const SizedBox(width: 8),
            Expanded(child: _buildContentArea(context, l, isMobile: false)),
            const SizedBox(width: 12),
          ],
        );
      },
    );

    if (widget.embedded) return desktopContent;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group == null
              ? _menuTitle(l, _selectedMenu)
              : '${_menuTitle(l, _selectedMenu)} - ${group.name}',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh),
            onPressed:
                context.read<EnableBankingController>().refreshLinkStatus,
          ),
        ],
      ),
      body: desktopContent,
    );
  }
}
