enum NavigationDisplayMode {
  automatic,
  iconsAndText,
  iconsOnly,
}

/// How workspace-level and contextual navigation are composed on desktop.
enum NavigationLayout {
  /// Primary modules and the active module submenu use separate columns.
  split,

  /// The active module submenu becomes the only navigation column and exposes
  /// a module switcher in its header.
  unified,
}

/// Placement of Hexora's global application controls around the workspace.
enum GlobalHeaderPosition {
  top,
  bottom,
}
