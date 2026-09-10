import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/presupuesto/presupuesto_kind.dart';
import 'package:hexora/b-backend/invoicing/presupuestos_api.dart';

void main() {
  group('PresupuestosApi.buildListByGroupUri', () {
    final api = PresupuestosApi();

    test('number desc includes sortBy=number&sortDir=desc', () {
      final uri = api.buildListByGroupUri(
        'g1',
        sortBy: 'number',
        sortDir: 'desc',
      );
      expect(uri.path, '/api/presupuestos/group/g1');
      expect(uri.queryParameters['sortBy'], 'number');
      expect(uri.queryParameters['sortDir'], 'desc');
    });

    test('number asc includes sortBy=number&sortDir=asc', () {
      final uri = api.buildListByGroupUri(
        'g1',
        sortBy: 'number',
        sortDir: 'asc',
      );
      expect(uri.path, '/api/presupuestos/group/g1');
      expect(uri.queryParameters['sortBy'], 'number');
      expect(uri.queryParameters['sortDir'], 'asc');
    });

    test('date sort keeps number params absent', () {
      final uri = api.buildListByGroupUri('g1');
      expect(uri.path, '/api/presupuestos/group/g1');
      expect(uri.queryParameters.containsKey('sortBy'), isFalse);
      expect(uri.queryParameters.containsKey('sortDir'), isFalse);
    });

    test('includes explicit presupuesto kind', () {
      final uri = api.buildListByGroupUri(
        'g1',
        presupuestoKind: PresupuestoKind.structured,
      );
      expect(uri.queryParameters['presupuestoKind'], 'structured');
    });

    test('combines presupuesto kind and status', () {
      final uri = api.buildListByGroupUri(
        'g1',
        presupuestoKind: PresupuestoKind.document,
        status: 'draft',
      );
      expect(uri.queryParameters['presupuestoKind'], 'document');
      expect(uri.queryParameters['status'], 'draft');
    });
  });
}
