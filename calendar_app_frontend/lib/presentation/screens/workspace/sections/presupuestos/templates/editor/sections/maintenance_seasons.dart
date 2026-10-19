part of '../../presupuesto_template_editor_screen.dart';

const _seasonVariableKeys = {
  'MESES_TEMPORADA_ALTA',
  'DIAS_TEMPORADA_ALTA',
  'MESES_TEMPORADA_BAJA',
  'FRECUENCIA_TEMPORADA_BAJA',
};
const _seasonMonthLabels = [
  'Ene',
  'Feb',
  'Mar',
  'Abr',
  'May',
  'Jun',
  'Jul',
  'Ago',
  'Sep',
  'Oct',
  'Nov',
  'Dic',
];

extension _MaintenanceSeasons on _PresupuestoTemplateEditorScreenState {
  bool _validateServiceSelection() {
    if (widget.templateOnly ||
        _documentFlow.presupuestoId != null ||
        !_variables.containsKey('SERVICIO_MANTENIMIENTO') ||
        _serviceChosen) {
      return true;
    }
    _updateEditorState(() {
      _serviceSelectionError = true;
      _activeStep = 1;
    });
    return false;
  }

  // Bind exact default sentences on creation or an explicit service choice.
  // Custom wording and deleted items must never be reconstructed.
  void _bindDefaultServiceDescriptions() {
    const replacements = {
      'La limpieza de la piscina se realizará tres días por semana en temporada alta: [DIAS_TEMPORADA_ALTA]':
          'Temporada alta ([MESES_TEMPORADA_ALTA]): [SERVICIO_MANTENIMIENTO], [DIAS_TEMPORADA_ALTA]',
      'En temporada baja la limpieza de la piscina se realizará [FRECUENCIA_TEMPORADA_BAJA]':
          'Temporada baja ([MESES_TEMPORADA_BAJA]): [SERVICIO_MANTENIMIENTO], [FRECUENCIA_TEMPORADA_BAJA]',
    };
    for (final section in _sections) {
      for (final item in section.itemControllers) {
        final text = item.text;
        final punctuation = text.endsWith('.') ? '.' : '';
        final key =
            punctuation.isEmpty ? text : text.substring(0, text.length - 1);
        final replacement = replacements[key];
        if (replacement != null) item.text = '$replacement$punctuation';
      }
    }
  }

  bool get _hasSeasons =>
      _sourceContent['seasonConfiguration'] is Map ||
      _variableFieldDefinitions.keys.any(_seasonVariableKeys.contains);

  List<int> get _lowSeasonMonths => [
        for (var month = 1; month <= 12; month++)
          if (!_highSeasonMonths.contains(month)) month,
      ];

  void _hydrateSeasons(Map<String, dynamic> source) {
    final config = _asMap(source['seasonConfiguration']);
    final high = _asMap(config?['highSeason']);
    final months = high?['months'];
    _highSeasonMonths = months is List
        ? months.whereType<int>().where((m) => m >= 1 && m <= 12).toSet()
        : {6, 7, 8, 9};
    _seasonEdited = false;
    _seasonMonthsEdited = false;
    _highSeasonFrequency.clear();
    _lowSeasonFrequency.clear();
  }

  void _readSeasonFrequencies() {
    if (_seasonEdited) return;
    final highMonths = _variables['MESES_TEMPORADA_ALTA']?.text.trim() ?? '';
    if (highMonths.isNotEmpty) {
      final parsed = SeasonalFrequency.monthIndexes(highMonths);
      _highSeasonMonths =
          parsed == null ? {} : parsed.map((m) => m + 1).toSet();
    }
    final config = _asMap(_sourceContent['seasonConfiguration']);
    _highSeasonFrequency.text =
        _string(_asMap(config?['highSeason'])?['frequency']) ??
            _variables['DIAS_TEMPORADA_ALTA']?.text ??
            '';
    _lowSeasonFrequency.text =
        _string(_asMap(config?['lowSeason'])?['frequency']) ??
            _variables['FRECUENCIA_TEMPORADA_BAJA']?.text ??
            '';
  }

  Map<String, dynamic> _seasonConfiguration() {
    final previous = _asMap(_sourceContent['seasonConfiguration']) ?? const {};
    return {
      ...previous,
      'highSeason': {
        ...?_asMap(previous['highSeason']),
        if (_seasonMonthsEdited ||
            SeasonalFrequency.monthIndexes(
                    _variables['MESES_TEMPORADA_ALTA']?.text ?? '') !=
                null)
          'months': _highSeasonMonths.toList()..sort(),
        'frequency': _highSeasonFrequency.text.trim(),
      },
      'lowSeason': {
        ...?_asMap(previous['lowSeason']),
        if (_seasonMonthsEdited ||
            SeasonalFrequency.monthIndexes(
                    _variables['MESES_TEMPORADA_BAJA']?.text ?? '') !=
                null)
          'months': _lowSeasonMonths,
        'frequency': _lowSeasonFrequency.text.trim(),
      },
    };
  }

  String _seasonMonthsText(Iterable<int> months) {
    final sorted = months.toList()..sort();
    return sorted.map((m) => _seasonMonthLabels[m - 1]).join(', ');
  }

  void _syncSeasonVariables() {
    if (!_hasSeasons || !_seasonEdited) return;
    final values = {
      if (_seasonMonthsEdited ||
          (_variables['MESES_TEMPORADA_ALTA']?.text.isEmpty ?? true))
        'MESES_TEMPORADA_ALTA': _seasonMonthsText(_highSeasonMonths),
      'DIAS_TEMPORADA_ALTA': _highSeasonFrequency.text.trim(),
      if (_seasonMonthsEdited ||
          (_variables['MESES_TEMPORADA_BAJA']?.text.isEmpty ?? true))
        'MESES_TEMPORADA_BAJA': _seasonMonthsText(_lowSeasonMonths),
      'FRECUENCIA_TEMPORADA_BAJA': _lowSeasonFrequency.text.trim(),
    };
    for (final entry in values.entries) {
      _variables.putIfAbsent(entry.key, TextEditingController.new).text =
          entry.value;
    }
  }

  Widget _buildMaintenanceSeasons() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    Widget season({required bool high}) {
      final months = high ? _highSeasonMonths : _lowSeasonMonths.toSet();
      final savedPeriod =
          _variables[high ? 'MESES_TEMPORADA_ALTA' : 'MESES_TEMPORADA_BAJA']
                  ?.text ??
              '';
      final customPeriod = !_seasonMonthsEdited &&
          SeasonalFrequency.monthIndexes(savedPeriod) == null;
      final frequency = high ? _highSeasonFrequency : _lowSeasonFrequency;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _editorInsetBg(theme),
          border: Border.all(color: _editorBorder(theme)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 10, runSpacing: 4, children: [
            Text(high ? 'Temporada alta' : 'Temporada baja',
                style: theme.textTheme.titleSmall),
            Text(
                '${months.length} ${months.length == 1 ? 'mes' : 'meses'}${high ? '' : ' · Automático'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ]),
          if (customPeriod)
            Text('Periodo personalizado conservado: $savedPeriod'),
          const SizedBox(height: 8),
          Wrap(spacing: 5, runSpacing: 5, children: [
            for (var month = 1; month <= 12; month++)
              if (high)
                FilterChip(
                  key: ValueKey('high_season_month_$month'),
                  label: Text(_seasonMonthLabels[month - 1]),
                  selected: months.contains(month),
                  visualDensity: VisualDensity.compact,
                  onSelected: (selected) => _updateSeasons(() {
                    _seasonMonthsEdited = true;
                    _seasonEdited = true;
                    selected
                        ? _highSeasonMonths.add(month)
                        : _highSeasonMonths.remove(month);
                  }),
                )
              else
                Semantics(
                  selected: months.contains(month),
                  label:
                      '${_seasonMonthLabels[month - 1]}, temporada baja, automático',
                  child: Chip(
                    key: ValueKey('low_season_month_$month'),
                    label: Text(_seasonMonthLabels[month - 1]),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: months.contains(month)
                        ? cs.primary.withValues(alpha: 0.16)
                        : Colors.transparent,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: months.contains(month)
                            ? cs.onSurface
                            : cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
          ]),
          const SizedBox(height: 10),
          _field(frequency, 'Frecuencia de mantenimiento',
              fieldKey: ValueKey(
                  high ? 'high_season_frequency' : 'low_season_frequency'),
              dense: true,
              hint: high ? 'Ej. 3 veces por semana' : 'Ej. 1 vez por semana',
              onChanged: (_) => _updateSeasons(() {})),
        ]),
      );
    }

    String summary(bool high) {
      if (_sections.any((section) => section.generatedFrequency)) {
        return _generatedFrequencyItems()[high ? 0 : 1];
      }
      final months = high ? _highSeasonMonths : _lowSeasonMonths;
      final frequency =
          (high ? _highSeasonFrequency : _lowSeasonFrequency).text.trim();
      final service = _variables['SERVICIO_MANTENIMIENTO']?.text.trim() ?? '';
      return '${high ? 'Temporada alta' : 'Temporada baja'}: '
          '${service.isEmpty ? '' : '$service — '}'
          '${months.isEmpty ? 'Sin meses asignados' : _seasonMonthsText(months)}'
          '${months.isEmpty ? '' : ' — ${frequency.isEmpty ? 'Indica la frecuencia' : frequency}'}.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Frecuencia de trabajos', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        _buildVariableInput(
            _variableFieldDefinitions['SERVICIO_MANTENIMIENTO']!),
        const SizedBox(height: 4),
        Text(
            'Selecciona los meses de temporada alta. Los restantes se asignarán automáticamente a temporada baja.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(children: [
              season(high: true),
              const SizedBox(height: 10),
              season(high: false)
            ]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: season(high: true)),
            const SizedBox(width: 12),
            Expanded(child: season(high: false)),
          ]);
        }),
        const SizedBox(height: 10),
        Text('Resumen para el presupuesto', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(summary(true),
            key: const ValueKey('high_season_summary'),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(summary(false),
            key: const ValueKey('low_season_summary'),
            style: theme.textTheme.bodySmall),
      ]),
    );
  }
}
