part of '../../widgets/group_invoices_invoices_view.dart';

String _invoiceFallbackClientName(Invoice invoice, AppLocalizations l) {
  final candidates = <String?>[
    invoice.clientName,
    invoice.billingName,
    invoice.clientSnapshot?.legalName,
  ];
  for (final candidate in candidates) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return l.unknownClient;
}

GroupClient _resolveInvoiceClient(
  Invoice invoice,
  List<GroupClient> clients,
  AppLocalizations l,
) {
  final invoiceClientId = invoice.clientId.trim();
  for (final client in clients) {
    if (client.id == invoiceClientId) return client;
  }
  return GroupClient(
    id: invoiceClientId,
    name: _invoiceFallbackClientName(invoice, l),
    isActive: true,
    billing: invoice.clientSnapshot,
  );
}
