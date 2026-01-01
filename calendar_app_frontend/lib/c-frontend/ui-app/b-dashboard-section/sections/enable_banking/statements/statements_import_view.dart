import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'statements_history_tab.dart';
import '../statements_tab.dart';

class StatementsImportView extends StatelessWidget {
  const StatementsImportView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: l.statementsImportTabTitle),
                Tab(text: l.statementsHistoryTabTitle),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: TabBarView(
              children: [
                StatementsTab(),
                StatementsHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
