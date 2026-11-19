import 'package:flutter/material.dart';

/// A single contextual action available on a chat message.
class ChatMessageAction {
  const ChatMessageAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// Wraps a message bubble and surfaces its actions contextually instead of
/// reserving permanent icon space.
///
/// On desktop a compact floating toolbar appears when the message is hovered
/// or keyboard-focused; a right-click (secondary tap) opens a context menu at
/// the pointer. Only the actions passed in are shown, so callers gate them by
/// permission. On touch layouts ([enabled] false) the bubble is returned as-is
/// and callers wire long-press elsewhere.
class ChatMessageActions extends StatefulWidget {
  const ChatMessageActions({
    super.key,
    required this.child,
    required this.actions,
    required this.mine,
    this.enabled = true,
    this.menuSemanticLabel,
  });

  final Widget child;
  final List<ChatMessageAction> actions;
  final bool mine;
  final bool enabled;
  final String? menuSemanticLabel;

  @override
  State<ChatMessageActions> createState() => _ChatMessageActionsState();
}

class _ChatMessageActionsState extends State<ChatMessageActions> {
  bool _hovering = false;
  bool _focused = false;

  bool get _active => _hovering || _focused;

  Future<void> _openContextMenu(Offset globalPosition) async {
    if (widget.actions.isEmpty) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final selected = await showMenu<ChatMessageAction>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final action in widget.actions)
          PopupMenuItem<ChatMessageAction>(
            value: action,
            child: Row(children: [
              Icon(
                action.icon,
                size: 18,
                color: action.destructive
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                action.label,
                style: action.destructive
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
            ]),
          ),
      ],
    );
    selected?.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.actions.isEmpty) return widget.child;
    final cs = Theme.of(context).colorScheme;

    final toolbar = AnimatedOpacity(
      opacity: _active ? 1 : 0,
      duration: const Duration(milliseconds: 120),
      child: IgnorePointer(
        ignoring: !_active,
        child: Material(
          elevation: 2,
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final action in widget.actions)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: action.label,
                  color: action.destructive ? cs.error : cs.onSurfaceVariant,
                  onPressed: action.onSelected,
                  icon: Icon(action.icon),
                ),
            ]),
          ),
        ),
      ),
    );

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovering = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: GestureDetector(
        onSecondaryTapDown: (details) =>
            _openContextMenu(details.globalPosition),
        onLongPressStart: (details) => _openContextMenu(details.globalPosition),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              top: -14,
              right: widget.mine ? null : 4,
              left: widget.mine ? 4 : null,
              child: toolbar,
            ),
          ],
        ),
      ),
    );
  }
}
