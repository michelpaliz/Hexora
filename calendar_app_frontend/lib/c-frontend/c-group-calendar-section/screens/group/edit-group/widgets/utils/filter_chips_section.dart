import 'package:flutter/material.dart';
import 'package:hexora/f-themes/app_colors/themes/text_styles/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';

class FilterChipsSection extends StatelessWidget {
  final bool showAccepted;
  final bool showPending;
  final bool showNotWantedToJoin;
  final bool showNewUsers;
  final bool showExpired;

  final void Function(String filter, bool isSelected) onFilterChange;

  const FilterChipsSection({
    Key? key,
    required this.showAccepted,
    required this.showPending,
    required this.showNotWantedToJoin,
    required this.showNewUsers,
    required this.showExpired,
    required this.onFilterChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(
          context: context,
          keyId: 'Accepted',
          label: 'Accepted',
          selected: showAccepted,
          textStyle: t.bodyMedium,
        ),
        _chip(
          context: context,
          keyId: 'Pending',
          label: 'Pending',
          selected: showPending,
          textStyle: t.bodyMedium,
        ),
        _chip(
          context: context,
          keyId: 'NotAccepted',
          label: 'NotAccepted',
          selected: showNotWantedToJoin,
          textStyle: t.bodyMedium,
        ),
        _chip(
          context: context,
          keyId: 'NewUsers',
          label: 'New Users',
          selected: showNewUsers,
          textStyle: t.bodyMedium,
        ),
        _chip(
          context: context,
          keyId: 'Expired',
          label: 'Expired',
          selected: showExpired,
          textStyle: t.bodyMedium,
        ),
      ],
    );
  }

  Widget _chip({
    required BuildContext context,
    required String keyId,
    required String label,
    required bool selected,
    required TextStyle textStyle,
  }) {
    final palette = _paletteFor(context, keyId);
    final inactiveBg = palette.inactiveBg;
    final activeBg = palette.activeBg;
    final inactiveOn = ThemeColors.contrastOn(inactiveBg);
    final activeOn = ThemeColors.contrastOn(activeBg);
    final glow = ThemeColors.chipGlow(context, activeBg);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        boxShadow: selected
            ? [BoxShadow(color: glow, blurRadius: 10, spreadRadius: 2)]
            : const [],
      ),
      child: FilterChip(
        avatar: Icon(
          palette.icon,
          size: 18,
          color: selected ? activeOn : inactiveOn.withOpacity(0.9),
        ),
        label: Text(
          label,
          style: textStyle.copyWith(
            color: selected ? activeOn : inactiveOn.withOpacity(0.95),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        backgroundColor: inactiveBg,
        selectedColor: activeBg,
        side: BorderSide(
          color: selected
              ? activeBg
              : Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onSelected: (val) => onFilterChange(label, val),
      ),
    );
  }

  _ChipPalette _paletteFor(BuildContext context, String keyId) {
    final cs = Theme.of(context).colorScheme;
    switch (keyId) {
      case 'Accepted':
        return _ChipPalette(
          icon: Icons.check_circle,
          activeBg: cs.primary.withOpacity(0.92),
          inactiveBg: cs.primary.withOpacity(0.18),
        );
      case 'Pending':
        return _ChipPalette(
          icon: Icons.hourglass_bottom,
          activeBg: cs.tertiary.withOpacity(0.90),
          inactiveBg: cs.tertiary.withOpacity(0.18),
        );
      case 'NotAccepted':
        return _ChipPalette(
          icon: Icons.cancel,
          activeBg: cs.error.withOpacity(0.95),
          inactiveBg: cs.error.withOpacity(0.20),
        );
      case 'NewUsers':
        return _ChipPalette(
          icon: Icons.person_add_alt_1,
          activeBg: cs.secondary.withOpacity(0.90),
          inactiveBg: cs.secondary.withOpacity(0.18),
        );
      case 'Expired':
        return _ChipPalette(
          icon: Icons.schedule,
          activeBg: cs.surfaceTint.withOpacity(0.85),
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
