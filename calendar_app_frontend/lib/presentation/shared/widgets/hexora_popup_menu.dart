import 'package:flutter/material.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

enum HexoraPopupMenuTone { neutral, primary, destructive }

/// Shared compact popup surface used by contextual action menus.
class HexoraPopupMenuButton<T> extends StatelessWidget {
  const HexoraPopupMenuButton({
    super.key,
    required this.itemBuilder,
    required this.onSelected,
    required this.tooltip,
    this.icon = const Icon(Icons.more_vert, size: 16),
    this.enabled = true,
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final String tooltip;
  final Widget icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
        tooltip: tooltip,
        enabled: enabled,
        icon: icon,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 200, maxWidth: 220),
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NavigationTokens.radius),
        ),
        clipBehavior: Clip.antiAlias,
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
      );
}

/// Aligned icon-and-label entry for [HexoraPopupMenuButton].
class HexoraPopupMenuActionItem<T> extends PopupMenuItem<T> {
  HexoraPopupMenuActionItem({
    super.key,
    required T value,
    required IconData icon,
    required String label,
    super.enabled = true,
    HexoraPopupMenuTone tone = HexoraPopupMenuTone.neutral,
  }) : super(
          value: value,
          height: NavigationTokens.desktopRowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            final color = !enabled
                ? cs.onSurface.withValues(alpha: 0.38)
                : switch (tone) {
                    HexoraPopupMenuTone.primary => cs.primary,
                    HexoraPopupMenuTone.destructive => cs.error,
                    HexoraPopupMenuTone.neutral => cs.onSurfaceVariant,
                  };
            return Row(children: [
              SizedBox(
                width: 20,
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NavigationTokens.label(context).copyWith(color: color),
                ),
              ),
            ]);
          }),
        );
}

class HexoraPopupMenuDivider extends PopupMenuDivider {
  const HexoraPopupMenuDivider({super.key}) : super(height: 9);
}
