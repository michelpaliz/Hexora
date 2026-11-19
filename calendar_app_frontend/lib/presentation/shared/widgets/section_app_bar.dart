import 'package:flutter/material.dart';

/// Unified 56 px mobile navigation header used by standalone screens.
class HexoraMobileAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HexoraMobileAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.onBack,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;
  final Widget? leading;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final appBarTheme = theme.appBarTheme;
    final canGoBack = onBack != null || Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: kToolbarHeight,
      centerTitle: false,
      titleSpacing: 16,
      backgroundColor: appBarTheme.backgroundColor ?? cs.surfaceContainerLow,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: cs.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: cs.onSurface, size: 24),
      automaticallyImplyLeading: false,
      leading: leading ??
          (canGoBack
              ? BackButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop())
              : null),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Backwards-compatible name used throughout existing section screens.
class SectionAppBar extends HexoraMobileAppBar {
  const SectionAppBar({
    super.key,
    required super.title,
    super.actions,
    super.bottom,
    super.onBack,
    super.leading,
  });
}

class HexoraHeaderAction extends StatelessWidget {
  const HexoraHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: selected ? cs.primary : cs.onSurfaceVariant,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        backgroundColor:
            selected ? cs.primaryContainer.withValues(alpha: .7) : null,
      ),
    );
  }
}

class HexoraSectionHeader extends StatelessWidget {
  const HexoraSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}
