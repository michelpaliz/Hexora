import 'package:flutter/material.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/f-themes/app_colors/tools_colors/theme_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class InfoHelpButton extends StatelessWidget {
  const InfoHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).aboutListTileTitle('Hexora'),
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => _showInfoSheet(context),
    );
  }

  void _showInfoSheet(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = context.read<UserDomain?>()?.user;
    final bg = ThemeColors.getCardBackgroundColor(context);
    final onBg = ThemeColors.getContrastTextColorForBackground(bg);
    final hint = user != null
        ? loc.welcomeGroupView(user.name)
        : loc.groups; // fallback short label

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: onBg),
                  const SizedBox(width: 8),
                  Text(
                    loc.groupSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: onBg,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hint,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: onBg.withOpacity(.9)),
              ),
              const SizedBox(height: 16),
              Text(
                // small extra tip; change or localize if you want
                loc.upcomingEventsForThisGroup,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: onBg.withOpacity(.7)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
