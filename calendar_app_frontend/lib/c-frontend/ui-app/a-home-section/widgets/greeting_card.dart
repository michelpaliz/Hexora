// lib/c-frontend/home/widgets/greeting_card.dart
import 'package:flutter/material.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/f-themes/app_colors/palette/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

class GreetingCard extends StatelessWidget {
  final User user;
  const GreetingCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final displayName = (user.name.isNotEmpty ? user.name : user.userName);
    final prettyName = displayName.isEmpty
        ? 'User'
        : displayName[0].toUpperCase() + displayName.substring(1);

    final bg = ThemeColors.cardBg(context);
    final onBg = ThemeColors.textPrimary(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: cs.outlineVariant.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.cardShadow(context),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          l.welcomeGroupView(prettyName),
          style: t.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: onBg,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
