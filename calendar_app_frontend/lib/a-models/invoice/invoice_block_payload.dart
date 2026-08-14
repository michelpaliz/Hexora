import 'package:hexora/a-models/invoice/invoice_block.dart';
import 'package:hexora/a-models/invoice/invoice_concept_utils.dart';

String _dateBlockTitle(String serviceDate) {
  final parts = serviceDate.split('-');
  if (parts.length != 3) return serviceDate;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String? _dateFromBlock(InvoiceBlock block) =>
    cleanInvoiceServiceDate(block.value ?? block.title);

/// Converts persisted date wrappers into line-level service dates for editing.
List<InvoiceBlock> invoiceBlocksForEditor(Iterable<InvoiceBlock> blocks) {
  final result = <InvoiceBlock>[];
  String? activeDate;

  for (final block in blocks) {
    if (block.type == InvoiceBlockType.date) {
      final date = _dateFromBlock(block);
      if (date == null) {
        result.add(block);
      }
      activeDate = date;
      continue;
    }

    if (block.type == InvoiceBlockType.item) {
      final ownDate = cleanInvoiceServiceDate(block.serviceDate);
      final serviceDate = ownDate ?? activeDate;
      result.add(
        serviceDate == null ? block : block.copyWith(serviceDate: serviceDate),
      );
      if (ownDate != null) activeDate = ownDate;
      continue;
    }

    result.add(block);
  }

  return result;
}

/// Adds the structural date rows expected by the PDF renderer.
List<InvoiceBlock> buildInvoiceBlocksPayload(Iterable<InvoiceBlock> blocks) {
  final editorBlocks = invoiceBlocksForEditor(blocks);
  final result = <InvoiceBlock>[];
  String? activeDate;

  for (final block in editorBlocks) {
    if (block.type == InvoiceBlockType.item) {
      final serviceDate = cleanInvoiceServiceDate(block.serviceDate);
      if (serviceDate != null && serviceDate != activeDate) {
        result.add(
          InvoiceBlock(
            type: InvoiceBlockType.date,
            title: _dateBlockTitle(serviceDate),
            level: 0,
          ),
        );
      }
      result.add(
        serviceDate == null ? block : block.copyWith(serviceDate: serviceDate),
      );
      activeDate = serviceDate;
      continue;
    }

    result.add(block);
    activeDate = null;
  }

  return result;
}
