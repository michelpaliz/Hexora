import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/c-group-calendar-section/screens/group/show-groups/group_profile/dialog_choosement/alert_dialog/widgets/group_identity_row.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('group dialog metadata fits narrow card at $scale text scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const Scaffold(
            body: Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GroupIdentityRow(
                  title: 'Mantenimiento Michael con nombre largo',
                  metaTexts: [],
                  metaEntries: [
                    MetaEntry.text('Creado el 8 oct 2025'),
                    MetaEntry.icon(Icons.group_outlined),
                  ],
                ),
                SizedBox(height: 12),
                Text('Grupo para la empresa de jardinería'),
              ],
            ),
          ),
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.group_outlined), findsWidgets);
      expect(find.text('Creado el 8 oct 2025'), findsOneWidget);
    });
  }
}
