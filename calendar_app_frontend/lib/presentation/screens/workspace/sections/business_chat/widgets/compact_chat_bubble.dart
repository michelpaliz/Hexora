import 'package:flutter/material.dart';

/// Content-sized chat bubble for the message thread.
///
/// Short messages produce short bubbles. Incoming messages use a neutral
/// surface; outgoing messages use a subtle blue tint. Grouped messages from
/// the same sender share flatter adjacent corners so a run reads as one block.
class CompactChatBubble extends StatelessWidget {
  const CompactChatBubble({
    super.key,
    required this.mine,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.child,
    this.maxWidth = 520,
    this.onLongPress,
  });

  final bool mine;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final Widget child;
  final double maxWidth;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Derive both sides from the selected appearance. This keeps neutral
    // light, blue light and dark chat surfaces consistent with the workspace.
    final Color background = mine
        ? Color.alphaBlend(
            cs.primary.withValues(alpha: .14),
            cs.surface,
          )
        : cs.surfaceContainerLow;
    const double big = 16;
    const double small = 5;
    // Flatten the corner on the side that connects to the sender's other
    // grouped messages so a run of messages reads as a single stack.
    final radius = BorderRadius.only(
      topLeft: Radius.circular(mine || isFirstInGroup ? big : small),
      topRight: Radius.circular(!mine || isFirstInGroup ? big : small),
      bottomLeft: Radius.circular(mine || isLastInGroup ? big : small),
      bottomRight: Radius.circular(!mine || isLastInGroup ? big : small),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          key: const ValueKey('business-chat-bubble-surface'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
          ),
          child: child,
        ),
      ),
    );
  }
}
