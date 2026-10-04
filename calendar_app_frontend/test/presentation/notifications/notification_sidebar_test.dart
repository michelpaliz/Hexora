import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/panels/notifications/widgets/notification_category_filter_bar.dart';
import 'package:hexora/presentation/shared/widgets/collapsible_sidebar.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('notification sidebar selects filters and collapses', (tester) async {
    var selected = NotificationWorkflowFilter.all;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.fromBrightness(Brightness.light),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: StatefulBuilder(builder: (context, update) => Row(
        children: [
          NotificationCategoryFilterBar(
            sidebar: true,
            notifications: const [],
            selectedWorkflow: selected,
            selectedCategory: null,
            onCategorySelected: (_) {},
            onWorkflowSelected: (value) => update(() => selected = value),
          ),
          const Expanded(child: Text('Content')),
        ],
      ))),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CollapsibleSidebar), findsOneWidget);
    await tester.tap(find.text('No leidas (0)'));
    await tester.pumpAndSettle();
    expect(selected, NotificationWorkflowFilter.unread);
    await tester.tap(find.byKey(const ValueKey('collapsible-sidebar-toggle')));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('collapsible-sidebar'))).width,
      CollapsibleSidebar.collapsedWidth);
    expect(tester.takeException(), isNull);
  });
}
