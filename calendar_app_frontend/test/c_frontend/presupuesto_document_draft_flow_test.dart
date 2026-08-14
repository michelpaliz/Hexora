import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_document_draft_flow.dart';

void main() {
  const content = <String, dynamic>{
    'name': 'Mantenimiento anual',
    'header': <String, dynamic>{'website': 'example.test'},
    'watermark': 'BORRADOR',
    'title': 'Presupuesto [CLIENTE]',
    'subtitle': 'Servicio anual',
    'intro': 'Contenido',
    'variables': <String, dynamic>{'CLIENTE': 'Comunidad Las Alondras'},
    'sections': <Map<String, dynamic>>[],
    'images': <Map<String, dynamic>>[],
  };

  test('Guardar creates a presupuesto draft and subsequent saves patch it',
      () async {
    final api = _FakePresupuestosApi();
    final flow = PresupuestoDocumentDraftFlow(api: api);

    final createdId = await flow.save(groupId: 'group-1', content: content);
    final updatedId = await flow.save(groupId: 'group-1', content: content);

    expect(createdId, 'draft-1');
    expect(updatedId, 'draft-1');
    expect(flow.presupuestoId, 'draft-1');
    expect(api.documentDraftCreates, 1);
    expect(api.documentContentUpdates, 1);
    expect(api.templateCreates, 0);
    expect(api.templateUpdates, 0);
  });

  test('Usar plantilla creates a presupuesto draft from the default', () async {
    final api = _FakePresupuestosApi();
    final flow = PresupuestoDocumentDraftFlow(api: api);

    final result = await flow.createFromDefault(
      key: 'maintenance',
      groupId: 'group-1',
      content: content,
    );

    expect(result.presupuestoId, 'default-draft-1');
    expect(flow.presupuestoId, 'default-draft-1');
    expect(api.defaultDocumentCreates, 1);
    expect(api.lastDefaultKey, 'maintenance');
    expect(api.lastDocumentContent, content);
    expect(api.templateCreates, 0);
    expect(api.templateUpdates, 0);
  });

  test('document payload includes group and CLIENTE as clientName', () {
    final payload = PresupuestosApi().buildDocumentDraftPayload(
      groupId: ' group-1 ',
      content: content,
    );

    expect(payload['groupId'], 'group-1');
    expect(payload['clientName'], 'Comunidad Las Alondras');
    for (final key in const [
      'name',
      'header',
      'watermark',
      'title',
      'subtitle',
      'intro',
      'variables',
      'sections',
      'images',
    ]) {
      expect(payload.containsKey(key), isTrue, reason: 'Missing $key');
    }
  });

  test('document endpoints do not change invoice-style presupuesto creation',
      () {
    final api = PresupuestosApi();

    expect(api.buildCreateDraftUri().path, '/api/presupuestos');
    expect(
      api.buildCreateDocumentDraftUri().path,
      '/api/presupuestos/documents',
    );
    expect(
      api
          .buildCreateDocumentFromDefaultUri(
            key: 'maintenance annual',
            groupId: 'group-1',
          )
          .path,
      '/api/presupuestos/documents/defaults/maintenance%20annual/group/group-1',
    );
    expect(
      api.buildListDocumentsByGroupUri('group-1').path,
      '/api/presupuestos/documents/group/group-1',
    );
    expect(
      api.buildDocumentIssueUri('draft-1').path,
      '/api/presupuestos/draft-1/issue',
    );
  });
}

class _FakePresupuestosApi extends PresupuestosApi {
  int documentDraftCreates = 0;
  int defaultDocumentCreates = 0;
  int documentContentUpdates = 0;
  int templateCreates = 0;
  int templateUpdates = 0;
  String? lastDefaultKey;
  Map<String, dynamic>? lastDocumentContent;

  @override
  Future<Map<String, dynamic>> createDocumentDraft({
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    documentDraftCreates++;
    lastDocumentContent = Map<String, dynamic>.from(content);
    return <String, dynamic>{'presupuestoId': 'draft-1'};
  }

  @override
  Future<Map<String, dynamic>> createDocumentFromDefault({
    required String key,
    required String groupId,
    required Map<String, dynamic> content,
  }) async {
    defaultDocumentCreates++;
    lastDefaultKey = key;
    lastDocumentContent = Map<String, dynamic>.from(content);
    return <String, dynamic>{
      'presupuesto': <String, dynamic>{'_id': 'default-draft-1'},
    };
  }

  @override
  Future<Map<String, dynamic>> saveTemplateContent(
    String presupuestoId,
    Map<String, dynamic> payload,
  ) async {
    documentContentUpdates++;
    return <String, dynamic>{'presupuestoId': presupuestoId};
  }

  @override
  Future<Map<String, dynamic>> createTemplate(
    Map<String, dynamic> payload,
  ) async {
    templateCreates++;
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> updateTemplate(
    String templateId,
    Map<String, dynamic> payload,
  ) async {
    templateUpdates++;
    return <String, dynamic>{};
  }
}
