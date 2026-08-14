import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/presupuesto_document_workspace.dart';

void main() {
  final draft = <String, dynamic>{
    '_id': 'document-1',
    'status': 'draft',
    'hasDocumentContent': true,
    'clientName': 'Comunidad Las Alondras',
    'title': 'Mantenimiento anual',
    'lines': const <dynamic>[],
    'blocks': const <dynamic>[],
  };

  test('document records appear only in their dedicated status section', () {
    final documents = <Map<String, dynamic>>[
      draft,
      <String, dynamic>{
        ...draft,
        '_id': 'document-2',
        'status': 'issued',
        'presupuestoNumber': 'P-2026-18',
      },
      <String, dynamic>{
        '_id': 'structured-1',
        'status': 'draft',
        'hasDocumentContent': false,
      },
    ];

    final drafts = filterPresupuestoDocuments(
      documents,
      section: PresupuestoDocumentSection.drafts,
    );
    final issued = filterPresupuestoDocuments(
      documents,
      section: PresupuestoDocumentSection.issued,
    );

    expect(drafts.map(presupuestoDocumentId), ['document-1']);
    expect(issued.map(presupuestoDocumentId), ['document-2']);
  });

  test('Word-style draft issues without invoice lines and moves to issued',
      () async {
    final api = _FakeDocumentApi(draft);
    final workspace = PresupuestoDocumentWorkspace(api: api);
    await workspace.refresh('group-1');

    final issued = await workspace.issue(workspace.drafts.single);

    expect(api.issueCalls, 1);
    expect(api.issuedId, 'document-1');
    expect(issued['status'], 'issued');
    expect(issued['presupuestoNumber'], 'P-2026-18');
    expect(workspace.drafts, isEmpty);
    expect(workspace.issued.single['presupuestoNumber'], 'P-2026-18');
  });

  test('duplicate Emit requests are prevented while one is running', () async {
    final api = _FakeDocumentApi(draft)..holdIssue = true;
    final workspace = PresupuestoDocumentWorkspace(api: api);
    await workspace.refresh('group-1');

    final first = workspace.issue(workspace.drafts.single);
    await Future<void>.delayed(Duration.zero);

    await expectLater(
      workspace.issue(workspace.drafts.single),
      throwsA(isA<PresupuestoDocumentIssueInProgressException>()),
    );
    api.completeIssue();
    await first;
    expect(api.issueCalls, 1);
  });

  test('document issuing requires client and document content', () {
    expect(
      presupuestoDocumentIssueValidation(<String, dynamic>{
        ...draft,
        'clientName': '',
      }),
      contains('cliente'),
    );
    expect(
      presupuestoDocumentIssueValidation(<String, dynamic>{
        ...draft,
        'hasDocumentContent': false,
      }),
      contains('documento'),
    );
  });

  test('document amount prefers populated Word variables over empty totals', () {
    expect(
      presupuestoDocumentAmount(<String, dynamic>{
        'total': 0,
        'documentContent': <String, dynamic>{
          'variables': <String, dynamic>{
            'IMPORTE_MENSUAL': '1.400,50 EUR',
          },
        },
      }),
      1400.5,
    );
  });
}

class _FakeDocumentApi extends PresupuestosApi {
  _FakeDocumentApi(Map<String, dynamic> draft)
      : documents = [Map<String, dynamic>.from(draft)];

  List<Map<String, dynamic>> documents;
  int issueCalls = 0;
  String? issuedId;
  bool holdIssue = false;
  Completer<void>? _issueGate;

  @override
  Future<List<Map<String, dynamic>>> listDocumentsByGroup(
    String groupId,
  ) async =>
      documents.map(Map<String, dynamic>.from).toList(growable: false);

  @override
  Future<Map<String, dynamic>> issueDocument(String presupuestoId) async {
    issueCalls++;
    issuedId = presupuestoId;
    if (holdIssue) {
      _issueGate = Completer<void>();
      await _issueGate!.future;
    }
    final issued = <String, dynamic>{
      ...documents.single,
      'status': 'issued',
      'presupuestoNumber': 'P-2026-18',
      'issueDate': '2026-08-05T10:00:00.000Z',
    };
    documents = [issued];
    return <String, dynamic>{'presupuesto': issued};
  }

  void completeIssue() => _issueGate?.complete();
}
