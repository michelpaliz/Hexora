import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class LoadingList extends StatelessWidget {
  const LoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => _LoadingTile(
        bg: ThemeColors.listTileBg(context),
        barColor: cs.surfaceVariant.withOpacity(0.6),
        secondaryBarColor: cs.surfaceVariant.withOpacity(0.35),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  final Color bg;
  final Color barColor;
  final Color secondaryBarColor;

  const _LoadingTile({
    required this.bg,
    required this.barColor,
    required this.secondaryBarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: _ShimmerBar(
          width: 160,
          height: 14,
          color: barColor,
          highlight: secondaryBarColor,
          radius: 4,
        ),
      ),
    );
  }
}

class _ShimmerBar extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;
  final Color highlight;

  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.color,
    required this.highlight,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, t, child) {
        // simple pulse between color and highlight
        final blended =
            Color.lerp(color, highlight, (0.5 - (t - 0.5).abs()) * 2)!;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: blended,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}
