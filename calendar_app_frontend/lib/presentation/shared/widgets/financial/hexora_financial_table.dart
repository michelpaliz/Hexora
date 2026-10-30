import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HexoraFinancialColumn { date, concept, taxableBase, vat, total, payment }

extension HexoraFinancialColumnX on HexoraFinancialColumn {
  String get storageName => switch (this) {
        HexoraFinancialColumn.date => 'date',
        HexoraFinancialColumn.concept => 'concept',
        HexoraFinancialColumn.taxableBase => 'taxableBase',
        HexoraFinancialColumn.vat => 'vat',
        HexoraFinancialColumn.total => 'total',
        HexoraFinancialColumn.payment => 'payment',
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

enum HexoraHeaderSortDirection { ascending, descending }

/// Keeps Material's date-range picker compact on desktop while allowing it to
/// use the available viewport on phones and small tablets.
Widget hexoraCompactDateRangePickerBuilder(
  BuildContext context,
  Widget? child,
) {
  final viewport = MediaQuery.sizeOf(context);
  final availableWidth = viewport.width - 32;
  final availableHeight = viewport.height - 32;
  final maxWidth = availableWidth < 520 ? availableWidth : 520.0;
  final maxHeight = availableHeight < 620 ? availableHeight : 620.0;
  final theme = Theme.of(context);
  const radius = 14.0;

  return Theme(
    data: theme.copyWith(
      datePickerTheme: theme.datePickerTheme.copyWith(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Material(
            type: MaterialType.transparency,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

/// Compact table-header control shared by document workspaces. The popover
/// keeps filter inputs out of the table until they are needed.
class HexoraFilterableHeaderCell extends StatelessWidget {
  const HexoraFilterableHeaderCell({
    super.key,
    required this.label,
    required this.width,
    required this.menuBuilder,
    this.numeric = false,
    this.centered = false,
    this.filterActive = false,
    this.sortDirection,
  });

  final String label;
  final double width;
  final bool numeric;
  final bool centered;
  final bool filterActive;
  final HexoraHeaderSortDirection? sortDirection;
  final WidgetBuilder menuBuilder;

  Future<void> _showFilterDialog(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final maxHeight = (viewport.height - 48).clamp(240.0, 520.0);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.08),
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 280,
              maxWidth: 320,
              maxHeight: maxHeight,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: menuBuilder(dialogContext),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Align(
        alignment: centered
            ? AlignmentDirectional.center
            : numeric
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
        child: Tooltip(
          message: 'Filtrar y ordenar $label',
          child: Semantics(
            button: true,
            label: 'Filtrar y ordenar $label',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showFilterDialog(context),
              child: Container(
                constraints: const BoxConstraints(minHeight: 30),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: filterActive
                    ? BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: width > 32 ? width - 32 : width,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: HexoraTypography.fontFamily,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: filterActive
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      sortDirection == HexoraHeaderSortDirection.ascending
                          ? Icons.arrow_upward_rounded
                          : sortDirection ==
                                  HexoraHeaderSortDirection.descending
                              ? Icons.arrow_downward_rounded
                              : Icons.filter_alt_outlined,
                      size: 13,
                      color: filterActive || sortDirection != null
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                    if (filterActive)
                      Container(
                        margin: const EdgeInsetsDirectional.only(start: 3),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void closeHexoraColumnFilterMenu(BuildContext context) {
  Navigator.of(context).maybePop();
}

class HexoraColumnFilterMenu extends StatelessWidget {
  const HexoraColumnFilterMenu({
    super.key,
    required this.label,
    required this.onSortAscending,
    required this.onSortDescending,
    required this.child,
    required this.filterActive,
    required this.onClear,
    this.sortDirection,
  });

  final String label;
  final VoidCallback onSortAscending;
  final VoidCallback onSortDescending;
  final HexoraHeaderSortDirection? sortDirection;
  final Widget child;
  final bool filterActive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SegmentedButton<HexoraHeaderSortDirection>(
              segments: const [
                ButtonSegment(
                  value: HexoraHeaderSortDirection.ascending,
                  icon: Icon(Icons.arrow_upward_rounded, size: 15),
                  label: Text('Ascendente'),
                ),
                ButtonSegment(
                  value: HexoraHeaderSortDirection.descending,
                  icon: Icon(Icons.arrow_downward_rounded, size: 15),
                  label: Text('Descendente'),
                ),
              ],
              selected: sortDirection == null ? const {} : {sortDirection!},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                if (value.isEmpty) return;
                value.first == HexoraHeaderSortDirection.ascending
                    ? onSortAscending()
                    : onSortDescending();
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            const SizedBox(height: 10),
            child,
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: filterActive
                    ? () {
                        onClear();
                        closeHexoraColumnFilterMenu(context);
                      }
                    : null,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
                label: const Text('Limpiar'),
              ),
            ),
          ],
        ),
      );
}

class HexoraMultiSelectFilter extends StatefulWidget {
  const HexoraMultiSelectFilter({
    super.key,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
    this.searchable = false,
    this.searchHint = 'Buscar...',
    this.emptyLabel = 'No se encontraron resultados',
    this.selectionSingularLabel = 'elemento seleccionado',
    this.selectionPluralLabel = 'elementos seleccionados',
  });

  final List<String> values;
  final Set<String> selected;
  final String Function(String) labelFor;
  final ValueChanged<Set<String>> onChanged;
  final bool searchable;
  final String searchHint;
  final String emptyLabel;
  final String selectionSingularLabel;
  final String selectionPluralLabel;

  @override
  State<HexoraMultiSelectFilter> createState() =>
      _HexoraMultiSelectFilterState();
}

class _HexoraMultiSelectFilterState extends State<HexoraMultiSelectFilter> {
  late final Set<String> _selected = Set.of(widget.selected);
  String _query = '';

  String _normalized(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâã]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöôõ]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n');

  void _toggle(String value) {
    setState(() {
      _selected.contains(value)
          ? _selected.remove(value)
          : _selected.add(value);
    });
    widget.onChanged(Set.of(_selected));
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalized(_query);
    final visibleValues = normalizedQuery.isEmpty
        ? widget.values
        : widget.values
            .where((value) =>
                _normalized(widget.labelFor(value)).contains(normalizedQuery))
            .toList(growable: false);

    final list = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 230),
      child: visibleValues.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                widget.emptyLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: visibleValues.length,
              itemBuilder: (context, index) {
                final value = visibleValues[index];
                return CheckboxListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(widget.labelFor(value),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  value: _selected.contains(value),
                  onChanged: (_) => _toggle(value),
                );
              },
            ),
    );

    if (!widget.searchable) return list;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            closeHexoraColumnFilterMenu(context),
      },
      child: FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              autofocus: MediaQuery.sizeOf(context).width >= 600,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 6),
            list,
            const SizedBox(height: 4),
            Text(
              '${_selected.length} ${_selected.length == 1 ? widget.selectionSingularLabel : widget.selectionPluralLabel}',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class HexoraAmountRangeInput extends StatefulWidget {
  const HexoraAmountRangeInput({
    super.key,
    this.min,
    this.max,
    required this.onChanged,
  });

  final num? min;
  final num? max;
  final void Function(num? min, num? max) onChanged;

  @override
  State<HexoraAmountRangeInput> createState() => _HexoraAmountRangeInputState();
}

class _HexoraAmountRangeInputState extends State<HexoraAmountRangeInput> {
  late num? _min = widget.min;
  late num? _max = widget.max;

  num? _parse(String raw) =>
      num.tryParse(raw.trim().replaceAll('.', '').replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: TextFormField(
            initialValue: widget.min?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Mínimo', isDense: true),
            onChanged: (raw) {
              _min = _parse(raw);
              widget.onChanged(_min, _max);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: widget.max?.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Máximo', isDense: true),
            onChanged: (raw) {
              _max = _parse(raw);
              widget.onChanged(_min, _max);
            },
          ),
        ),
      ]);
}

class HexoraColumnVisibilityStore {
  const HexoraColumnVisibilityStore._();

  static String _key(String moduleKey) =>
      'hexora.financialTable.$moduleKey.visibleColumns.v2';

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
        HexoraFinancialColumn.concept => 'Concepto',
        HexoraFinancialColumn.taxableBase => 'Base imponible',
        HexoraFinancialColumn.vat => 'IVA',
        HexoraFinancialColumn.total => 'Total',
        HexoraFinancialColumn.payment => 'Pago',
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
