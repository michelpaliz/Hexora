part of '../invoice_editor_screen.dart';

class _InvoiceDraftStatusChip extends StatelessWidget {
  const _InvoiceDraftStatusChip({
    required this.controller,
    required this.t,
    required this.cs,
  });

  final InvoiceEditorController controller;
  final AppTypography t;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final hasDraft = controller.savedInvoice != null ||
        (controller.editingDraftId ?? '').trim().isNotEmpty;
    final text = controller.draftSaveFailed
        ? (isEs ? 'No se pudo guardar' : 'Save failed')
        : controller.saving
            ? (isEs ? 'Guardando...' : 'Saving...')
            : controller.draftDirty
                ? (isEs ? 'Cambios sin guardar' : 'Unsaved changes')
                : hasDraft
                    ? (isEs ? 'Borrador guardado' : 'Draft saved')
                    : (isEs ? 'Sin guardar' : 'Not saved');
    final icon = controller.draftSaveFailed
        ? Icons.cloud_off_outlined
        : controller.saving
            ? Icons.sync_rounded
            : controller.draftDirty
                ? Icons.edit_note_rounded
                : hasDraft
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_queue_outlined;
    final color = controller.draftSaveFailed
        ? cs.error
        : controller.saving || controller.draftDirty
            ? cs.tertiary
            : hasDraft
                ? cs.primary
                : cs.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      label: text,
      child: AnimatedContainer(
        key: const Key('invoice-draft-status'),
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.saving)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceFlowTopBar extends StatelessWidget {
  const _InvoiceFlowTopBar({
    required this.selectedClientName,
    required this.showBack,
    required this.backLabel,
    required this.onBack,
    required this.onClientTapped,
  });

  final String selectedClientName;
  final bool showBack;
  final String backLabel;
  final VoidCallback onBack;
  final VoidCallback onClientTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final contextChips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InvoiceClientContextChip(
          clientName: selectedClientName,
          onTap: onClientTapped,
        ),
      ],
    );
    final backButton = HexoraButton(
      key: const Key('invoice-flow-back'),
      onPressed: onBack,
      icon: Icons.arrow_back_rounded,
      label: backLabel,
      variant: HexoraButtonVariant.secondary,
    );

    return Container(
      key: const Key('invoice-flow-top-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      color: cs.surface,
      child: Row(
        children: [
          if (showBack) backButton,
          const Spacer(),
          contextChips,
        ],
      ),
    );
  }
}

class _InvoiceWizardRail extends StatelessWidget {
  const _InvoiceWizardRail({
    required this.steps,
    required this.currentStep,
    required this.lineMode,
    required this.linesExpanded,
    required this.collapsed,
    required this.onStepTapped,
    required this.onLineModeSelected,
    required this.onToggleLines,
    required this.onToggleCollapsed,
  });

  final List<String> steps;
  final int currentStep;
  final String lineMode;
  final bool linesExpanded;
  final bool collapsed;
  final ValueChanged<int> onStepTapped;
  final ValueChanged<String> onLineModeSelected;
  final VoidCallback onToggleLines;
  final VoidCallback onToggleCollapsed;

  static const _stepIcons = [
    Icons.person_outline_rounded,
    Icons.calendar_today_outlined,
    Icons.receipt_long_outlined,
    Icons.preview_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final modes = [
      ('manual', 'Manual', Icons.edit_note_outlined),
      ('photo', isEs ? 'Foto e IA' : 'Photo & AI', Icons.auto_awesome_outlined),
      ('json', 'JSON', Icons.data_object_rounded),
    ];

    Widget mainStep(int index) {
      final active = currentStep == index;
      final complete = index < currentStep;
      final future = index > currentStep;
      final color = active || complete ? cs.primary : cs.onSurfaceVariant;
      final row = Semantics(
        button: true,
        selected: active,
        label: '${index + 1}. ${steps[index]}',
        child: InkWell(
          key: Key('invoice-flow-step-$index'),
          onTap: () => onStepTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 36,
            padding: EdgeInsets.only(
              left: collapsed ? 13 : 10,
              right: collapsed ? 13 : 4,
            ),
            decoration: BoxDecoration(
              color: active ? cs.primary.withValues(alpha: .09) : null,
              border: Border(
                left: BorderSide(
                  width: 2,
                  color: active ? cs.primary : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  complete ? Icons.check_rounded : _stepIcons[index],
                  size: 16,
                  color: future ? color.withValues(alpha: .52) : color,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: future ? color.withValues(alpha: .62) : color,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (index == 2)
                    IconButton(
                      tooltip: linesExpanded
                          ? (isEs ? 'Contraer métodos' : 'Collapse methods')
                          : (isEs ? 'Mostrar métodos' : 'Show methods'),
                      onPressed: onToggleLines,
                      icon: Icon(
                        linesExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 17,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );

      if (!collapsed || index != 2) return row;
      return MenuAnchor(
        alignmentOffset: const Offset(48, -36),
        menuChildren: [
          for (final mode in modes)
            MenuItemButton(
              key: Key('invoice-collapsed-line-mode-${mode.$1}'),
              onPressed: () => onLineModeSelected(mode.$1),
              child: SizedBox(
                width: 132,
                child: Row(
                  children: [
                    Icon(mode.$3, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(mode.$2)),
                    if (mode.$1 == lineMode)
                      Icon(Icons.check_rounded, size: 16, color: cs.primary),
                  ],
                ),
              ),
            ),
        ],
        builder: (context, controller, child) => Tooltip(
          message: isEs ? 'Método de líneas' : 'Line input method',
          child: InkWell(
            onTap: () {
              controller.isOpen ? controller.close() : controller.open();
            },
            child: AbsorbPointer(child: row),
          ),
        ),
      );
    }

    return AnimatedContainer(
      key: const Key('invoice-wizard-rail'),
      duration: const Duration(milliseconds: 180),
      width: collapsed ? 52 : 184,
      color: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: collapsed ? Alignment.center : Alignment.centerRight,
            child: IconButton(
              key: const Key('invoice-wizard-rail-toggle'),
              tooltip: collapsed
                  ? (isEs ? 'Expandir navegación' : 'Expand navigation')
                  : (isEs ? 'Contraer navegación' : 'Collapse navigation'),
              onPressed: onToggleCollapsed,
              icon: Icon(
                collapsed
                    ? Icons.keyboard_double_arrow_right_rounded
                    : Icons.keyboard_double_arrow_left_rounded,
                size: 17,
              ),
              constraints: const BoxConstraints.tightFor(
                width: 34,
                height: 32,
              ),
            ),
          ),
          for (var index = 0; index < steps.length; index++) ...[
            mainStep(index),
            if (index == 2 && !collapsed && linesExpanded)
              for (final mode in modes)
                Semantics(
                  button: true,
                  selected: currentStep == 2 && lineMode == mode.$1,
                  child: InkWell(
                    key: Key('invoice-line-mode-${mode.$1}'),
                    onTap: () => onLineModeSelected(mode.$1),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.only(left: 36, right: 10),
                      decoration: BoxDecoration(
                        color: currentStep == 2 && lineMode == mode.$1
                            ? cs.primary.withValues(alpha: .07)
                            : null,
                        border: Border(
                          left: BorderSide(
                            width: 2,
                            color: currentStep == 2 && lineMode == mode.$1
                                ? cs.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mode.$3,
                            size: 14,
                            color: currentStep == 2 && lineMode == mode.$1
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              mode.$2,
                              style: t.bodySmall.copyWith(
                                fontSize: 10.5,
                                color: currentStep == 2 && lineMode == mode.$1
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                                fontWeight:
                                    currentStep == 2 && lineMode == mode.$1
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceWizardMobileSelector extends StatelessWidget {
  const _InvoiceWizardMobileSelector({
    required this.steps,
    required this.currentStep,
    required this.lineMode,
    required this.onStepTapped,
    required this.onLineModeSelected,
  });

  final List<String> steps;
  final int currentStep;
  final String lineMode;
  final ValueChanged<int> onStepTapped;
  final ValueChanged<String> onLineModeSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final modeLabels = {
      'manual': 'Manual',
      'photo': isEs ? 'Foto e IA' : 'Photo & AI',
      'json': 'JSON',
    };
    final label = currentStep == 2
        ? '${steps[2]} · ${modeLabels[lineMode]}'
        : steps[currentStep];

    return PopupMenuButton<String>(
      key: const Key('invoice-wizard-mobile-selector'),
      tooltip: isEs ? 'Cambiar paso' : 'Change step',
      onSelected: (value) {
        if (value.startsWith('step:')) {
          onStepTapped(int.parse(value.substring(5)));
        } else if (value.startsWith('mode:')) {
          onLineModeSelected(value.substring(5));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'step:0', child: Text(steps[0])),
        PopupMenuItem(value: 'step:1', child: Text(steps[1])),
        PopupMenuItem(value: 'step:2', child: Text(steps[2])),
        for (final entry in modeLabels.entries)
          PopupMenuItem(
            value: 'mode:${entry.key}',
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Expanded(child: Text(entry.value)),
                  if (currentStep == 2 && lineMode == entry.key)
                    Icon(Icons.check_rounded, size: 16, color: cs.primary),
                ],
              ),
            ),
          ),
        PopupMenuItem(value: 'step:3', child: Text(steps[3])),
      ],
      child: Container(
        height: 38,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _InvoiceClientContextChip extends StatelessWidget {
  const _InvoiceClientContextChip({
    required this.clientName,
    required this.onTap,
  });

  final String clientName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isSpanish = l.localeName.toLowerCase().startsWith('es');

    return Tooltip(
      message: isSpanish ? 'Cambiar cliente' : 'Change customer',
      child: InkWell(
        key: const Key('invoice-client-context'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
