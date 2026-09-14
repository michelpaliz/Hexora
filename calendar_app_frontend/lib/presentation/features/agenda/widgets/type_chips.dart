import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';

/// Modern pill-style type filter chips.
/// Accepts 'all' | 'simple' | 'work_service' (UI) | 'work_visit' (backend/deeplink)
class TypeChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TypeChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final v = value.toLowerCase();
    final isWork = v == 'work_service' || v == 'work_visit';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TypePill(
            icon: Icons.apps_rounded,
            label: loc?.allTypes ?? 'All',
            selected: v == 'all',
            onTap: () => onChanged('all'),
          ),
          const SizedBox(width: 6),
          _TypePill(
            icon: Icons.event_note_outlined,
            label: loc?.simpleEvents ?? 'Simple',
            selected: v == 'simple',
            onTap: () => onChanged('simple'),
          ),
          const SizedBox(width: 6),
          _TypePill(
            icon: Icons.build_circle_outlined,
            label: loc?.workVisits ?? 'Work',
            selected: isWork,
            onTap: () => onChanged('work_service'),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : icon,
              size: 14,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? cs.onPrimaryContainer
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
