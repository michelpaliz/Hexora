import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:intl/intl.dart';

class InvoiceEditorFormatters {
  static String yearSuffix(DateTime now) => DateFormat('yy').format(now);

  static String invoiceNumber({
    required String digitsText,
    required DateTime now,
  }) {
    final padded = digitsText.padLeft(3, '0');
    return '$padded-${yearSuffix(now)}';
  }

  static num total(List<LineDraft> lines) {
    return lines.fold<num>(0, (sum, line) {
      final qty = line.quantity ?? 1;
      final price = line.unitPrice ?? 0;
      final taxRate = line.taxRate ?? 21;
      final subtotal = qty * price;
      final tax = subtotal * (taxRate / 100);
      return sum + subtotal + tax;
    });
  }
}
