import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_lines_editor.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/invoice_editor/widgets/invoice_form_sheet/invoice_blocks_editor.dart';
import 'package:intl/intl.dart';

class InvoiceEditorFormatters {
  static String yearSuffix(DateTime now) => DateFormat('yy').format(now);

  static String nextInvoiceDigits({
    required Iterable<String> invoiceNumbers,
    required DateTime now,
  }) {
    final suffix = yearSuffix(now);
    final pattern = RegExp(r'(\d+)-' + suffix + r'$');
    var max = 0;
    var found = false;
    for (final raw in invoiceNumbers) {
      final match = pattern.firstMatch(raw.trim());
      if (match == null) continue;
      final value = int.tryParse(match.group(1) ?? '');
      if (value == null) continue;
      if (value > max) {
        max = value;
        found = true;
      }
    }
    final next = found ? max + 1 : 1;
    return next.toString().padLeft(3, '0');
  }

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

  static num totalBlocks(List<InvoiceBlockDraft> blocks) {
    return blocks.fold<num>(0, (sum, block) {
      if (!block.isBillableItem) return sum;
      final qty = block.qty ?? 1;
      final price = block.unitPrice ?? 0;
      final taxRate = block.taxRate ?? 21;
      final subtotal = qty * price;
      final tax = subtotal * (taxRate / 100);
      return sum + subtotal + tax;
    });
  }
}
