part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateSectionEditors on _PresupuestoTemplateEditorScreenState {
  Widget _buildSectionsCard() {
    final theme = Theme.of(context);
    return _card(
      title: 'Secciones',
      icon: Icons.view_agenda_outlined,
      trailing: TextButton.icon(
        onPressed: _addSection,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Anadir seccion'),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: _sections.isEmpty
          ? Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _editorInsetBg(Theme.of(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anade una seccion para explicar el servicio, lo incluido o las condiciones.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _editorBorder(theme, alpha: 0.55),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  itemCount: _sections.length,
                  proxyDecorator: (child, index, animation) => AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (context, child) => Material(
                      elevation: 1.5 * animation.value,
                      color: theme.colorScheme.surface,
                      shadowColor:
                          theme.colorScheme.shadow.withValues(alpha: 0.12),
                      child: child,
                    ),
                  ),
                  onReorder: (oldIndex, newIndex) {
                    if (_sections[oldIndex].isPinned) return;
                    _updateEditorState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      // Free sections can't be dropped below the pinned ones.
                      final limit = _firstPinnedSectionIndex - 1;
                      if (newIndex > limit) newIndex = limit;
                      final section = _sections.removeAt(oldIndex);
                      _sections.insert(newIndex, section);
                    });
                  },
                  itemBuilder: (context, i) => _sectionTile(_sections[i], i),
                ),
              ),
            ),
    );
  }

  Widget _sectionTile(_TemplateSectionState section, int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final itemsCount = section.itemControllers
            .where((controller) => controller.text.trim().isNotEmpty)
            .length +
        (section.generatedFrequency ? 2 : 0);
    final expanded = _sectionExpansionState[section.key] ?? index == 0;
    final hovered = _hoveredSectionKey == section.key;
    final muted = cs.onSurfaceVariant;
    return MouseRegion(
      key: ValueKey('section_card_${section.key}'),
      onEnter: (_) => setState(() => _hoveredSectionKey = section.key),
      onExit: (_) {
        if (_hoveredSectionKey == section.key) {
          setState(() => _hoveredSectionKey = null);
        }
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: HexoraMotion.duration(context, HexoraMotion.fast),
            curve: HexoraMotion.enter,
            decoration: BoxDecoration(
              color: expanded
                  ? cs.primary.withValues(alpha: 0.045)
                  : hovered
                      ? (_isDark(theme)
                          ? cs.onSurface.withValues(alpha: 0.035)
                          : const Color(0xFFF8FAFC))
                      : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: expanded ? cs.primary : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: ExpansionTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -2),
              expansionAnimationStyle: HexoraMotion.expansionStyle(context),
              initiallyExpanded: expanded,
              onExpansionChanged: (value) => setState(
                () => _sectionExpansionState[section.key] = value,
              ),
              shape: const Border(),
              collapsedShape: const Border(),
              backgroundColor: Colors.transparent,
              collapsedBackgroundColor: Colors.transparent,
              tilePadding: const EdgeInsets.only(left: 8, right: 4),
              minTileHeight: 48,
              title: Text(
                section.title.text.trim().isEmpty
                    ? 'Seccion ${index + 1}'
                    : section.title.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                section.enabled
                    ? '$itemsCount ${itemsCount == 1 ? 'elemento' : 'elementos'} · Incluida en el PDF'
                    : '$itemsCount ${itemsCount == 1 ? 'elemento' : 'elementos'} · No incluida en el PDF',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  fontSize: 11.5,
                ),
              ),
              leading: section.isPinned
                  ? Tooltip(
                      message: section.pinnedRank == 2
                          ? 'Posición fija: siempre la última sección'
                          : 'Posición fija: siempre antes del anexo',
                      child: SizedBox.square(
                        dimension: 32,
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 17,
                          color: muted,
                        ),
                      ),
                    )
                  : ReorderableDragStartListener(
                      index: index,
                      child: _SectionDragHandle(colorScheme: cs),
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: section.enabled
                        ? 'Sección incluida en el PDF'
                        : 'Sección no incluida en el PDF',
                    toggled: section.enabled,
                    child: Tooltip(
                      message: section.enabled
                          ? 'Incluida en el PDF. Pulsa para ocultarla'
                          : 'No incluida en el PDF. Pulsa para mostrarla',
                      child: Switch(
                        key: ValueKey('section_enabled_${section.key}'),
                        value: section.enabled,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (value) => _updateEditorState(
                          () => section.enabled = value,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Más acciones',
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      switch (value) {
                        case 'duplicate':
                          _duplicateSection(index);
                        case 'up':
                          _moveSection(index, -1);
                        case 'down':
                          _moveSection(index, 1);
                        case 'delete':
                          _removeSection(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.copy_all_outlined),
                          title: Text('Duplicar sección'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'up',
                        enabled: index != 0 && !section.isPinned,
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.arrow_upward_rounded),
                          title: Text('Mover arriba'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'down',
                        enabled: !section.isPinned &&
                            index + 1 < _firstPinnedSectionIndex,
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(Icons.arrow_downward_rounded),
                          title: Text('Mover abajo'),
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: cs.error,
                          ),
                          title: Text(
                            'Eliminar',
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              children: [
                _field(
                  section.title,
                  'Titulo',
                  maxLines: 2,
                  hint: 'Ej. Alcance del servicio',
                  markdown: true,
                ),
                _field(
                  section.body,
                  'Texto',
                  maxLines: 6,
                  minLines: 4,
                  hint: 'Explica esta parte del presupuesto con claridad.',
                  markdown: true,
                ),
                _sectionItemsEditor(section),
                if (section.table != null) _sectionTableEditor(section.table!),
              ],
            ),
          ),
          if (index < _sections.length - 1)
            Divider(
              height: 1,
              indent: 12,
              endIndent: 12,
              color: _editorBorder(theme, alpha: 0.5),
            ),
        ],
      ),
    );
  }

  Widget _sectionItemsEditor(_TemplateSectionState section) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controllers = section.itemControllers;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.generatedFrequency) ...[
            const Text('Generado automáticamente'),
            for (final item in _generatedFrequencyItems())
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('✓ $item'),
              ),
            TextButton.icon(
              onPressed: _editFrequencyControls,
              icon: const Icon(Icons.tune),
              label: const Text('Editar servicio y frecuencias'),
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.generatedFrequency
                        ? 'Elementos adicionales'
                        : 'Elementos de la lista',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
                Text(
                  '${controllers.length} '
                  '${controllers.length == 1 ? 'elemento' : 'elementos'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          if (controllers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _editorInsetBg(theme),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _editorBorder(theme, alpha: 0.7)),
              ),
              child: Text(
                section.generatedFrequency
                    ? 'Puedes añadir condiciones adicionales sin modificar la frecuencia automática.'
                    : 'Todavía no hay elementos en esta lista.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              padding: EdgeInsets.zero,
              itemCount: controllers.length,
              onReorder: (oldIndex, newIndex) {
                _updateEditorState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  section.moveItem(oldIndex, newIndex);
                });
              },
              itemBuilder: (context, i) => _sectionItemRow(section, i),
            ),
          OutlinedButton.icon(
            onPressed: () => _updateEditorState(section.addItem),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Añadir elemento'),
          ),
        ],
      ),
    );
  }

  Widget _sectionItemRow(_TemplateSectionState section, int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      key: ValueKey('${section.key}_item_$index'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: ValueKey('${section.key}_item_field_$index'),
              controller: section.itemControllers[index],
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _updateEditorState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Describe este elemento',
                filled: true,
                fillColor: _editorInsetBg(theme),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _editorBorder(theme)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _editorBorder(theme)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 1.4),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Eliminar elemento',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                _updateEditorState(() => section.removeItemAt(index)),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _sectionTableEditor(_TemplateTableState table) {
    final theme = Theme.of(context);
    double columnWidth(int index) {
      if (table.columns.length == 4) {
        return switch (index) {
          0 => 145,
          1 => 105,
          2 => 145,
          _ => 135,
        };
      }
      return 135;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _editorInsetBg(theme),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _editorBorder(theme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tabla',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _updateEditorState(table.addRow),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Anadir fila'),
              ),
            ],
          ),
          if (table.hasComputedColumns) ...[
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in table.bulkValues.entries)
                  SizedBox(
                    width: 190,
                    child: _field(
                      entry.value,
                      entry.key < table.columns.length
                          ? table.columns[entry.key].text
                          : 'Valor',
                      dense: true,
                      fieldKey: ValueKey('table_bulk_${entry.key}'),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FilledButton.icon(
                    onPressed: table.selectedRows.isEmpty
                        ? null
                        : () => _updateEditorState(table.applyToSelectedRows),
                    icon: const Icon(Icons.playlist_add_check_rounded),
                    label: Text(
                      table.selectedRows.isEmpty
                          ? 'Selecciona meses'
                          : table.selectedRows.length == 1
                              ? 'Aplicar a 1 mes'
                              : 'Aplicar a ${table.selectedRows.length} meses',
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Scrollbar(
            controller: table.horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: table.horizontalScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (table.hasComputedColumns)
                        SizedBox(
                          width: 42,
                          child: Checkbox(
                            tristate: true,
                            value: table.selectedRows.isEmpty
                                ? false
                                : table.selectedRows.length == table.rows.length
                                    ? true
                                    : null,
                            onChanged: (value) => _updateEditorState(
                              () => table.toggleAllRows(value == true),
                            ),
                          ),
                        ),
                      for (var columnIndex = 0;
                          columnIndex < table.columns.length;
                          columnIndex++)
                        SizedBox(
                          width: columnWidth(columnIndex),
                          child: _field(
                            table.columns[columnIndex],
                            'Encabezado',
                            dense: true,
                            showLabel: false,
                          ),
                        ),
                      const SizedBox(width: 42),
                    ],
                  ),
                  for (var rowIndex = 0;
                      rowIndex < table.rows.length;
                      rowIndex++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (table.hasComputedColumns)
                          SizedBox(
                            width: 42,
                            child: Checkbox(
                              value: table.selectedRows.contains(rowIndex),
                              onChanged: (value) => _updateEditorState(
                                () => table.toggleRow(rowIndex, value == true),
                              ),
                            ),
                          ),
                        for (var columnIndex = 0;
                            columnIndex < table.columns.length;
                            columnIndex++)
                          SizedBox(
                            width: columnWidth(columnIndex),
                            child: _field(
                              table.cell(rowIndex, columnIndex),
                              'Fila ${rowIndex + 1}',
                              fieldKey: ValueKey(
                                'table_cell_${rowIndex}_$columnIndex',
                              ),
                              dense: true,
                              showLabel: false,
                              readOnly: table.isReadOnlyColumn(columnIndex),
                              disabledMessage:
                                  table.isReadOnlyColumn(columnIndex)
                                      ? 'Calculado'
                                      : null,
                              onChanged: (_) => table.recalculateRow(rowIndex),
                            ),
                          ),
                        SizedBox(
                          width: 42,
                          child: IconButton(
                            tooltip: 'Eliminar fila',
                            onPressed: () => _updateEditorState(
                              () => table.removeRow(rowIndex),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDragHandle extends StatefulWidget {
  const _SectionDragHandle({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<_SectionDragHandle> createState() => _SectionDragHandleState();
}

class _SectionDragHandleState extends State<_SectionDragHandle> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    return MouseRegion(
      cursor: _pressed ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: Tooltip(
          message: 'Arrastrar para reordenar',
          child: SizedBox.square(
            dimension: 32,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: active
                  ? widget.colorScheme.primary
                  : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
