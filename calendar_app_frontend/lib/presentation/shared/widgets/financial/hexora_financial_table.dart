import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HexoraFinancialColumn { date, taxableBase, vat, total }

extension HexoraFinancialColumnX on HexoraFinancialColumn {
  String get storageName => switch (this) {
        HexoraFinancialColumn.date => 'date',
        HexoraFinancialColumn.taxableBase => 'taxableBase',
        HexoraFinancialColumn.vat => 'vat',
        HexoraFinancialColumn.total => 'total',
      };
}

abstract final class HexoraFinancialFormat {
  static String money(num? value) {
    if (value == null) return '—';
    return NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    ).format(value);
  }

  static String date(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('d MMM y', 'es_ES').format(value.toLocal());
  }
}

class HexoraColumnVisibilityStore {
  const HexoraColumnVisibilityStore._();

  static String _key(String moduleKey) =>
      'hexora.financialTable.$moduleKey.visibleColumns.v1';

  static Future<Set<HexoraFinancialColumn>> load(
    String moduleKey,
    Set<HexoraFinancialColumn> defaults,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key(moduleKey));
    if (stored == null) return Set.of(defaults);
    final values = HexoraFinancialColumn.values
        .where((column) => stored.contains(column.storageName))
        .toSet();
    return values;
  }

  static Future<void> save(
    String moduleKey,
    Set<HexoraFinancialColumn> columns,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(moduleKey),
      columns.map((column) => column.storageName).toList(growable: false),
    );
  }
}

class HexoraColumnVisibilityMenu extends StatelessWidget {
  const HexoraColumnVisibilityMenu({
    super.key,
    required this.moduleKey,
    required this.availableColumns,
    required this.visibleColumns,
    required this.onChanged,
  });

  final String moduleKey;
  final Set<HexoraFinancialColumn> availableColumns;
  final Set<HexoraFinancialColumn> visibleColumns;
  final ValueChanged<Set<HexoraFinancialColumn>> onChanged;

  String _label(HexoraFinancialColumn column) => switch (column) {
        HexoraFinancialColumn.date => 'Fecha',
        HexoraFinancialColumn.taxableBase => 'Base imponible',
        HexoraFinancialColumn.vat => 'IVA',
        HexoraFinancialColumn.total => 'Total',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<HexoraFinancialColumn>(
      tooltip: 'Columnas visibles',
      onSelected: (column) {
        final next = Set<HexoraFinancialColumn>.of(visibleColumns);
        if (!next.remove(column)) next.add(column);
        onChanged(next);
        HexoraColumnVisibilityStore.save(moduleKey, next);
      },
      itemBuilder: (context) => [
        for (final column in HexoraFinancialColumn.values)
          if (availableColumns.contains(column))
            PopupMenuItem(
              value: column,
              child: Row(children: [
                Icon(
                  visibleColumns.contains(column)
                      ? Icons.check_box_outlined
                      : Icons.check_box_outline_blank,
                  size: 18,
                  color: visibleColumns.contains(column)
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(_label(column)),
              ]),
            ),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .55)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.view_column_outlined, size: 17),
          SizedBox(width: 6),
          Text('Columnas', style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}

class HexoraFinancialCell extends StatelessWidget {
  const HexoraFinancialCell({
    super.key,
    required this.value,
    this.total = false,
    this.width = 112,
  });

  final num? value;
  final bool total;
  final double width;

  @override
  Widget build(BuildContext context) {
    final label = HexoraFinancialFormat.money(value);
    return SizedBox(
      width: width,
      child: Tooltip(
        message: label,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: HexoraTypography.fontFamily,
            fontSize: 12.5,
            fontWeight: total ? FontWeight.w600 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class HexoraDateCell extends StatelessWidget {
  const HexoraDateCell({super.key, required this.value, this.width = 104});

  final DateTime? value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final label = HexoraFinancialFormat.date(value);
    return SizedBox(
      width: width,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: HexoraTypography.fontFamily,
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class HexoraFinancialHeaderCell extends StatelessWidget {
  const HexoraFinancialHeaderCell({
    super.key,
    required this.label,
    required this.width,
    this.numeric = false,
  });

  final String label;
  final double width;
  final bool numeric;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          label,
          textAlign: numeric ? TextAlign.right : TextAlign.start,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontFamily: HexoraTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
