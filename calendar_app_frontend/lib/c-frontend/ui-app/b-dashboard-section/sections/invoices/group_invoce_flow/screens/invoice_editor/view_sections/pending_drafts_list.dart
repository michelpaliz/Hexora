part of '../invoice_editor_screen.dart';

class _PendingDraftsList extends StatelessWidget {
  final List<Invoice> drafts;
  final List<GroupClient> clients;
  final bool deleting;
  final ValueChanged<Invoice> onPreview;
  final ValueChanged<Invoice> onDownload;
  final ValueChanged<Invoice> onEdit;
  final ValueChanged<Invoice> onDelete;

  const _PendingDraftsList({
    required this.drafts,
    required this.clients,
    required this.deleting,
    required this.onPreview,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final dateFmt = DateFormat.yMMMd();

    String clientName(String id) {
      return clients
          .firstWhere(
            (c) => c.id == id,
            orElse: () =>
                GroupClient(id: id, name: l.unknownClient, isActive: true),
          )
          .name;
    }

    String draftSubtitle(Invoice inv) {
      final date = inv.registeredAt ?? inv.issueDate;
      if (date == null) return clientName(inv.clientId);
      return '${clientName(inv.clientId)} • ${dateFmt.format(date)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.invoicePendingDraftsLabel,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final inv in drafts) ...[
            Row(
              children: [
                Icon(Icons.edit_note_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber.trim().isEmpty
                            ? l.statusDraft
                            : inv.invoiceNumber,
                        style: t.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        draftSubtitle(inv),
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.edit,
                  onPressed: () => onEdit(inv),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: l.download,
                  onPressed: () async {
                    final action = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(l.invoiceDraftPdfDialogTitle),
                        content: Text(l.invoiceDraftPdfDialogContent),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop('preview'),
                            child: Text(l.invoiceDraftPreviewInBrowser),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop('download'),
                            child: Text(l.invoiceDraftDownloadPdf),
                          ),
                        ],
                      ),
                    );
                    if (action == 'preview') {
                      onPreview(inv);
                    } else if (action == 'download') {
                      onDownload(inv);
                    }
                  },
                  icon: const Icon(Icons.download_outlined),
                ),
                IconButton(
                  tooltip: l.remove,
                  onPressed: deleting ? null : () => onDelete(inv),
                  icon: Icon(Icons.delete_outline, color: cs.error),
                ),
              ],
            ),
            if (inv != drafts.last)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
