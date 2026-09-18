import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final (width, scale) in [(320.0, 1.5), (390.0, 1.0)]) {
    testWidgets('client invoice tabs fit ${width.toInt()}px at ${scale}x text',
        (tester) async {
      tester.view.physicalSize = Size(width, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.dark,
          platform: TargetPlatform.android,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              final controller = DefaultTabController.of(context);
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Las Alondras Playa'),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ClientInvoicesMobileTabBar(
                        controller: controller,
                        issuedCount: 8,
                        draftCount: 0,
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  controller: controller,
                  children: const [
                    Center(child: Text('Issued page')),
                    Center(child: Text('Draft page')),
                    Center(child: Text('Contracts page')),
                  ],
                ),
              );
            },
          ),
        ),
      ));

      final l = AppLocalizations.of(
        tester.element(find.byType(ClientInvoicesMobileTabBar)),
      )!;
      expect(find.text(l.groupInvoicesTabInvoices(8)), findsOneWidget);
      expect(find.text(l.groupInvoicesTabDrafts(0)), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text(l.contractsTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.contractsTitle));
      await tester.pumpAndSettle();
      expect(find.text('Contracts page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
