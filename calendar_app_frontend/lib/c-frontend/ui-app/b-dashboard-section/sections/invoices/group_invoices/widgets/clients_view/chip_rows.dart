import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class FilterChipRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  const FilterChipRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final isActive = selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isActive ? cs.primary : cs.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: t.bodySmall.copyWith(
                  color: isActive ? cs.onSurface : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (isActive)
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close_rounded,
                          size: 10, color: cs.error),
                      const SizedBox(width: 3),
                      Text(
                        l.clientFiltersClear,
                        style: t.caption.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in options)
              _PillChip(
                label: o,
                selected: selected == o,
                onTap: () => selected == o ? onClear() : onToggle(o),
              ),
          ],
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: t.bodySmall.copyWith(
            color: selected ? cs.onPrimary : cs.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class AssignChipRow extends StatelessWidget {
  final String label;
  final String current;
  final List<String> options;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onClear;

  const AssignChipRow({
    super.key,
    required this.label,
    required this.current,
    required this.options,
    required this.busy,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final trimmed = current.trim();
    final hasCurrent = trimmed.isNotEmpty;
    final displayOptions = [
      if (hasCurrent && !options.contains(trimmed)) trimmed,
      ...options,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: t.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 84),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in displayOptions)
                          FilterChip(
                            label: Text(o),
                            selected: hasCurrent && trimmed == o,
                            onSelected: busy
                                ? null
                                : (selected) {
                                    if (selected) {
                                      onSelect(o);
                                    } else {
                                      onClear();
                                    }
                                  },
                            visualDensity: VisualDensity.compact,
                            showCheckmark: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
