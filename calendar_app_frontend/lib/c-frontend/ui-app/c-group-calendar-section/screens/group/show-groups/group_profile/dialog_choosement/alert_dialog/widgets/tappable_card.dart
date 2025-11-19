// lib/c-frontend/ui-app/shared/widgets/tappable_card.dart
import 'package:flutter/material.dart';

class TappableCard extends StatelessWidget {
  const TappableCard({
    super.key,
    required this.onTap,
    required this.child,
    this.isPrimary = false,
    this.padding = const EdgeInsets.all(12),
    this.radius = 12,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool isPrimary;
  final EdgeInsets padding;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg = isPrimary ? cs.primary : cs.surface;
    final Color border = isPrimary
        ? cs.primary.withOpacity(0.25)
        : cs.outlineVariant.withOpacity(0.35);

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: bg,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border, width: isPrimary ? 2 : 1),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: isPrimary ? cs.onPrimary : cs.onSurface),
              child: IconTheme.merge(
                data: IconThemeData(
                    color: isPrimary ? cs.onPrimary : cs.onSurfaceVariant),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
