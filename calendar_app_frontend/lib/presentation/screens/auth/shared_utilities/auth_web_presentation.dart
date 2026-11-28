import 'package:flutter/material.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';

class AuthWebIntroduction extends StatelessWidget {
  const AuthWebIntroduction({super.key, required this.news});
  final Widget news;

  @override
  Widget build(BuildContext context) {
    final es = Localizations.localeOf(context).languageCode == 'es';
    final cs = Theme.of(context).colorScheme;
    final features = [
      (Icons.description_outlined, es ? 'Facturación' : 'Invoicing'),
      (Icons.event_available_outlined, es ? 'Planificación' : 'Planning'),
      (Icons.people_outline_rounded, es ? 'Equipos' : 'Teams'),
      (Icons.bar_chart_rounded, es ? 'Informes' : 'Reports'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HexoraSurfaceWordmark(),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
                es
                    ? 'GESTIÓN EMPRESARIAL TODO EN UNO'
                    : 'ALL-IN-ONE BUSINESS MANAGEMENT',
                style: TextStyle(
                    color: cs.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          Text(
              es
                  ? 'Gestiona tu negocio\nde forma más inteligente'
                  : 'A smarter way\nto manage your business',
              style: TextStyle(
                  fontSize: 34,
                  height: 1.2,
                  letterSpacing: -.9,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 16),
          Text(
              es
                  ? 'Facturación, equipos, gastos, planificación y mucho más en una sola plataforma.'
                  : 'Invoicing, teams, expenses, planning and more in one platform.',
              style: TextStyle(
                  fontSize: 16, height: 1.5, color: cs.onSurfaceVariant)),
          const SizedBox(height: 26),
          Row(children: [
            for (var i = 0; i < features.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.primary.withValues(alpha: .09)),
                ),
                child: Column(children: [
                  Icon(features[i].$1, color: cs.primary, size: 28),
                  const SizedBox(height: 10),
                  Text(features[i].$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: cs.onSurface)),
                ]),
              )),
            ],
          ]),
          const SizedBox(height: 32),
          news,
        ],
      ),
    );
  }
}

class AuthWebBackdrop extends CustomPainter {
  const AuthWebBackdrop({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF86B7FF).withValues(alpha: dark ? .06 : .14);
    final top = Path()
      ..moveTo(0, size.height * .2)
      ..quadraticBezierTo(
          size.width * .16, size.height * .06, size.width * .32, 0)
      ..lineTo(size.width * .18, 0)
      ..quadraticBezierTo(
          size.width * .08, size.height * .09, 0, size.height * .14)
      ..close();
    canvas.drawPath(top, paint);
    final bottom = Path()
      ..moveTo(size.width * .55, size.height)
      ..quadraticBezierTo(
          size.width * .86, size.height * .96, size.width, size.height * .62)
      ..lineTo(size.width, size.height * .76)
      ..quadraticBezierTo(
          size.width * .9, size.height * .98, size.width * .72, size.height)
      ..close();
    canvas.drawPath(bottom, paint);
  }

  @override
  bool shouldRepaint(AuthWebBackdrop oldDelegate) => oldDelegate.dark != dark;
}
