import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';

class CurvedHeader extends StatelessWidget {
  final double height;

  /// Optional overrides if you want a custom accent for a specific screen.
  final Color? startColor; // defaults to theme.primary
  final Color? endColor; // defaults to container background

  const CurvedHeader({
    Key? key,
    this.height = 180,
    this.startColor,
    this.endColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = startColor ?? cs.primary;
    final end = endColor ?? ThemeColors.containerBg(context);

    return ClipPath(
      clipper: _CurvedTopClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              start,
              Color.lerp(start, end, 0.35)!,
              end.withOpacity(0.9),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class _CurvedTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.75,
    );
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
