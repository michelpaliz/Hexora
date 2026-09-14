part of '../../mail_compose_screen.dart';

Widget _composeMessageEditor(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact,
        required bool isWideEmbedded,
        required InputDecoration inputDecoration}) =>
    AnimatedBuilder(
      animation: state._bodyFocus,
      builder: (context, _) {
        final focused = state._bodyFocus.hasFocus;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: inputDecoration.fillColor ?? cs.surface,
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
            minHeight: isWideEmbedded ? 300 : 180,
          ),
          child: DefaultTextStyle(
            style: t.bodySmall.copyWith(
              color: cs.onSurface,
              fontSize: compact ? 16 : 12,
              height: 1.45,
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
                          fontSize: compact ? 16 : 12,
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
