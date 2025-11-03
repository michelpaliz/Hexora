// lib/c-frontend/home/widgets/see_all_groups_button.dart
import 'package:flutter/material.dart';
import 'package:hexora/c-frontend/routes/appRoutes.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class SeeAllGroupsButton extends StatelessWidget {
  const SeeAllGroupsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bg = ThemeColors.getButtonBackgroundColor(context, isSecondary: true);
    final fg = ThemeColors.getButtonTextColor(context);
    final shadow = ThemeColors.getCardShadowColor(context);
    final loc = AppLocalizations.of(context)!;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.pushNamed(context, AppRoutes.showGroups),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (loc.seeAll.isNotEmpty ? loc.seeAll : loc.viewDetails),
                style: t.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w600),
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
