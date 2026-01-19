import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:provider/provider.dart';

import 'banking_tab.dart';
import 'enable_banking_controller.dart';
import 'enable_banking_left_nav.dart';
import 'enable_banking_link_store.dart';
import 'statements/all_data/statements_all_data_tab.dart';
import 'statements/analytics/statements_analytics_controller.dart';
import 'statements/analytics/statements_analytics_view.dart';
import 'statements/statements_controller.dart';
import 'statements/statements_import_view.dart';
import 'truelayer_controller.dart';

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
        ChangeNotifierProvider(create: (_) => StatementsAnalyticsController()),
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

class _EnableBankingViewState extends State<_EnableBankingView> {
  bool _didInit = false;
  EnableBankingMenu _selectedMenu = EnableBankingMenu.imports;
  bool _navCollapsed = false;

  bool? _parseBool(String? v) {
    if (v == null) return null;
    final s = v.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
    return null;
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

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final content = Row(
      children: [
        const SizedBox(width: 12),
        EnableBankingLeftNav(
          selected: _selectedMenu,
          onSelect: (menu) => setState(() => _selectedMenu = menu),
          collapsed: _navCollapsed,
          onToggleCollapse: () =>
              setState(() => _navCollapsed = !_navCollapsed),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _selectedMenu == EnableBankingMenu.imports
              ? const StatementsImportView()
              : (_selectedMenu == EnableBankingMenu.allData
                  ? const StatementsAllDataTab()
                  : (_selectedMenu == EnableBankingMenu.analytics
                      ? const StatementsAnalyticsView()
                      : const BankingTab())),
        ),
        const SizedBox(width: 12),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group == null
            ? 'Enable Banking'
            : 'Enable Banking • ${group.name}'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh),
            onPressed:
                context.read<EnableBankingController>().refreshLinkStatus,
          ),
        ],
      ),
      body: content,
    );
  }
}
