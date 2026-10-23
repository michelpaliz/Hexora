part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateEditorLayout on _PresupuestoTemplateEditorScreenState {
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: _editorPageBg(theme),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1080;
                final steps = _editorSteps();
                final activeStep = steps.isEmpty
                    ? 0
                    : _activeStep.clamp(0, steps.length - 1).toInt();
                final previewColumn = <Widget>[
                  _buildLivePreviewCard(),
                  if (!widget.templateOnly) _buildDocumentActionsCard(),
                ];
                final leftPane = ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHero(theme),
                    const SizedBox(height: 10),
                    _buildStepSelector(steps, activeStep),
                    if (steps.isNotEmpty) ...steps[activeStep].children,
                    if (!wide) ...previewColumn,
                  ],
                );
                final workspace = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: leftPane),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: previewColumn,
                            ),
                          ),
                        ],
                      )
                    : leftPane;
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 1800 : 1480),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 24 : 12,
                        wide ? 16 : 12,
                        wide ? 24 : 12,
                        0,
                      ),
                      child: Column(children: [
                        Expanded(child: workspace),
                        _buildStepFooter(theme, steps, activeStep),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool _isDark(ThemeData theme) => theme.brightness == Brightness.dark;

  Color _editorPageBg(ThemeData theme) => _isDark(theme)
      ? theme.colorScheme.surface
      : theme.scaffoldBackgroundColor;

  Color _editorCardBg(ThemeData theme) =>
      _isDark(theme) ? const Color(0xFF101A28) : theme.colorScheme.surface;

  Color _editorPanelBg(ThemeData theme) =>
      _isDark(theme) ? const Color(0xFF132235) : theme.colorScheme.surface;

  Color _editorInsetBg(ThemeData theme) => _isDark(theme)
      ? const Color(0xFF0B1624)
      : theme.colorScheme.surfaceContainerLowest;

  Color _editorSoftAccentBg(ThemeData theme) => _isDark(theme)
      ? const Color(0xFF153044)
      : theme.colorScheme.surfaceContainerHighest;

  Color _editorBorder(ThemeData theme, {double alpha = 1}) => _isDark(theme)
      ? const Color(0xFF3A5F78).withValues(alpha: alpha)
      : theme.colorScheme.outlineVariant.withValues(alpha: alpha);

  Widget _buildStepSelector(List<_EditorStep> steps, int activeStep) {
    final theme = Theme.of(context);
    if (steps.isEmpty) return const SizedBox.shrink();
    final step = steps[activeStep];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepper(theme, steps, activeStep),
          const SizedBox(height: 12),
          Text(
            step.subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(
    ThemeData theme,
    List<_EditorStep> steps,
    int activeStep,
  ) {
    return HexoraDocumentStepper(
      steps: [
        for (var i = 0; i < steps.length; i++)
          HexoraDocumentStep(
            label: steps[i].title,
            icon: steps[i].icon,
            enabled: !(_mustSelectDefaultTemplate && i > 0),
          ),
      ],
      currentStep: activeStep,
      onStepTapped: (index) => _updateEditorState(() => _activeStep = index),
      itemKeyBuilder: (_, step) => ValueKey('editor_step_${step.label}'),
    );
  }

  Widget _buildStepFooter(
    ThemeData theme,
    List<_EditorStep> steps,
    int activeStep,
  ) {
    final isLastStep = steps.isEmpty || activeStep >= steps.length - 1;
    final selectionBlocked = _mustSelectDefaultTemplate;
    final saveLabel =
        widget.templateOnly ? 'Guardar como plantilla' : 'Guardar borrador';
    final footerText = widget.templateOnly
        ? (isLastStep
            ? 'Crea o actualiza una plantilla reutilizable.'
            : 'Podrás crear o actualizar la plantilla en el último paso.')
        : (isLastStep
            ? 'Guarda este presupuesto como borrador para continuar editandolo.'
            : 'El presupuesto se guardará como borrador en el último paso.');
    final info = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_done_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            footerText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
    final nextTitle = isLastStep ? null : steps[activeStep + 1].title;
    final backButton = OutlinedButton.icon(
      onPressed: activeStep <= 0
          ? null
          : () => _updateEditorState(() => _activeStep = activeStep - 1),
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: const Text('Atrás'),
    );
    final createFromTemplateButton = widget.templateOnly && isLastStep
        ? OutlinedButton.icon(
            onPressed: _creatingDocumentFromTemplate || _saving
                ? null
                : _createDocumentFromCurrentTemplate,
            icon: _creatingDocumentFromTemplate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.article_outlined, size: 18),
            label: Text(
              _creatingDocumentFromTemplate
                  ? 'Creando...'
                  : 'Crear presupuesto',
            ),
          )
        : null;
    final primaryLabel = _saving
        ? 'Guardando...'
        : isLastStep
            ? saveLabel
            : selectionBlocked
                ? 'Selecciona una plantilla'
                : 'Continuar a ${nextTitle!.toLowerCase()}';
    Widget primaryButton({bool compact = false}) => FilledButton.icon(
          onPressed: _saving ||
                  _creatingDocumentFromTemplate ||
                  selectionBlocked
              ? null
              : isLastStep
                  ? () => _save()
                  : () =>
                      _updateEditorState(() => _activeStep = activeStep + 1),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isLastStep
                      ? Icons.save_outlined
                      : Icons.arrow_forward_rounded,
                  size: 18,
                ),
          label: Text(
            primaryLabel,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.clip,
            softWrap: false,
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        );
    return HexoraDocumentFooter(
      status: info,
      back: backButton,
      secondaryActions: [
        if (createFromTemplateButton != null) createFromTemplateButton,
      ],
      primary: primaryButton(compact: true),
    );
  }

  Widget _buildHero(ThemeData theme) {
    final title = widget.templateOnly ? 'Plantilla PDF' : 'Presupuesto PDF';
    final subtitle = widget.templateOnly
        ? 'Crea una base simple para generar presupuestos con cliente, precio, secciones e imagenes.'
        : 'Crea un presupuesto borrador con cliente, precio, secciones e imagenes.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _isDark(theme)
              ? const [Color(0xFF173653), Color(0xFF101A28)]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.12),
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.92,
                  ),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.82),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.templateOnly
                      ? Icons.auto_awesome_motion_rounded
                      : Icons.description_outlined,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedDefaultTemplate != null)
                _heroChip(
                  theme,
                  icon: Icons.account_tree_outlined,
                  label: _string(_selectedDefaultTemplate!['name']) ??
                      'Tipo seleccionado',
                ),
              _heroChip(
                theme,
                icon: Icons.person_outline_rounded,
                label: _variableValue('CLIENTE').isEmpty
                    ? 'Cliente'
                    : _variableValue('CLIENTE'),
              ),
              _heroChip(
                theme,
                icon: Icons.euro_rounded,
                label: _primaryPriceValue().isEmpty
                    ? 'Precio'
                    : _primaryPriceValue(),
              ),
              _heroChip(
                theme,
                icon: Icons.segment_rounded,
                label: '${_sections.length} secciones',
              ),
              if (_images.isNotEmpty)
                _heroChip(
                  theme,
                  icon: Icons.photo_library_outlined,
                  label:
                      '${_images.where((img) => img.url.trim().isNotEmpty).length}/${_images.length} imagenes',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _isDark(theme)
            ? const Color(0xFF0B1624).withValues(alpha: 0.86)
            : theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
