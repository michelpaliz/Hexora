import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? cta; // now optional
  final VoidCallback? onPressed; // now optional

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cta,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (cta != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(cta!),
                onPressed: onPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => onRetry(),
            ),
          ],
        ),
      ),
    );
  }
}

class ListItemCard extends StatelessWidget {
  final Widget leading;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? subtitleWidget;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool showLeadingStripe;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const ListItemCard({
    super.key,
    required this.leading,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.subtitleWidget,
    this.titleStyle,
    this.subtitleStyle,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.showLeadingStripe = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.borderRadius,
  }) : assert(title != null || titleWidget != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight
        ? (selected
            ? cs.primaryContainer.withValues(alpha: 0.28)
            : Colors.white)
        : Colors.transparent;
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.35)
        : cs.outlineVariant.withValues(alpha: 0.3);
    final effectiveTitleStyle = titleStyle ??
        t.bodyMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: cs.onSurface,
        );
    final effectiveSubtitleStyle = subtitleStyle ??
        t.bodySmall.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        );

    final effectiveRadius = borderRadius ?? BorderRadius.circular(10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: effectiveRadius,
        border: Border.all(color: borderColor),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: selected ? 0.055 : 0.035),
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Stack(
          children: [
            if (selected && showLeadingStripe)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: cs.primary,
                ),
              ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: effectiveRadius,
                onTap: onTap,
                child: Padding(
                  padding: padding,
                  child: Row(
                    children: [
                      leading,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget ??
                                Text(
                                  title ?? '',
                                  style: effectiveTitleStyle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            if (subtitleWidget != null ||
                                (subtitle != null && subtitle!.isNotEmpty)) ...[
                              const SizedBox(height: 3),
                              subtitleWidget ??
                                  Text(
                                    subtitle ?? '',
                                    style: effectiveSubtitleStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
