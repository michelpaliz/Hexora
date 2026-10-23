import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/documents/presupuesto_document_actions_view.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_workspace_chrome.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/templates/presupuesto_template_editor_screen.dart';

class _Api extends PresupuestosApi {
  @override
  Future<Map<String, dynamic>> getTemplateVariables(String id) async => {
        'variables': {'CLIENTE': 'Client'},
        'unresolvedKeys': <String>[],
      };

  final removed = <String>[];
  Map<String, dynamic>? copied;
  @override
  Future<void> remove(String id) async {
    removed.add(id);
  }

  @override
  Future<Map<String, dynamic>> getTemplateContent(String id) async => {
        'content': {
          'name': 'Original',
          'title': 'Original title',
          'variables': {'CLIENTE': 'Client'},
          'sections': [],
          'status': 'issued',
          'presupuestoNumber': 'PRE-007',
          '_id': id
        },
      };
  @override
  Future<Map<String, dynamic>> createDocumentDraft(
      {required String groupId, required Map<String, dynamic> content}) async {
    copied = content;
    return {'presupuestoId': 'copy'};
  }

  @override
  Future<List<Map<String, dynamic>>> listDocumentsByGroup(String groupId,
          {String? search}) async =>
      [
        for (var i = 0; i < 12; i++)
          {
            '_id': '$i',
            'presupuestoKind': 'document',
            'hasDocumentContent': true,
            'title': 'Proposal $i',
            'status': i.isEven ? 'draft' : 'issued',
            'clientName': 'Client $i',
            'amount': 100,
            'updatedAt': '2026-09-01',
            'issueDate': '2026-09-01',
          },
      ];
}

void main() {
  for (final width in [600.0, 1600.0]) {
    testWidgets('opens proposal inside workspace and returns to list: $width',
        (tester) async {
      await initializeDateFormatting('es');
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Row(children: [
        const SizedBox(width: 100, child: Text('Workspace sidebar')),
        Expanded(
            child: PresupuestoDocumentActionsView(
          groupId: 'group',
          clients: const [],
          api: _Api(),
          mode: PresupuestoDocumentActionMode.all,
        )),
      ]))));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Proposal 0');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proposal 0', findRichText: false).last);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(PresupuestoTemplateEditorScreen), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(PresupuestoDocumentActionsView),
              matching: find.byType(PresupuestoTemplateEditorScreen)),
          findsOneWidget);
      expect(find.text('Workspace sidebar').hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('back_to_proposals')));
      await tester.pumpAndSettle();
      expect(find.byType(PresupuestoTemplateEditorScreen), findsNothing);
      expect(find.text('Proposal 0'), findsWidgets);
      expect(find.text('Proposal 1'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    for (final width in [360.0, 1320.0]) {
      testWidgets('proposals support enlarged text: $brightness $width',
          (tester) async {
        await initializeDateFormatting('es');
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.forPlatform(brightness,
              platform: TargetPlatform.windows),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: Scaffold(
              body: PresupuestoDocumentActionsView(
                  groupId: 'group',
                  clients: const [],
                  api: _Api(),
                  mode: PresupuestoDocumentActionMode.all)),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(HexoraDocumentStatusTabs), findsOneWidget);
      });
    }
  }

  testWidgets(
      'proposal actions duplicate content and delete only selected drafts',
      (tester) async {
    await initializeDateFormatting('es');
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _Api();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.windows),
        home: Scaffold(
            body: PresupuestoDocumentActionsView(
          groupId: 'group',
          clients: const [],
          api: api,
          mode: PresupuestoDocumentActionMode.all,
        ))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Más acciones').first);
    await tester.pumpAndSettle();
    expect(find.text('Descargar'), findsWidgets);
    expect(find.text('Editar propuesta'), findsOneWidget);
    await tester.tap(find.text('Duplicar como borrador'));
    await tester.pumpAndSettle();
    expect(api.copied?['name'], 'Original (copia)');
    expect(api.copied?['variables'], {'CLIENTE': 'Client'});
    for (final key in ['_id', 'status', 'presupuestoNumber']) {
      expect(api.copied!.containsKey(key), isFalse);
    }
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar borradores (5)'));
    await tester.pumpAndSettle();
    expect(api.removed, isEmpty);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(api.removed, isEmpty);
    await tester.tap(find.text('Eliminar borradores (5)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(api.removed, ['0', '2', '4', '6', '8']);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
  });

  testWidgets('proposal table filters, paginates and creates without overflow',
      (tester) async {
    await initializeDateFormatting('es');
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var creates = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.windows),
        home: Scaffold(
            body: PresupuestoDocumentActionsView(
          groupId: 'group',
          clients: const [],
          api: _Api(),
          mode: PresupuestoDocumentActionMode.all,
          onCreate: () => creates++,
        ))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(HexoraDocumentStatusTabs), findsOneWidget);
    final rows = find.byWidgetPredicate((w) =>
        w is Container &&
        w.constraints?.minHeight == HexoraTableTokens.rowMinHeight);
    expect(rows, findsWidgets);
    // Rows may grow to retain the 48px action targets plus cell padding.
    expect(tester.getSize(rows.first).height,
        inInclusiveRange(HexoraTableTokens.rowMinHeight, 60));
    final download = find
        .byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Descargar')
        .first;
    expect(tester.getSize(download).height,
        greaterThanOrEqualTo(HexoraDimensions.touchTarget));
    expect(tester.getSize(download).width,
        greaterThanOrEqualTo(HexoraDimensions.touchTarget));
    expect(find.text('Mostrando 1–10 de 12 propuestas'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrando 11–12 de 12 propuestas'), findsOneWidget);
    await tester.ensureVisible(find.text('Borradores'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Borradores'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrando 1–6 de 6 propuestas'), findsOneWidget);
    await tester.ensureVisible(find.text('Nueva propuesta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nueva propuesta'));
    expect(creates, 1);
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
