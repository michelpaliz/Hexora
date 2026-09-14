part of '../../presupuesto_template_editor_screen.dart';

class _EditorStep {
  const _EditorStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
}

class _TemplateVariableField {
  const _TemplateVariableField({
    required this.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.isAutomatic = false,
    this.isUsedInTemplate = true,
    this.readOnly = false,
    this.calculation,
  });

  final String key;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isAutomatic;
  final bool isUsedInTemplate;
  final bool readOnly;
  final _VariableCalculation? calculation;
}

class _VariableCalculation {
  const _VariableCalculation({
    required this.operation,
    required this.operands,
    required this.format,
    required this.currency,
    required this.readOnly,
  });

  factory _VariableCalculation.fromMap(Map<String, dynamic> map) {
    return _VariableCalculation(
      operation: _string(map['operation']) ?? '',
      operands: map['operands'] is List
          ? (map['operands'] as List)
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const [],
      format: _string(map['format']) ?? '',
      currency: _string(map['currency']) ?? 'EUR',
      readOnly: map['readOnly'] == true,
    );
  }

  final String operation;
  final List<String> operands;
  final String format;
  final String currency;
  final bool readOnly;
}

class _TemplateSectionState {
  _TemplateSectionState({
    required this.original,
    required this.key,
    required this.order,
    required this.enabled,
    required this.title,
    required this.body,
    required this.itemControllers,
    this.table,
  });

  factory _TemplateSectionState.fromMap(
    Map<String, dynamic> map, {
    int fallbackOrder = 1,
  }) {
    final items = map['items'] is List
        ? (map['items'] as List)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList()
        : const <String>[];
    return _TemplateSectionState(
      original: Map<String, dynamic>.from(map),
      key: _string(map['key']) ?? 'section_$fallbackOrder',
      order: _int(map['order']) ?? fallbackOrder,
      enabled: map['enabled'] != false,
      title: TextEditingController(text: _string(map['title']) ?? ''),
      body: TextEditingController(text: _string(map['body']) ?? ''),
      itemControllers: [
        for (final item in items) TextEditingController(text: item),
      ],
      table: _asMap(map['table']) == null
          ? null
          : _TemplateTableState.fromMap(_asMap(map['table'])!),
    );
  }

  final Map<String, dynamic> original;
  final String key;
  int order;
  bool enabled;
  final TextEditingController title;
  final TextEditingController body;
  final List<TextEditingController> itemControllers;
  final _TemplateTableState? table;

  bool get isGarageCleaning {
    final normalizedKey = key.toLowerCase();
    final normalizedTitle = title.text.toLowerCase();
    return normalizedKey.contains('garage') ||
        normalizedKey.contains('garaje') ||
        normalizedTitle.contains('garaje');
  }

  bool get isOptional =>
      original['optional'] == true ||
      original['isOptional'] == true ||
      isGarageCleaning;

  void addItem() => itemControllers.add(TextEditingController());

  void removeItemAt(int index) {
    if (index < 0 || index >= itemControllers.length) return;
    itemControllers.removeAt(index).dispose();
  }

  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= itemControllers.length ||
        newIndex < 0 ||
        newIndex >= itemControllers.length) {
      return;
    }
    final controller = itemControllers.removeAt(oldIndex);
    itemControllers.insert(newIndex, controller);
  }

  bool referencesVariable(String variableKey) {
    final marker = '[$variableKey]';
    if (title.text.contains(marker) ||
        body.text.contains(marker) ||
        itemControllers.any((controller) => controller.text.contains(marker))) {
      return true;
    }
    return jsonEncode(<String, dynamic>{
      ...original,
      if (table != null) 'table': table!.toJson(),
    }).contains(variableKey);
  }

  Map<String, dynamic> toJson() => {
        ...original,
        'key': key,
        'order': order,
        'title': title.text,
        'body': body.text,
        'items': itemControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
        'enabled': enabled,
        if (table != null) 'table': table!.toJson(),
      };

  void dispose() {
    title.dispose();
    body.dispose();
    for (final controller in itemControllers) {
      controller.dispose();
    }
    table?.dispose();
  }
}

class _TemplateComputedColumn {
  const _TemplateComputedColumn({
    required this.targetIndex,
    required this.operation,
    required this.sourceIndexes,
    required this.format,
    required this.currency,
    required this.readOnly,
  });

  factory _TemplateComputedColumn.fromMap(Map<String, dynamic> map) {
    return _TemplateComputedColumn(
      targetIndex: _int(map['targetIndex']) ?? -1,
      operation: _string(map['operation']) ?? '',
      sourceIndexes: map['sourceIndexes'] is List
          ? (map['sourceIndexes'] as List)
              .map(_int)
              .whereType<int>()
              .toList(growable: false)
          : const [],
      format: _string(map['format']) ?? '',
      currency: _string(map['currency']) ?? 'EUR',
      readOnly: map['readOnly'] == true,
    );
  }

  final int targetIndex;
  final String operation;
  final List<int> sourceIndexes;
  final String format;
  final String currency;
  final bool readOnly;
}

class _TemplateTableState {
  _TemplateTableState({
    required this.original,
    required this.columns,
    required this.rows,
    required this.computedColumns,
    required this.bulkValues,
  });

  factory _TemplateTableState.fromMap(Map<String, dynamic> map) {
    final rawColumns =
        map['columns'] is List ? map['columns'] as List : const <dynamic>[];
    final columns = rawColumns
        .map((value) => TextEditingController(text: value?.toString() ?? ''))
        .toList();
    final rows = <List<TextEditingController>>[];
    if (map['rows'] is List) {
      for (final rawRow in map['rows'] as List) {
        final values = rawRow is List ? rawRow : const <dynamic>[];
        rows.add([
          for (var i = 0; i < values.length || i < columns.length; i++)
            TextEditingController(
              text: i < values.length ? values[i]?.toString() ?? '' : '',
            ),
        ]);
      }
    }
    var computedColumns = map['computedColumns'] is List
        ? (map['computedColumns'] as List)
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .map(_TemplateComputedColumn.fromMap)
            .where((value) => value.targetIndex >= 0)
            .toList(growable: false)
        : const <_TemplateComputedColumn>[];
    if (computedColumns.isEmpty) {
      final frequencyIndex = _tableColumnIndex(
        columns,
        const ['FRECUENCIA', 'FRECUENCIA MENSUAL'],
      );
      final priceIndex = _tableColumnIndex(
        columns,
        const [
          'VALOR POR LIMPIEZA',
          'PRECIO POR LIMPIEZA',
          'PRECIO POR VISITA',
          'PRECIO VISITA',
        ],
      );
      final totalIndex = _tableColumnIndex(
        columns,
        const ['TOTAL MENSUAL', 'IMPORTE MENSUAL'],
      );
      if (frequencyIndex != null && priceIndex != null && totalIndex != null) {
        computedColumns = <_TemplateComputedColumn>[
          _TemplateComputedColumn(
            targetIndex: totalIndex,
            operation: 'multiply',
            sourceIndexes: <int>[frequencyIndex, priceIndex],
            format: 'currency',
            currency: 'EUR',
            readOnly: true,
          ),
        ];
      }
    }
    final sourceIndexes = <int>{
      for (final computed in computedColumns) ...computed.sourceIndexes,
    };
    final state = _TemplateTableState(
      original: Map<String, dynamic>.from(map),
      columns: columns,
      rows: rows,
      computedColumns: computedColumns,
      bulkValues: <int, TextEditingController>{
        for (final index in sourceIndexes)
          index: TextEditingController(
            text: rows.isNotEmpty && index < rows.first.length
                ? rows.first[index].text
                : '',
          ),
      },
    );
    state.recalculateAll();
    return state;
  }

  final Map<String, dynamic> original;
  final List<TextEditingController> columns;
  final List<List<TextEditingController>> rows;
  final List<_TemplateComputedColumn> computedColumns;
  final Map<int, TextEditingController> bulkValues;
  final Set<int> selectedRows = <int>{};
  final ScrollController horizontalScrollController = ScrollController();

  bool get hasComputedColumns => computedColumns.isNotEmpty;

  bool isReadOnlyColumn(int index) => computedColumns.any(
        (computed) => computed.targetIndex == index && computed.readOnly,
      );

  void toggleAllRows(bool selected) {
    selectedRows
      ..clear()
      ..addAll(selected ? List.generate(rows.length, (index) => index) : []);
  }

  void toggleRow(int index, bool selected) {
    if (selected) {
      selectedRows.add(index);
    } else {
      selectedRows.remove(index);
    }
  }

  void applyToSelectedRows() {
    for (final rowIndex in selectedRows) {
      if (rowIndex < 0 || rowIndex >= rows.length) continue;
      for (final entry in bulkValues.entries) {
        cell(rowIndex, entry.key).text = entry.value.text;
      }
      recalculateRow(rowIndex);
    }
  }

  void applyVariableValue(String key, String value) {
    if (key != 'PRECIO_VISITA') return;
    final headerIndex = _tableColumnIndex(
      columns,
      const [
        'VALOR POR LIMPIEZA',
        'PRECIO POR LIMPIEZA',
        'PRECIO POR VISITA',
        'PRECIO VISITA',
      ],
    );
    final calculatedIndex = computedColumns
        .where((computed) => computed.sourceIndexes.length >= 2)
        .map((computed) => computed.sourceIndexes[1])
        .firstOrNull;
    final columnIndex = headerIndex ?? calculatedIndex;
    if (columnIndex != null) applyGlobalValue(columnIndex, value);
  }

  void applyGlobalValue(int columnIndex, String value) {
    if (columnIndex < 0 || columnIndex >= columns.length) return;
    bulkValues[columnIndex]?.text = value;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      cell(rowIndex, columnIndex).text = value;
    }
    recalculateAll();
  }

  double? totalAmount() {
    final totalColumn = _tableColumnIndex(
          columns,
          const ['TOTAL MENSUAL', 'IMPORTE MENSUAL', 'TOTAL'],
        ) ??
        computedColumns.map((computed) => computed.targetIndex).firstOrNull;
    if (totalColumn == null) return null;
    var total = 0.0;
    var found = false;
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final value = _parseLocalizedNumber(cell(rowIndex, totalColumn).text);
      if (value == null) continue;
      total += value;
      found = true;
    }
    return found ? total : null;
  }

  void recalculateAll() {
    for (var index = 0; index < rows.length; index++) {
      recalculateRow(index);
    }
  }

  void recalculateRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= rows.length) return;
    for (final computed in computedColumns) {
      if (computed.operation != 'multiply' || computed.sourceIndexes.isEmpty) {
        continue;
      }
      var result = 1.0;
      var valid = true;
      for (final sourceIndex in computed.sourceIndexes) {
        final value = _parseLocalizedNumber(cell(rowIndex, sourceIndex).text);
        if (value == null) {
          valid = false;
          break;
        }
        result *= value;
      }
      cell(rowIndex, computed.targetIndex).text = valid
          ? _formatCalculatedValue(
              result,
              format: computed.format,
              currency: computed.currency,
            )
          : '';
    }
  }

  TextEditingController cell(int rowIndex, int columnIndex) {
    final row = rows[rowIndex];
    while (row.length < columns.length) {
      row.add(TextEditingController());
    }
    return row[columnIndex];
  }

  void addRow() {
    rows.add(List.generate(columns.length, (_) => TextEditingController()));
  }

  void removeRow(int index) {
    if (index < 0 || index >= rows.length) return;
    final removed = rows.removeAt(index);
    for (final controller in removed) {
      controller.dispose();
    }
    final nextSelection = <int>{};
    for (final selected in selectedRows) {
      if (selected < index) nextSelection.add(selected);
      if (selected > index) nextSelection.add(selected - 1);
    }
    selectedRows
      ..clear()
      ..addAll(nextSelection);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        ...original,
        'columns': columns.map((controller) => controller.text).toList(),
        'rows': [
          for (final row in rows)
            row.map((controller) => controller.text).toList(),
        ],
      };

  void dispose() {
    horizontalScrollController.dispose();
    for (final controller in columns) {
      controller.dispose();
    }
    for (final row in rows) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    for (final controller in bulkValues.values) {
      controller.dispose();
    }
  }
}

class _TemplateImageState {
  _TemplateImageState({
    required this.original,
    required this.slot,
    required this.enabled,
    required this.label,
    this.url = '',
    this.blobName = '',
  });

  factory _TemplateImageState.fromMap(Map<String, dynamic> map) {
    return _TemplateImageState(
      original: Map<String, dynamic>.from(map),
      slot: _string(map['slot']) ?? 'photo_1',
      enabled: map['enabled'] != false,
      label: TextEditingController(text: _string(map['label']) ?? ''),
      url: _string(map['url']) ?? '',
      blobName: _string(map['blobName']) ?? '',
    );
  }

  final Map<String, dynamic> original;
  final String slot;
  bool enabled;
  final TextEditingController label;
  String url;
  String blobName;

  void apply(Map<String, dynamic> map) {
    url = _string(map['url']) ?? _string(map['readUrl']) ?? url;
    blobName = _string(map['blobName']) ?? blobName;
    final nextLabel = _string(map['label']);
    if (nextLabel != null) label.text = nextLabel;
    enabled = map['enabled'] != false;
  }

  Map<String, dynamic> toJson() => {
        ...original,
        'slot': slot,
        'label': label.text,
        'url': url,
        'blobName': blobName,
        'enabled': enabled,
      };

  void dispose() => label.dispose();
}
