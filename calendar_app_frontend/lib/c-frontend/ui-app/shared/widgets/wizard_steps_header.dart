import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class WizardStepsHeader extends StatelessWidget {
  final List<Step> steps;
  final int currentStep;
  final bool isWide;
  final VoidCallback? onStepContinue;
  final VoidCallback? onStepCancel;
  final ValueChanged<int>? onStepTapped;
  final double maxWidth;
  final double? height;

  const WizardStepsHeader({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.isWide,
    this.onStepContinue,
    this.onStepCancel,
    this.onStepTapped,
    this.maxWidth = 820,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (!isWide) {
      // Fallback to the built-in Stepper for narrow layouts
      final stepper = Theme(
        data: Theme.of(context).copyWith(
          canvasColor: cs.surface,
          shadowColor: Colors.transparent,
          colorScheme: cs.copyWith(surface: cs.surface),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: currentStep,
          connectorThickness: 2,
          stepIconHeight: 24,
          stepIconWidth: 24,
          stepIconBuilder: (index, state) {
            final isCurrent = currentStep == index;
            final isCompleted = currentStep > index;
            final color = isCurrent
                ? cs.onPrimary
                : (isCompleted ? cs.primary : cs.onSurfaceVariant);
            if (state == StepState.complete) {
              return Icon(Icons.check, color: color, size: 14);
            }
            return Text(
              '${index + 1}',
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: color,
              ),
            );
          },
          onStepContinue: onStepContinue,
          onStepCancel: onStepCancel,
          onStepTapped: onStepTapped,
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: steps,
        ),
      );
      return stepper;
    }

    // Compact horizontal step indicator
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 12,
                  child: Divider(
                    thickness: 1.5,
                    color: i <= currentStep
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
            _CompactStep(
              index: i,
              step: steps[i],
              isCurrent: i == currentStep,
              isCompleted: i < currentStep,
              onTap: onStepTapped != null ? () => onStepTapped!(i) : null,
            ),
          ],
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: body,
      ),
    );
  }
}

class _CompactStep extends StatelessWidget {
  final int index;
  final Step step;
  final bool isCurrent;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _CompactStep({
    required this.index,
    required this.step,
    required this.isCurrent,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final circleColor = isCurrent
        ? cs.primary
        : isCompleted
            ? cs.primary.withValues(alpha: 0.7)
            : cs.surfaceContainerHighest;
    final contentColor = isCurrent
        ? cs.onPrimary
        : isCompleted
            ? cs.onPrimary
            : cs.onSurfaceVariant;
    final labelColor = isCurrent
        ? cs.onSurface
        : isCompleted
            ? cs.primary
            : cs.onSurfaceVariant.withValues(alpha: 0.7);

    // Extract label text from the Step title widget
    String label = '';
    final title = step.title;
    if (title is Text) {
      label = title.data ?? '';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? Icon(Icons.check, size: 12, color: contentColor)
                  : Text(
                      '${index + 1}',
                      style: t.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: contentColor,
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: t.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
