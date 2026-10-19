import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

/// Shared non-interactive status styling for document and directory rows.
class HexoraStatusBadge extends StatelessWidget {
  const HexoraStatusBadge(
      {super.key, required this.label, required this.color, this.leading});

  final String label;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: HexoraTableTokens.badgeHorizontalPadding,
          vertical: HexoraTableTokens.badgeVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(HexoraDimensions.radius),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: HexoraDimensions.space)
          ],
          Flexible(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: HexoraTypography.fontFamily,
                        fontSize: HexoraTypography.caption,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ))),
        ]),
      );
}
