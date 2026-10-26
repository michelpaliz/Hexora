part of '../../mail_compose_screen.dart';

Widget _composeSubjectCard(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact,
        required Color inputFill}) =>
    Container(
      key: const ValueKey('mail-compose-subject-input-surface'),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!compact) ...[
            SizedBox(
              width: 42,
              child: Text(
                l.mailComposeSubjectLabel,
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
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
          Expanded(
            child: TextField(
              controller: state._subjectCtrl,
              enabled: !state._sending,
              maxLines: 1,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontSize: compact ? 15 : 13,
              ),
              decoration: InputDecoration(
                labelText: compact ? l.mailComposeSubjectLabel : null,
                hintText: compact ? null : l.mailComposeSubjectHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: compact
                    ? const EdgeInsets.symmetric(vertical: 7)
                    : EdgeInsets.zero,
              ),
              onChanged: (_) => state.update(() {}),
            ),
          ),
          const SizedBox(width: 4),
          if (state._composeTemplatesLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: cs.onSurfaceVariant),
              ),
            )
          else if (state._selectedComposeTemplateName == null || compact)
            IconButton(
              onPressed: state._sending ? null : state._showTemplatePicker,
              tooltip: state._selectedComposeTemplateName != null
                  ? (state._isSpanishLocale
                      ? 'Cambiar plantilla'
                      : 'Change template')
                  : (state._isSpanishLocale
                      ? 'Usar plantilla'
                      : 'Use template'),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              icon: Icon(
                state._selectedComposeTemplateName != null
                    ? Icons.description_rounded
                    : Icons.description_outlined,
                size: 17,
                color: state._selectedComposeTemplateName != null
                    ? cs.primary
                    : cs.onSurfaceVariant,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Container(
                height: 30,
                padding: const EdgeInsets.only(left: 9),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined,
                        size: 15, color: cs.primary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: InkWell(
                        onTap:
                            state._sending ? null : state._showTemplatePicker,
                        child: Text(
                          state._selectedComposeTemplateName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall.copyWith(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: state._isSpanishLocale
                          ? 'Quitar plantilla'
                          : 'Remove template',
                      onPressed: state._sending
                          ? null
                          : () => state.update(() {
                                state._selectedComposeTemplateId = null;
                                state._selectedComposeTemplateName = null;
                              }),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints.tightFor(width: 30, height: 30),
                      icon: const Icon(Icons.close_rounded, size: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
