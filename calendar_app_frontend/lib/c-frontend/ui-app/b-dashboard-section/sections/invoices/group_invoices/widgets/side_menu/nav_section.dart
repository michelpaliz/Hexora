import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class GroupInvoicesNavSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const GroupInvoicesNavSection({
    super.key,
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 7),
      padding: EdgeInsets.fromLTRB(7, 5, 7, expanded ? 6 : 5),
      decoration: BoxDecoration(
        color: expanded
            ? cs.surfaceContainerHighest.withValues(alpha: 0.115)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expanded
              ? cs.outlineVariant.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggle,
            hoverColor: cs.primary.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: expanded
                          ? cs.primary.withValues(alpha: 0.13)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 15,
                      color: expanded ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: t.bodySmall.copyWith(
                        fontSize: 12.5,
                        fontWeight:
                            expanded ? FontWeight.w900 : FontWeight.w800,
                        color: expanded ? cs.onSurface : cs.onSurfaceVariant,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 19,
                      color: expanded ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 210),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
