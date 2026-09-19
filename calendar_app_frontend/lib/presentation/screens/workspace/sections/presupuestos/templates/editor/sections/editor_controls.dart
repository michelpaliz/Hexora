part of '../../presupuesto_template_editor_screen.dart';

extension _TemplateEditorControls on _PresupuestoTemplateEditorScreenState {
  Widget _card({
    required String title,
    required Widget child,
    String? subtitle,
    IconData? icon,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: _editorCardBg(theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _editorBorder(theme)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    Key? fieldKey,
    int maxLines = 1,
    int? minLines,
    String? hint,
    bool dense = false,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool markdown = false,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    String? disabledMessage,
    bool showLabel = true,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15,
                      ),
                    ),
                  ),
                  if (disabledMessage != null)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          disabledMessage,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  if (markdown)
                    _markdownToolbar(
                      theme,
                      controller,
                      allowLineBreak: maxLines != 1,
                    ),
                ],
              ),
            ),
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: (value) {
              onChanged?.call(value);
              _updateEditorState(() {});
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.62),
              ),
              prefixIcon: prefixIcon == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(
                        left: 14,
                        right: 11,
                        bottom: maxLines > 3
                            ? 70
                            : maxLines > 1
                                ? 18
                                : 0,
                      ),
                      child: Icon(prefixIcon, size: 20, color: cs.primary),
                    ),
              prefixIconConstraints: const BoxConstraints(minWidth: 46),
              filled: true,
              fillColor: _editorInsetBg(theme),
              isDense: dense,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: _editorBorder(theme)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: _editorBorder(theme)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: cs.primary, width: 1.6),
              ),
              hoverColor: cs.primary.withValues(alpha: 0.025),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markdownToolbar(
    ThemeData theme,
    TextEditingController controller, {
    required bool allowLineBreak,
  }) {
    final cs = theme.colorScheme;
    return Container(
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _isDark(theme)
            ? const Color(0xFF16263A)
            : cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _editorBorder(theme, alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatButton(
            tooltip: 'Negrita',
            icon: Icons.format_bold_rounded,
            onPressed: () => _wrapSelection(controller, '**'),
          ),
          _formatButton(
            tooltip: 'Cursiva',
            icon: Icons.format_italic_rounded,
            onPressed: () => _wrapSelection(controller, '*'),
          ),
          if (allowLineBreak)
            _formatButton(
              tooltip: 'Salto de linea',
              icon: Icons.keyboard_return_rounded,
              onPressed: () => _insertLineBreak(controller),
            ),
        ],
      ),
    );
  }

  Widget _formatButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }
}
