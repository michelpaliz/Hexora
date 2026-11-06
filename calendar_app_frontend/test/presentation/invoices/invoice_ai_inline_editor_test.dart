import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/form/invoice_content_section/photo_extract_panel.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_flow.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('shows the unified AI chat inline without secondary tabs',
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
    expect(find.text('¿Qué quieres incluir en la factura?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('invoice-ai-composer')),
      findsOneWidget,
    );
    final summary = find.byKey(const ValueKey('invoice-ai-summary-panel'));
    expect(summary, findsOneWidget);
    expect(find.text('Resumen de factura'), findsOneWidget);
    expect(find.text('0 líneas'), findsOneWidget);
    expect(find.text('Sin líneas todavía'), findsOneWidget);
    expect(
      find.text(
        'Describe los trabajos o adjunta un archivo para generar las líneas.',
      ),
      findsOneWidget,
    );
    expect(tester.getSize(summary).height, lessThan(200));
    expect(
      find.byKey(const ValueKey('invoice-ai-confirm-action')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('invoice-ai-apply-action')),
      findsNothing,
    );
    expect(find.text('Crear factura con IA'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Chat IA'), findsNothing);
    expect(find.text('Extracción rápida'), findsNothing);
    expect(find.byType(TabBar), findsNothing);
  });
}
