import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/documents/document_wizard_navigation.dart';

/// Navigation only: validation and draft ownership remain with the expense form.
class ExpenseCreationStepper extends StatelessWidget {
  const ExpenseCreationStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.collapsed,
    required this.forcedCollapsed,
    required this.canSelect,
    required this.isComplete,
    required this.onSelected,
    required this.onToggle,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final List<DocumentWizardStep> steps;
  final int currentStep;
  final bool collapsed;
  final bool forcedCollapsed;
  final bool Function(int) canSelect;
  final bool Function(int) isComplete;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggle;
  final String selectedSection;
  final ValueChanged<String> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final compact = collapsed || forcedCollapsed;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return AnimatedContainer(
      key: const Key('expense-stepper'),
      duration: duration,
      width: compact ? 56 : 216,
      color: theme.scaffoldBackgroundColor,
      // Keep expanded contents at their final width during the animation.
      child: ClipRect(
          child: OverflowBox(
        alignment: AlignmentDirectional.topStart,
        minWidth: compact ? 56 : 216,
        maxWidth: compact ? 56 : 216,
        child: Column(children: [
          SizedBox(
              height: 48,
              child: Row(children: [
                if (!compact)
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 12),
                    child: Text(es ? 'Nuevo gasto' : 'New expense',
                        style: theme.textTheme.titleSmall),
                  )),
                if (compact) const Spacer(),
                IconButton(
                  key: const Key('expense-stepper-toggle'),
                  tooltip: forcedCollapsed
                      ? (es
                          ? 'Amplía el espacio para expandir los pasos'
                          : 'Widen the workspace to expand steps')
                      : compact
                          ? (es ? 'Expandir pasos' : 'Expand steps')
                          : (es ? 'Contraer pasos' : 'Collapse steps'),
                  onPressed: forcedCollapsed ? null : onToggle,
                  icon:
                      Icon(compact ? Icons.chevron_right : Icons.chevron_left),
                ),
                if (compact) const Spacer(),
              ])),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                      es
                          ? 'Paso ${currentStep + 1} de ${steps.length}'
                          : 'Step ${currentStep + 1} of ${steps.length}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant))),
            ),
          Expanded(
              child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final active = index == currentStep;
              final complete = isComplete(index);
              final enabled = canSelect(index);
              final status = active
                  ? (es ? 'Paso actual' : 'Current step')
                  : complete
                      ? (es ? 'Completado' : 'Completed')
                      : enabled
                          ? (es ? 'Disponible' : 'Available')
                          : (es
                              ? 'Completa el paso anterior para continuar'
                              : 'Complete the previous step to continue');
              final color = active ? cs.primary : cs.onSurfaceVariant;
              return Column(children: [
                Tooltip(
                    message: '${step.label} · $status',
                    child: Semantics(
                      selected: active,
                      enabled: enabled,
                      button: true,
                      child: Material(
                        color: active
                            ? cs.primary.withValues(alpha: .09)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          key: Key('expense-stepper-step-$index'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: enabled ? () => onSelected(index) : null,
                          child: SizedBox(
                              height: 44,
                              child: Row(children: [
                                SizedBox(
                                    width: 48,
                                    child: Center(
                                        child: compact
                                            ? Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                    Icon(
                                                        complete && !active
                                                            ? Icons
                                                                .check_rounded
                                                            : step.icon,
                                                        size: 20,
                                                        color: color),
                                                    if (!enabled)
                                                      Positioned(
                                                          right: -6,
                                                          bottom: -5,
                                                          child: Icon(
                                                              Icons
                                                                  .lock_outline,
                                                              size: 12,
                                                              color: cs
                                                                  .onSurfaceVariant)),
                                                  ])
                                            : Container(
                                                width: 26,
                                                height: 26,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: active
                                                        ? cs.primary
                                                        : cs.primary.withValues(
                                                            alpha: .07),
                                                    border: active
                                                        ? null
                                                        : Border.all(
                                                            color: cs
                                                                .outlineVariant)),
                                                child: complete && !active
                                                    ? Icon(Icons.check_rounded,
                                                        size: 16,
                                                        color: cs.primary)
                                                    : Text('${index + 1}',
                                                        style: theme.textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                                color: active
                                                                    ? cs.onPrimary
                                                                    : color)),
                                              ))),
                                if (!compact) ...[
                                  Expanded(
                                      child: Text(step.label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  color: color,
                                                  fontWeight: active
                                                      ? FontWeight.w600
                                                      : FontWeight.w400))),
                                  if (!enabled)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Icon(Icons.lock_outline,
                                            size: 14,
                                            color: cs.onSurfaceVariant)),
                                ],
                              ])),
                        ),
                      ),
                    )),
                if (active && enabled && step.sections.isNotEmpty)
                  if (compact)
                    PopupMenuButton<String>(
                      tooltip: es ? 'Secciones de datos' : 'Detail sections',
                      icon: const Icon(Icons.more_horiz, size: 18),
                      onSelected: onSectionSelected,
                      itemBuilder: (_) => [
                        for (final section in step.sections)
                          CheckedPopupMenuItem(
                              value: section.id,
                              checked: section.id == selectedSection,
                              child: Text(section.label))
                      ],
                    )
                  else
                    for (final section in step.sections)
                      Padding(
                          padding: const EdgeInsetsDirectional.only(start: 48),
                          child: ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              selected: selectedSection == section.id,
                              title: Text(section.label,
                                  style: theme.textTheme.bodySmall),
                              onTap: () => onSectionSelected(section.id))),
                if (!compact && index < steps.length - 1)
                  Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                          margin: const EdgeInsetsDirectional.only(start: 23),
                          width: 1,
                          height: 12,
                          color: cs.outlineVariant)),
              ]);
            },
          )),
        ]),
      )),
    );
  }
}
