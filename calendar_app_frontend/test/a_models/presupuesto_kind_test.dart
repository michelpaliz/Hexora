import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/presupuesto/presupuesto_kind.dart';

void main() {
  test('parses valid explicit presupuesto kinds', () {
    expect(
      PresupuestoKind.fromJson({'presupuestoKind': 'structured'}),
      PresupuestoKind.structured,
    );
    expect(
      PresupuestoKind.fromJson({'presupuestoKind': 'document'}),
      PresupuestoKind.document,
    );
  });

  test('valid backend kind is never overridden by other content', () {
    expect(
      PresupuestoKind.fromJson({
        'presupuestoKind': 'structured',
        'proposalTemplate': {'title': 'Old metadata'},
      }),
      PresupuestoKind.structured,
    );
    expect(
      PresupuestoKind.fromJson({
        'presupuestoKind': 'document',
        'blocks': [
          {'type': 'item'}
        ],
      }),
      PresupuestoKind.document,
    );
    expect(
      PresupuestoKind.fromJson({
        'presupuestoKind': null,
        'proposalTemplate': {'title': 'Must not override explicit field'},
      }),
      PresupuestoKind.structured,
    );
  });

  test('missing kind uses only the temporary proposalTemplate fallback', () {
    expect(
      PresupuestoKind.fromJson({
        'proposalTemplate': {'title': 'Legacy proposal'},
      }),
      PresupuestoKind.document,
    );
    expect(
      PresupuestoKind.fromJson({
        'hasDocumentContent': true,
        'documentTitle': 'Not a supported fallback',
      }),
      PresupuestoKind.structured,
    );
  });

  test('kind lists never mix and status filters remain independent', () {
    final items = <Map<String, dynamic>>[
      {
        'id': 'structured-draft',
        'presupuestoKind': 'structured',
        'status': 'draft',
      },
      {
        'id': 'structured-issued',
        'presupuestoKind': 'structured',
        'status': 'issued',
      },
      {
        'id': 'document-draft',
        'presupuestoKind': 'document',
        'status': 'draft',
      },
      {
        'id': 'document-issued',
        'presupuestoKind': 'document',
        'status': 'issued',
      },
    ];

    final structured = filterPresupuestos(
      items: items,
      kind: PresupuestoKind.structured,
    );
    final documentDrafts = filterPresupuestos(
      items: items,
      kind: PresupuestoKind.document,
      status: PresupuestoStatusFilter.draft,
    );
    final allIssued = filterPresupuestos(
      items: items,
      status: PresupuestoStatusFilter.issued,
    );

    expect(structured.map((item) => item['id']), [
      'structured-draft',
      'structured-issued',
    ]);
    expect(documentDrafts.single['id'], 'document-draft');
    expect(allIssued.map((item) => item['id']), [
      'structured-issued',
      'document-issued',
    ]);
  });

  test('filtering never changes an official presupuesto number', () {
    final source = <String, dynamic>{
      'id': 'budget-1',
      'presupuestoKind': 'structured',
      'status': 'issued',
      'presupuestoNumber': '025-26',
    };
    final result = filterPresupuestos(
      items: [source],
      kind: PresupuestoKind.structured,
    );

    expect(result.single['presupuestoNumber'], '025-26');
    expect(source['presupuestoNumber'], '025-26');
  });
}
