import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/palette/app_colors/app_colors.dart';

class HomeSectionNavItem {
  final String id;
  final String label;
  final GlobalKey key;

  HomeSectionNavItem({
    required this.id,
    required this.label,
    required this.key,
  });
}

class HomeSectionNav extends StatelessWidget {
  final List<HomeSectionNavItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool isDark;
  final Axis axis;
  final EdgeInsetsGeometry padding;
  final double chipSpacing;

  const HomeSectionNav({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    required this.isDark,
    this.axis = Axis.horizontal,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 12, 10),
    this.chipSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppDarkColors.background : AppColors.background;
    final border = Colors.black.withOpacity(isDark ? 0.25 : 0.1);
    final pillColor = isDark ? AppDarkColors.surface : AppColors.surface;
    final activeColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final onSurface =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    final chips = [
      for (final item in items)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: axis == Axis.horizontal ? chipSpacing / 2 : 0,
            vertical: axis == Axis.vertical ? chipSpacing / 2 : 0,
          ),
          child: ChoiceChip(
            label: Text(item.label),
            selected: selectedId == item.id,
            onSelected: (_) => onSelect(item.id),
            selectedColor: activeColor.withOpacity(0.14),
            labelStyle: TextStyle(
              color: selectedId == item.id
                  ? activeColor
                  : onSurface.withOpacity(0.85),
              fontWeight:
                  selectedId == item.id ? FontWeight.w700 : FontWeight.w500,
            ),
            backgroundColor: Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: selectedId == item.id
                    ? activeColor.withOpacity(0.45)
                    : border,
              ),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
    ];

    final content = axis == Axis.horizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: chips),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: chips,
            ),
          );

    return Container(
      color: bg,
      padding: padding,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pillColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.8),
        ),
        child: content,
      ),
    );
  }
}
