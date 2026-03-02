import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/invoicing/invoice_api.dart';

void main() {
  group('InvoicesApi.buildListByGroupUri', () {
    final api = InvoicesApi();

    test('number desc includes sortBy=number&sortDir=desc', () {
      final uri = api.buildListByGroupUri(
        'g1',
        status: 'issued',
        sortBy: 'number',
        sortDir: 'desc',
      );
      expect(uri.path, '/api/invoices/group/g1');
      expect(uri.queryParameters['status'], 'issued');
      expect(uri.queryParameters['sortBy'], 'number');
      expect(uri.queryParameters['sortDir'], 'desc');
    });

    test('number asc includes sortBy=number&sortDir=asc', () {
      final uri = api.buildListByGroupUri(
        'g1',
        status: 'draft',
        sortBy: 'number',
        sortDir: 'asc',
      );
      expect(uri.path, '/api/invoices/group/g1');
      expect(uri.queryParameters['status'], 'draft');
      expect(uri.queryParameters['sortBy'], 'number');
      expect(uri.queryParameters['sortDir'], 'asc');
    });
  });
}
