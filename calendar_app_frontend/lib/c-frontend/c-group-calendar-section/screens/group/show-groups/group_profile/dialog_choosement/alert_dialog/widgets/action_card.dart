// lib/c-frontend/dialog_content/profile/widgets/action_card.dart
import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
    this.isCompact = false,
    this.iconOnly = false, // NEW
    this.semanticLabel, // NEW (a11y)
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isPrimary;
  final bool isCompact;
  final bool iconOnly; // NEW
  final String? semanticLabel; // NEW
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final borderColor = isPrimary ? color : color.withOpacity(0.3);
    final bgColor = isPrimary ? color : cs.surfaceContainerHighest;

    // Sizes tuned for compact icon-only tiles
    final double pad = isCompact ? 12 : 16;
    final double iconPad = isCompact ? 10 : 12;
    final double iconSize = isCompact ? 22 : 24;

    Widget leadingIcon = Container(
      padding: EdgeInsets.all(iconPad),
      decoration: BoxDecoration(
        color:
            isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: isPrimary ? cs.onPrimary : color,
        size: iconSize,
        semanticLabel: semanticLabel ?? (iconOnly ? title : null),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isPrimary ? 2 : 1),
          ),
          child: iconOnly
              // ICON-ONLY LAYOUT
              ? Center(child: leadingIcon)
              // DEFAULT LAYOUT
              : Row(
                  children: [
                    leadingIcon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isPrimary ? cs.onPrimary : cs.onSurface,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isPrimary
                                          ? cs.onPrimary.withOpacity(0.8)
                                          : cs.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isPrimary
                          ? cs.onPrimary.withOpacity(0.7)
                          : cs.onSurfaceVariant,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
