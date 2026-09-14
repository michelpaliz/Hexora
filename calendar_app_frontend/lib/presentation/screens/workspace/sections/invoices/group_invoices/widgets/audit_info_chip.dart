import 'package:flutter/material.dart';

class AuditInfoChip extends StatelessWidget {
  const AuditInfoChip({
    super.key,
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(fontSize: 11, color: colors.onSurface)),
        ],
      ),
    );
  }
}
