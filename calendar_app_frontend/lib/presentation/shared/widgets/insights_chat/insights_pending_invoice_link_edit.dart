class PendingInvoiceLinkEdit {
  const PendingInvoiceLinkEdit({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.clientName,
    required this.total,
    required this.totalFormatted,
    required this.pendingStatusLabel,
    required this.displayLabel,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String clientName;
  final num? total;
  final String totalFormatted;
  final String pendingStatusLabel;
  final String displayLabel;
}
