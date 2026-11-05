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
                final previewColumn = <Widget>[_buildLivePreviewCard()];
                final leftPane = ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildHero(theme),
                    const SizedBox(height: 4),
                    _buildStepSelector(steps, activeStep),
                    if (steps.isNotEmpty) ...steps[activeStep].children,
                    if (!wide) ...previewColumn,
                  ],
                );
                final workspace = wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: leftPane),
                          VerticalDivider(
                            width: 21,
                            thickness: 1,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.55),
                          ),
                          Expanded(
                            flex: 6,
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
                        wide ? 20 : 12,
                        wide ? 10 : 8,
                        wide ? 20 : 12,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: steps[activeStep].subtitle,
        child: _buildStepper(theme, steps, activeStep),
      ),
    );
  }

  Widget _buildStepper(
    ThemeData theme,
    List<_EditorStep> steps,
    int activeStep,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            Semantics(
              button: true,
              selected: i == activeStep,
              enabled: !(_mustSelectDefaultTemplate && i > 0),
              child: InkWell(
                key: ValueKey('editor_step_${steps[i].title}'),
                onTap: _mustSelectDefaultTemplate && i > 0
                    ? null
                    : () => _updateEditorState(() => _activeStep = i),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == activeStep
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    steps[i].title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: i == activeStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: _mustSelectDefaultTemplate && i > 0
                                  ? 0.45
                                  : 1,
                            ),
                      fontWeight:
                          i == activeStep ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
    final footerText = isLastStep
        ? (widget.templateOnly ? 'Lista para guardar' : 'Borrador listo')
        : 'Cambios sin guardar';
    final info = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_done_outlined,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
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
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
      compact: true,
    );
  }

  Widget _buildHero(ThemeData theme) {
    final title = widget.templateOnly ? 'Plantilla PDF' : 'Presupuesto PDF';
    final selectedTemplateName = _selectedTemplateName;
    return Row(
      children: [
        Icon(
          widget.templateOnly
              ? Icons.auto_awesome_motion_outlined
              : Icons.description_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        if (selectedTemplateName != null)
          Flexible(
            child: _heroChip(
              theme,
              icon: Icons.account_tree_outlined,
              label: selectedTemplateName,
            ),
          ),
        const Spacer(),
        Text(
          '${_sections.length} secciones',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            '${_images.where((image) => image.url.trim().isNotEmpty).length}/${_images.length} imagenes',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _heroChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
