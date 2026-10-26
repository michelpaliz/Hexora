part of '../../mail_compose_screen.dart';

Widget _composeAttachmentsCard(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact}) =>
    Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          if (state._attachments.isEmpty)
            Expanded(
              child: Text(
                l.mailComposeAttachmentsLabel,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state._attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, index) {
                  final attachment = state._attachments[index];
                  final label =
                      attachment.filename ?? attachment.storageKey ?? '-';
                  return InputChip(
                    visualDensity: VisualDensity.compact,
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(fontSize: 11),
                      ),
                    ),
                    onDeleted: state._sending
                        ? null
                        : () => state.update(
                              () => state._attachments.removeAt(index),
                            ),
                  );
                },
              ),
            ),
          IconButton(
            tooltip: l.mailComposeAddAttachment,
            onPressed: state._sending || state._uploadingAttachment
                ? null
                : state._showAttachmentActions,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            padding: EdgeInsets.zero,
            icon: state._uploadingAttachment
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
