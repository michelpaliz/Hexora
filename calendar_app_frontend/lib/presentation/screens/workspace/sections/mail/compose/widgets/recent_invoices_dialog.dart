part of '../../mail_compose_screen.dart';

class _RecentIssuedInvoicesDialog extends StatelessWidget {
  const _RecentIssuedInvoicesDialog({
    required this.invoices,
    required this.clients,
    required this.isSpanish,
    required this.formatDate,
    required this.formatTotal,
  });

  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final bool isSpanish;
  final String Function(DateTime value) formatDate;
  final String Function(Invoice invoice) formatTotal;

  GroupClient? _clientFor(Invoice invoice) {
    final clientId = invoice.clientId.trim();
    if (clientId.isEmpty) return null;
    return clients.cast<GroupClient?>().firstWhere(
          (client) => client?.id == clientId,
          orElse: () => null,
        );
  }

  DateTime _invoiceDate(Invoice invoice) {
    return (invoice.issueDate ??
            invoice.issuedAtResolved ??
            invoice.registeredAt ??
            DateTime.fromMillisecondsSinceEpoch(0))
        .toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final title = isSpanish ? 'Facturas emitidas hoy' : 'Today issued invoices';
    final empty = isSpanish
        ? 'No hay facturas emitidas hoy.'
        : 'No invoices issued today.';

    return AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: SizedBox(
        width: 520,
        child: invoices.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  empty,
                  style: t.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final client = _clientFor(invoice);
                    final clientName = (client?.name.trim().isNotEmpty == true
                            ? client!.name
                            : invoice.clientName ?? '')
                        .trim();
                    final number = invoice.invoiceNumber.trim().isEmpty
                        ? invoice.id
                        : invoice.invoiceNumber.trim();
                    final email =
                        (client?.billing?.email ?? client?.email ?? '').trim();
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(invoice),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    cs.primaryContainer.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: cs.primary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#$number · ${clientName.isEmpty ? '-' : clientName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      formatDate(_invoiceDate(invoice)),
                                      if (email.isNotEmpty) email,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatTotal(invoice),
                              style: t.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isSpanish ? 'Cerrar' : 'Close'),
        ),
      ],
    );
  }
}
