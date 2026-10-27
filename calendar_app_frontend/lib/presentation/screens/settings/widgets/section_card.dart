import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final bool compact;
  const SectionCard({super.key, required this.child, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        child: child,
      ),
    );
  }
}
