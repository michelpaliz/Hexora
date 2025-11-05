import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class RoundedSectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const RoundedSectionCard({
    Key? key,
    required this.child,
    this.title,
    this.backgroundColor, // Allows override, still respected
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Default to card surface; allow override. Slightly lighten if you prefer input-like feel.
    final Color bg = backgroundColor ?? ThemeColors.cardBg(context);
    final Color onBg = ThemeColors.textPrimary(context);

    return Container(
      margin:
          margin ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.cardShadow(context),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                title!,
                style: t.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onBg,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
