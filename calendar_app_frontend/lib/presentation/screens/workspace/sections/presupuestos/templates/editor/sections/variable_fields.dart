part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateVariableFields on _PresupuestoTemplateEditorScreenState {
  Widget _buildVariableInput(_TemplateVariableField field) {
    final allowsManualOverride = field.key == 'CLIENTE';
    final editable =
        (!field.isAutomatic || allowsManualOverride) && !field.readOnly;
    if (field.readOnly) {
      return _readOnlySummaryField(field);
    }
    if (field.key == 'SERVICIO_MANTENIMIENTO') {
      final controller = _variables[field.key]!;
      final selected = controller.text.trim();
      const options = <String, String>{
        'Jardín y piscina': 'mantenimiento del jardín y la piscina',
        'Solo jardín': 'mantenimiento del jardín',
        'Solo piscina': 'limpieza de la piscina',
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de servicio *'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options.entries)
                  ChoiceChip(
                    key: ValueKey('service_${option.value}'),
                    label: Text(option.key),
                    selected: selected == option.value &&
                        (_serviceChosen ||
                            _documentFlow.presupuestoId != null ||
                            widget.templateOnly),
                    onSelected: editable
                        ? (chosen) {
                            if (!chosen) return;
                            _updateEditorState(() {
                              controller.text = option.value;
                              _serviceChosen = true;
                              _serviceSelectionError = false;
                              _bindDefaultServiceDescriptions();
                            });
                          }
                        : null,
                  ),
              ],
            ),
            if (_serviceSelectionError)
              Text('Selecciona un tipo de servicio para continuar.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (selected.isNotEmpty && !options.containsValue(selected)) ...[
              const SizedBox(height: 8),
              Text('Servicio personalizado: $selected'),
            ],
          ],
        ),
      );
    }
    return _field(
      _variables[field.key]!,
      '${_variableDisplayLabel(field)}${field.isRequired ? ' *' : ' (opcional)'}',
      fieldKey: ValueKey('variable_${field.key}'),
      hint: field.hint,
      dense: true,
      prefixIcon: const ['TOTAL_MENSUAL', 'IMPORTE_MENSUAL'].contains(field.key)
          ? Icons.euro_rounded
          : field.inputType == 'currency'
              ? Icons.euro_rounded
              : null,
      keyboardType: field.keyboardType,
      maxLines: field.maxLines,
      textCapitalization: field.key == 'CLIENTE'
          ? TextCapitalization.words
          : TextCapitalization.none,
      enabled: editable,
      readOnly: field.key == 'FECHA',
      onTap: editable && field.key == 'FECHA'
          ? () => _selectVariableDate(field.key)
          : null,
      onChanged: (_) => _recalculateVariableFields(changedKey: field.key),
      disabledMessage:
          field.readOnly || (field.isAutomatic && !allowsManualOverride)
              ? 'Solo lectura'
              : null,
    );
  }

  Widget _readOnlySummaryField(_TemplateVariableField field) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final value = _variables[field.key]?.text.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_variableDisplayLabel(field)}${field.isRequired ? ' *' : ' (opcional)'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                    ),
                  ),
                ),
                Text(
                  'Calculado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(field.icon, size: 19, color: cs.primary),
                const SizedBox(width: 10),
                Text(
                  value.isEmpty ? '—' : value,
                  key: ValueKey('variable_${field.key}'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInput(_TemplateVariableField field) {
    return _ClientAutocompleteField(
      key: const ValueKey('client_autocomplete'),
      fieldKey: ValueKey('variable_${field.key}'),
      controller: _variables[field.key]!,
      label: _variableDisplayLabel(field),
      hint: 'Buscar cliente por nombre...',
      selectedClientId: _selectedClientId,
      customName: _customClientName,
      onSearchMode: () => _updateEditorState(() => _customClientName = false),
      search: _searchActiveClients,
      onCustomName: (name) {
        _updateEditorState(() {
          _customClientName = true;
          _selectedClientId = null;
          _selectedClientName = null;
          _variables[field.key]!.text = name;
          _recalculateVariableFields(changedKey: field.key);
        });
      },
      onSelected: (client) {
        _updateEditorState(() {
          _customClientName = false;
          _selectedClientId = client.id;
          _selectedClientName = client.name.trim();
          _variables[field.key]!.text = client.name.trim();
          _recalculateVariableFields(changedKey: field.key);
        });
      },
      onClear: () {
        _updateEditorState(() {
          _selectedClientId = null;
          _selectedClientName = null;
          _variables[field.key]!.clear();
          _recalculateVariableFields(changedKey: field.key);
        });
      },
      onChanged: (value) {
        if (_selectedClientId != null &&
            value.trim() != (_selectedClientName ?? '').trim()) {
          _selectedClientId = null;
          _selectedClientName = null;
        }
        _recalculateVariableFields(changedKey: field.key);
        _updateEditorState(() {});
      },
    );
  }

  Widget _buildMainCopyCard() {
    final priceKey = _primaryPriceKey();
    final clientDefinition = _variableFieldDefinitions['CLIENTE'];
    final clientField =
        clientDefinition == null ? null : _buildClientInput(clientDefinition);
    final priceDefinition =
        priceKey == null ? null : _variableFieldDefinitions[priceKey];
    final priceField =
        priceKey == null ? null : _buildVariableInput(priceDefinition!);
    return _card(
      title: 'Datos del presupuesto',
      subtitle: 'Nombre, cliente e importe.',
      icon: Icons.edit_note_rounded,
      child: Column(
        children: [
          _field(
            _name,
            widget.templateOnly
                ? 'Nombre de plantilla'
                : 'Nombre del presupuesto',
            dense: true,
            hint: widget.templateOnly
                ? 'Ej. Mantenimiento mensual comunidades'
                : 'Ej. Mantenimiento anual Las Alondras',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final primaryFields = <Widget>[
                if (clientField != null) clientField,
                if (priceField != null) priceField,
              ];
              if (primaryFields.isEmpty) return const SizedBox.shrink();
              if (primaryFields.length == 1 || constraints.maxWidth < 620) {
                return Column(
                  children: primaryFields,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: primaryFields[0]),
                  const SizedBox(width: 12),
                  Expanded(child: primaryFields[1]),
                ],
              );
            },
          ),
          if (_hasSeasons) _buildMaintenanceSeasons(),
          _buildTagFields(),
          _field(
            _title,
            'Titulo del PDF',
            maxLines: 2,
            hint: 'Ej. Presupuesto para [CLIENTE]',
            markdown: true,
          ),
          _field(
            _subtitle,
            'Subtitulo',
            maxLines: 2,
            hint: 'Ej. [MES] de [ANO]',
            markdown: true,
          ),
          _field(
            _intro,
            'Texto inicial',
            maxLines: 6,
            minLines: 5,
            hint: 'Explica brevemente el servicio y el precio propuesto.',
            textCapitalization: TextCapitalization.sentences,
            markdown: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTagFields() {
    final theme = Theme.of(context);
    final primaryPriceKey = _primaryPriceKey();
    final primaryKeys = {
      'CLIENTE',
      if (primaryPriceKey != null) primaryPriceKey,
    };
    final fields = _variableFieldDefinitions.values
        .where(
          (field) =>
              !primaryKeys.contains(field.key) &&
              !_seasonVariableKeys.contains(field.key) &&
              !(_hasSeasons && field.key == 'SERVICIO_MANTENIMIENTO') &&
              !_isRedundantPricingField(field) &&
              (_documentFlow.presupuestoId != null ||
                  _isVariableFieldVisible(field)),
        )
        .toList(growable: false);
    final automaticFields = fields
        .where((field) => field.isAutomatic || field.readOnly)
        .toList(growable: false);
    final editableFields = fields
        .where((field) => !field.isAutomatic && !field.readOnly)
        .toList(growable: false);
    final usedFields = editableFields
        .where((field) =>
            field.isUsedInTemplate || field.key == 'SERVICIO_MANTENIMIENTO')
        .toList(growable: false);
    final optionalFields = editableFields
        .where((field) =>
            !field.isUsedInTemplate && field.key != 'SERVICIO_MANTENIMIENTO')
        .toList(growable: false);

    if (fields.isEmpty) return const SizedBox.shrink();

    return KeyedSubtree(
      key: ValueKey(_variableSchemaKey),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Divider(color: _editorBorder(theme, alpha: 0.72)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Text(
                'Detalles del presupuesto',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Completa únicamente la información que aparecerá en este documento.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (automaticFields.isNotEmpty) ...[
            _automaticVariablesPanel(theme, automaticFields),
            const SizedBox(height: 18),
          ],
          if (usedFields.isNotEmpty) _groupedVariableFields(usedFields),
          if (optionalFields.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _editorInsetBg(theme),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _editorBorder(theme, alpha: 0.65)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                leading: Icon(
                  Icons.tune_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: const Text('Otros campos opcionales'),
                subtitle: Text(
                  '${optionalFields.length} campos no utilizados por la plantilla actual',
                ),
                children: [_variableFieldsGrid(optionalFields)],
              ),
            ),
          Divider(color: _editorBorder(theme, alpha: 0.72)),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _variableFieldsGrid(List<_TemplateVariableField> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth < 620
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          children: [
            for (final field in fields)
              SizedBox(
                width: fieldWidth,
                child: _buildVariableInput(field),
              ),
          ],
        );
      },
    );
  }

  Widget _groupedVariableFields(List<_TemplateVariableField> fields) {
    const labels = {
      'services': 'Servicios y mantenimiento',
      'pricing': 'Precios adicionales',
      'contract': 'Condiciones del contrato',
      'details': 'Información adicional',
    };
    const icons = {
      'services': Icons.home_repair_service_outlined,
      'pricing': Icons.euro_rounded,
      'contract': Icons.description_outlined,
    };
    final groups = <String, List<_TemplateVariableField>>{};
    for (final field in fields) {
      groups.putIfAbsent(field.group, () => []).add(field);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Row(children: [
              Icon(icons[entry.key] ?? Icons.notes_rounded,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      labels[entry.key] ?? _variableLabel(entry.key, null),
                      style: Theme.of(context).textTheme.titleSmall)),
            ]),
          ),
          _variableFieldsGrid(entry.value),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _automaticVariablesPanel(
    ThemeData theme,
    List<_TemplateVariableField> fields,
  ) {
    final cs = theme.colorScheme;
    final unique = <String, _TemplateVariableField>{};
    for (final field in fields) {
      unique.putIfAbsent(
          field.key.toUpperCase().replaceAll('Ñ', 'N'), () => field);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos automáticos', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                  'Estos datos se completan automáticamente al generar el documento.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(spacing: 16, runSpacing: 4, children: [
                for (final field in unique.values)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_variableDisplayLabel(field)}: ',
                        style: theme.textTheme.bodySmall),
                    Text(
                        (_variables[field.key]?.text.trim().isEmpty ?? true)
                            ? 'Automático'
                            : _variables[field.key]!.text.trim(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
              ]),
            ],
          )),
        ],
      ),
    );
  }
}
