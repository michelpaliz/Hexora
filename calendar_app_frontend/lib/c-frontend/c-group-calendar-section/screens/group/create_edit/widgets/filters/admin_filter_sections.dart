import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class AdminWithFiltersSection extends StatelessWidget {
  final User currentUser;
  final bool showAccepted;
  final bool showPending;
  final bool showNotWantedToJoin;
  final bool showNewUsers;
  final bool showExpired;

  /// Accepts either a localized label String or any key/enum (parent resolves).
  final void Function(dynamic filter, bool isSelected) onFilterChange;

  const AdminWithFiltersSection({
    super.key,
    required this.currentUser,
    required this.showAccepted,
    required this.showPending,
    required this.showNotWantedToJoin,
    required this.showNewUsers,
    required this.showExpired,
    required this.onFilterChange,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Surfaces and contrasts via the new helpers
    final containerBg = ThemeColors.containerBg(context);
    final cardBg = ThemeColors.cardBg(context);
    final onContainer = ThemeColors.contrastOn(containerBg);

    return Card(
      color: cardBg,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      shadowColor: ThemeColors.cardShadow(context),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.secondary.withOpacity(0.15),
                  child: Icon(Icons.person, color: cs.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser.userName,
                      style: t.titleLarge.copyWith(
                        color: ThemeColors.textPrimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      loc.administrator,
                      style: t.bodySmall.copyWith(
                        color:
                            ThemeColors.textPrimary(context).withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Filters
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  context,
                  keyId: 'newUsers',
                  label: loc.newUsers,
                  selected: showNewUsers,
                ),
                _buildFilterChip(
                  context,
                  keyId: 'pending',
                  label: loc.pending,
                  selected: showPending,
                ),
                _buildFilterChip(
                  context,
                  keyId: 'accepted',
                  label: loc.accepted,
                  selected: showAccepted,
                ),
                _buildFilterChip(
                  context,
                  keyId: 'notAccepted',
                  label: loc.notAccepted,
                  selected: showNotWantedToJoin,
                ),
                _buildFilterChip(
                  context,
                  keyId: 'expired',
                  label: loc.expired,
                  selected: showExpired,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String keyId,
    required String label,
    required bool selected,
  }) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    // Map each filter to a semantic role from ColorScheme
    final _ChipPalette palette = _paletteFor(context, keyId);

    final inactiveBg = palette.inactiveBg;
    final activeBg = palette.activeBg;
    final inactiveOn = ThemeColors.contrastOn(inactiveBg);
    final activeOn = ThemeColors.contrastOn(activeBg);
    final glow = ThemeColors.chipGlow(context, activeBg);

    return FilterChip(
      avatar: Icon(
        palette.icon,
        size: 18,
        color: selected ? activeOn : inactiveOn.withOpacity(0.9),
      ),
      label: Text(
        label,
        style: t.bodyMedium.copyWith(
          color: selected ? activeOn : inactiveOn.withOpacity(0.95),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(
        color: selected ? activeBg : cs.outlineVariant.withOpacity(0.4),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: inactiveBg,
      selectedColor: activeBg,
      shadowColor: glow,
      pressElevation: 0,
      onSelected: (bool isSelected) => onFilterChange(label, isSelected),
    );
  }

  _ChipPalette _paletteFor(BuildContext context, String keyId) {
    final cs = Theme.of(context).colorScheme;

    switch (keyId) {
      case 'accepted':
        return _ChipPalette(
          icon: Icons.check_circle,
          activeBg: cs.primary.withOpacity(0.92),
          inactiveBg: cs.primary.withOpacity(0.18),
        );
      case 'pending':
        return _ChipPalette(
          icon: Icons.hourglass_empty,
          activeBg: cs.tertiary.withOpacity(0.90),
          inactiveBg: cs.tertiary.withOpacity(0.18),
        );
      case 'notAccepted':
        return _ChipPalette(
          icon: Icons.cancel,
          activeBg: cs.error.withOpacity(0.95),
          inactiveBg: cs.error.withOpacity(0.20),
        );
      case 'newUsers':
        return _ChipPalette(
          icon: Icons.group_add,
          activeBg: cs.secondary.withOpacity(0.90),
          inactiveBg: cs.secondary.withOpacity(0.18),
        );
      case 'expired':
        return _ChipPalette(
          icon: Icons.schedule,
          activeBg: cs.surfaceTint.withOpacity(0.85), // nice accent in M3
          inactiveBg: cs.surfaceTint.withOpacity(0.18),
        );
      default:
        return _ChipPalette(
          icon: Icons.label,
          activeBg: cs.primaryContainer.withOpacity(0.85),
          inactiveBg: cs.primaryContainer.withOpacity(0.22),
        );
    }
  }
}

class _ChipPalette {
  final IconData icon;
  final Color activeBg;
  final Color inactiveBg;

  const _ChipPalette({
    required this.icon,
    required this.activeBg,
    required this.inactiveBg,
  });
}
