import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/hexora_design_tokens.dart';

double hexoraSectionTabsHeight(BuildContext context) {
  final platform = Theme.of(context).platform;
  final touch = MediaQuery.sizeOf(context).width < 650 ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS;
  return math.max(
      touch ? HexoraDimensions.touchTarget : HexoraDocumentTokens.tabsHeight,
      MediaQuery.textScalerOf(context).scale(13) + 16);
}

/// Shared section navigation; scrolls on narrow layouts without truncating tabs.
class HexoraSectionTabs extends StatelessWidget {
  const HexoraSectionTabs({
    super.key,
    this.controller,
    required this.tabs,
    this.compact = false,
    this.segmented = false,
    this.onTap,
  });
  final TabController? controller;
  final List<Tab> tabs;
  final bool compact;

  /// Uses a filled selected state for compact controls such as document tabs.
  /// Content-navigation tabs keep the traditional underline by default.
  final bool segmented;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final defaultHeight = hexoraSectionTabsHeight(context);
    final compactHeight = math.max(
      36.0,
      MediaQuery.textScalerOf(context).scale(12) + 16,
    );
    final height = compact && MediaQuery.sizeOf(context).width >= 650
        ? compactHeight
        : defaultHeight;
    return SizedBox(
        height: height,
        child: TabBar(
          controller: controller,
          onTap: onTap,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: segmented
              ? BoxDecoration(
                  color: cs.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.primary.withValues(alpha: .28)),
                )
              : UnderlineTabIndicator(
                  borderSide: BorderSide(color: cs.primary, width: 2)),
          indicatorPadding: segmented
              ? const EdgeInsets.symmetric(vertical: 2)
              : EdgeInsets.zero,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 12 : 13, fontWeight: FontWeight.w500),
          overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? cs.primary.withValues(alpha: .12)
                  : states.contains(WidgetState.hovered)
                      ? cs.primary.withValues(alpha: .04)
                      : null),
          labelPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
          tabs: [
            for (final tab in tabs)
              Tab(
                  key: tab.key,
                  height: height,
                  text: tab.text,
                  icon: tab.icon,
                  iconMargin: tab.iconMargin,
                  child: tab.child)
          ],
        ));
  }
}
