import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class CtaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color onSurface;
  final AppTypography typo;
  final VoidCallback onPressed;

  const CtaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSurface,
    required this.typo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: onSurface),
              const SizedBox(width: 8),
              Text(
                title,
                style: typo.bodyMedium.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: typo.bodySmall.copyWith(
              color: onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(title),
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
