import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BankTransactionChatCard extends StatelessWidget {
  const BankTransactionChatCard(
      {super.key,
      required this.transaction,
      required this.onOpen,
      this.onReview,
      this.onRequestReview,
      this.sharedBy,
      this.sharedAt});

  final Map<String, dynamic> transaction;
  final VoidCallback? onOpen;
  final VoidCallback? onReview;
  final VoidCallback? onRequestReview;
  final String? sharedBy;
  final DateTime? sharedAt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (transaction['restricted'] == true) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text('Movimiento bancario · acceso restringido'),
      );
    }
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final date = DateTime.tryParse((transaction['date'] ?? '').toString());
    final available = transaction['available'] == true;
    final status = !available
        ? 'No disponible'
        : transaction['status'] == 'linked'
            ? 'Vinculado'
            : 'Sin vincular';
    final description = (transaction['description'] ?? '').toString().trim();
    final documents = (transaction['linkedDocuments'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final invoices =
        documents.where((item) => item['type'] == 'invoice').toList();
    final invoiceTotalsKnown =
        invoices.isNotEmpty && invoices.every((item) => item['total'] is num);
    final invoiceTotal = invoices.fold<double>(
        0, (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0));
    final amountDiffers =
        invoiceTotalsKnown && (invoiceTotal - amount.abs()).abs() > 0.01;
    final money = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                    child: Text(
                        description.isEmpty
                            ? 'Movimiento bancario'
                            : description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
                Text(
                    NumberFormat.currency(locale: 'es_ES', symbol: '€')
                        .format(amount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: amount < 0 ? cs.error : cs.primary,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 3),
              Text(
                  '${date == null ? 'Sin fecha' : DateFormat('dd/MM/yyyy').format(date.toLocal())} · $status',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              for (final document in documents.take(2))
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${document['type'] == 'expense' ? 'Gasto' : 'Factura'} '
                    '${document['available'] == true ? (document['number'] ?? 'sin número') : 'no disponible'}'
                    '${document['counterparty'] == null || document['counterparty'].toString().isEmpty ? '' : ' · ${document['counterparty']}'}'
                    '${document['total'] is num ? ' · ${money.format(document['total'])}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              if (documents.length > 2)
                Text('+${documents.length - 2} documentos vinculados',
                    style: Theme.of(context).textTheme.labelSmall),
              if (amountDiffers)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'Los importes difieren; puede ser un pago parcial. Revisa el vínculo.',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.error)),
                ),
              if (sharedBy != null && sharedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'Compartido por $sharedBy · ${DateFormat('dd/MM/yyyy HH:mm').format(sharedAt!.toLocal())}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
              if (available)
                Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 4,
                        children: [
                          if (onRequestReview != null)
                            TextButton.icon(
                                onPressed: onRequestReview,
                                icon: const Icon(Icons.rate_review_outlined,
                                    size: 15),
                                label: const Text('Pedir revisión')),
                          if (documents
                                  .any((item) => item['type'] == 'invoice') &&
                              onReview != null)
                            TextButton(
                                onPressed: onReview,
                                child: const Text('Revisar vínculo')),
                          TextButton.icon(
                              onPressed: onOpen,
                              icon: const Icon(Icons.open_in_new, size: 15),
                              label: const Text('Ver movimiento')),
                        ])),
            ]),
      ),
    );
  }
}
