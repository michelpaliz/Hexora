import 'package:flutter/material.dart';

class BlueAuthHeader extends StatelessWidget {
  const BlueAuthHeader({super.key, this.height = 360});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        isComplex: true,
        painter: _BlueHeaderPainter(),
      ),
    );
  }
}

class _BlueHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ---- Header shape with a wavy bottom edge ----
    final headerPath = Path()
      ..moveTo(0, 0) // top-left
      ..lineTo(size.width, 0) // top-right
      ..lineTo(size.width, size.height * .72)
      // wave: three smooth segments across the bottom
      ..quadraticBezierTo(
        size.width * .82, size.height * .88, // control
        size.width * .66, size.height * .83, // end 1 (dip)
      )
      ..quadraticBezierTo(
        size.width * .45, size.height * .75, // control
        size.width * .33, size.height * .86, // end 2 (crest)
      )
      ..quadraticBezierTo(
        size.width * .12, size.height * .98, // control
        0, size.height * .86, // end 3 (dip)
      )
      ..close();

    // Clip everything to the header wave shape so it "occupies all sides"
    canvas.save();
    canvas.clipPath(headerPath, doAntiAlias: true);

    // ---- Base gradient (fills the clipped area) ----
    final base = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 14, 63, 81), // light blue
          Color(0xFF168AF0), // deeper blue
        ],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    // ---- Soft band across top for depth ----
    final band = Path()
      ..moveTo(0, size.height * 0.40)
      ..quadraticBezierTo(
          size.width * 0.40, size.height * 0.22, size.width, size.height * 0.30)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(band, Paint()..color = Colors.white.withOpacity(0.10));

    // ---- Right-side swoosh accent ----
    final swoosh = Path()
      ..moveTo(size.width * 0.58, 0)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.06,
          size.width * 0.88, size.height * 0.36)
      ..quadraticBezierTo(size.width * 0.70, size.height * 0.26,
          size.width * 0.52, size.height * 0.18)
      ..close();
    canvas.drawPath(swoosh, Paint()..color = Colors.black.withOpacity(0.06));

    // ---- Top-right translucent oval ----
    final oval = Rect.fromCircle(
      center: Offset(size.width * 0.94, size.height * 0.10),
      radius: size.width * 0.22,
    );
    canvas.drawOval(oval, Paint()..color = Colors.white.withOpacity(0.08));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
