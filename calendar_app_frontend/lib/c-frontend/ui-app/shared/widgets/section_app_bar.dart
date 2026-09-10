import 'package:flutter/material.dart';

/// Shared navigation header for standalone dashboard sections.
class SectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SectionAppBar({
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
    final canGoBack = onBack != null || Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: kToolbarHeight,
      centerTitle: false,
      titleSpacing: 16,
      backgroundColor: cs.surface,
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
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
