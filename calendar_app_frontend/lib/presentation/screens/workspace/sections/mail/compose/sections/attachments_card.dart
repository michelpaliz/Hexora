part of '../../mail_compose_screen.dart';

Widget _composeAttachmentsCard(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: _CollapsedPanel(
        title: state._attachments.isEmpty
            ? l.mailComposeAttachmentsLabel
            : '${l.mailComposeAttachmentsLabel} (${state._attachments.length})',
        expanded: state._attachmentsExpanded,
        onToggle: () => state.update(
          () => state._attachmentsExpanded = !state._attachmentsExpanded,
        ),
        trailing: compact
            ? IconButton.filledTonal(
                tooltip: l.mailComposeAddAttachment,
                onPressed: state._sending || state._uploadingAttachment
                    ? null
                    : state._showAttachmentActions,
                icon: state._uploadingAttachment
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.attach_file_rounded),
              )
            : TextButton.icon(
                onPressed: state._sending || state._uploadingAttachment
                    ? null
                    : state._showAttachmentActions,
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurfaceVariant,
                  textStyle: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                icon: state._uploadingAttachment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file, size: 18),
                label: Text(l.mailComposeAddAttachment),
              ),
        child: state._attachments.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l.mailComposeAttachmentsEmpty,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state._attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attachment = entry.value;
                  final label =
                      attachment.filename ?? attachment.storageKey ?? '-';
                  return InputChip(
                    label: Text(label, style: t.bodySmall),
                    onDeleted: () =>
                        state.update(() => state._attachments.removeAt(index)),
                  );
                }).toList(),
              ),
      ),
    );
