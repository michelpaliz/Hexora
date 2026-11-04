part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateSelection on _PresupuestoTemplateEditorScreenState {
  Widget _buildDefaultTemplatesCard() {
    final theme = Theme.of(context);
    final templateCount = _defaultTemplates.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plantillas recomendadas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$templateCount ${templateCount == 1 ? 'disponible' : 'disponibles'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_loadErrorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(_loadErrorMessage!)),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (_defaultTemplates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No hay tipos de presupuesto disponibles. Vuelve a intentarlo mas tarde.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _editorBorder(theme, alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _defaultTemplates.length; i++) ...[
                    _defaultTemplateQueueItem(theme, _defaultTemplates[i]),
                    if (i < _defaultTemplates.length - 1)
                      Divider(
                        height: 1,
                        color: _editorBorder(theme, alpha: 0.45),
                      ),
                  ],
                ],
              ),
            ),
        ],
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

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? cs.primary.withValues(alpha: 0.055) : null,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.description_rounded : Icons.description_outlined,
            color: selected ? cs.primary : cs.onSurfaceVariant,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _string(template['name']) ?? 'Plantilla predeterminada',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _string(template['description']) ??
                      'Plantilla preparada para empezar rapidamente.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Vista previa',
            child: IconButton(
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
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: creating || previewing || key == null || selected
                ? null
                : () => _useDefaultTemplate(template),
            icon: creating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    selected ? Icons.check_rounded : Icons.add_rounded,
                    size: 17,
                  ),
            label: Text(
              creating
                  ? 'Preparando...'
                  : selected
                      ? 'Seleccionada'
                      : 'Usar plantilla',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
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
