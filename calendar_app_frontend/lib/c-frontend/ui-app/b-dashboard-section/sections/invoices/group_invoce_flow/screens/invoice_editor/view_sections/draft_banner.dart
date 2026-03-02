part of '../invoice_editor_screen.dart';

class _DraftBanner extends StatelessWidget {
  final Invoice draft;
  final bool previewing;
  final bool deleting;
  final VoidCallback onPreview;
  final VoidCallback onDelete;
  final bool showActions;
  final bool compact;

  const _DraftBanner({
    required this.draft,
    required this.previewing,
    required this.deleting,
    required this.onPreview,
    required this.onDelete,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final number = draft.invoiceNumber.trim().isEmpty
        ? l.statusDraft
        : '${l.statusDraft} • ${draft.invoiceNumber}';

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 999 : 12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note_outlined, color: cs.primary, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              number,
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (showActions) ...[
            IconButton(
              tooltip: l.invoicePreviewCta,
              onPressed: previewing ? null : onPreview,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: l.remove,
              onPressed: deleting ? null : onDelete,
              icon: Icon(Icons.delete_outline, color: cs.error),
            ),
          ],
        ],
      ),
    );
  }
}
