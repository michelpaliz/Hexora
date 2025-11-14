// c-frontend/b-calendar-section/screens/group-screen/members/widgets/section_header.dart
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final TextStyle? textStyle;
  final double dividerSpacing;
  final double dividerHeight;
  final double dividerThickness;
  final Color? dividerColor;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.textStyle,
    this.dividerSpacing = 8,
    this.dividerHeight = 1,
    this.dividerThickness = 1,
    this.dividerColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final defaultTextStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    final effectiveTextStyle = textStyle ?? defaultTextStyle;
    final effectiveDividerColor =
        dividerColor ?? colors.onSurface.withOpacity(0.08);

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          title,
          style: effectiveTextStyle,
        ),
        if (showDivider) ...[
          SizedBox(width: dividerSpacing),
          Expanded(
            child: Divider(
              height: dividerHeight,
              thickness: dividerThickness,
              color: effectiveDividerColor,
            ),
          ),
        ],
      ],
    );
  }
}
