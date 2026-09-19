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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
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
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
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
    required this.steps,
    required this.currentStep,
    required this.controller,
    required this.selectedClientName,
    required this.showBack,
    required this.backLabel,
    required this.onBack,
    required this.onStepTapped,
    required this.onClientTapped,
  });

  final List<String> steps;
  final int currentStep;
  final InvoiceEditorController controller;
  final String selectedClientName;
  final bool showBack;
  final String backLabel;
  final VoidCallback onBack;
  final ValueChanged<int> onStepTapped;
  final VoidCallback onClientTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    final stepper = _InvoiceFlowSteps(
      steps: steps,
      currentStep: currentStep,
      onStepTapped: onStepTapped,
    );
    final contextChips = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InvoiceDraftStatusChip(controller: controller, t: t, cs: cs),
        const SizedBox(width: 8),
        _InvoiceClientContextChip(
          clientName: selectedClientName,
          onTap: onClientTapped,
        ),
      ],
    );
    final backButton = OutlinedButton.icon(
      key: const Key('invoice-flow-back'),
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back_rounded, size: 18),
      label: Text(backLabel),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.outlineVariant),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackNavigation = constraints.maxWidth < 1120;
        final leading = showBack ? backButton : const SizedBox.shrink();

        return Container(
          key: const Key('invoice-flow-top-bar'),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: stackNavigation ? 12 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: stackNavigation
              ? Column(
                  children: [
                    Row(
                      children: [
                        leading,
                        const Spacer(),
                        contextChips,
                      ],
                    ),
                    const SizedBox(height: 10),
                    stepper,
                  ],
                )
              : Row(
                  children: [
                    leading,
                    if (showBack) const SizedBox(width: 16),
                    Expanded(child: stepper),
                    const SizedBox(width: 16),
                    contextChips,
                  ],
                ),
        );
      },
    );
  }
}

class _InvoiceFlowSteps extends StatelessWidget {
  const _InvoiceFlowSteps({
    required this.steps,
    required this.currentStep,
    required this.onStepTapped,
  });

  final List<String> steps;
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Row(
          children: [
            for (var index = 0; index < steps.length; index++) ...[
              if (index > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    color: index <= currentStep
                        ? cs.primary.withValues(alpha: 0.55)
                        : cs.outlineVariant.withValues(alpha: 0.65),
                  ),
                ),
              _InvoiceFlowStep(
                key: Key('invoice-flow-step-$index'),
                index: index,
                totalSteps: steps.length,
                label: steps[index],
                isCurrent: index == currentStep,
                isCompleted: index < currentStep,
                onTap: () => onStepTapped(index),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceFlowStep extends StatelessWidget {
  const _InvoiceFlowStep({
    super.key,
    required this.index,
    required this.totalSteps,
    required this.label,
    required this.isCurrent,
    required this.isCompleted,
    required this.onTap,
  });

  final int index;
  final int totalSteps;
  final String label;
  final bool isCurrent;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    final isSpanish = l.localeName.toLowerCase().startsWith('es');
    final foreground = isCurrent
        ? cs.primary
        : isCompleted
            ? cs.primary
            : cs.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: isSpanish
          ? 'Paso ${index + 1} de $totalSteps: $label'
          : 'Step ${index + 1} of $totalSteps: $label',
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: isCurrent
                  ? cs.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent
                    ? cs.primary.withValues(alpha: 0.28)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? cs.primary
                        : isCompleted
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent || isCompleted
                          ? cs.primary.withValues(alpha: 0.4)
                          : cs.outlineVariant,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(Icons.check_rounded, size: 14, color: cs.primary)
                      : Text(
                          '${index + 1}',
                          style: t.bodySmall.copyWith(
                            color: isCurrent ? cs.onPrimary : foreground,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
