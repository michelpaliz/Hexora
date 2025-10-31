import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';

class CalendarTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Tab> tabs;
  final ValueChanged<int>? onTabChanged;
  final List<Widget>? actions;

  const CalendarTopBar({
    super.key,
    required this.title,
    required this.tabs,
    this.onTabChanged,
    this.actions,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);

    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0.5,
      iconTheme: IconThemeData(color: cs.onSurface),
      title: Text(
        title,
        style: typo.bodyLarge.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
          color: cs.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
      bottom: TabBar(
        isScrollable: false,
        tabs: tabs,
        onTap: onTabChanged,
        labelStyle: typo.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: typo.bodySmall,
        labelColor: cs.primary, // selected label color
        unselectedLabelColor: cs.onSurfaceVariant,
        indicator: const UnderlineTabIndicator(
          // classic underline
          borderSide: BorderSide(width: 3),
        ),
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }
}
