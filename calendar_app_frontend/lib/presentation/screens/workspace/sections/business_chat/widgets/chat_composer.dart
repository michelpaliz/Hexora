import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Unified message composer: [+] [input] [send].
///
/// The input grows vertically with its content. On desktop, Enter sends and
/// Shift+Enter inserts a new line; on touch layouts Enter inserts a new line
/// and the send button is used instead. The send button stays disabled until
/// the field holds a non-blank message.
class ChatComposer extends StatefulWidget {
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
    this.plusKey,
    this.actionsOpen = false,
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
  final Key? plusKey;
  final bool actionsOpen;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final FocusNode _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode;

  @override
  void initState() {
    super.initState();
    _ownedFocusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)
          .removeListener(_handleFocusChanged);
      _focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleSend() {
    if (!widget.enabled || widget.sending) return;
    if (widget.controller.text.trim().isEmpty) return;
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled && !widget.sending,
      maxLength: 2000,
      minLines: 1,
      maxLines: 5,
      style: const TextStyle(fontSize: 14, height: 1.35),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: cs.onSurfaceVariant,
        ),
        hintMaxLines: 1,
        counterText: '',
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );

    // Desktop: Enter sends, Shift+Enter falls through to insert a newline.
    if (!widget.narrow) {
      field = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _handleSend,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _handleSend,
        },
        child: field,
      );
    }

    final focused = _focusNode.hasFocus && widget.enabled && !widget.sending;
    return AnimatedContainer(
      key: const ValueKey('chat-composer-surface'),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focused
              ? cs.primary.withValues(alpha: .85)
              : cs.outlineVariant.withValues(alpha: .75),
          width: focused ? 1.4 : 1,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(
          key: widget.plusKey,
          onPressed: widget.enabled && !widget.sending ? widget.onPlus : null,
          tooltip: widget.plusTooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(
            widget.actionsOpen ? Icons.close_rounded : Icons.add_rounded,
            size: 21,
          ),
        ),
        Expanded(child: field),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final canSend = widget.enabled &&
                !widget.sending &&
                value.text.trim().isNotEmpty;
            return IconButton.filled(
              onPressed: canSend ? _handleSend : null,
              tooltip: widget.sendTooltip,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.standard,
              style: IconButton.styleFrom(
                fixedSize: const Size.square(40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: widget.sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            );
          },
        ),
      ]),
    );
  }
}
