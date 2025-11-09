import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class SolidHeader extends StatelessWidget {
  /// Total header height.
  final double height;

  /// Optional override for the start color; defaults to theme.primary.
  final Color? startColor;

  /// Optional override for the end color; defaults to container background.
  final Color? endColor;

  const SolidHeader({
    Key? key,
    this.height = 160,
    this.startColor,
    this.endColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Use theme-aware colors with sensible fallbacks.
    final Color start = startColor ?? cs.primary;
    final Color end = endColor ?? ThemeColors.containerBg(context);

    return ClipPath(
      clipper: _BottomCurvedClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              start,
              Color.lerp(start, end, 0.35)!, // smooth middle blend
              end.withOpacity(0.85),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BottomCurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
