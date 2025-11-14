// lib/c-frontend/home/widgets/see_all_groups_button.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SeeAllGroupsButton extends StatelessWidget {
  const SeeAllGroupsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final bg = cs.secondary;
    final fg = ThemeColors.contrastOn(bg);
    final shadow = ThemeColors.cardShadow(context);
    final radius = BorderRadius.circular(12);

    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => Navigator.pushNamed(context, AppRoutes.showGroups),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.seeAll.isNotEmpty ? loc.seeAll : loc.viewDetails,
                style: t.buttonText.copyWith(color: fg),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}
