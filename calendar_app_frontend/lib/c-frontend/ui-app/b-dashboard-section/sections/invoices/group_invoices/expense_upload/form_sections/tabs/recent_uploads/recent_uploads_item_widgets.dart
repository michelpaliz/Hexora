part of '../recent_uploads_tab.dart';

class _StatusPill extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _StatusPill({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme cs;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 9, color: cs.onSurfaceVariant),
              const SizedBox(width: 2),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: t.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
