import 'package:flutter/material.dart';
import 'package:hexora/presentation/shared/widgets/hexora_section_tabs.dart';

export 'package:hexora/presentation/shared/widgets/section_app_bar.dart'
    show HexoraHeaderAction, HexoraMobileAppBar, HexoraSectionHeader;

/// Standard primary tabs for phone layouts.
class HexoraMobileTabs extends StatelessWidget {
  const HexoraMobileTabs({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
  });

  final TabController? controller;
  final List<Tab> tabs;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) => HexoraSectionTabs(
        controller: controller,
        tabs: tabs,
        onTap: onTap,
      );
}

/// Compact theme-aware selector for filters and view switches.
class HexoraSegmentedControl<T> extends StatelessWidget {
  const HexoraSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
  });

  final Map<T, Widget> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onChanged;
  final bool multiSelectionEnabled;
  final bool emptySelectionAllowed;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
        segments: [
          for (final entry in segments.entries)
            ButtonSegment<T>(value: entry.key, label: entry.value),
        ],
        selected: selected,
        onSelectionChanged: onChanged,
        multiSelectionEnabled: multiSelectionEnabled,
        emptySelectionAllowed: emptySelectionAllowed,
        showSelectedIcon: false,
      );
}
