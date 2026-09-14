part of '../../mail_compose_screen.dart';

class _RecipientModeToggle extends StatelessWidget {
  const _RecipientModeToggle({
    required this.clientMode,
    required this.enabled,
    required this.emailLabel,
    required this.clientLabel,
    required this.recentLabel,
    required this.recentLoading,
    required this.onChanged,
    required this.onRecentTap,
  });

  final bool clientMode;
  final bool enabled;
  final String emailLabel;
  final String clientLabel;
  final String recentLabel;
  final bool recentLoading;
  final void Function(bool) onChanged;
  final VoidCallback onRecentTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    if (MediaQuery.sizeOf(context).width < 600) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        for (final mode in [false, true])
          ChoiceChip(
            selected: clientMode == mode,
            showCheckmark: false,
            avatar: Icon(mode ? Icons.person_outline : Icons.alternate_email,
                size: 18),
            label: Text(mode ? clientLabel : emailLabel,
                style: TextStyle(
                    color: clientMode == mode
                        ? cs.onPrimaryContainer
                        : cs.onSurface,
                    fontSize: 14)),
            selectedColor: cs.primaryContainer,
            onSelected: enabled ? (_) => onChanged(mode) : null,
          ),
        TextButton.icon(
            onPressed: enabled && !recentLoading ? onRecentTap : null,
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text(recentLabel)),
      ]);
    }

    Widget tab({
      required bool value,
      required IconData icon,
      required String label,
    }) {
      final selected = clientMode == value;
      return GestureDetector(
        onTap: enabled && !selected ? () => onChanged(value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? cs.primaryContainer.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13, color: selected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget recentTab() {
      return GestureDetector(
        onTap: enabled && !recentLoading ? onRecentTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recentLoading)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              else
                Icon(Icons.history_rounded, size: 13, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                recentLabel,
                style: t.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: recentLoading ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab(value: false, icon: Icons.edit_outlined, label: emailLabel),
          tab(value: true, icon: Icons.person_outline, label: clientLabel),
          recentTab(),
        ],
      ),
    );
  }
}

class _InlineRecipientRow extends StatelessWidget {
  const _InlineRecipientRow({
    required this.label,
    required this.controller,
    required this.values,
    required this.hint,
    required this.enabled,
    required this.inputDecoration,
    required this.onChanged,
    required this.onRemove,
  });

  final String label;
  final TextEditingController controller;
  final List<String> values;
  final String hint;
  final bool enabled;
  final InputDecoration inputDecoration;
  final void Function(List<String>) onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: t.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _EmailChipsInput(
              controller: controller,
              values: values,
              hint: hint,
              enabled: enabled,
              decoration: inputDecoration.copyWith(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
          if (values.isEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16),
              onPressed: enabled ? onRemove : null,
              visualDensity: VisualDensity.compact,
              color: cs.onSurfaceVariant,
              tooltip: 'Remove',
            ),
        ],
      ),
    );
  }
}
