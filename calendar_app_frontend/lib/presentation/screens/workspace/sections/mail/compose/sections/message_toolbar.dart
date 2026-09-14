part of '../../mail_compose_screen.dart';

Widget _composeMessageToolbar(
        {required _MailComposeScreenState state,
        required AppTypography t,
        required ColorScheme cs,
        required AppLocalizations l,
        required bool compact}) =>
    AnimatedBuilder(
      animation: Listenable.merge([state._quillController, state._bodyFocus]),
      builder: (context, _) {
        final canUndo = state._quillController.hasUndo;
        final canRedo = state._quillController.hasRedo;
        final showTools = state._bodyFocus.hasFocus;

        Widget toolBtn({
          required IconData icon,
          required String tooltip,
          VoidCallback? onPressed,
          bool active = false,
        }) {
          return SizedBox(
            width: compact ? 48 : 26,
            height: compact ? 48 : 26,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: compact ? 22 : 16,
              onPressed: onPressed,
              icon: Icon(icon),
              color: active ? cs.primary : cs.onSurface,
              tooltip: tooltip,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: showTools
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: showTools ? 1.3 : 1.0,
            ),
          ),
          child: Row(
            children: [
              if (!compact)
                Text(
                  l.mailComposeBodyLabel,
                  style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (!compact) const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: compact || showTools ? 1 : 0.45,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    toolBtn(
                      icon: Icons.undo_rounded,
                      tooltip: 'Undo',
                      onPressed:
                          canUndo ? () => state._quillController.undo() : null,
                    ),
                    toolBtn(
                      icon: Icons.redo_rounded,
                      tooltip: 'Redo',
                      onPressed:
                          canRedo ? () => state._quillController.redo() : null,
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    toolBtn(
                      icon: Icons.format_bold_rounded,
                      tooltip: 'Bold',
                      onPressed: () {
                        final isBold = state._quillController
                            .getSelectionStyle()
                            .attributes
                            .containsKey(quill.Attribute.bold.key);
                        state._quillController.formatSelection(
                          isBold
                              ? quill.Attribute.clone(
                                  quill.Attribute.bold, null)
                              : quill.Attribute.bold,
                        );
                      },
                    ),
                    toolBtn(
                      icon: Icons.format_italic_rounded,
                      tooltip: 'Italic',
                      onPressed: () {
                        final isItalic = state._quillController
                            .getSelectionStyle()
                            .attributes
                            .containsKey(quill.Attribute.italic.key);
                        state._quillController.formatSelection(
                          isItalic
                              ? quill.Attribute.clone(
                                  quill.Attribute.italic, null)
                              : quill.Attribute.italic,
                        );
                      },
                    ),
                    toolBtn(
                      icon: Icons.link_rounded,
                      tooltip: 'Link',
                      onPressed: state._promptLink,
                    ),
                    const SizedBox(width: 2),
                    if (!compact)
                      Text(
                        l.mailComposeFormat,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
