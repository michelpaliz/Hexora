import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class FolderSectionCard extends StatelessWidget {
  const FolderSectionCard({
    super.key,
    required this.label,
    required this.child,
    this.actions,
    this.leadingAction,
    this.leftTabOffset = 10,
    this.rightTabOffset = 10,
  });

  final String label;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leadingAction;
  final double leftTabOffset;
  final double rightTabOffset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final border = cs.outlineVariant.withValues(alpha: 0.35);
    final bg = cs.surface;
    final hasActions = actions != null && actions!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: child,
        ),
        Positioned(
          left: leftTabOffset,
          top: -8,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: leadingAction == null ? 8 : 4,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(6),
              ),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingAction != null) ...[
                  leadingAction!,
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: typography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasActions)
          Positioned(
            right: rightTabOffset,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(6),
                ),
                border: Border.all(color: border),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: actions!,
              ),
            ),
          ),
      ],
    );
  }
}
