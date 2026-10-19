import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/theme/themes/navigation_tokens.dart';

class NavigationGroup extends StatelessWidget {
  const NavigationGroup(
      {super.key,
      required this.title,
      required this.icon,
      required this.expanded,
      required this.onToggle,
      required this.child});
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: NavigationTokens.itemGap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
            expanded: expanded,
            child: SidebarItem(
                icon: icon,
                label: title,
                isSelected: false,
                collapsed: false,
                onTap: onToggle,
                trailing: AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: NavigationTokens.motion,
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: NavigationTokens.iconSize)))),
        AnimatedSize(
            duration: NavigationTokens.motion,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding:
                        const EdgeInsets.only(top: NavigationTokens.itemGap),
                    child: child)
                : const SizedBox.shrink()),
      ]));
}
