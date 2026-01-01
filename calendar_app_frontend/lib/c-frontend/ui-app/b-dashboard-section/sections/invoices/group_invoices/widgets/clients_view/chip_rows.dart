import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label:',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected != null)
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 84),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in options)
                    FilterChip(
                      label: Text(o),
                      selected: selected == o,
                      onSelected: (_) => onToggle(o),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
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
