part of '../../mail_compose_screen.dart';

Widget _composeSubjectCard(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact}) =>
    Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject row — inline label + borderless field + template btn
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!compact)
                  SizedBox(
                    width: 42,
                    child: Text(
                      l.mailComposeSubjectLabel,
                      style: t.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 16 : 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (!compact)
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                Expanded(
                  child: TextField(
                    controller: state._subjectCtrl,
                    enabled: !state._sending,
                    maxLines: 1,
                    style: t.bodySmall.copyWith(
                        color: cs.onSurface, fontSize: compact ? 16 : 13),
                    decoration: InputDecoration(
                      labelText: compact ? l.mailComposeSubjectLabel : null,
                      hintText: compact ? null : l.mailComposeSubjectHint,
                      hintStyle: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: compact ? 16 : 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: compact
                          ? const EdgeInsets.symmetric(vertical: 8)
                          : EdgeInsets.zero,
                    ),
                    onChanged: (_) => state.update(() {}),
                  ),
                ),
                const SizedBox(width: 4),
                // Template picker button
                if (state._composeTemplatesLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed:
                        state._sending ? null : state._showTemplatePicker,
                    tooltip: state._selectedComposeTemplateName != null
                        ? (state._isSpanishLocale
                            ? 'Cambiar plantilla'
                            : 'Change template')
                        : (state._isSpanishLocale
                            ? 'Usar plantilla'
                            : 'Use template'),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      state._selectedComposeTemplateName != null
                          ? Icons.description_rounded
                          : Icons.description_outlined,
                      size: 18,
                      color: state._selectedComposeTemplateName != null
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Active template chip — only when a template is applied
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            child: state._selectedComposeTemplateName != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
                        child: Row(
                          children: [
                            // Chip
                            Expanded(
                              child: GestureDetector(
                                onTap: state._sending
                                    ? null
                                    : state._showTemplatePicker,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        state._selectedComposeTemplateName!,
                                        style: t.bodySmall.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: cs.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: state._sending
                                          ? null
                                          : () => state.update(() {
                                                state._selectedComposeTemplateId =
                                                    null;
                                                state._selectedComposeTemplateName =
                                                    null;
                                              }),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 13,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: state._sending
                                  ? null
                                  : state._showTemplatePicker,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: cs.onSurfaceVariant,
                                textStyle: t.bodySmall.copyWith(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                              ),
                              child: const Text('Cambiar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
