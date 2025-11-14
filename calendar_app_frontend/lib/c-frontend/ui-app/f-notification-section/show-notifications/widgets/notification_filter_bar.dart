import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/c-frontend/enums/category/broad_category.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationFilterBar extends StatelessWidget {
  final List<NotificationUser> notifications;
  final BroadCategory? selectedCategory;
  final ValueChanged<BroadCategory?> onCategorySelected;

  const NotificationFilterBar({
    super.key,
    required this.notifications,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final manager = BroadCategoryManager();

    // Build set of used categories (from incoming notifications)
    final usedCats = notifications
        .map((ntf) => manager.categoryMapping[ntf.category])
        .whereType<BroadCategory>()
        .toSet()
        .toList()
      ..sort((a, b) =>
          a.localizedName(context).compareTo(b.localizedName(context)));

    // Precompute per-category counts to display a small badge
    final counts = <BroadCategory, int>{};
    for (final cat in usedCats) {
      counts[cat] = notifications.where((ntf) {
        final mapped = manager.categoryMapping[ntf.category];
        return mapped == cat;
      }).length;
    }

    // Horizontal list with nice spacing
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: usedCats.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final bool isAll = index == 0;
          final BroadCategory? cat = isAll ? null : usedCats[index - 1];
          final bool isSelected = selectedCategory == cat;

          final label = isAll ? _locAll(context) : cat!.localizedName(context);

          final count = isAll ? notifications.length : counts[cat] ?? 0;

          return _FilterPill(
            label: label,
            count: count,
            selected: isSelected,
            onTap: () => onCategorySelected(isSelected ? null : cat),
          );
        },
      ),
    );
  }

  // Graceful fallback if your l10n doesn’t have "all"
  String _locAll(BuildContext context) {
    // If you have AppLocalizations, use it here:
    final loc = AppLocalizations.of(context);
    return loc?.all ?? 'All';
    // return 'All';
  }
}

class _FilterPill extends StatefulWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedBg = scheme.primary;
    final selectedFg = scheme.onPrimary;
    final normalBg = scheme.surface.withOpacity(0.9);
    final normalFg = scheme.onSurface;

    final bg = widget.selected
        ? selectedBg
        : (_hovering ? normalBg.withOpacity(0.95) : normalBg);
    final fg = widget.selected ? selectedFg : normalFg;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.selected
                  ? selectedBg
                  : scheme.outlineVariant.withOpacity(0.25),
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Count badge (subtle)
              if (widget.count > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.selected
                        ? selectedFg.withOpacity(0.15)
                        : scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
