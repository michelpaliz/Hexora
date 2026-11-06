import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/form/invoice_content_section/photo_extract_panel.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_flow.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('shows AI chat inline and preserves quick extraction',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = InvoiceEditorController(
      group: Group(
        id: 'group',
        name: 'Grupo',
        ownerId: 'owner',
        userRoles: const {},
        userIds: const [],
        createdTime: DateTime(2026),
        description: '',
      ),
      clients: const [],
    );
    addTearDown(controller.dispose);

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
          body: InvoicePhotoExtractPanel(
            state: InvoiceLinesOcrFlowState.initial(),
            controller: controller,
            hasImagePreview: false,
            onPreviewImage: null,
            onPickImage: null,
            onApply: null,
            onClear: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(
      find.byKey(const ValueKey('invoice-ai-inline-editor')),
      findsOneWidget,
    );
    expect(find.text('Crear factura con IA'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);

    await tester.tap(find.text('Extracción rápida'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-quick-extraction-panel')),
      findsOneWidget,
    );
  });
}
