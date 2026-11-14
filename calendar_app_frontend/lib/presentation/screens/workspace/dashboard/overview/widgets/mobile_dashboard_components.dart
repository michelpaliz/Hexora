import 'package:flutter/material.dart';

/// Consistent compact section heading for the mobile business dashboard.
class MobileDashboardSection extends StatelessWidget {
  const MobileDashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: .65,
                        ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// One shared surface for tightly-related dashboard navigation destinations.
class CompactNavigationGroup extends StatelessWidget {
  const CompactNavigationGroup({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: 48,
                color: cs.outlineVariant.withValues(alpha: .45),
              ),
            children[index],
          ],
        ],
      ),
    );
  }
}

class CompactNavigationTile extends StatelessWidget {
  const CompactNavigationTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 47,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
