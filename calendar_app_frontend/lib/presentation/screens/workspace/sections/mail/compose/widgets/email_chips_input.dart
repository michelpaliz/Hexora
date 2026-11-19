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
  String? _errorText;

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
    final invalid = <String>[];
    for (final raw in parts) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (_isValidEmail(value) && !next.contains(value)) {
        next.add(value);
        changed = true;
      } else if (!_isValidEmail(value)) {
        invalid.add(value);
      }
    }
    if (changed) {
      widget.onChanged(next);
    }
    if (invalid.isEmpty) {
      widget.controller.clear();
      if (_errorText != null && mounted) setState(() => _errorText = null);
    } else if (mounted) {
      widget.controller.text = invalid.join(' ');
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
      setState(() {
        _errorText = Localizations.localeOf(context).languageCode == 'es'
            ? 'Correo no válido'
            : 'Invalid email address';
      });
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final inputStyle = t.bodySmall.copyWith(color: cs.onSurface);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('mail-compose-email-chips-input'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.decoration.fillColor ?? cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText == null ? cs.outlineVariant : cs.error,
            ),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 3,
            children: [
              ...widget.values.map(
                (email) => InputChip(
                  label: Text(
                    email,
                    style: inputStyle.copyWith(
                      color: cs.onPrimaryContainer,
                      fontSize: compact ? 14 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: cs.primaryContainer,
                  disabledColor: cs.primaryContainer.withValues(alpha: 0.55),
                  deleteIconColor: cs.onPrimaryContainer,
                  side: BorderSide(
                    color: cs.primary.withValues(alpha: 0.42),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (value) {
                      if (_errorText != null &&
                          (value.trim().isEmpty ||
                              _isValidEmail(value.trim()))) {
                        setState(() => _errorText = null);
                      }
                      _tryCommit();
                    },
                    onEditingComplete: _commitAll,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      hintText: widget.values.isEmpty ? widget.hint : null,
                      hintStyle: t.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: compact ? 16 : 12,
                      ),
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      border: InputBorder.none,
                    ),
                    style: inputStyle.copyWith(fontSize: compact ? 16 : 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 2),
            child: Text(
              _errorText!,
              style: t.bodySmall.copyWith(color: cs.error, fontSize: 10),
            ),
          ),
      ],
    );
  }
}
