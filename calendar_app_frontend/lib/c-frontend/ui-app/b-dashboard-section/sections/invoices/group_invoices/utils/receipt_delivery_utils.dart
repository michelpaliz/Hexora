import 'package:hexora/a-models/receipt/receipt.dart';
import 'package:hexora/b-backend/receipts/receipts_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/shared/delivery_status_badge.dart';

enum ReceiptDeliveryFilter { all, notSent, sent, failed }

bool receiptIsIssued(Receipt receipt) =>
    (receipt.status ?? '').trim().toLowerCase() == 'issued';

bool receiptCanMarkSent(Receipt receipt) =>
    receiptIsIssued(receipt) &&
    normalizedDeliveryStatus(receipt.deliveryStatus) != 'sent';

bool receiptCanMarkUnsent(Receipt receipt) =>
    receiptIsIssued(receipt) &&
    normalizedDeliveryStatus(receipt.deliveryStatus) == 'sent';

List<Receipt> replaceReceiptById(
  Iterable<Receipt> receipts,
  Receipt updated, {
  bool addIfMissing = true,
}) {
  final result = receipts.toList(growable: true);
  final index = result.indexWhere((receipt) => receipt.id == updated.id);
  if (index >= 0) {
    result[index] = updated;
  } else if (addIfMissing) {
    result.insert(0, updated);
  }
  return result;
}

List<Receipt> filterReceiptsByDelivery(
  Iterable<Receipt> receipts,
  ReceiptDeliveryFilter filter,
) {
  if (filter == ReceiptDeliveryFilter.all) return receipts.toList();
  final expected = switch (filter) {
    ReceiptDeliveryFilter.notSent => 'not_sent',
    ReceiptDeliveryFilter.sent => 'sent',
    ReceiptDeliveryFilter.failed => 'failed',
    ReceiptDeliveryFilter.all => '',
  };
  return receipts
      .where((receipt) =>
          normalizedDeliveryStatus(receipt.deliveryStatus) == expected)
      .toList();
}

String receiptDeliveryErrorMessage(Object error) {
  if (error is! ReceiptsApiException) {
    return 'No se pudo actualizar el estado de envío. Inténtalo de nuevo.';
  }
  final details = '${error.code ?? ''} ${error.message}'.toLowerCase();
  if (error.statusCode == 403) {
    return 'No tienes permisos para cambiar el estado de envío.';
  }
  if (error.statusCode == 404) return 'No se encontró el recibo.';
  if (error.statusCode == 409) {
    return 'Solo los recibos emitidos pueden cambiar su estado de envío.';
  }
  if (error.statusCode == 400) {
    if (details.contains('sentat') ||
        details.contains('sent_at') ||
        details.contains('date')) {
      return 'La fecha de envío no es válida.';
    }
    return 'El canal de envío no es válido.';
  }
  return 'No se pudo actualizar el estado de envío. Inténtalo de nuevo.';
}
