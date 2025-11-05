import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class GradientHeader extends StatelessWidget {
  final double height;

  /// Optional overrides (defaults to theme.primary → container background).
  final Color? startColor;
  final Color? endColor;

  const GradientHeader({
    Key? key,
    this.height = 160,
    this.startColor,
    this.endColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = startColor ?? cs.primary;
    final end = endColor ?? ThemeColors.containerBg(context);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            start,
            Color.lerp(start, end, 0.35)!, // soft mid blend
            end.withOpacity(0.9),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}
