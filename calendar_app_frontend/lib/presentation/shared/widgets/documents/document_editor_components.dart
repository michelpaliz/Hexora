import 'package:flutter/material.dart';

/// Presentation-only step definition shared by document editors.
///
/// Domain validation and navigation remain owned by each editor.
class HexoraDocumentStep {
  const HexoraDocumentStep({
    required this.label,
    this.icon,
    this.enabled = true,
    this.hasError = false,
  });

  final String label;
  final IconData? icon;
  final bool enabled;
  final bool hasError;
}

class HexoraDocumentStepper extends StatelessWidget {
  const HexoraDocumentStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.onStepTapped,
    this.itemKeyBuilder,
    this.compactConnectors = false,
  });

  final List<HexoraDocumentStep> steps;
  final int currentStep;
  final ValueChanged<int> onStepTapped;
  final Key Function(int index, HexoraDocumentStep step)? itemKeyBuilder;
  final bool compactConnectors;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget stepItem(int index) {
      final step = steps[index];
      final active = index == currentStep;
      final complete = index < currentStep;
      final color = step.hasError
          ? cs.error
          : active || complete
              ? cs.primary
              : cs.onSurfaceVariant;
      return Semantics(
        button: true,
        selected: active,
        enabled: step.enabled,
        label: 'Paso ${index + 1} de ${steps.length}: ${step.label}',
        child: Tooltip(
          message: step.label,
          child: InkWell(
            key: itemKeyBuilder?.call(index, step) ??
                ValueKey('document-editor-step-$index'),
            onTap: step.enabled ? () => onStepTapped(index) : null,
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: .10) : null,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: active
                      ? color.withValues(alpha: .30)
                      : Colors.transparent,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? color
                        : complete
                            ? color.withValues(alpha: .14)
                            : cs.surfaceContainerHighest,
                    border: Border.all(color: color.withValues(alpha: .38)),
                  ),
                  child: complete
                      ? Icon(Icons.check_rounded, size: 14, color: color)
                      : step.hasError
                          ? Icon(Icons.priority_high_rounded,
                              size: 13, color: active ? cs.onError : color)
                          : step.icon != null && active
                              ? Icon(step.icon, size: 13, color: cs.onPrimary)
                              : Text(
                                  '${index + 1}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: active ? cs.onPrimary : color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                ),
                const SizedBox(width: 6),
                Text(
                  step.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    Widget connector(int index) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 2,
            constraints: const BoxConstraints(minWidth: 12, maxWidth: 72),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: index <= currentStep
                ? cs.primary.withValues(alpha: .52)
                : cs.outlineVariant.withValues(alpha: .62),
          ),
        );

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 620;
      final row = Row(mainAxisSize: MainAxisSize.min, children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            compactConnectors
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: index <= currentStep
                          ? cs.primary.withValues(alpha: .62)
                          : cs.onSurfaceVariant.withValues(alpha: .5),
                    ),
                  )
                : compact
                    ? SizedBox(
                        width: 22,
                        child: Divider(
                          color: index <= currentStep
                              ? cs.primary.withValues(alpha: .52)
                              : cs.outlineVariant,
                        ),
                      )
                    : connector(index),
          stepItem(index),
        ],
      ]);
      if (compact) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      }
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: row,
        ),
      );
    });
  }
}

/// Shared responsive two-column frame. It only arranges presentation widgets;
/// editor state, validation and persistence remain outside this component.
class HexoraDocumentEditorShell extends StatelessWidget {
  const HexoraDocumentEditorShell({
    super.key,
    required this.header,
    required this.content,
    this.secondary,
    this.footer,
    this.maxWidth = 1800,
    this.twoColumnBreakpoint = 1080,
  });

  final Widget header;
  final Widget content;
  final Widget? secondary;
  final Widget? footer;
  final double maxWidth;
  final double twoColumnBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              secondary != null && constraints.maxWidth >= twoColumnBreakpoint;
          final body = wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 7, child: content),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: secondary!),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      content,
                      if (secondary != null) ...[
                        const SizedBox(height: 14),
                        secondary!,
                      ],
                    ]);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(children: [
                header,
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: body,
                  ),
                ),
                if (footer != null) footer!,
              ]),
            ),
          );
        },
      );
}

/// Shared visual frame for document-editor sections.
class HexoraDocumentContentPanel extends StatelessWidget {
  const HexoraDocumentContentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: .45),
        ),
      ),
      child: child,
    );
  }
}

/// Shared compact heading used by document-editor steps and panels.
class HexoraDocumentSectionHeader extends StatelessWidget {
  const HexoraDocumentSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class HexoraDocumentFooter extends StatelessWidget {
  const HexoraDocumentFooter({
    super.key,
    this.status,
    this.back,
    required this.primary,
    this.secondaryActions = const [],
    this.compact = false,
    this.showStatusWhenNarrow = false,
  });

  final Widget? status;
  final Widget? back;
  final Widget primary;
  final List<Widget> secondaryActions;
  final bool compact;
  final bool showStatusWhenNarrow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: compact ? 0 : 5,
      shadowColor: cs.shadow.withValues(alpha: .12),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 50 : 58),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 5 : 8,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            final actions = <Widget>[
              if (back != null) back!,
              ...secondaryActions,
              primary,
            ];
            if (compact) {
              final actionRow = Row(children: [
                if (back != null) back!,
                const Spacer(),
                Flexible(child: primary),
              ]);
              if (!showStatusWhenNarrow || status == null) return actionRow;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  status!,
                  const SizedBox(height: 4),
                  actionRow,
                ],
              );
            }
            return Row(children: [
              if (status != null) Expanded(child: status!) else const Spacer(),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions[i],
              ],
            ]);
          }),
        ),
      ),
    );
  }
}
