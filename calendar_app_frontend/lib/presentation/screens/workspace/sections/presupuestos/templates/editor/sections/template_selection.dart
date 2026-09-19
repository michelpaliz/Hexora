part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateSelection on _PresupuestoTemplateEditorScreenState {
  Widget _buildDefaultTemplatesCard() {
    final theme = Theme.of(context);
    final templateCount = _defaultTemplates.length;
    return _card(
      title: 'Plantillas recomendadas',
      subtitle: 'Empieza con una estructura preparada y adaptala a tu negocio.',
      icon: Icons.auto_awesome_motion_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              '$templateCount ${templateCount == 1 ? 'disponible' : 'disponibles'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      child: _loadErrorMessage != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_loadErrorMessage!)),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _defaultTemplates.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _editorInsetBg(theme),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _editorBorder(theme)),
                  ),
                  child: const Text(
                    'No hay tipos de presupuesto disponibles. Vuelve a intentarlo mas tarde.',
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = _defaultTemplates.length > 1 &&
                            constraints.maxWidth >= 920
                        ? 2
                        : 1;
                    const spacing = 12.0;
                    final itemWidth =
                        (constraints.maxWidth - (spacing * (columns - 1))) /
                            columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final template in _defaultTemplates)
                          SizedBox(
                            width: itemWidth,
                            child: _defaultTemplateQueueItem(theme, template),
                          ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _defaultTemplateQueueItem(
    ThemeData theme,
    Map<String, dynamic> template,
  ) {
    final key = _string(template['key']);
    final creating = _creatingDefaultKey == key;
    final previewing = _previewingDefaultKey == key;
    final selected = key != null && key == _selectedDefaultKey;
    final cs = theme.colorScheme;

    Widget templateInfo() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.description_outlined,
              color: cs.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _string(template['name']) ?? 'Plantilla predeterminada',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _string(template['description']) ??
                      'Plantilla preparada para empezar rapidamente.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if ((_string(template['category']) ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _string(template['category'])!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                if (template['editable'] != false)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Totalmente editable',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    }

    Widget templateActions({
      required bool expanded,
      bool stacked = false,
    }) {
      final previewButton = OutlinedButton.icon(
        onPressed: previewing || creating || key == null
            ? null
            : () => _previewDefaultTemplate(template),
        icon: previewing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.visibility_outlined, size: 19),
        label: Text(previewing ? 'Abriendo...' : 'Vista previa'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(138, 44),
          side: BorderSide(color: _editorBorder(theme)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      final useButton = FilledButton.icon(
        onPressed: creating || previewing || key == null || selected
            ? null
            : () => _useDefaultTemplate(template),
        icon: creating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                size: 19,
              ),
        label: Text(
          creating
              ? 'Preparando...'
              : selected
                  ? 'Seleccionada'
                  : 'Usar plantilla',
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(148, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            previewButton,
            const SizedBox(height: 8),
            useButton,
          ],
        );
      }
      if (!expanded) {
        return Row(
          children: [
            Expanded(child: previewButton),
            const SizedBox(width: 8),
            Expanded(child: useButton),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          previewButton,
          const SizedBox(width: 8),
          useButton,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isDark(theme)
                ? const Color(0xFF132A3E)
                : cs.primaryContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : _isDark(theme)
                      ? const Color(0xFF3F7596).withValues(alpha: 0.46)
                      : cs.primary.withValues(alpha: 0.18),
              width: selected ? 2 : 1,
            ),
          ),
          child: horizontal
              ? Row(
                  children: [
                    Expanded(child: templateInfo()),
                    const SizedBox(width: 24),
                    templateActions(expanded: true),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    templateInfo(),
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: _editorBorder(theme, alpha: 0.7),
                    ),
                    const SizedBox(height: 14),
                    templateActions(
                      expanded: false,
                      stacked: constraints.maxWidth < 480,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTemplateSelectorCard() {
    final selectedSavedTemplate = _templateById(_templateId);
    final selectedSavedTemplateId = selectedSavedTemplate == null
        ? null
        : (_string(selectedSavedTemplate['_id']) ??
            _string(selectedSavedTemplate['id']));
    final previewingSaved = selectedSavedTemplateId != null &&
        _previewingSavedTemplateId == selectedSavedTemplateId;
    final deletingSaved = selectedSavedTemplateId != null &&
        _deletingTemplateId == selectedSavedTemplateId;
    return _card(
      title: 'Plantilla base',
      subtitle: 'Opcional: parte de una plantilla guardada o crea una nueva.',
      icon: Icons.account_tree_outlined,
      trailing: widget.templateOnly
          ? TextButton.icon(
              onPressed: _newTemplate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear plantilla'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_templateId ?? 'new-template'),
                  initialValue: selectedSavedTemplate == null
                      ? null
                      : selectedSavedTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar plantilla',
                    hintText: 'Elige una base para editar',
                  ),
                  items: [
                    for (final template in _templates)
                      DropdownMenuItem(
                        value:
                            _string(template['_id']) ?? _string(template['id']),
                        child: Text(
                          _string(template['name']) ?? 'Plantilla sin nombre',
                        ),
                      ),
                  ],
                  onChanged: _selectTemplate,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  children: [
                    OutlinedButton.icon(
                      onPressed: selectedSavedTemplateId == null ||
                              previewingSaved
                          ? null
                          : () =>
                              _previewSavedTemplate(selectedSavedTemplateId),
                      icon: previewingSaved
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Vista previa'),
                    ),
                    if (selectedSavedTemplate != null &&
                        selectedSavedTemplateId != null)
                      IconButton(
                        tooltip: 'Eliminar plantilla',
                        onPressed: deletingSaved
                            ? null
                            : () => _deleteSavedTemplate(selectedSavedTemplate),
                        icon: deletingSaved
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (selectedSavedTemplate != null) ...[
            const SizedBox(height: 12),
            Text(
              'La seleccion carga el contenido completo de la plantilla elegida para seguir editando sobre ella.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ] else if (widget.templateOnly) ...[
            const SizedBox(height: 12),
            Text(
              'Usa "Previsualizar" en la vista previa para revisar los cambios actuales sin guardarlos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
