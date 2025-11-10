import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class HexoraSnackBar extends StatefulWidget {
  final String message;
  final String? translatedMessage;
  final Duration duration;
  final VoidCallback? onActionPressed;
  final String actionLabel;
  final String? translatedActionLabel;

  const HexoraSnackBar({
    Key? key,
    required this.message,
    this.translatedMessage,
    this.duration = const Duration(seconds: 4),
    this.onActionPressed,
    this.actionLabel = 'OK',
    this.translatedActionLabel,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required String message,
    String? translatedMessage,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onActionPressed,
    String actionLabel = 'OK',
    String? translatedActionLabel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: HexoraSnackBar(
          message: message,
          translatedMessage: translatedMessage,
          duration: duration,
          onActionPressed: onActionPressed,
          actionLabel: actionLabel,
          translatedActionLabel: translatedActionLabel,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  State<HexoraSnackBar> createState() => _HexoraSnackBarState();
}

class _HexoraSnackBarState extends State<HexoraSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAction() {
    widget.onActionPressed?.call();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _handleCopyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.message));
    // Show a brief feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    HexoraSnackBar.show(
      context: context,
      message: AppLocalizations.of(context)?.copiedToClipboard ??
          'Copied to clipboard',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typography = AppTypography.of(context);
    final bg = ThemeColors.containerBg(context);
    final onBg = ThemeColors.textPrimary(context);

    // Use translated message if available, otherwise fallback to original
    final displayMessage = widget.translatedMessage ?? widget.message;
    final displayActionLabel =
        widget.translatedActionLabel ?? widget.actionLabel;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ThemeColors.cardShadow(context),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Original message (smaller, faded)
                      if (widget.translatedMessage != null &&
                          widget.message != widget.translatedMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            widget.message,
                            style: typography.bodySmall.copyWith(
                              color: ThemeColors.textSecondary(context),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // Main message (translated)
                      Text(
                        displayMessage,
                        style: typography.bodyMedium.copyWith(
                          color: onBg,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: widget.translatedMessage != null ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    // Copy button (only show if we have a translation)
                    if (widget.translatedMessage != null &&
                        widget.message != widget.translatedMessage)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: _handleCopyToClipboard,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.content_copy,
                              size: 16,
                              color: cs.secondary,
                            ),
                          ),
                        ),
                      ),
                    // Action button
                    GestureDetector(
                      onTap: _handleAction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          displayActionLabel,
                          style: typography.buttonText.copyWith(
                            color: ThemeColors.contrastOn(cs.primary),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Convenience extension for easy usage
extension HexoraSnackBarExtension on BuildContext {
  void showSnackBar({
    required String message,
    String? translatedMessage,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onActionPressed,
    String actionLabel = 'OK',
    String? translatedActionLabel,
  }) {
    HexoraSnackBar.show(
      context: this,
      message: message,
      translatedMessage: translatedMessage,
      duration: duration,
      onActionPressed: onActionPressed,
      actionLabel: actionLabel,
      translatedActionLabel: translatedActionLabel,
    );
  }
}

