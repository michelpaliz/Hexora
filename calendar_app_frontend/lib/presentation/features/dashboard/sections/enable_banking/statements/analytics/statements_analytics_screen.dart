import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'statements_analytics_controller.dart';
import 'statements_analytics_view.dart';

class StatementsAnalyticsScreen extends StatelessWidget {
  const StatementsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatementsAnalyticsController(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.statementsAnalyticsTitle),
        ),
        body: const StatementsAnalyticsView(),
      ),
    );
  }
}
