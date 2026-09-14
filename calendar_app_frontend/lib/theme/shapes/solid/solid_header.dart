import 'package:flutter/material.dart';

class SolidHeader extends StatelessWidget {
  final double height;

  /// Optional override; defaults to theme.primary.
  final Color? color;

  const SolidHeader({
    Key? key,
    this.height = 160,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color baseColor = color ?? Theme.of(context).colorScheme.primary;

    return ClipPath(
      clipper: _BottomCurvedClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        color: baseColor, // solid color
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
