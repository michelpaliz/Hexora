import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/invoice_list/utils/invoice_number_search.dart';

void main() {
  test('matches invoice numbers with or without separators', () {
    expect(invoiceNumberMatchesSearch('202-26', '202-26'), isTrue);
    expect(invoiceNumberMatchesSearch('202-26', '20226'), isTrue);
    expect(invoiceNumberMatchesSearch('202-26', '26'), isTrue);
    expect(invoiceNumberMatchesSearch('202-26', ' 202 / 26 '), isTrue);
    expect(invoiceNumberMatchesSearch('202-26', '203-26'), isFalse);
  });
}
