import 'package:flutter/material.dart';

enum HexoraEmptyStateVariant { standard, compact }

@immutable
class HexoraEmptyStateAction {
  const HexoraEmptyStateAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
}

/// Shared presentation for an intentional absence of data.
///
/// Loading, error and permission states should use their dedicated widgets.
/// This component is only for successfully loaded content that is empty.
class HexoraEmptyState extends StatelessWidget {
  const HexoraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.primaryAction,
    this.secondaryAction,
    this.variant = HexoraEmptyStateVariant.standard,
    this.maxDescriptionWidth = 440,
  });

  final IconData icon;
  final String title;
  final String description;
  final HexoraEmptyStateAction? primaryAction;
  final HexoraEmptyStateAction? secondaryAction;
  final HexoraEmptyStateVariant variant;
  final double maxDescriptionWidth;

  @override
  Widget build(BuildContext context) {
    final compact = variant == HexoraEmptyStateVariant.compact;
    final content = _EmptyStateContent(
      icon: icon,
      title: title,
      description: description,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      compact: compact,
      maxDescriptionWidth: maxDescriptionWidth,
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final child = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: content,
        );
        if (!constraints.hasBoundedHeight) return child;
        return SizedBox(
          height: constraints.maxHeight,
          child: Align(
            alignment: const Alignment(0, -0.28),
            child: child,
          ),
        );
      },
    );
  }
}

class _EmptyStateContent extends StatelessWidget {
  const _EmptyStateContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.secondaryAction,
    required this.compact,
    required this.maxDescriptionWidth,
  });

  final IconData icon;
  final String title;
  final String description;
  final HexoraEmptyStateAction? primaryAction;
  final HexoraEmptyStateAction? secondaryAction;
  final bool compact;
  final double maxDescriptionWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconSize = compact ? 19.0 : 22.0;
    final iconContainerSize = compact ? 38.0 : 46.0;

    return Semantics(
      container: true,
      label: '$title. $description',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.alphaBlend(
                cs.primary.withValues(alpha: 0.11),
                cs.surface,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: cs.primary),
          ),
          SizedBox(height: compact ? 9 : 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (compact
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: compact ? 4 : 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDescriptionWidth),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          if (primaryAction != null || secondaryAction != null) ...[
            SizedBox(height: compact ? 12 : 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (primaryAction case final action?)
                  FilledButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon ?? Icons.add_rounded, size: 18),
                    label: Text(action.label),
                  ),
                if (secondaryAction case final action?)
                  TextButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon ?? Icons.arrow_forward_rounded,
                        size: 18),
                    label: Text(action.label),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
