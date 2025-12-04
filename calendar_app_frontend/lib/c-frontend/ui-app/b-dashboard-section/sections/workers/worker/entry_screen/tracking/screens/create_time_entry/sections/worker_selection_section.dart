import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class WorkerSelectionSection extends StatelessWidget {
  const WorkerSelectionSection({
    super.key,
    required this.workers,
    required this.selectedIds,
    required this.onSelectAll,
    required this.onClear,
    required this.onToggle,
  });

  final List<Worker> workers;
  final Set<String> selectedIds;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final void Function(String id, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.workersLabel,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: onSelectAll, child: Text(l.selectAll)),
            TextButton(onPressed: onClear, child: Text(l.clearSelection)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: workers.map((w) {
            final selected = selectedIds.contains(w.id);
            final fg =
                selected ? cs.onPrimary : ThemeColors.textPrimary(context);
            final bg =
                selected ? cs.primary : cs.surfaceVariant.withOpacity(0.65);
            return ChoiceChip(
              selected: selected,
              label: Text(
                w.displayName ?? w.id,
                style: t.bodySmall.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selectedColor: bg,
              backgroundColor: bg,
              onSelected: (val) => onToggle(w.id, val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
