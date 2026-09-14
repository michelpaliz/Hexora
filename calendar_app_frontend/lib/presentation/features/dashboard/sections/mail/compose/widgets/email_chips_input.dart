part of '../../mail_compose_screen.dart';

/// Email chips input widget with auto-commit on delimiters
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
    final inputStyle = t.bodySmall.copyWith(color: cs.onSurface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: widget.decoration.fillColor ?? cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          ...widget.values.map(
            (email) => InputChip(
              label: Text(email, style: inputStyle.copyWith(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onDeleted: widget.enabled
                  ? () {
                      final next = [...widget.values]..remove(email);
                      widget.onChanged(next);
                    }
                  : null,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 120, maxWidth: 280),
            child: IntrinsicWidth(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                onChanged: (_) => _tryCommit(),
                onEditingComplete: _commitAll,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  hintText: widget.values.isEmpty ? widget.hint : null,
                  hintStyle: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                ),
                style: inputStyle.copyWith(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
