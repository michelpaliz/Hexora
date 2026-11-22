import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/section_app_bar.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_access.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/tabs/workspace_content.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_access.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:provider/provider.dart';

import 'enable_banking_controller.dart';
import 'enable_banking_left_nav.dart';
import 'enable_banking_link_store.dart';
import 'statements/all_data/mobile/statements_mobile_view.dart';
import 'statements/all_data/statements_all_data_tab.dart';
import 'statements/all_data/statements_all_data_details.dart';
import 'statements/analytics/mobile/statements_analytics_mobile.dart';
import 'statements/analytics/statements_analytics_copy.dart';
import 'statements/analytics/statements_analytics_controller.dart';
import 'statements/analytics/statements_analytics_view.dart';
import 'statements/statements_controller.dart';
import 'statements/statements_shared.dart';
import 'statements/statements_history_tab.dart';
import 'statements/statements_import_view.dart';
import 'truelayer_controller.dart';
import 'widgets/folder_section_card.dart';

class EnableBankingScreen extends StatelessWidget {
  const EnableBankingScreen({
    super.key,
    this.group,
    this.embedded = false,
    this.initialEntry,
    this.initialReviewLink = false,
  });

  final Group? group;
  final bool embedded;
  final Map<String, dynamic>? initialEntry;
  final bool initialReviewLink;

  static EnableBankingScreen fromRoute(BuildContext context) {
    final group = ModalRoute.of(context)?.settings.arguments as Group? ??
        context.read<GroupDomain?>()?.currentGroup;
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
      child: _EnableBankingView(
          group: group,
          embedded: embedded,
          initialEntry: initialEntry,
          initialReviewLink: initialReviewLink),
    );
  }
}

class _SourceDataTabsView extends StatelessWidget {
  const _SourceDataTabsView({
    required this.initialIndex,
    required this.isMobile,
    required this.isSpanish,
    required this.historyLabel,
  });

  final int initialIndex;
  final bool isMobile;
  final bool isSpanish;
  final String historyLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tabs = [
      Tab(text: isSpanish ? 'Movimientos' : 'Movements'),
      Tab(text: isSpanish ? 'Importar' : 'Import'),
      Tab(text: historyLabel),
    ];
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Column(
        children: [
          Material(
            color: cs.surface,
            child: SizedBox(
              height: 44,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: tabs,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                indicatorColor: cs.primary,
                dividerColor: cs.outlineVariant.withValues(alpha: .35),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                isMobile
                    ? const StatementsMobileView()
                    : const StatementsAllDataTab(),
                const StatementsImportView(),
                const _SourceHistoryView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceHistoryView extends StatelessWidget {
  const _SourceHistoryView();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: FolderSectionCard(
        label: l.statementsHistoryTabTitle,
        showTitle: false,
        leftTabOffset: 0,
        actions: const [],
        child: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: StatementsHistoryTab(),
        ),
      ),
    );
  }
}

class _EnableBankingView extends StatefulWidget {
  const _EnableBankingView({
    required this.group,
    required this.embedded,
    required this.initialEntry,
    required this.initialReviewLink,
  });

  final Group? group;
  final bool embedded;
  final Map<String, dynamic>? initialEntry;
  final bool initialReviewLink;

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
        return isSpanish ? 'Importar' : 'Import';
      case EnableBankingMenu.history:
        return l.statementsHistoryTabTitle;
      case EnableBankingMenu.banking:
        return isSpanish ? 'Movimientos' : 'Movements';
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

    if (widget.initialEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialReviewLink) {
          final entry = widget.initialEntry!;
          final amount = num.tryParse(entry['amount']?.toString() ?? '') ?? 0;
          StatementsShared.showInvoiceLinkDialog(
              context, context.read<StatementsController>(), entry,
              expenseOnly: amount < 0);
          return;
        }
        StatementsAllDataDetails.show(
          context,
          AppLocalizations.of(context)!,
          widget.initialEntry!,
          context.read<StatementsController>(),
        );
      });
    }

    if (!context.mounted) return;
    Future<void>(() async {
      if (!mounted) return;
      await context.read<StatementsController>().listImports();
    });

    Future<void>(() async {
      if (!mounted) return;
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
    final sourceMenu = forMenu ?? _selectedMenu;
    if (sourceMenu == EnableBankingMenu.banking ||
        sourceMenu == EnableBankingMenu.imports ||
        sourceMenu == EnableBankingMenu.history) {
      return _SourceDataTabsView(
        initialIndex: sourceMenu == EnableBankingMenu.imports
            ? 1
            : sourceMenu == EnableBankingMenu.history
                ? 2
                : 0,
        isMobile: isMobile,
        isSpanish: Localizations.localeOf(context).languageCode == 'es',
        historyLabel: l.statementsHistoryTabTitle,
      );
    }

    switch (sourceMenu) {
      case EnableBankingMenu.imports:
      case EnableBankingMenu.history:
      case EnableBankingMenu.banking:
        return const SizedBox.shrink();

      /*
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
                padding: const EdgeInsets.symmetric(
                    horizontal: HexoraTableTokens.cellPadding, vertical: 6),
                minimumSize: const Size(0, HexoraDimensions.buttonCompact),
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
              showTitle: false,
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
      */

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserDomain?>()?.user?.id;
    final canUseBanking = canManagePremiumFeature(
        widget.group, currentUserId, PremiumFeature.banking);
    if (!canUseBanking) {
      return PremiumFeatureRequestScreen(
        feature: PremiumFeatureRequest.banking,
        group: widget.group,
        embedded: widget.embedded,
      );
    }
    final l = AppLocalizations.of(context)!;
    if (!hasPremiumFeature(widget.group, PremiumFeature.banking)) {
      return PremiumFeatureRequestScreen(
        group: widget.group,
        feature: PremiumFeatureRequest.banking,
        embedded: widget.embedded,
      );
    }
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final group = widget.group;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    // ── Mobile layout ─────────────────────────────────────────────────────────
    if (isMobile) {
      final cs = Theme.of(context).colorScheme;
      final tabBar = PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: TabBar(
              controller: _mobileTabController,
              tabs: [
                Tab(text: isSpanish ? 'Movimientos' : l.statementsAllDataTitle),
                Tab(
                    text:
                        isSpanish ? 'Analíticas' : l.statementsAnalyticsTitle),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
              unselectedLabelStyle:
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                      ),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
              splashBorderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
      final body = TabBarView(
        controller: _mobileTabController,
        children: [
          for (final menu in _mobileTabs)
            _buildContentArea(context, l, forMenu: menu, isMobile: true),
        ],
      );

      if (widget.embedded) {
        return Column(
          children: [
            Material(color: cs.surface, child: tabBar),
            Expanded(child: body),
          ],
        );
      }

      return Scaffold(
        appBar: SectionAppBar(
          title: isSpanish ? 'Bancos' : 'Bank',
          bottom: tabBar,
        ),
        body: body,
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
            Expanded(
              child: WorkspaceMainContent(
                child: _buildContentArea(context, l, isMobile: false),
              ),
            ),
            const SizedBox(width: 12),
          ],
        );
      },
    );

    if (widget.embedded) return desktopContent;

    return Scaffold(
      appBar: SectionAppBar(
        title: group == null
            ? _menuTitle(l, _selectedMenu)
            : '${_menuTitle(l, _selectedMenu)} - ${group.name}',
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
