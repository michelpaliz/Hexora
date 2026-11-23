import 'package:flutter/material.dart';

/// Initial-letter avatar that identifies a client consistently across the
/// client list and the selected client's workspace header.
class ClientInitialAvatar extends StatelessWidget {
  const ClientInitialAvatar({
    super.key,
    required this.name,
    this.size = 24,
    this.emphasized = false,
  });

  final String name;
  final double size;

  /// Blue accent used for the selected client (list row and header).
  final bool emphasized;

  static String initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final background = emphasized
        ? Color.alphaBlend(cs.primary.withValues(alpha: .16), cs.surface)
        : cs.surfaceContainerHighest;
    final foreground = emphasized ? cs.primary : cs.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(
          color: emphasized
              ? cs.primary.withValues(alpha: .28)
              : Colors.transparent,
        ),
      ),
      child: Text(
        initialOf(name),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: size * .46,
              height: 1,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
      ),
    );
  }
}
