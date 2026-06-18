import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double markerHeight;
  final double markerWidth;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
    this.markerHeight = 24,
    this.markerWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final titleStyle = Theme.of(context).textTheme.titleLarge!;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: markerWidth,
            height: markerHeight,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: titleStyle.copyWith(
                fontWeight: FontWeight.w800,
                color: onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Align(
              alignment: Alignment.centerRight,
              child: trailing!,
            ),
          ],
        ],
      ),
    );
  }
}
