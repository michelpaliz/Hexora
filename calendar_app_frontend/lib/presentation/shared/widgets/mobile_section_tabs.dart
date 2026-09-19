import 'package:flutter/material.dart';
import 'package:hexora/theme/colors/theme_colors.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// Bank-style section navigation, wrapping so every destination stays visible.
class MobileSectionTabs extends StatelessWidget {
  const MobileSectionTabs({
    super.key,
    required this.controller,
    required this.labels,
    this.scrollable = false,
  });

  final TabController controller;
  final List<String> labels;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    if (scrollable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: labels.map((label) => Tab(text: label, height: 48)).toList(),
        ),
      );
    }
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
