import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/form/invoice_content_section/invoice_ai_chat_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/form/invoice_content_section/photo_extract_panel.dart';
import 'package:hexora/services/invoicing/invoice_lines_ocr_flow.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('shows only the conversation before an AI draft exists',
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
    final composer = find.byKey(const ValueKey('invoice-ai-composer'));
    expect(tester.getSize(composer).height, inInclusiveRange(78, 104));
    expect(
      find.text('Describe la factura que quieres crear...'),
      findsOneWidget,
    );
    expect(find.byTooltip('Enviar'), findsOneWidget);
    final sendButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.arrow_upward_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(sendButton.onPressed, isNull);
    final initialComposerHeight = tester.getSize(composer).height;
    final messageField = find.descendant(
      of: composer,
      matching: find.byType(TextField),
    );
    await tester.enterText(
      messageField,
      'Corte de césped\nRecorte de setos\nRetirada de residuos',
    );
    await tester.pump();
    expect(tester.getSize(composer).height, greaterThan(initialComposerHeight));
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.arrow_upward_rounded),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    tester.view.physicalSize = const Size(620, 700);
    await tester.pumpAndSettle();
    expect(tester.getSize(composer).width, lessThan(620));
    expect(tester.takeException(), isNull);
    final summary = find.byKey(const ValueKey('invoice-ai-summary-panel'));
    expect(summary, findsNothing);
    expect(find.text('Resumen de factura'), findsNothing);
    expect(find.text('0 líneas'), findsNothing);
    expect(find.text('Sin líneas todavía'), findsNothing);
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
    expect(
      find.text('Revisa siempre las líneas antes de añadirlas al borrador.'),
      findsNothing,
    );
    expect(find.byType(TabBar), findsOneWidget);
  });

  testWidgets('collapses and expands long user invoice messages',
      (tester) async {
    final longMessage = List.generate(
      12,
      (index) => 'A${index + 1}: Trabajo de mantenimiento = ${index + 1}',
    ).join('\n');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 620,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InvoiceAiUserMessageBubble(
                    text: longMessage,
                    isSpanish: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final bubble = find.byKey(const ValueKey('invoice-ai-user-message'));
    final collapsedHeight = tester.getSize(bubble).height;
    expect(find.text('Ver más'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('invoice-ai-user-message-toggle')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver menos'), findsOneWidget);
    expect(tester.getSize(bubble).height, greaterThan(collapsedHeight));
  });

  testWidgets('keeps the complete AI response behind a compact detail action',
      (tester) async {
    const fullReply =
        'Se aplicaron los precios configurados y se conservaron todos los conceptos detectados.';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        home: const Scaffold(
          body: InvoiceAiAssistantDetail(
            text: fullReply,
            isSpanish: true,
            initiallyExpanded: false,
          ),
        ),
      ),
    );

    expect(find.text(fullReply), findsNothing);
    expect(find.text('Ver detalle'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('invoice-ai-assistant-detail-toggle')),
    );
    await tester.pumpAndSettle();

    expect(find.text(fullReply), findsOneWidget);
    expect(find.text('Ocultar detalle'), findsOneWidget);
  });
}
