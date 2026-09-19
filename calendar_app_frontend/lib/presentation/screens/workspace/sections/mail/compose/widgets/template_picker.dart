part of '../../mail_compose_screen.dart';

class _ComposeTemplatePicker extends StatelessWidget {
  const _ComposeTemplatePicker({
    required this.templates,
    required this.selectedId,
    required this.onSelect,
    this.onClear,
  });

  final List<Map<String, dynamic>> templates;
  final String? selectedId;
  final void Function(Map<String, dynamic>) onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccionar plantilla',
                    style: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (onClear != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.remove_circle_outline, size: 14),
                    label: const Text('Quitar'),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.error,
                      textStyle: t.bodySmall.copyWith(fontSize: 12),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // ── Template list ────────────────────────────────────────────────
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final tpl = templates[index];
                final id = (tpl['id'] ?? tpl['_id'])?.toString().trim() ?? '';
                final name = (tpl['name'] ?? '').toString().trim();
                final subject = (tpl['subject'] ?? '').toString().trim();
                final preview = (tpl['text'] ?? '').toString().trim();
                final isSelected = id == selectedId;
                final isDefault = tpl['isDefault'] == true;

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(tpl),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer.withValues(alpha: 0.45)
                          : cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.6)
                            : cs.outlineVariant.withValues(alpha: 0.45),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.description_outlined,
                            size: 18,
                            color:
                                isSelected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name.isEmpty ? 'Template' : name,
                                      style: t.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (isDefault)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            cs.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: t.bodySmall.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (subject.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subject,
                                  style: t.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (preview.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  preview,
                                  style: t.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
