import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'search_filters_header.dart';

class ClientStatusSegments extends StatelessWidget {
  const ClientStatusSegments(
      {super.key,
      required this.value,
      required this.active,
      required this.inactive,
      required this.onChanged});
  final String value;
  final int active;
  final int inactive;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
                selectedForegroundColor: Theme.of(context).colorScheme.primary,
                selectedBackgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: .1),
                textStyle: Theme.of(context).textTheme.labelMedium,
                minimumSize:
                    Size(0, clientFilterControlHeight(context, desktop: 32)),
                // Height comes from clientFilterControlHeight (48 on touch),
                // so the extra Material tap padding is not needed.
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            segments: [
              ButtonSegment(
                  value: 'all', label: Text('${l.all} ${active + inactive}')),
              ButtonSegment(
                  value: 'active', label: Text('${l.active} $active')),
              ButtonSegment(
                  value: 'inactive', label: Text('${l.inactive} $inactive')),
            ],
            selected: {value},
            onSelectionChanged: (values) => onChanged(values.single)));
  }
}

/// This counts clients missing a current-month invoice, not unpaid invoices.
class ClientMissingInvoiceFilter extends StatelessWidget {
  const ClientMissingInvoiceFilter(
      {super.key,
      required this.count,
      required this.selected,
      required this.onTap});
  final int? count;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final label = count == null
        ? l.clientMissingInvoiceThisMonth
        : l.clientMissingCountThisMonth(count!);
    final es = Localizations.localeOf(context).languageCode == 'es';
    final explanation = selected
        ? (es
            ? 'Mostrando solo clientes activos sin factura emitida este mes. Pulsa para quitar el filtro.'
            : 'Showing only active clients without an invoice issued this month. Click to clear.')
        : (es
            ? 'Clientes activos sin factura emitida este mes. Pulsa para filtrar la lista.'
            : 'Active clients without an invoice issued this month. Click to filter the list.');
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Semantics(
            selected: selected,
            child: Tooltip(
                message: count == null
                    ? l.clientInvoiceStatusUnavailableTitle
                    : explanation,
                child: TextButton(
                    onPressed: onTap,
                    key: const ValueKey('client-missing-month-invoice-filter'),
                    style: TextButton.styleFrom(
                        minimumSize: Size(
                            0, clientFilterControlHeight(context, desktop: 32)),
                        foregroundColor:
                            selected ? cs.primary : cs.onSurfaceVariant,
                        backgroundColor: selected
                            ? cs.primary.withValues(alpha: .08)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          selected
                              ? Icons.check_circle_outline
                              : Icons.receipt_long_outlined,
                          size: 16,
                          color:
                              !selected && (count ?? 0) > 0 ? cs.error : null),
                      const SizedBox(width: 6),
                      Flexible(
                          child: Text(label,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      color: selected
                                          ? cs.primary
                                          : cs.onSurfaceVariant))),
                    ])))));
  }
}
