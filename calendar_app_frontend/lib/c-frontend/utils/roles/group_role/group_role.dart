import 'package:flutter/material.dart';

/// Backend-driven role model (wire value + rank + icon).
class GroupRole {
  final String wire;
  final int rank; // higher rank => more permissions
  final IconData icon;

  const GroupRole({
    required this.wire,
    required this.rank,
    required this.icon,
  });

  /// Color helper for chips
  Color roleChipColor(ColorScheme cs) {
    // Basic mapping; adjust as needed
    final key = _sanitize(wire);
    return switch (key) {
      'owner' => cs.primary,
      'admin' => cs.tertiary,
      'coadmin' => cs.tertiary,
      _ => cs.onSurfaceVariant,
    };
  }

  /// Built-in defaults (used as fallback if backend fetch fails)
  static const GroupRole owner =
      GroupRole(wire: 'owner', rank: 3, icon: Icons.workspace_premium_rounded);
  static const GroupRole admin = GroupRole(
      wire: 'admin', rank: 2, icon: Icons.admin_panel_settings_rounded);
  static const GroupRole coAdmin =
      GroupRole(wire: 'co-admin', rank: 1, icon: Icons.shield_rounded);
  static const GroupRole member =
      GroupRole(wire: 'member', rank: 0, icon: Icons.person_rounded);

  static const List<GroupRole> defaults = [member, coAdmin, admin, owner];

  /// Find a matching role by wire, using provided roles first, then defaults.
  static GroupRole fromWire(
    String? raw, {
    List<GroupRole>? available,
  }) {
    final list = available ?? defaults;
    final s = _sanitize(raw);
    for (final r in list) {
      if (_sanitize(r.wire) == s) return r;
    }
    // try common variants
    if (s == 'coadmin') {
      final match = list.firstWhere(
        (r) => _sanitize(r.wire) == 'coadmin',
        orElse: () => coAdmin,
      );
      return match;
    }
    return list.firstWhere((_) => true, orElse: () => member);
  }

  static String _sanitize(String? v) =>
      (v ?? '').toLowerCase().replaceAll('-', '').replaceAll('_', '').trim();
}
