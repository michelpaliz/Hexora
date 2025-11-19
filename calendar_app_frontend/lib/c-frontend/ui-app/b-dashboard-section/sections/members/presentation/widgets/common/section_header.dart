// c-frontend/b-calendar-section/screens/group-screen/members/widgets/section_header.dart
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.textStyle,
    this.subtitleStyle,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 10),
    this.dividerSpacing = 8,
    this.dividerThickness = 1,
    this.dividerColor,
    this.showDivider = true,
    this.uppercase = false,
    this.dense = false,
  });

  /// Main title
  final String title;

  /// Optional tiny subtitle under the title (left-aligned)
  final String? subtitle;

  /// Styles (fallbacks to theme)
  final TextStyle? textStyle;
  final TextStyle? subtitleStyle;

  /// Optional leading/trailing widgets (icon, chip, action button, etc.)
  final Widget? leading;
  final Widget? trailing;

  /// Layout controls
  final EdgeInsets padding;
  final double dividerSpacing;
  final double dividerThickness;
  final Color? dividerColor;
  final bool showDivider;
  final bool uppercase;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final defaultTitle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: uppercase ? 0.3 : null,
    );
    final effectiveTitle = (textStyle ?? defaultTitle)!;

    final defaultSubtitle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );
    final effectiveSubtitle = subtitleStyle ?? defaultSubtitle;

    final lineColor = dividerColor ?? cs.onSurface.withOpacity(0.08);
    final titleText = uppercase ? title.toUpperCase() : title;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment:
                dense ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                Padding(
                  padding: EdgeInsets.only(right: dense ? 8 : 10),
                  child: leading!,
                ),
              ],
              // Title + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: effectiveTitle),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: effectiveSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: dense ? 8 : 10),
                trailing!,
              ],
            ],
          ),
          if (showDivider) ...[
            SizedBox(height: dividerSpacing),
            // Divider’s height param is the total widget height; thickness is the line.
            Divider(
                thickness: dividerThickness,
                height: dividerThickness,
                color: lineColor),
          ],
        ],
      ),
    );
  }
}
