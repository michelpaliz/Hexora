import 'package:flutter/material.dart';
// 🔹 Add these imports to use the global role label helper
import 'package:hexora/c-frontend/utils/roles/group_role/group_role.dart';
import 'package:hexora/c-frontend/utils/roles/group_role/group_role_labels.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';

/// A reusable information-first header with:
/// - Title
/// - Optional subtitle/helper text
/// - Optional stat chips (Wrap)
/// - Optional trailing action (e.g., a button)
/// - Optional bottom widget (e.g., filters/search)
class InfoHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> stats; // chips/badges
  final Widget? trailingAction; // button or menu
  final Widget? bottom; // filters/search row
  final EdgeInsets padding;
  final double spacing;
  final double runSpacing;

  const InfoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.stats = const [],
    this.trailingAction,
    this.bottom,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 8),
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + trailing action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (trailingAction != null) ...[
                const SizedBox(width: 12),
                trailingAction!,
              ],
            ],
          ),

          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ],

          if (stats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: stats,
            ),
          ],

          if (bottom != null) ...[
            const SizedBox(height: 12),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// Generic stat chip (e.g., “Invites · 12”)
class StatChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData? icon;

  const StatChip({
    super.key,
    required this.label,
    required this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Chip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: cs.onSurfaceVariant)
          : null,
      label: Text('$label · $count', style: t.bodySmall),
      side: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
      backgroundColor: isDark
          ? cs.surfaceContainerHighest.withOpacity(.22)
          : cs.surfaceContainerHighest.withOpacity(.28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }
}

/// Role-aware stat chip that uses the global i18n helper for labels.
/// Example: RoleStatChip(role: GroupRole.admin, count: 5)
class RoleStatChip extends StatelessWidget {
  final GroupRole role;
  final int count;
  final IconData? icon;

  const RoleStatChip({
    super.key,
    required this.role,
    required this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Localized label via global helper
    final label = roleLabelOf(context, role);
    return StatChip(label: label, count: count, icon: icon);
  }
}
