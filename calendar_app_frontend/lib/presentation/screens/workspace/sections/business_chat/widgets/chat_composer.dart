import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact message composer: [+] [input] [send].
///
/// The input grows vertically with its content. On desktop, Enter sends and
/// Shift+Enter inserts a new line; on touch layouts Enter inserts a new line
/// and the send button is used instead. The send button stays disabled until
/// the field holds a non-blank message.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.onSend,
    required this.onPlus,
    required this.hintText,
    required this.narrow,
    this.plusTooltip,
    this.sendTooltip,
    this.focusNode,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onPlus;
  final String hintText;
  final bool narrow;
  final String? plusTooltip;
  final String? sendTooltip;
  final FocusNode? focusNode;

  void _handleSend() {
    if (!enabled || sending) return;
    if (controller.text.trim().isEmpty) return;
    onSend();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled && !sending,
      maxLength: 2000,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textInputAction:
          narrow ? TextInputAction.newline : TextInputAction.newline,
      decoration: InputDecoration(
        hintText: hintText,
        hintMaxLines: 1,
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.28),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),
    );

    // Desktop: Enter sends, Shift+Enter falls through to insert a newline.
    if (!narrow) {
      field = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _handleSend,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _handleSend,
        },
        child: field,
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      IconButton(
        onPressed: enabled && !sending ? onPlus : null,
        tooltip: plusTooltip,
        icon: const Icon(Icons.add_rounded),
      ),
      Expanded(child: field),
      const SizedBox(width: 8),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final canSend =
              enabled && !sending && value.text.trim().isNotEmpty;
          return IconButton.filled(
            onPressed: canSend ? _handleSend : null,
            tooltip: sendTooltip,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          );
        },
      ),
    ]);
  }
}
