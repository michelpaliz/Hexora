import 'package:flutter/material.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
                '${l.workersLabel} (${selectedIds.length})',
                style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.localeName.startsWith('es')
                  ? 'Opciones de selección'
                  : 'Selection options',
              icon: const Icon(Icons.more_horiz_rounded, size: 18),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'all') onSelectAll();
                if (value == 'clear') onClear();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'all', child: Text(l.selectAll)),
                PopupMenuItem(value: 'clear', child: Text(l.clearSelection)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: workers.map((w) {
            final selected = selectedIds.contains(w.id);
            return FilterChip(
              selected: selected,
              showCheckmark: true,
              checkmarkColor: cs.primary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(
                w.displayName ?? w.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodySmall.copyWith(
                  color: selected ? cs.primary : cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              selectedColor: cs.primary.withValues(alpha: .09),
              backgroundColor: cs.surface,
              side: BorderSide(
                color: selected
                    ? cs.primary.withValues(alpha: .45)
                    : cs.outlineVariant.withValues(alpha: .55),
              ),
              onSelected: (val) => onToggle(w.id, val),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
