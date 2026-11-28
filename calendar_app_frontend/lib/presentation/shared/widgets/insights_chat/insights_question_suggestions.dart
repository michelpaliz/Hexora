import 'package:flutter/material.dart';

class InsightsQuestionSuggestions extends StatelessWidget {
  const InsightsQuestionSuggestions(
      {super.key, required this.onSelected, this.enabled = true});
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final suggestions = [
      (
        Icons.trending_up,
        es ? 'Ingresos del mes' : 'Monthly income',
        es
            ? '¿Cuánto ingresamos este mes? Muéstrame el desglose en una tabla.'
            : 'How much income did we have this month? Show the breakdown in a table.'
      ),
      (
        Icons.receipt_long_outlined,
        es ? 'Facturas pendientes' : 'Unpaid invoices',
        es
            ? '¿Qué facturas siguen pendientes? Muéstrame una tabla con cliente, vencimiento e importe pendiente.'
            : 'Which invoices are still unpaid? Show a table with the client, due date and outstanding amount.'
      ),
      (
        Icons.payments_outlined,
        es ? 'Gastos del mes' : 'Monthly expenses',
        es
            ? 'Muéstrame los gastos de este mes en una tabla con proveedor, fecha e importe.'
            : 'Show this month’s expenses in a table with supplier, date and amount.'
      ),
      (
        Icons.people_outline,
        es ? 'Ingresos por cliente' : 'Income by client',
        es
            ? '¿Qué clientes generaron más ingresos este mes? Muéstrame una tabla con los importes por cliente.'
            : 'Which clients generated the most income this month? Show a table with the amounts by client.'
      ),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(es ? 'Prueba con una pregunta' : 'Try a question',
          style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final suggestion in suggestions)
          Tooltip(
              message: suggestion.$3,
              child: ActionChip(
                avatar: Icon(suggestion.$1, size: 18),
                label: Text(suggestion.$2),
                onPressed: enabled ? () => onSelected(suggestion.$3) : null,
              )),
      ]),
      const SizedBox(height: 6),
      Text(
          es
              ? 'Puedes editar la pregunta antes de enviarla.'
              : 'You can edit the question before sending.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]);
  }
}
