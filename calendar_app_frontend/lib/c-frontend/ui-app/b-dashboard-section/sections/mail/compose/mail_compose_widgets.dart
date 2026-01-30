part of '../mail_compose_screen.dart';

class _EmailChipsInput extends StatefulWidget {
  const _EmailChipsInput({
    required this.controller,
    required this.values,
    required this.hint,
    required this.enabled,
    required this.decoration,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> values;
  final String hint;
  final bool enabled;
  final InputDecoration decoration;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_EmailChipsInput> createState() => _EmailChipsInputState();
}

class _EmailChipsInputState extends State<_EmailChipsInput> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commitAll();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _tryCommit() {
    final text = widget.controller.text;
    if (text.trim().isEmpty) return;
    if (!text.contains(RegExp(r'[;,\s]'))) return;
    _commitAll();
  }

  void _commitAll() {
    final parts = widget.controller.text.split(RegExp(r'[;,\s]'));
    final next = [...widget.values];
    var changed = false;
    for (final raw in parts) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (_isValidEmail(value) && !next.contains(value)) {
        next.add(value);
        changed = true;
      }
    }
    if (changed) {
      widget.onChanged(next);
      widget.controller.clear();
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: widget.decoration.fillColor ?? cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...widget.values.map(
            (email) => InputChip(
              label: Text(email, style: t.bodySmall),
              onDeleted: widget.enabled
                  ? () {
                      final next = [...widget.values]..remove(email);
                      widget.onChanged(next);
                    }
                  : null,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 140, maxWidth: 320),
            child: IntrinsicWidth(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                onChanged: (_) => _tryCommit(),
                onEditingComplete: _commitAll,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.values.isEmpty ? widget.hint : null,
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedPanel extends StatelessWidget {
  const _CollapsedPanel({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.trailing,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onToggle,
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.expand_more_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _ComposeBottomBar extends StatelessWidget {
  const _ComposeBottomBar({
    required this.sending,
    required this.enabled,
    required this.onSend,
    required this.label,
  });

  final bool sending;
  final bool enabled;
  final VoidCallback onSend;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: enabled && !sending ? onSend : null,
            icon: sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}
