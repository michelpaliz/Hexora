part of '../../mail_compose_screen.dart';

class _InvoiceSelectionPreviewScreen extends StatelessWidget {
  const _InvoiceSelectionPreviewScreen({
    required this.clientName,
    required this.invoices,
    required this.receipts,
    required this.presupuestos,
    required this.onPreviewInvoice,
    required this.onPreviewReceipt,
    required this.onPreviewPresupuesto,
  });

  final String clientName;
  final List<Invoice> invoices;
  final List<Receipt> receipts;
  final List<Map<String, dynamic>> presupuestos;
  final Future<void> Function(Invoice invoice) onPreviewInvoice;
  final Future<void> Function(Receipt receipt) onPreviewReceipt;
  final Future<void> Function(String presupuestoId) onPreviewPresupuesto;

  String _presupuestoId(Map<String, dynamic> item) {
    return (item['_id'] ?? item['id'] ?? '').toString();
  }

  String _presupuestoNumber(Map<String, dynamic> item) {
    return (item['presupuestoNumber'] ?? item['budgetNumber'] ?? '')
        .toString()
        .trim();
  }

  String _presupuestoStatus(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'draft').toString().trim();
    return status.isEmpty ? 'draft' : status;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.preview)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l.invoiceBillToLabel}: $clientName',
              style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${l.mailComposeInvoiceIdsLabel}: ${invoices.length + receipts.length + presupuestos.length}',
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: invoices.isEmpty && receipts.isEmpty && presupuestos.isEmpty
                  ? Center(
                      child: Text(
                        l.noInvoicesYet,
                        style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView(
                      children: [
                        ...invoices.map((inv) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.55)),
                                ),
                                title: Text(
                                  inv.invoiceNumber.trim().isEmpty
                                      ? inv.id
                                      : inv.invoiceNumber,
                                  style: t.bodySmall
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  '${inv.status ?? 'draft'} - ${inv.id}',
                                  style: t.bodySmall
                                      .copyWith(color: cs.onSurfaceVariant),
                                ),
                                trailing: IconButton(
                                  tooltip: l.preview,
                                  onPressed: () => onPreviewInvoice(inv),
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                              ),
                            )),
                        ...receipts.map((receipt) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.55)),
                                ),
                                title: Text(
                                  (receipt.receiptNumber?.trim().isNotEmpty ==
                                          true)
                                      ? receipt.receiptNumber!.trim()
                                      : receipt.id,
                                  style: t.bodySmall
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  '${receipt.status ?? 'draft'} - ${receipt.id}',
                                  style: t.bodySmall
                                      .copyWith(color: cs.onSurfaceVariant),
                                ),
                                trailing: IconButton(
                                  tooltip: l.preview,
                                  onPressed: () => onPreviewReceipt(receipt),
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                              ),
                            )),
                        ...presupuestos.map((item) {
                          final id = _presupuestoId(item);
                          final number = _presupuestoNumber(item);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.55)),
                              ),
                              title: Text(
                                number.isEmpty ? id : number,
                                style: t.bodySmall
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${_presupuestoStatus(item)} - $id',
                                style: t.bodySmall
                                    .copyWith(color: cs.onSurfaceVariant),
                              ),
                              trailing: IconButton(
                                tooltip: l.preview,
                                onPressed: id.isEmpty
                                    ? null
                                    : () => onPreviewPresupuesto(id),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
