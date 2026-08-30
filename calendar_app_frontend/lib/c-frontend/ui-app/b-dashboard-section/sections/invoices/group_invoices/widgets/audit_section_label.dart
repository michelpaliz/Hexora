import 'package:flutter/material.dart';

class AuditSectionLabel extends StatelessWidget {
  const AuditSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}
