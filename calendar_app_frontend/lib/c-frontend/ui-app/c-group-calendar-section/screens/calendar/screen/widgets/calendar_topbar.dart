import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

class CalendarTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Tab> tabs;
  final bool showTabs;
  final ValueChanged<int>? onTabChanged;
  final List<Widget>? actions;
  final bool showWeatherToggle;
  final bool weatherIconsEnabled;
  final ValueChanged<bool>? onWeatherToggle;
  final VoidCallback? onToggleLeftPanel;
  final bool leftPanelCollapsed;

  const CalendarTopBar({
    super.key,
    required this.title,
    this.tabs = const [],
    this.showTabs = true,
    this.onTabChanged,
    this.actions,
    this.showWeatherToggle = false,
    this.weatherIconsEnabled = true,
    this.onWeatherToggle,
    this.onToggleLeftPanel,
    this.leftPanelCollapsed = false,
  });

  @override
  Size get preferredSize => showTabs && tabs.isNotEmpty
      ? const Size.fromHeight(kToolbarHeight + kTextTabBarHeight)
      : const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final trailing = <Widget>[
      if (actions != null) ...actions!,
      if (onToggleLeftPanel != null)
        IconButton(
          tooltip:
              leftPanelCollapsed ? 'Expand left panel' : 'Collapse left panel',
          icon: Icon(
            leftPanelCollapsed
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            color: cs.onSurface,
          ),
          onPressed: onToggleLeftPanel,
        ),
      if (showWeatherToggle)
        IconButton(
          tooltip:
              weatherIconsEnabled ? 'Hide weather icons' : 'Show weather icons',
          icon: Icon(
            weatherIconsEnabled ? Icons.wb_sunny_rounded : Icons.cloud_rounded,
            color: cs.primary,
          ),
          onPressed: onWeatherToggle == null
              ? null
              : () => onWeatherToggle!.call(!weatherIconsEnabled),
        ),
    ];

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
      actions: trailing,
      bottom: showTabs && tabs.isNotEmpty
          ? TabBar(
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
            )
          : null,
    );
  }
}
