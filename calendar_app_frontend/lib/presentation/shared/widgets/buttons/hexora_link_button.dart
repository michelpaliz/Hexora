import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

/// Shared "Vincular" action used by every invoice-link entry point.
///
/// Keeping the styling here guarantees that the chat rows and the bank
/// transactions table show the same labelled pill with the same states.
class HexoraLinkButton extends StatelessWidget {
  const HexoraLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.icon = Icons.link_rounded,
    this.showIcon = false,
    this.loading = false,
  });

  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool showIcon;
  final bool loading;

  static const double _iconSize = 18;

  Color _background(BuildContext context, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!enabled) {
      return isDark
          ? cs.onSurface.withValues(alpha: 0.05)
          : cs.onSurface.withValues(alpha: 0.04);
    }
    return isDark
        ? cs.primary.withValues(alpha: 0.08)
        : const Color(0xFFEAF3FF);
  }

  Color _borderColor(BuildContext context, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!enabled) {
      return cs.outlineVariant.withValues(alpha: 0.35);
    }
    return isDark
        ? cs.primary.withValues(alpha: 0.18)
        : const Color(0xFFBDD3F0);
  }

  Color _foreground(BuildContext context, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!enabled) {
      return cs.onSurfaceVariant.withValues(alpha: 0.55);
    }
    return isDark ? cs.primary : const Color(0xFF245C99);
  }

  Widget _progress(Color color, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 1.8,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final foreground = _foreground(context, enabled);
    final background = _background(context, enabled);
    final borderColor = _borderColor(context, enabled);
    final semanticsLabel = (tooltip ?? label).trim();

    final typography = AppTypography.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel.isEmpty ? null : semanticsLabel,
      child: Tooltip(
        message: tooltip ?? label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loading) ...[
                    _progress(foreground, 12),
                    const SizedBox(width: 5),
                  ] else if (showIcon) ...[
                    Icon(icon, size: _iconSize, color: foreground),
                    const SizedBox(width: 5),
                  ],
                  if (label.trim().isNotEmpty)
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: typography.caption.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
