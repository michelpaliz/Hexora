import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/invoice_editor_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/form/invoice_content_section.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  final group = Group(
    id: 'group',
    name: 'Grupo',
    ownerId: 'owner',
    userRoles: const {},
    userIds: const [],
    createdTime: DateTime(2026),
    description: '',
  );
  final client = GroupClient(
    id: 'client',
    name: 'Cliente de prueba',
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InvoiceEditorScreen(
            group: group,
            clients: [client],
            initialClientId: client.id,
            embedded: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('uses one vertical wizard with nested line input methods',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpEditor(tester, size: const Size(1400, 900));

    expect(find.byKey(const ValueKey('invoice-wizard-rail')), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      expect(
        find.byKey(ValueKey('invoice-flow-step-$index')),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const ValueKey('invoice-flow-step-2')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const ValueKey('invoice-line-mode-manual')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoice-line-mode-photo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoice-line-mode-json')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoice-content-mode-photo')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('invoice-line-mode-photo')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('invoice-ai-inline-editor')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('invoice-line-mode-json')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('invoice-ai-inline-editor')),
      findsNothing,
    );
  });

  testWidgets('uses a compact wizard selector on mobile', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpEditor(tester, size: const Size(600, 800));

    expect(
      find.byKey(const ValueKey('invoice-wizard-mobile-selector')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('invoice-wizard-rail')), findsNothing);
  });

  testWidgets('keeps line methods available from the collapsed rail',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpEditor(tester, size: const Size(900, 800));

    expect(find.byKey(const ValueKey('invoice-wizard-rail')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('invoice-line-mode-photo')),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Método de líneas'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(
      find.byKey(const ValueKey('invoice-collapsed-line-mode-photo')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester
          .widget<InvoiceContentSection>(find.byType(InvoiceContentSection))
          .contentMode,
      'photo',
    );
    expect(
      find.byKey(const ValueKey('invoice-ai-inline-editor')),
      findsOneWidget,
    );
  });
}
