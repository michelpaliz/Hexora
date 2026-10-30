part of '../../mail_compose_screen.dart';

Widget _composeAttachmentsCard(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact}) =>
    Builder(builder: (context) {
      final generatedNames = state._generatedDocumentDisplayNames;
      final attachmentCount = generatedNames.length + state._attachments.length;
      return Container(
        key: const ValueKey('mail-compose-attached-document-summary'),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .45)),
        ),
        child: Row(
          children: [
            if (compact) ...[
              Icon(Icons.attach_file_rounded,
                  size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
            ] else ...[
              SizedBox(
                width: 42,
                child: Text(
                  l.mailComposeAttachmentsLabel,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: cs.outlineVariant.withValues(alpha: .5),
              ),
            ],
            if (attachmentCount == 0)
              Expanded(
                child: Text(
                  compact
                      ? (state._isSpanishLocale
                          ? 'Sin adjuntos'
                          : 'No attachments')
                      : (state._isSpanishLocale ? 'Sin archivos' : 'No files'),
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
                  itemCount: attachmentCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (_, index) {
                    final generated = index < generatedNames.length;
                    final attachment = generated
                        ? null
                        : state._attachments[index - generatedNames.length];
                    final label = generated
                        ? generatedNames[index]
                        : attachment?.filename ?? attachment?.storageKey ?? '-';
                    return InputChip(
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(fontSize: 11),
                        ),
                      ),
                      onDeleted: state._sending
                          ? null
                          : () {
                              if (generated) {
                                state._removeAttachedDocumentAt(index);
                              } else {
                                state.update(() => state._attachments
                                    .removeAt(index - generatedNames.length));
                              }
                            },
                    );
                  },
                ),
              ),
            const SizedBox(width: 6),
            Text(
              '$attachmentCount',
              style: t.bodySmall.copyWith(
                color: attachmentCount > 0 ? cs.primary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            HexoraButton.iconOnly(
              key: const ValueKey('mail-compose-add-attachment'),
              tooltip: l.mailComposeAddAttachment,
              onPressed: state._sending || state._uploadingAttachment
                  ? null
                  : state._showAttachmentActions,
              icon: Icons.add_rounded,
              variant: HexoraButtonVariant.ghost,
              size: HexoraButtonSize.compact,
              loading: state._uploadingAttachment,
            ),
          ],
        ),
      );
    });
