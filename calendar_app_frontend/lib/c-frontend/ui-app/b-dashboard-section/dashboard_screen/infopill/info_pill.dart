import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

/// Reusable InfoPill widget extracted from the dashboard header.
///
/// Usage:
/// InfoPill(
///   icon: Icons.group_outlined,
///   label: '42 members',
///   onTap: () {},
/// )
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Optional overrides
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.radius = 999,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = (backgroundColor ?? cs.surfaceVariant.withOpacity(0.6));
    final fg = (foregroundColor ?? cs.onSurface.withOpacity(0.8));
    final t = AppTypography.of(context);

    final pill = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodySmall.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: pill,
    );
  }
}
