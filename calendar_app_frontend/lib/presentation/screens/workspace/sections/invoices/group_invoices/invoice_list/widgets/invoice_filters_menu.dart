part of '../../widgets/group_invoices_invoices_view.dart';

class _InvoiceFiltersMenu extends StatelessWidget {
  const _InvoiceFiltersMenu({
    required this.sortActions,
    required this.quickRange,
    required this.fromDate,
    required this.toDate,
    required this.onSelected,
  });

  final List<Widget> sortActions;
  final DateQuickRange quickRange;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<DateQuickRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isEs = l.localeName.startsWith('es');
    final active = fromDate != null || toDate != null;
    final format = DateFormat.yMMMd(l.localeName);
    final range = active
        ? '${fromDate == null ? '…' : format.format(fromDate!)} – ${toDate == null ? '…' : format.format(toDate!)}'
        : null;
    return MenuAnchor(
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEs ? 'Ordenar por' : 'Sort by',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: sortActions),
                if (range != null) ...[
                  const SizedBox(height: 12),
                  Text(range,
                      style: TextStyle(color: cs.primary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        for (final option in <DateQuickRange, String>{
          DateQuickRange.none: isEs ? 'Todas las fechas' : 'All dates',
          DateQuickRange.month: isEs ? 'Últimos 30 días' : 'Last 30 days',
          DateQuickRange.quarter: isEs ? 'Últimos 3 meses' : 'Last 3 months',
          DateQuickRange.custom: isEs ? 'Elegir fechas…' : 'Choose dates…',
        }.entries)
          MenuItemButton(
            onPressed: () => onSelected(option.key),
            leadingIcon: Icon(
              quickRange == option.key
                  ? Icons.check_rounded
                  : Icons.date_range_outlined,
              size: 18,
            ),
            child: Text(option.value),
          ),
      ],
      builder: (context, controller, child) => Tooltip(
        message: range ?? (isEs ? 'Filtros y orden' : 'Filters and sorting'),
        child: OutlinedButton(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            backgroundColor: active ? cs.primaryContainer : Colors.transparent,
            foregroundColor:
                active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? Icons.filter_alt : Icons.tune_rounded, size: 15),
              const SizedBox(width: 4),
              Text(isEs ? 'Filtros' : 'Filters'),
              const SizedBox(width: 2),
              Icon(controller.isOpen ? Icons.expand_less : Icons.expand_more,
                  size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
