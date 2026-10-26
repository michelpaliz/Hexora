part of '../../mail_compose_screen.dart';

Widget _composeMessageEditor(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact,
        required bool isWideEmbedded,
        required double minHeight,
        required InputDecoration inputDecoration}) =>
    AnimatedBuilder(
      key: const ValueKey('mail-compose-message-editor'),
      animation: state._bodyFocus,
      builder: (context, _) {
        final focused = state._bodyFocus.hasFocus;
        return Container(
          key: const ValueKey('mail-compose-body-input-surface'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
            border: Border(
              left: BorderSide(
                color: focused ? cs.primary : cs.outlineVariant,
                width: focused ? 1.3 : 1,
              ),
              right: BorderSide(
                color: focused ? cs.primary : cs.outlineVariant,
                width: focused ? 1.3 : 1,
              ),
              bottom: BorderSide(
                color: focused ? cs.primary : cs.outlineVariant,
                width: focused ? 1.3 : 1,
              ),
            ),
          ),
          constraints: BoxConstraints(
            minHeight: minHeight,
          ),
          child: DefaultTextStyle(
            style: t.bodySmall.copyWith(
              color: cs.onSurface,
              fontFamily: 'Inter',
              fontSize: compact ? 15 : 14,
              height: 1.35,
            ),
            child: Builder(
              builder: (context) {
                state._quillController.readOnly = state._sending;
                return quill.QuillEditor(
                  controller: state._quillController,
                  scrollController: state._bodyScroll,
                  focusNode: state._bodyFocus,
                  config: quill.QuillEditorConfig(
                    padding: EdgeInsets.zero,
                    autoFocus: false,
                    expands: false,
                    placeholder: l.mailComposeTextHint,
                    customStyles: quill.DefaultStyles(
                      placeHolder: quill.DefaultTextBlockStyle(
                        t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'Inter',
                          fontSize: compact ? 15 : 14,
                        ),
                        const quill.HorizontalSpacing(0, 0),
                        quill.VerticalSpacing.zero,
                        quill.VerticalSpacing.zero,
                        null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
