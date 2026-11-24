import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/premium/premium_feature_request_screen.dart';

Group _group() => Group(
      id: 'group-1',
      name: 'ClearFrame English Studio',
      ownerId: 'owner-1',
      userRoles: const {'owner-1': 'owner'},
      userIds: const ['owner-1'],
      createdTime: DateTime(2026),
      description: 'Demo business',
    );

void main() {
  testWidgets('premium request uses a compact dialog instead of an app page',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      home: PremiumFeatureRequestScreen(
        feature: PremiumFeatureRequest.banking,
        group: _group(),
      ),
    ));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Banking and transactions'), findsOneWidget);
    expect(find.text('Request access'), findsOneWidget);

    final size = tester.getSize(
      find.byKey(const ValueKey('premium-request-dialog')),
    );
    expect(size.width, lessThanOrEqualTo(480));
    expect(size.height, lessThan(450));
  });
}
