import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

/// Bank-style section navigation, wrapping so every destination stays visible.
class MobileSectionTabs extends StatelessWidget {
  const MobileSectionTabs({
    super.key,
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? labels.length : 2;
        final width = constraints.maxWidth / columns;
        return Material(
          color: ThemeColors.cardBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Wrap(
              children: [
                for (var i = 0; i < labels.length; i++)
                  SizedBox(
                    width: width,
                    child: Semantics(
                      selected: controller.index == i,
                      child: TextButton(
                        onPressed: () => controller.animateTo(i),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          foregroundColor: controller.index == i
                              ? ThemeColors.contrastOn(cs.primary)
                              : ThemeColors.textPrimary(context)
                                  .withValues(alpha: 0.7),
                          backgroundColor: controller.index == i
                              ? cs.primary
                              : Colors.transparent,
                          textStyle: t.bodySmall.copyWith(
                            fontWeight: controller.index == i
                                ? FontWeight.w700
                                : FontWeight.w600,
                            letterSpacing: .2,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(labels[i], textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
